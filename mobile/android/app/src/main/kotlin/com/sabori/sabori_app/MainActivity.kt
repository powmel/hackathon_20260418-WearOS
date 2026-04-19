package com.sabori.sabori_app

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.sabori.app/usage_stats"
    private val MONITOR_CHANNEL = "com.sabori.app/monitor"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 使用統計チャンネル
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasPermission" -> {
                    result.success(hasUsageStatsPermission())
                }
                "requestPermission" -> {
                    val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                    startActivity(intent)
                    result.success(null)
                }
                "getUsageStats" -> {
                    if (hasUsageStatsPermission()) {
                        val stats = getUsageStats()
                        result.success(stats)
                    } else {
                        result.error("PERMISSION_DENIED", "Usage stats permission not granted", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // 監視サービスチャンネル
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MONITOR_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startMonitoring" -> {
                    val timeLimit = call.argument<Int>("timeLimit") ?: 60
                    startMonitoringService(timeLimit)
                    result.success(true)
                }
                "stopMonitoring" -> {
                    stopMonitoringService()
                    result.success(true)
                }
                "isMonitoring" -> {
                    result.success(isServiceRunning())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.unsafeCheckOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            android.os.Process.myUid(),
            packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun getUsageStats(): Map<String, Long> {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager

        val calendar = Calendar.getInstance()
        val endTime = calendar.timeInMillis

        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        val startTime = calendar.timeInMillis

        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startTime,
            endTime
        )

        val targetPackages = listOf(
            "com.instagram.android",
            "com.twitter.android",
            "com.zhiliaoapp.musically"
        )

        val result = mutableMapOf<String, Long>()
        for (stat in stats) {
            if (stat.packageName in targetPackages) {
                result[stat.packageName] = stat.totalTimeInForeground / 60000
            }
        }

        return result
    }

    private fun startMonitoringService(timeLimit: Int) {
        val intent = Intent(this, UsageMonitorService::class.java).apply {
            action = UsageMonitorService.ACTION_START
            putExtra(UsageMonitorService.EXTRA_TIME_LIMIT, timeLimit)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stopMonitoringService() {
        val intent = Intent(this, UsageMonitorService::class.java).apply {
            action = UsageMonitorService.ACTION_STOP
        }
        startService(intent)
    }

    private fun isServiceRunning(): Boolean {
        val manager = getSystemService(Context.ACTIVITY_SERVICE) as android.app.ActivityManager
        for (service in manager.getRunningServices(Integer.MAX_VALUE)) {
            if (UsageMonitorService::class.java.name == service.service.className) {
                return true
            }
        }
        return false
    }
}
