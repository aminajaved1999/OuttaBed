package com.outtabed.outta_bed

import android.content.Context
import android.media.AudioAttributes
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.VibrationAttributes
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log

/**
 * Aggressive alarm vibration for Samsung and other devices.
 * Pulses every motor on the phone using multiple API fallbacks.
 */
object AlarmVibrator {
    private const val TAG = "OuttaBedAlarm"
    private val pulsePattern = longArrayOf(0, 1000, 400, 1000, 400, 1200)
    private var running = false
    private var pulseHandler: Handler? = null
    private var vibrators: List<Vibrator> = emptyList()

    fun start(context: Context) {
        if (running) return
        running = true
        vibrators = resolveAllVibrators(context.applicationContext)
        if (vibrators.isEmpty()) {
            Log.w(TAG, "No vibrator hardware detected")
            running = false
            return
        }

        Log.i(TAG, "Starting alarm vibration on ${vibrators.size} motor(s)")
        pulseAll()

        val handler = Handler(Looper.getMainLooper())
        pulseHandler = handler
        val runnable = object : Runnable {
            override fun run() {
                if (!running) return
                pulseAll()
                handler.postDelayed(this, 1400)
            }
        }
        handler.postDelayed(runnable, 1400)
    }

    fun stop() {
        running = false
        pulseHandler?.removeCallbacksAndMessages(null)
        pulseHandler = null
        vibrators.forEach { runCatching { it.cancel() } }
        vibrators = emptyList()
    }

    fun forceStop() = stop()

    private fun pulseAll() {
        for (vib in vibrators) {
            if (!vib.hasVibrator()) continue
            pulseOne(vib)
        }
    }

    private fun pulseOne(vib: Vibrator) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            try {
                val attrs = VibrationAttributes.Builder()
                    .setUsage(VibrationAttributes.USAGE_ALARM)
                    .build()
                vib.vibrate(VibrationEffect.createWaveform(pulsePattern, 0), attrs)
                return
            } catch (error: Exception) {
                Log.w(TAG, "VibrationAttributes waveform failed", error)
            }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                vib.vibrate(
                    VibrationEffect.createWaveform(pulsePattern, 0),
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build(),
                )
                return
            } catch (error: Exception) {
                Log.w(TAG, "AudioAttributes alarm waveform failed", error)
            }

            try {
                vib.vibrate(
                    VibrationEffect.createWaveform(pulsePattern, 0),
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build(),
                )
                return
            } catch (error: Exception) {
                Log.w(TAG, "AudioAttributes ringtone waveform failed", error)
            }

            try {
                vib.vibrate(VibrationEffect.createOneShot(900, VibrationEffect.DEFAULT_AMPLITUDE))
                return
            } catch (error: Exception) {
                Log.w(TAG, "One-shot vibration failed", error)
            }
        }

        @Suppress("DEPRECATION")
        runCatching { vib.vibrate(pulsePattern, 0) }
    }

    private fun resolveAllVibrators(context: Context): List<Vibrator> {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val manager = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            val result = mutableListOf<Vibrator>()
            for (id in manager.vibratorIds) {
                val vibrator = runCatching { manager.getVibrator(id) }.getOrNull()
                if (vibrator != null && vibrator.hasVibrator()) {
                    result.add(vibrator)
                }
            }
            return result
        }

        @Suppress("DEPRECATION")
        val legacy = context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        return if (legacy.hasVibrator()) listOf(legacy) else emptyList()
    }
}
