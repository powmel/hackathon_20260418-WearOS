package com.sabori.sabori_app

import android.app.*
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat
import java.util.Calendar

class UsageMonitorService : Service() {

    companion object {
        const val CHANNEL_ID_FOREGROUND = "usage_monitor_channel"
        const val CHANNEL_ID_ALERT = "rhino_alert"
        const val NOTIFICATION_ID_FOREGROUND = 1
        const val CHECK_INTERVAL_MS = 30000L // 30秒ごとにチェック

        const val ACTION_START = "START"
        const val ACTION_STOP = "STOP"
        const val EXTRA_TIME_LIMIT = "time_limit"
    }

    private val handler = Handler(Looper.getMainLooper())
    private var isRunning = false
    private var timeLimitMinutes = 60 // デフォルト60分
    private var lastAlertTime = 0L
    private val alertCooldownMs = 300000L // 5分間は再通知しない

    private val targetPackages = listOf(
        "com.instagram.android",
        "com.twitter.android",
        "com.zhiliaoapp.musically"
    )

    private val checkRunnable = object : Runnable {
        override fun run() {
            if (isRunning) {
                checkUsageAndNotify()
                handler.postDelayed(this, CHECK_INTERVAL_MS)
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannels()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                timeLimitMinutes = intent.getIntExtra(EXTRA_TIME_LIMIT, 60)
                startMonitoring()
            }
            ACTION_STOP -> {
                stopMonitoring()
            }
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // 常駐通知用チャンネル
            val foregroundChannel = NotificationChannel(
                CHANNEL_ID_FOREGROUND,
                "使用時間監視",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "SNS使用時間をリアルタイム監視中"
            }

            // アラート通知用チャンネル
            val alertChannel = NotificationChannel(
                CHANNEL_ID_ALERT,
                "サイの警告通知",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "SNS使用時間超過の警告"
                enableVibration(true)
            }

            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(foregroundChannel)
            manager.createNotificationChannel(alertChannel)
        }
    }

    private fun startMonitoring() {
        if (isRunning) return
        isRunning = true

        val notification = createForegroundNotification()
        startForeground(NOTIFICATION_ID_FOREGROUND, notification)

        handler.post(checkRunnable)
    }

    private fun stopMonitoring() {
        isRunning = false
        handler.removeCallbacks(checkRunnable)
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun createForegroundNotification(): Notification {
        val intent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID_FOREGROUND)
            .setContentTitle("🦏 SNS監視中")
            .setContentText("制限時間: ${timeLimitMinutes}分")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
    }

    private fun checkUsageAndNotify() {
        val totalMinutes = getTodayTotalUsageMinutes()

        // 常駐通知を更新
        updateForegroundNotification(totalMinutes)

        // 制限超過チェック
        if (totalMinutes >= timeLimitMinutes) {
            val now = System.currentTimeMillis()
            if (now - lastAlertTime > alertCooldownMs) {
                showAlertNotification(totalMinutes)
                lastAlertTime = now
            }
        }
    }

    private fun getTodayTotalUsageMinutes(): Int {
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

        var totalMs = 0L
        for (stat in stats) {
            if (stat.packageName in targetPackages) {
                totalMs += stat.totalTimeInForeground
            }
        }

        return (totalMs / 60000).toInt()
    }

    private fun updateForegroundNotification(currentMinutes: Int) {
        val intent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val status = if (currentMinutes >= timeLimitMinutes) "⚠️ 制限超過！" else "✓ 監視中"

        val notification = NotificationCompat.Builder(this, CHANNEL_ID_FOREGROUND)
            .setContentTitle("🦏 $status")
            .setContentText("今日の使用: ${currentMinutes}分 / 制限: ${timeLimitMinutes}分")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()

        val manager = getSystemService(NotificationManager::class.java)
        manager.notify(NOTIFICATION_ID_FOREGROUND, notification)
    }

    private fun showAlertNotification(currentMinutes: Int) {
        val messages = listOf(
            "SNS使いすぎサイ！もう${currentMinutes}分も使ってるサイ！",
            "スマホを置くサイ！目が疲れるサイ！",
            "制限時間を超えたサイ！休憩するサイ！",
            "サイは怒ってるサイ！スマホから離れるサイ！"
        )
        val message = messages.random()

        val intent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_ID_ALERT)
            .setContentTitle("🦏 SNS使いすぎサイ！")
            .setContentText(message)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .build()

        val manager = getSystemService(NotificationManager::class.java)
        manager.notify(System.currentTimeMillis().toInt(), notification)
    }
}
