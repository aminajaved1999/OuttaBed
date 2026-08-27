package com.outtabed.outta_bed

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import androidx.core.app.NotificationCompat

class AlarmRingService : Service() {
    private var mediaPlayer: MediaPlayer? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var vibrator: Vibrator? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val alarmId = intent?.getStringExtra(EXTRA_ALARM_ID) ?: return START_NOT_STICKY
        val label = intent.getStringExtra(EXTRA_LABEL) ?: "OuttaBed"
        val soundUri = intent.getStringExtra(EXTRA_SOUND_URI)
        val volume = intent.getFloatExtra(EXTRA_VOLUME, 1f)

        acquireWakeLock()
        routeToSpeaker()
        startForeground(NOTIFICATION_ID, buildNotification(alarmId, label))
        playAlarmSound(soundUri, volume)
        startVibration()
        launchAlarmUi(alarmId)

        return START_STICKY
    }

    private fun acquireWakeLock() {
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = pm.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
            "outtabed:alarm",
        ).apply { acquire(10 * 60 * 1000L) }
    }

    private fun routeToSpeaker() {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        audioManager.mode = AudioManager.MODE_NORMAL
        audioManager.stopBluetoothSco()
        audioManager.isBluetoothScoOn = false
        audioManager.isSpeakerphoneOn = true
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            audioManager.availableCommunicationDevices
                .firstOrNull { it.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER }
                ?.let { audioManager.setCommunicationDevice(it) }
        }
    }

    private fun startVibration() {
        vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val manager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            manager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
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

    private fun stopVibration() {
        vibrator?.cancel()
        vibrator = null
    }

    private fun playAlarmSound(soundUri: String?, volume: Float) {
        stopPlayer()
        val uri = resolveSoundUri(soundUri)

        mediaPlayer = MediaPlayer().apply {
            setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build(),
            )
            setDataSource(this@AlarmRingService, uri)
            isLooping = true
            setVolume(volume.coerceIn(0f, 1f), volume.coerceIn(0f, 1f))
            prepare()
            start()
        }
    }

    private fun resolveSoundUri(soundUri: String?): Uri {
        if (!soundUri.isNullOrBlank()) {
            if (soundUri.startsWith("asset://")) {
                val rawName = soundUri.removePrefix("asset://")
                val resId = resources.getIdentifier(rawName, "raw", packageName)
                if (resId != 0) {
                    return Uri.parse("android.resource://$packageName/$resId")
                }
            }
            return Uri.parse(soundUri)
        }
        return RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
    }

    private fun launchAlarmUi(alarmId: String) {
        val launchIntent = Intent(this, MainActivity::class.java).apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP,
            )
            putExtra(EXTRA_ALARM_ID, alarmId)
        }
        startActivity(launchIntent)
    }

    private fun buildNotification(alarmId: String, label: String): Notification {
        createChannel()
        val fullScreenIntent = PendingIntent.getActivity(
            this,
            alarmId.hashCode(),
            Intent(this, MainActivity::class.java).apply {
                putExtra(EXTRA_ALARM_ID, alarmId)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(label)
            .setContentText("Wake up — speaker + vibration")
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setFullScreenIntent(fullScreenIntent, true)
            .build()
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "OuttaBed Alarms",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Alarm notifications"
            setSound(null, null)
        }
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(channel)
    }

    private fun stopPlayer() {
        mediaPlayer?.run {
            if (isPlaying) stop()
            release()
        }
        mediaPlayer = null
    }

    override fun onDestroy() {
        stopPlayer()
        stopVibration()
        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = null
        super.onDestroy()
    }

    companion object {
        const val CHANNEL_ID = "outta_bed_alarm_ring"
        const val NOTIFICATION_ID = 424242
        const val EXTRA_ALARM_ID = "alarm_id"
        const val EXTRA_LABEL = "label"
        const val EXTRA_SOUND_URI = "sound_uri"
        const val EXTRA_VOLUME = "volume"

        fun stop(context: Context) {
            val service = Intent(context, AlarmRingService::class.java)
            context.stopService(service)
        }

        fun stopVibration(context: Context) {
            // no-op if service not running; vibration stops in onDestroy
        }

        fun start(
            context: Context,
            alarmId: String,
            label: String,
            soundUri: String?,
            volume: Float,
        ) {
            val intent = Intent(context, AlarmRingService::class.java).apply {
                putExtra(EXTRA_ALARM_ID, alarmId)
                putExtra(EXTRA_LABEL, label)
                putExtra(EXTRA_SOUND_URI, soundUri)
                putExtra(EXTRA_VOLUME, volume)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
    }
}
