package com.outtabed.outta_bed

import android.content.Context
import android.media.AudioAttributes
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log

/**
 * Reliable alarm vibration for Samsung and other devices.
 * Reference-counted so one layer stopping does not cancel active alarm vibration.
 */
object AlarmVibrator {
    private const val TAG = "OuttaBedAlarm"
    private var vibrator: Vibrator? = null
    private var pulseHandler: Handler? = null
    private var activeSessions = 0

    fun start(context: Context) {
        activeSessions++
        if (activeSessions > 1) return
        actuallyStart(context.applicationContext)
    }

    fun stop() {
        if (activeSessions <= 0) return
        activeSessions--
        if (activeSessions == 0) {
            actuallyStop()
        }
    }

    fun forceStop() {
        activeSessions = 0
        actuallyStop()
    }

    private fun actuallyStart(context: Context) {
        actuallyStop()
        val vib = resolveVibrator(context)
        if (vib == null || !vib.hasVibrator()) {
            Log.w(TAG, "No vibrator available on this device")
            return
        }
        vibrator = vib

        val pattern = longArrayOf(0, 900, 300, 900, 300, 1200)
        var started = false

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                vib.vibrate(
                    VibrationEffect.createWaveform(pattern, 0),
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build(),
                )
                started = true
            } catch (error: Exception) {
                Log.w(TAG, "Alarm-attribute waveform failed", error)
            }

            if (!started) {
                try {
                    vib.vibrate(VibrationEffect.createWaveform(pattern, 0))
                    started = true
                } catch (error: Exception) {
                    Log.w(TAG, "Default waveform failed", error)
                }
            }
        } else {
            @Suppress("DEPRECATION")
            vib.vibrate(pattern, 0)
            started = true
        }

        if (!started) {
            startPulseLoop(vib)
        }
    }

    private fun startPulseLoop(vib: Vibrator) {
        val handler = Handler(Looper.getMainLooper())
        pulseHandler = handler
        val runnable = object : Runnable {
            override fun run() {
                if (activeSessions <= 0) return
                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        vib.vibrate(
                            VibrationEffect.createOneShot(700, VibrationEffect.DEFAULT_AMPLITUDE),
                        )
                    } else {
                        @Suppress("DEPRECATION")
                        vib.vibrate(700)
                    }
                } catch (error: Exception) {
                    Log.e(TAG, "Pulse vibration failed", error)
                }
                handler.postDelayed(this, 1000)
            }
        }
        handler.post(runnable)
    }

    private fun actuallyStop() {
        pulseHandler?.removeCallbacksAndMessages(null)
        pulseHandler = null
        vibrator?.cancel()
        vibrator = null
    }

    private fun resolveVibrator(context: Context): Vibrator? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val manager = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            manager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
    }
}
