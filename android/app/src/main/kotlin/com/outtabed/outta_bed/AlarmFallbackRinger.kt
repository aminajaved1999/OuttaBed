package com.outtabed.outta_bed

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat

/**
 * Last-resort alarm playback when the foreground service cannot start
 * (common on Samsung / Android 14+ background restrictions).
 */
object AlarmFallbackRinger {
    private const val CHANNEL_ID = "outta_bed_alarm_fallback"

    fun ring(
        context: Context,
        alarmId: String,
        label: String,
        soundUri: String?,
        volume: Float,
    ) {
        val appContext = context.applicationContext
        AlarmRinger.ring(appContext, soundUri, volume, vibrate = true)
        showNotification(appContext, alarmId, label)
        launchUi(appContext, alarmId)
    }

    fun stop(context: Context) {
        AlarmRinger.stop(context.applicationContext)
        val manager = context.applicationContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.cancel(AlarmRingService.NOTIFICATION_ID)
    }

    private fun showNotification(context: Context, alarmId: String, label: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "OuttaBed Alarms",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Alarm notifications"
                setSound(null, null)
                enableVibration(true)
            }
            val manager = context.getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }

        val fullScreenIntent = PendingIntent.getActivity(
            context,
            alarmId.hashCode(),
            Intent(context, MainActivity::class.java).apply {
                putExtra(AlarmRingService.EXTRA_ALARM_ID, alarmId)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(label)
            .setContentText("Wake up — speaker + vibration")
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setFullScreenIntent(fullScreenIntent, true)
            .build()

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(AlarmRingService.NOTIFICATION_ID, notification)
    }

    private fun launchUi(context: Context, alarmId: String) {
        val launchIntent = Intent(context, MainActivity::class.java).apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP,
            )
            putExtra(AlarmRingService.EXTRA_ALARM_ID, alarmId)
        }
        context.startActivity(launchIntent)
    }
}
