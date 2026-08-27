package com.outtabed.outta_bed

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class AlarmTriggerReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val alarmId = intent.getStringExtra(AlarmRingService.EXTRA_ALARM_ID) ?: return
        val label = intent.getStringExtra(AlarmRingService.EXTRA_LABEL) ?: "OuttaBed"
        val soundUri = intent.getStringExtra(AlarmRingService.EXTRA_SOUND_URI)
        val volume = intent.getFloatExtra(AlarmRingService.EXTRA_VOLUME, 1f)

        AlarmRingService.start(context, alarmId, label, soundUri, volume)
    }
}
