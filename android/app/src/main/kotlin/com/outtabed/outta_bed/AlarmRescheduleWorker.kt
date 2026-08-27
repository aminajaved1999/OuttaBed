package com.outtabed.outta_bed

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar

object AlarmRescheduleWorker {
    private const val PREFS = "FlutterSharedPreferences"
    private const val ALARMS_KEY = "flutter.alarms_v1"

    fun rescheduleFromStorage(context: Context) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val raw = prefs.getString(ALARMS_KEY, null) ?: return
        try {
            val alarms = JSONArray(raw)
            for (i in 0 until alarms.length()) {
                val alarm = alarms.getJSONObject(i)
                if (!alarm.optBoolean("enabled", true)) continue
                scheduleIfFuture(context, alarm)
            }
        } catch (_: Exception) {
            // Flutter will reschedule when app opens.
        }
    }

    fun rescheduleAlarmById(context: Context, alarmId: String) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val raw = prefs.getString(ALARMS_KEY, null) ?: return
        try {
            val alarms = JSONArray(raw)
            for (i in 0 until alarms.length()) {
                val alarm = alarms.getJSONObject(i)
                if (alarm.getString("id") != alarmId) continue
                if (!alarm.optBoolean("enabled", true)) return
                scheduleIfFuture(context, alarm)
                return
            }
        } catch (_: Exception) {
            // Flutter will reschedule when app opens.
        }
    }

    private fun scheduleIfFuture(context: Context, alarm: JSONObject) {
        val id = alarm.getString("id")
        val hour = alarm.getInt("hour")
        val minute = alarm.getInt("minute")
        val label = alarm.optString("label", "OuttaBed")
        val volume = alarm.optDouble("volume", 1.0).toFloat()
        val soundSource = alarm.optString("soundSource", "builtin")
        val soundUri = if (soundSource == "device") {
            alarm.optString("deviceSoundUri", null)?.takeIf { it.isNotBlank() }
        } else {
            val soundName = alarm.optString("sound", "classic")
            "asset://${soundName}_alarm"
        }
        val repeatDays = alarm.optJSONArray("repeatDays")
        val scheduleMode = alarm.optString("scheduleMode", "weekly")
        val onceDate = alarm.optString("onceDate", null)?.takeIf { it.isNotBlank() }

        val triggerAt = nextTriggerMillis(hour, minute, repeatDays, scheduleMode, onceDate) ?: return
        NativeAlarmScheduler.schedule(
            context = context,
            requestCode = id.hashCode() and 0x7fffffff,
            alarmId = id,
            triggerAtMillis = triggerAt,
            label = label,
            soundUri = soundUri,
            volume = volume,
        )
    }

    private fun nextTriggerMillis(
        hour: Int,
        minute: Int,
        repeatDays: JSONArray?,
        scheduleMode: String,
        onceDate: String?,
    ): Long? {
        val now = Calendar.getInstance()
        val candidates = mutableListOf<Calendar>()

        if (scheduleMode == "once" && !onceDate.isNullOrBlank()) {
            val parts = onceDate.split("-")
            if (parts.size != 3) return null
            val year = parts[0].toIntOrNull() ?: return null
            val month = parts[1].toIntOrNull() ?: return null
            val day = parts[2].toIntOrNull() ?: return null
            val c = Calendar.getInstance().apply {
                set(Calendar.YEAR, year)
                set(Calendar.MONTH, month - 1)
                set(Calendar.DAY_OF_MONTH, day)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
                set(Calendar.HOUR_OF_DAY, hour)
                set(Calendar.MINUTE, minute)
            }
            return if (c.after(now)) c.timeInMillis else null
        }

        if (repeatDays == null || repeatDays.length() == 0) {
            val c = Calendar.getInstance().apply {
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
                set(Calendar.HOUR_OF_DAY, hour)
                set(Calendar.MINUTE, minute)
            }
            if (!c.after(now)) c.add(Calendar.DAY_OF_YEAR, 1)
            candidates.add(c)
        } else {
            val days = (0 until repeatDays.length()).map { repeatDays.getInt(it) }.toSet()
            for (offset in 0..7) {
                val c = Calendar.getInstance().apply {
                    add(Calendar.DAY_OF_YEAR, offset)
                    set(Calendar.SECOND, 0)
                    set(Calendar.MILLISECOND, 0)
                    set(Calendar.HOUR_OF_DAY, hour)
                    set(Calendar.MINUTE, minute)
                }
                val weekday = c.get(Calendar.DAY_OF_WEEK) - 1 // Sun=0
                if (days.contains(weekday) && c.after(now)) {
                    candidates.add(c)
                    break
                }
            }
        }

        return candidates.minByOrNull { it.timeInMillis }?.timeInMillis
    }
}
