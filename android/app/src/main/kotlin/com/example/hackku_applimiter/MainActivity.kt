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

class MainActivity : FlutterActivity() {
    private val channelName = "uniqueChannelName"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val method = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)

        method.setMethodCallHandler { call, result ->
            if(call.method == "userName"){
                Toast.makeText(this, "FreeTrained", Toast.LENGTH_LONG).show()
            }
            else if (call.method == "getInstalledApps") {
                val appsList = getVisibleApps()
                result.success(appsList)
            }
            else {
                result.notImplemented()
            }
        }
    }

    // functions for implemention app list
    private fun getVisibleApps(): List<Map<String, String>> {
        val pm = context.packageManager
        val apps = pm.getInstallApplications(PackageManager.GET_META_DATA)
        val appList = ArrayList<Map<String, String>>()

        for (appInfo in apps) {
            if (pm.getLaunchIntentForPackage(appInfo.packageName) != null) {
                val appMap = HashMap <String, String>()
                appMap["name"] = appInfo.loadLabel(pm).toString()
                appMap["packageId"] = appInfo.packageName
                appList.add(addMap)
            }
        }
        return appList.sortedBy {it["name"]?.lowercase()}
    }

    // implement function for permissions check
    override fun onResume() {
        super.onResume()
        evaluateUsageStatsPermission()
    }

    private fun evaluateUsageStatsPermission() {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.unsafeCheckOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            packageName
        )
        if (mode == AppOpsManager.MODE_ALLOWED) {
            Log.d("UsageStatsCheck", "GRANTED: PACKAGE_USAGE_STATS is active")
        }
        else {
            promptForUsageStats()
        }
    }
    private fun promptForUsageStats() {
        Log.d("UsageStatsCheck", "DENIED: promptForUsageStats() called.")
    }
}