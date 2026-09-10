package com.outtabed.outta_bed

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class AlarmTriggerReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val pendingResult = goAsync()
        val appContext = context.applicationContext
        try {
            val alarmId = intent.getStringExtra(AlarmRingService.EXTRA_ALARM_ID)
            if (alarmId.isNullOrBlank()) return

            val label = intent.getStringExtra(AlarmRingService.EXTRA_LABEL) ?: "OuttaBed"
            val soundUri = intent.getStringExtra(AlarmRingService.EXTRA_SOUND_URI)
            val volume = intent.getFloatExtra(AlarmRingService.EXTRA_VOLUME, 1f)

            Log.i("OuttaBedAlarm", "Alarm fired: $alarmId")
            AlarmPrefs.setRingingAlarmId(appContext, alarmId)

            try {
                AlarmRingService.start(appContext, alarmId, label, soundUri, volume)
            } catch (error: Exception) {
                Log.e("OuttaBedAlarm", "Foreground service failed, using fallback ringer", error)
                AlarmFallbackRinger.ring(appContext, alarmId, label, soundUri, volume)
            }

            AlarmRescheduleWorker.rescheduleAlarmById(appContext, alarmId)
        } catch (error: Exception) {
            Log.e("OuttaBedAlarm", "Alarm receiver failed", error)
        } finally {
            pendingResult.finish()
        }
    }
}
