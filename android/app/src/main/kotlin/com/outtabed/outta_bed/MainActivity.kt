package com.outtabed.outta_bed

import android.content.Context
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.outtabed.outta_bed/speaker"
    private var previousSpeakerphoneState: Boolean? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "routeAlarmToSpeaker" -> {
                        routeAlarmToSpeaker()
                        result.success(null)
                    }
                    "restoreAudioRouting" -> {
                        restoreAudioRouting()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun routeAlarmToSpeaker() {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager

        if (previousSpeakerphoneState == null) {
            previousSpeakerphoneState = audioManager.isSpeakerphoneOn
        }

        audioManager.mode = AudioManager.MODE_NORMAL
        audioManager.stopBluetoothSco()
        audioManager.isBluetoothScoOn = false
        audioManager.isSpeakerphoneOn = true

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val speaker = audioManager.availableCommunicationDevices
                .firstOrNull { it.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER }
            if (speaker != null) {
                audioManager.setCommunicationDevice(speaker)
            }
        }
    }

    private fun restoreAudioRouting() {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        previousSpeakerphoneState?.let { audioManager.isSpeakerphoneOn = it }
        previousSpeakerphoneState = null

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            audioManager.clearCommunicationDevice()
        }
    }
}
