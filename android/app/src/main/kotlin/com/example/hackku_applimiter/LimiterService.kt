package com.example.hackku_applimiter

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import kotlinx.coroutines.*
import org.json.JSONObject
import java.util.Calendar

import android.content.pm.ServiceInfo // Add this import at the top






class LimiterService : Service() {
    private val scope = CoroutineScope(Dispatchers.IO + Job())
    private val CHANNEL_ID = "AppLimiterServiceChannel"

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("AppLimiter Active")
            .setContentText("Monitoring your app usage...")
            .setSmallIcon(android.R.drawable.ic_secure) // Default icon for MVP
            .build()

        // THE FIX: Explicitly state the service type when starting it
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(1, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(1, notification)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startMonitoring()
        return START_STICKY
    }

    private fun startMonitoring() {
        scope.launch {
            val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val prefs = getSharedPreferences("AppLimiterPrefs", Context.MODE_PRIVATE)

            while (isActive) {
                // 1. Read the latest config from Flutter
                val configStr = prefs.getString("limiterConfig", null)
                if (configStr != null) {
                    val config = JSONObject(configStr)
                    val appsArray = config.getJSONArray("packages")
                    val targetApps = mutableListOf<String>()
                    for (i in 0 until appsArray.length()) targetApps.add(appsArray.getString(i))

                    val budgetMinutes = config.getInt("sharedBudget")
                    val budgetMillis = budgetMinutes * 60 * 1000L

                    // 2. Find the current app on screen
                    val time = System.currentTimeMillis()
                    val events = usm.queryEvents(time - 10000, time) // Look at last 10 seconds
                    var currentForegroundApp = ""
                    val event = UsageEvents.Event()
                    
                    while (events.hasNextEvent()) {
                        events.getNextEvent(event)
                        if (event.eventType == UsageEvents.Event.ACTIVITY_RESUMED) {
                            currentForegroundApp = event.packageName
                        }
                    }

                    // 3. If they are in a targeted app, check their time
                    if (targetApps.contains(currentForegroundApp)) {
                        // Get start of today
                        val cal = Calendar.getInstance()
                        cal.set(Calendar.HOUR_OF_DAY, 0)
                        cal.set(Calendar.MINUTE, 0)
                        
                        val statsMap = usm.queryAndAggregateUsageStats(cal.timeInMillis, time)
                        val appStats = statsMap[currentForegroundApp]

                        if (appStats != null && appStats.totalTimeInForeground >= budgetMillis) {
                            // 4. LIMIT REACHED! Launch Blocker.
                            launchBlocker()
                        }
                    }
                }
                // Sleep for 2 seconds before polling again
                delay(2000)
            }
        }
    }

    private fun launchBlocker() {
        val blockIntent = Intent(this, BlockActivity::class.java)
        blockIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        startActivity(blockIntent)
    }

    override fun onDestroy() {
        super.onDestroy()
        scope.cancel()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "AppLimiter Background Service",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }
}