package com.outtabed.outta_bed

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

object NativeAlarmScheduler {
    private const val TAG = "OuttaBedAlarm"

    fun schedule(
        context: Context,
        requestCode: Int,
        alarmId: String,
        triggerAtMillis: Long,
        label: String,
        soundUri: String?,
        volume: Float,
    ): Boolean {
        val appContext = context.applicationContext
        val alarmManager = appContext.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val triggerIntent = Intent(appContext, AlarmTriggerReceiver::class.java).apply {
            putExtra(AlarmRingService.EXTRA_ALARM_ID, alarmId)
            putExtra(AlarmRingService.EXTRA_LABEL, label)
            putExtra(AlarmRingService.EXTRA_SOUND_URI, soundUri)
            putExtra(AlarmRingService.EXTRA_VOLUME, volume)
        }
        val pending = PendingIntent.getBroadcast(
            appContext,
            requestCode,
            triggerIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val showIntent = PendingIntent.getActivity(
            appContext,
            requestCode + 1,
            Intent(appContext, MainActivity::class.java).apply {
                putExtra(AlarmRingService.EXTRA_ALARM_ID, alarmId)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val safeTriggerAt = maxOf(triggerAtMillis, System.currentTimeMillis() + 2_000L)
        val info = AlarmManager.AlarmClockInfo(safeTriggerAt, showIntent)

        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (alarmManager.canScheduleExactAlarms()) {
                    alarmManager.setAlarmClock(info, pending)
                } else {
                    Log.w(TAG, "Exact alarm permission missing — using inexact fallback for $alarmId")
                    alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, safeTriggerAt, pending)
                }
            } else {
                alarmManager.setAlarmClock(info, pending)
            }
            Log.i(TAG, "Scheduled alarm $alarmId at $safeTriggerAt")
            true
        } catch (security: SecurityException) {
            Log.e(TAG, "SecurityException scheduling alarm $alarmId", security)
            try {
                alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, safeTriggerAt, pending)
                true
            } catch (fallback: Exception) {
                Log.e(TAG, "Failed fallback schedule for $alarmId", fallback)
                false
            }
        } catch (error: Exception) {
            Log.e(TAG, "Failed to schedule alarm $alarmId", error)
            false
        }
    }

    fun cancel(context: Context, requestCode: Int, alarmId: String) {
        val appContext = context.applicationContext
        val alarmManager = appContext.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(appContext, AlarmTriggerReceiver::class.java).apply {
            putExtra(AlarmRingService.EXTRA_ALARM_ID, alarmId)
        }
        val pending = PendingIntent.getBroadcast(
            appContext,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        alarmManager.cancel(pending)
    }
}
