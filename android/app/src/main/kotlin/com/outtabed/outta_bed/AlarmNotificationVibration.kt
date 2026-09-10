package com.outtabed.outta_bed

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.app.NotificationCompat

/**
 * Samsung devices often block direct Vibrator calls while alarm audio plays.
 * Re-posting a high-priority notification with a vibration pattern works reliably.
 */
object AlarmNotificationVibration {
    const val CHANNEL_ID = "outta_bed_alarm_vibrate_v2"
    private const val BASE_NOTIFICATION_ID = 424250
    private val pattern = longArrayOf(0, 900, 300, 900, 300, 1200)

    private var handler: Handler? = null
    private var running = false
    private var tick = 0

    fun start(context: Context, label: String) {
        if (running) return
        running = true
        tick = 0
        ensureChannel(context.applicationContext)

        val appContext = context.applicationContext
        val manager = appContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val handler = Handler(Looper.getMainLooper())
        this.handler = handler

        val runnable = object : Runnable {
            override fun run() {
                if (!running) return
                val id = BASE_NOTIFICATION_ID + (tick % 3)
                // Cancel then re-post so Android re-triggers channel vibration.
                manager.cancel(id)
                manager.notify(
                    id,
                    NotificationCompat.Builder(appContext, CHANNEL_ID)
                        .setSmallIcon(R.mipmap.ic_launcher)
                        .setContentTitle(label)
                        .setContentText("Vibrating — wake up!")
                        .setCategory(NotificationCompat.CATEGORY_ALARM)
                        .setPriority(NotificationCompat.PRIORITY_MAX)
                        .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                        .setOngoing(true)
                        .setSilent(true)
                        .setVibrate(pattern)
                        .setDefaults(NotificationCompat.DEFAULT_VIBRATE)
                        .build(),
                )
                tick++
                handler.postDelayed(this, 1800)
            }
        }
        handler.post(runnable)
    }

    fun stop(context: Context) {
        running = false
        handler?.removeCallbacksAndMessages(null)
        handler = null
        val manager = context.applicationContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        for (id in BASE_NOTIFICATION_ID until BASE_NOTIFICATION_ID + 3) {
            manager.cancel(id)
        }
    }

    private fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val existing = manager.getNotificationChannel(CHANNEL_ID)
        if (existing != null) return

        val channel = NotificationChannel(
            CHANNEL_ID,
            "OuttaBed Vibration",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Alarm vibration"
            enableVibration(true)
            vibrationPattern = pattern
            setSound(null, null)
            enableLights(false)
            setBypassDnd(true)
            lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
        }
        manager.createNotificationChannel(channel)
    }
}
