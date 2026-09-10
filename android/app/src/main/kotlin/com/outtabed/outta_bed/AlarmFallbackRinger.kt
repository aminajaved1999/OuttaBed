package com.outtabed.outta_bed

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.Ringtone
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import androidx.core.app.NotificationCompat

/**
 * Last-resort alarm playback when the foreground service cannot start
 * (common on Samsung / Android 14+ background restrictions).
 */
object AlarmFallbackRinger {
    private const val CHANNEL_ID = "outta_bed_alarm_fallback"
    private var ringtone: Ringtone? = null
    private var vibrator: Vibrator? = null

    fun ring(
        context: Context,
        alarmId: String,
        label: String,
        soundUri: String?,
        volume: Float,
    ) {
        val appContext = context.applicationContext
        routeToSpeaker(appContext)
        startVibration(appContext)
        playSound(appContext, soundUri)
        showNotification(appContext, alarmId, label)
        launchUi(appContext, alarmId)
    }

    fun stop(context: Context) {
        ringtone?.stop()
        ringtone = null
        vibrator?.cancel()
        vibrator = null
        val manager = context.applicationContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.cancel(AlarmRingService.NOTIFICATION_ID)
    }

    private fun routeToSpeaker(context: Context) {
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        audioManager.mode = AudioManager.MODE_NORMAL
        audioManager.stopBluetoothSco()
        audioManager.isBluetoothScoOn = false
        audioManager.isSpeakerphoneOn = true
    }

    private fun playSound(context: Context, soundUri: String?) {
        val uri = resolveSoundUri(context, soundUri)
        ringtone = RingtoneManager.getRingtone(context, uri)?.apply {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                isLooping = true
            }
            audioAttributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
            play()
        }
    }

    private fun resolveSoundUri(context: Context, soundUri: String?): Uri {
        if (!soundUri.isNullOrBlank()) {
            if (soundUri.startsWith("asset://")) {
                val rawName = soundUri.removePrefix("asset://")
                val resId = context.resources.getIdentifier(rawName, "raw", context.packageName)
                if (resId != 0) {
                    return Uri.parse("android.resource://${context.packageName}/$resId")
                }
            }
            return Uri.parse(soundUri)
        }
        return RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
    }

    private fun startVibration(context: Context) {
        vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val manager = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            manager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
        val pattern = longArrayOf(0, 700, 250, 700, 250, 900)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator?.vibrate(
                VibrationEffect.createWaveform(pattern, 0),
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build(),
            )
        } else {
            @Suppress("DEPRECATION")
            vibrator?.vibrate(pattern, 0)
        }
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
