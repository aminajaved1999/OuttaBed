package com.outtabed.outta_bed

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build

object NativeAlarmScheduler {
    fun schedule(
        context: Context,
        requestCode: Int,
        alarmId: String,
        triggerAtMillis: Long,
        label: String,
        soundUri: String?,
        volume: Float,
    ) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val triggerIntent = Intent(context, AlarmTriggerReceiver::class.java).apply {
            putExtra(AlarmRingService.EXTRA_ALARM_ID, alarmId)
            putExtra(AlarmRingService.EXTRA_LABEL, label)
            putExtra(AlarmRingService.EXTRA_SOUND_URI, soundUri)
            putExtra(AlarmRingService.EXTRA_VOLUME, volume)
        }
        val pending = PendingIntent.getBroadcast(
            context,
            requestCode,
            triggerIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val showIntent = PendingIntent.getActivity(
            context,
            requestCode + 1,
            Intent(context, MainActivity::class.java).apply {
                putExtra(AlarmRingService.EXTRA_ALARM_ID, alarmId)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val safeTriggerAt = maxOf(triggerAtMillis, System.currentTimeMillis() + 2_000L)
        val info = AlarmManager.AlarmClockInfo(safeTriggerAt, showIntent)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (alarmManager.canScheduleExactAlarms()) {
                alarmManager.setAlarmClock(info, pending)
            } else {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    safeTriggerAt,
                    pending,
                )
            }
        } else {
            alarmManager.setAlarmClock(info, pending)
        }
    }

    fun cancel(context: Context, requestCode: Int, alarmId: String) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, AlarmTriggerReceiver::class.java).apply {
            putExtra(AlarmRingService.EXTRA_ALARM_ID, alarmId)
        }
        val pending = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        alarmManager.cancel(pending)
    }
}
