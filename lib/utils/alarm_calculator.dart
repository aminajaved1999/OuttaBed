import '../models/alarm.dart';

DateTime nextAlarmDateTime(Alarm alarm, {DateTime? from}) {
  final now = from ?? DateTime.now();
  var candidate = DateTime(now.year, now.month, now.day, alarm.hour, alarm.minute);

  if (alarm.repeatDays.isEmpty) {
    if (!candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }

  for (var offset = 0; offset < 8; offset++) {
    final day = candidate.add(Duration(days: offset));
    if (alarm.repeatDays.contains(day.weekday % 7)) {
      final scheduled = DateTime(day.year, day.month, day.day, alarm.hour, alarm.minute);
      if (scheduled.isAfter(now)) {
        return scheduled;
      }
    }
  }

  return candidate.add(const Duration(days: 1));
}

int alarmNotificationId(String alarmId) => alarmId.hashCode & 0x7fffffff;
