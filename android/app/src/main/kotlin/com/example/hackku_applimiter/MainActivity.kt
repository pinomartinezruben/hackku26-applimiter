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

class MainActivity : FlutterActivity() {
    private val channelName = "uniqueChannelName"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val method = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)

        method.setMethodCallHandler { call, result ->
            if(call.method == "userName"){
                Toast.makeText(this, "FreeTrained", Toast.LENGTH_LONG).show()
            }

        }
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