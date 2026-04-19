package com.example.hackku_applimiter

import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// imports needed for permissions checker
import android.app.AppOpsManager // includes funcs: onResume(), evaluateUsageStatsPermission(), getSystemService
import android.content.Context
import android.os.Process
import android.util.Log

// imports needed for OS giving us app list
import android.content.pm.PackageManager
import java.util.ArrayList
import java.util.HashMap

// imports needed for getting images of the android OS apps
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Build
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.ByteArrayOutputStream

//
import android.content.Intent // Add this

class MainActivity : FlutterActivity() {
    private val channelName = "uniqueChannelName"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val method = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)

        method.setMethodCallHandler { call, result ->
            if (call.method == "userName"){
                Toast.makeText(this, "FreeTrained", Toast.LENGTH_LONG).show()
            }
            else if (call.method == "getInstalledApps") {
                CoroutineScope(Dispatchers.IO).launch {
                    val appsList = getVisibleApps()
                    withContext(Dispatchers.Main) {
                        result.success(appsList)
                    }
                }
            }
            // --- NEW: Handle Config Save and Start Service ---
            else if (call.method == "saveLimiterConfig") {
                val jsonString = call.arguments as String

                // Save JSON natively
                val prefs = getSharedPreferences("AppLimiterPrefs", Context.MODE_PRIVATE)
                prefs.edit().putString("limiterConfig", jsonString).apply()

                // Boot the Native Background Engine
                val serviceIntent = Intent(this, LimiterService::class.java)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    startForegroundService(serviceIntent)
                } else {
                    startService(serviceIntent)
                }

                result.success(true)
            }
            else {
                result.notImplemented()
            }
        }
    }

    // functions for implemention app list
    private fun getVisibleApps(): List<Map<String, Any>> {
        val pm = context.packageManager
        val apps = pm.getInstalledApplications(PackageManager.GET_META_DATA)
        val appList = ArrayList<Map<String, Any>>()

        for (appInfo in apps) {
            if (pm.getLaunchIntentForPackage(appInfo.packageName) != null) {
                val appMap = HashMap <String, Any>()
                appMap["name"] = appInfo.loadLabel(pm).toString()
                appMap["packageId"] = appInfo.packageName

                val iconDrawable = appInfo.loadIcon(pm)
                val bitmap = drawableToBitmap(iconDrawable)
                val stream = ByteArrayOutputStream()

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    bitmap.compress(Bitmap.CompressFormat.WEBP_LOSSY, 60, stream)
                }
                else {
                    @Suppress("DEPRECATION")
                    bitmap.compress(Bitmap.CompressFormat.WEBP, 60, stream)
                }
                appMap["icon"] = stream.toByteArray()

                appList.add(appMap)
            }
        }
        return appList.sortedBy {(it["name"] as String).lowercase()}
    }

    // implement function for app icon when searching for apps
    private fun drawableToBitmap(drawable: Drawable): Bitmap {
        if (drawable is BitmapDrawable && drawable.bitmap != null) {
            return drawable.bitmap
        }
        val bitmap = if (drawable.intrinsicWidth <= 0 || drawable.intrinsicHeight <= 0) {
            Bitmap.createBitmap(1,1, Bitmap.Config.ARGB_8888)
        }
        else {
            Bitmap.createBitmap(drawable.intrinsicWidth, drawable.intrinsicHeight, Bitmap.Config.ARGB_8888)
        }
        val canvas  = Canvas(bitmap)
        drawable.setBounds(0,0,canvas.width, canvas.height)
        drawable.draw(canvas)
        return bitmap
    }

    // implement function for permissions check
    override fun onResume() {
        super.onResume()
        evaluateUsageStatsPermission()
    }

    private fun evaluateUsageStatsPermission() {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager

        // Safely check permission based on the Android version of the user's phone
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), packageName)
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), packageName)
        }

        if (mode == AppOpsManager.MODE_ALLOWED) {
            Log.d("UsageStatsCheck", "GRANTED: PACKAGE_USAGE_STATS is active")
        } else {
            promptForUsageStats()
        }
    }
    private fun promptForUsageStats() {
        Log.d("UsageStatsCheck", "DENIED: promptForUsageStats() called.")
    }
}