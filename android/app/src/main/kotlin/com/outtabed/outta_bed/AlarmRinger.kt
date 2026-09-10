package com.outtabed.outta_bed

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.Ringtone
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build

/**
 * Shared alarm audio + vibration used by the foreground service, fallback ringer,
 * and Flutter method-channel calls when the ring screen is open.
 */
object AlarmRinger {
    private var mediaPlayer: MediaPlayer? = null
    private var ringtone: Ringtone? = null
    private var audioFocusRequest: AudioFocusRequest? = null
    private var legacyAudioFocusListener: AudioManager.OnAudioFocusChangeListener? = null

    fun routeToSpeaker(context: Context) {
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        audioManager.mode = AudioManager.MODE_NORMAL
        audioManager.stopBluetoothSco()
        audioManager.isBluetoothScoOn = false
        audioManager.isSpeakerphoneOn = true
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            audioManager.availableCommunicationDevices
                .firstOrNull { it.type == android.media.AudioDeviceInfo.TYPE_BUILTIN_SPEAKER }
                ?.let { audioManager.setCommunicationDevice(it) }
        }
    }

    fun ensureAlarmAudible(context: Context) {
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_ALARM)
        val currentVolume = audioManager.getStreamVolume(AudioManager.STREAM_ALARM)
        if (currentVolume == 0 && maxVolume > 0) {
            val target = maxOf(1, maxVolume / 2)
            audioManager.setStreamVolume(AudioManager.STREAM_ALARM, target, 0)
        }
        if (audioManager.ringerMode == AudioManager.RINGER_MODE_SILENT) {
            audioManager.ringerMode = AudioManager.RINGER_MODE_NORMAL
        }
    }

    fun requestAudioFocus(context: Context) {
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val attributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                .setAudioAttributes(attributes)
                .setAcceptsDelayedFocusGain(false)
                .setWillPauseWhenDucked(false)
                .build()
            audioFocusRequest = request
            audioManager.requestAudioFocus(request)
        } else {
            @Suppress("DEPRECATION")
            val listener = AudioManager.OnAudioFocusChangeListener { }
            legacyAudioFocusListener = listener
            @Suppress("DEPRECATION")
            audioManager.requestAudioFocus(
                listener,
                AudioManager.STREAM_ALARM,
                AudioManager.AUDIOFOCUS_GAIN,
            )
        }
    }

    fun abandonAudioFocus(context: Context) {
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest?.let { audioManager.abandonAudioFocusRequest(it) }
        } else {
            @Suppress("DEPRECATION")
            legacyAudioFocusListener?.let { audioManager.abandonAudioFocus(it) }
        }
        audioFocusRequest = null
        legacyAudioFocusListener = null
    }

    fun startVibration(context: Context) {
        AlarmVibrator.start(context.applicationContext)
    }

    fun stopVibration() {
        AlarmVibrator.stop()
    }

    fun playSound(context: Context, soundUri: String?, volume: Float) {
        stopSound()
        val uri = resolveSoundUri(context, soundUri)
        val clampedVolume = volume.coerceIn(0f, 1f)

        try {
            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build(),
                )
                setDataSource(context.applicationContext, uri)
                isLooping = true
                setVolume(clampedVolume, clampedVolume)
                prepare()
                start()
            }
        } catch (error: Exception) {
            android.util.Log.e("OuttaBedAlarm", "MediaPlayer failed, using ringtone", error)
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
    }

    fun ring(
        context: Context,
        soundUri: String?,
        volume: Float,
        vibrate: Boolean = true,
    ) {
        val appContext = context.applicationContext
        ensureAlarmAudible(appContext)
        routeToSpeaker(appContext)
        requestAudioFocus(appContext)
        if (vibrate) startVibration(appContext)
        playSound(appContext, soundUri, volume)
    }

    fun stop(context: Context) {
        stopSound()
        stopVibration()
        abandonAudioFocus(context.applicationContext)
    }

    fun stopSound() {
        mediaPlayer?.run {
            if (isPlaying) stop()
            release()
        }
        mediaPlayer = null
        ringtone?.stop()
        ringtone = null
    }

    fun resolveSoundUri(context: Context, soundUri: String?): Uri {
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
}
