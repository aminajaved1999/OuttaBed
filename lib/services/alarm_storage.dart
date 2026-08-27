import 'package:shared_preferences/shared_preferences.dart';

import '../models/alarm.dart';

class AlarmStorage {
  AlarmStorage._();
  static final AlarmStorage instance = AlarmStorage._();

  static const _alarmsKey = 'alarms_v1';
  static const _ringingAlarmKey = 'ringing_alarm_id';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<List<Alarm>> loadAlarms() async {
    await init();
    final raw = _prefs!.getString(_alarmsKey);
    if (raw == null || raw.isEmpty) return [];
    return Alarm.decodeList(raw);
  }

  Future<void> saveAlarms(List<Alarm> alarms) async {
    await init();
    await _prefs!.setString(_alarmsKey, Alarm.encodeList(alarms));
  }

  Future<Alarm?> getAlarm(String id) async {
    final alarms = await loadAlarms();
    for (final alarm in alarms) {
      if (alarm.id == id) return alarm;
    }
    return null;
  }

  Future<void> setRingingAlarmId(String? alarmId) async {
    await init();
    if (alarmId == null) {
      await _prefs!.remove(_ringingAlarmKey);
    } else {
      await _prefs!.setString(_ringingAlarmKey, alarmId);
    }
  }

  Future<String?> getRingingAlarmId() async {
    await init();
    return _prefs!.getString(_ringingAlarmKey);
  }
}
