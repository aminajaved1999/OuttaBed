package com.outtabed.outta_bed

import android.content.Context

object AlarmPrefs {
    private const val PREFS = "FlutterSharedPreferences"
    private const val RINGING_KEY = "flutter.ringing_alarm_id"

    fun setRingingAlarmId(context: Context, alarmId: String) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(RINGING_KEY, alarmId)
            .apply()
    }

    fun clearRingingAlarmId(context: Context) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .remove(RINGING_KEY)
            .apply()
    }
}
