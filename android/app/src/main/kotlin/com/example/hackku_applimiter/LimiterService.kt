package com.example.hackku_applimiter

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import kotlinx.coroutines.*
import org.json.JSONObject
import java.util.Calendar

// ─────────────────────────────────────────────────────────────────────────────
//  LimiterService — Foreground Service: the real-time enforcement engine.
//
//  Why a foreground service and not WorkManager / alarms?
//  -------------------------------------------------------
//  WorkManager and AlarmManager fire periodically and then stop. They cannot
//  maintain a continuous polling loop. Android's Doze mode will defer alarms
//  by up to 9 minutes in deep-sleep. A Foreground Service with a persistent
//  notification is the only mechanism that keeps a coroutine loop alive while
//  the user is actively using their phone — which is exactly when we need it.
//
//  Why queryEvents() instead of queryAndAggregateUsageStats()?
//  -----------------------------------------------------------
//  queryAndAggregateUsageStats() returns pre-bucketed summaries. Android
//  collects these lazily and can be 15–30 minutes stale. It is useless for
//  a real-time blocker. queryEvents() gives us the raw event stream with
//  millisecond-precision ACTIVITY_RESUMED / ACTIVITY_PAUSED timestamps. We
//  reconstruct elapsed time ourselves by walking the stream — this is the
//  only way to get an accurate sub-second reading.
//
//  The polling loop ticks every 2 000 ms. On each tick:
//    1. Confirm the current wall-clock time is inside the configured window.
//    2. Query the raw event stream from the window's start boundary to now.
//    3. Walk the stream, summing RESUMED→PAUSED (or RESUMED→now) deltas for
//       every restricted package.
//    4. If aggregated foreground milliseconds ≥ budget, launch BlockActivity.
// ─────────────────────────────────────────────────────────────────────────────

class LimiterService : Service() {

    companion object {
        private const val TAG        = "LimiterService"
        private const val CHANNEL_ID = "AppLimiterServiceChannel"
        private const val NOTIF_ID   = 1
        private const val POLL_MS    = 2_000L   // Polling cadence: 2 seconds
    }

    // A SupervisorJob lets individual child coroutines fail without killing
    // the parent scope. If the loop throws an unexpected exception it will
    // be caught inside the while block rather than crashing the service.
    private val serviceJob   = SupervisorJob()
    private val serviceScope = CoroutineScope(Dispatchers.IO + serviceJob)

    // ─────────────────────────────────────────────────────────────────────
    // Service Lifecycle
    // ─────────────────────────────────────────────────────────────────────

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("AppLimiter Active")
            .setContentText("Monitoring your app time budget…")
            .setSmallIcon(android.R.drawable.ic_secure)
            .setOngoing(true)
            .build()

        // Android 14 (API 34) requires FOREGROUND_SERVICE_TYPE declared in the manifest.
        // FOREGROUND_SERVICE_TYPE_SPECIAL_USE covers our non-standard usage-stats loop.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIF_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
            )
        } else {
            startForeground(NOTIF_ID, notification)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Kick off the enforcement loop each time the service is (re)started.
        // START_STICKY tells the OS to automatically restart this service if it
        // is killed by the system — it will receive a null Intent on restart.
        startMonitoringLoop()
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        // Cancel all coroutines cleanly. The SupervisorJob propagates
        // cancellation to every child without throwing exceptions upward.
        serviceJob.cancel()
        Log.d(TAG, "LimiterService destroyed, coroutine scope cancelled.")
    }

    override fun onBind(intent: Intent?): IBinder? = null

    // ─────────────────────────────────────────────────────────────────────
    // Core Monitoring Loop
    // ─────────────────────────────────────────────────────────────────────

    private fun startMonitoringLoop() {
        serviceScope.launch {
            val usm   = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val prefs = getSharedPreferences("AppLimiterPrefs", Context.MODE_PRIVATE)

            while (isActive) {
                try {
                    tick(usm, prefs)
                } catch (e: Exception) {
                    // Log but never crash — the loop must survive bad data.
                    Log.e(TAG, "Error in monitoring tick: ${e.message}", e)
                }
                delay(POLL_MS)
            }
        }
    }

    // ── Single monitoring tick ────────────────────────────────────────────────
    //
    // Called every POLL_MS milliseconds. All the interesting logic lives here.

    private fun tick(usm: UsageStatsManager, prefs: android.content.SharedPreferences) {
        // ── Step 1: Load & parse the config ──────────────────────────────────
        val configStr = prefs.getString("limiterConfig", null) ?: run {
            Log.d(TAG, "No limiterConfig found in SharedPreferences — sleeping.")
            return
        }

        val config      = JSONObject(configStr)
        val model       = config.getString("model")
        val budgetMin   = config.getInt("sharedBudget") // minutes
        val budgetMs    = budgetMin * 60 * 1_000L       // convert to millis

        val targetApps  = mutableListOf<String>()
        val appsArray   = config.getJSONArray("packages")
        for (i in 0 until appsArray.length()) targetApps.add(appsArray.getString(i))

        if (targetApps.isEmpty()) return

        // ── Step 2: Compute today's active window boundaries ──────────────────
        //
        // We build Calendar instances anchored to today's date with the exact
        // hours and minutes from the config. timeInMillis gives us the epoch ms
        // timestamp we use as the queryEvents() start boundary.
        //
        // Example: if startTimeHour=8, startTimeMinute=0 and endTimeHour=9, then:
        //   windowStartMs = today @ 08:00:00.000
        //   windowEndMs   = today @ 09:00:00.000
        //
        // Any usage that occurred at 07:59:59 is EXCLUDED because we only query
        // the event stream starting at windowStartMs.

        val windowStartMs = calendarToMs(
            config.getInt("startTimeHour"),
            config.getInt("startTimeMinute")
        )
        val windowEndMs = calendarToMs(
            config.getInt("endTimeHour"),
            config.getInt("endTimeMinute")
        )

        val now = System.currentTimeMillis()

        // ── Step 3: Guard — only enforce inside the active window ─────────────
        //
        // If the user is outside the configured hours (e.g., it's 7:59 AM and the
        // window starts at 8:00 AM), skip the tick entirely. Do NOT block, do NOT
        // accumulate time.
        if (now < windowStartMs || now > windowEndMs) {
            Log.d(TAG, "Outside active window. Current=$now Window=[$windowStartMs, $windowEndMs]")
            return
        }

        // ── Step 4: Query the raw event stream ────────────────────────────────
        //
        // We ask for ALL events from the window's start boundary up to right now.
        // This gives us a complete picture of every app that was foregrounded or
        // backgrounded since the window opened. The stream is ordered chronologically.
        val usageEvents = usm.queryEvents(windowStartMs, now)

        // ── Step 5: Walk the event stream and sum foreground deltas ───────────
        //
        // Data structure:
        //   lastResumedAt: Map<packageName, resumedTimestampMs>
        //   Tracks the most recent ACTIVITY_RESUMED timestamp for each package.
        //
        // Algorithm:
        //   On ACTIVITY_RESUMED  → record event.timeStamp for that package.
        //   On ACTIVITY_PAUSED   → if we have a recorded resume for that package,
        //                          delta = pauseTimestamp - resumeTimestamp
        //                          add delta to totalForegroundMs
        //                          clear the resume record for that package.
        //   After the stream ends → for any package still in lastResumedAt
        //                          (meaning it is currently in the foreground),
        //                          add (now - resumeTimestamp) as the running delta.
        //
        // This correctly handles:
        //   - Multiple open/close cycles within the window
        //   - The currently-open app (no PAUSED event yet)
        //   - Apps opened before the window that had a PAUSED event at windowStartMs

        val lastResumedAt = mutableMapOf<String, Long>()
        var totalForegroundMs = 0L
        val event = UsageEvents.Event()

        while (usageEvents.hasNextEvent()) {
            usageEvents.getNextEvent(event)
            val pkg = event.packageName

            // Only care about our restricted packages
            if (!targetApps.contains(pkg)) continue

            when (event.eventType) {
                UsageEvents.Event.ACTIVITY_RESUMED -> {
                    // The user opened/switched to this app. Record the timestamp.
                    // If they switched FROM one restricted app TO another restricted app,
                    // the first app will emit a PAUSED event before this RESUMED, so the
                    // state is kept consistent automatically.
                    lastResumedAt[pkg] = event.timeStamp
                    Log.d(TAG, "RESUMED $pkg @ ${event.timeStamp}")
                }

                UsageEvents.Event.ACTIVITY_PAUSED -> {
                    val resumedAt = lastResumedAt.remove(pkg)
                    if (resumedAt != null) {
                        val delta = event.timeStamp - resumedAt
                        totalForegroundMs += delta
                        Log.d(TAG, "PAUSED  $pkg delta=${delta}ms running=${totalForegroundMs}ms")
                    }
                }
            }
        }

        // ── Step 6: Handle currently-foregrounded apps ────────────────────────
        //
        // Any package remaining in lastResumedAt is still in the foreground.
        // We extend its delta to the current moment. This is the key difference
        // between queryEvents() and queryAndAggregateUsageStats() — we capture
        // the live, in-progress session rather than waiting for it to flush.
        for ((pkg, resumedAt) in lastResumedAt) {
            val delta = now - resumedAt
            totalForegroundMs += delta
            Log.d(TAG, "RUNNING $pkg delta=${delta}ms running total=${totalForegroundMs}ms")
        }

        // ── Step 7: Enforce ───────────────────────────────────────────────────
        //
        // Convert aggregated ms to a readable value for logging, then compare
        // to the budget. If exceeded, launch BlockActivity.

        val totalForegroundMin = totalForegroundMs / (1_000 * 60)
        Log.d(TAG, "Total foreground: ${totalForegroundMs}ms (${totalForegroundMin}min) Budget: ${budgetMin}min")

        if (totalForegroundMs >= budgetMs) {
            Log.w(TAG, "BUDGET EXCEEDED. Launching blocker.")
            launchBlocker()
        }
    }

    // ── Utility: build epoch milliseconds for a given H:M on today's date ────
    //
    // We intentionally set SECOND and MILLISECOND to 0 so the boundary snaps
    // cleanly to the minute. This avoids off-by-one timing issues if the system
    // clock drifts slightly between ticks.

    private fun calendarToMs(hour: Int, minute: Int): Long {
        val cal = Calendar.getInstance()
        cal.set(Calendar.HOUR_OF_DAY, hour)
        cal.set(Calendar.MINUTE,      minute)
        cal.set(Calendar.SECOND,      0)
        cal.set(Calendar.MILLISECOND, 0)
        return cal.timeInMillis
    }

    // ── Launch the inescapable blocker activity ───────────────────────────────
    //
    // FLAG_ACTIVITY_NEW_TASK    — required when starting an Activity from a Service
    //                             (Services don't have their own task stack).
    // FLAG_ACTIVITY_CLEAR_TASK  — destroys whatever task is currently in front
    //                             and starts BlockActivity as the root. The user
    //                             cannot press Back to return because there IS
    //                             nothing behind it in the task stack.
    // FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS — BlockActivity will not appear in the
    //                             Recent Apps screen, making it harder to dismiss.
    //
    // Re-entry protection: if the user presses the Recent Apps button and taps
    // the restricted app, our 2-second polling loop will fire again within 2 s
    // and re-launch BlockActivity, trapping them back instantly.

    private fun launchBlocker() {
        val intent = Intent(this, BlockActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TASK or
                    Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS
        }
        startActivity(intent)
    }

    // ─────────────────────────────────────────────────────────────────────
    // Notification Channel (required Android O+)
    // ─────────────────────────────────────────────────────────────────────

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "AppLimiter Background Service",
                NotificationManager.IMPORTANCE_LOW  // IMPORTANCE_LOW = no sound
            ).apply {
                description = "Monitors app usage and enforces time limits."
            }
            getSystemService(NotificationManager::class.java)
                ?.createNotificationChannel(channel)
        }
    }
}