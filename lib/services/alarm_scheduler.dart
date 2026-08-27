import 'dart:io';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

import '../alarm_callback.dart';
import '../models/alarm.dart';
import '../utils/alarm_calculator.dart';
import 'alarm_storage.dart';
import 'notification_service.dart';

class AlarmScheduler {
  AlarmScheduler._();
  static final AlarmScheduler instance = AlarmScheduler._();

  Future<void> init() async {
    if (Platform.isAndroid) {
      await AndroidAlarmManager.initialize();
    }
    await NotificationService.instance.init();
  }

  Future<void> scheduleAlarm(Alarm alarm) async {
    if (!alarm.enabled) {
      await cancelAlarm(alarm.id);
      return;
    }

    final scheduledAt = nextAlarmDateTime(alarm);
    if (Platform.isAndroid) {
      await AndroidAlarmManager.oneShotAt(
        scheduledAt,
        alarmNotificationId(alarm.id),
        alarmFireCallback,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
        allowWhileIdle: true,
        params: {'alarmId': alarm.id},
      );
    }

    await NotificationService.instance.scheduleIosBackup(alarm, scheduledAt);
  }

  Future<void> cancelAlarm(String alarmId) async {
    if (Platform.isAndroid) {
      await AndroidAlarmManager.cancel(alarmNotificationId(alarmId));
    }
    await NotificationService.instance.cancelIosBackup(alarmId);
    await NotificationService.instance.cancelAlarmNotification(alarmId);
  }

  Future<void> rescheduleAll() async {
    final alarms = await AlarmStorage.instance.loadAlarms();
    for (final alarm in alarms) {
      await cancelAlarm(alarm.id);
      if (alarm.enabled) {
        await scheduleAlarm(alarm);
      }
    }
  }

  Future<void> scheduleSnooze(Alarm alarm) async {
    final snoozeTime = DateTime.now().add(Duration(minutes: alarm.snoozeMinutes));
    if (Platform.isAndroid) {
      await AndroidAlarmManager.oneShotAt(
        snoozeTime,
        alarmNotificationId('${alarm.id}_snooze'),
        alarmFireCallback,
        exact: true,
        wakeup: true,
        allowWhileIdle: true,
        params: {'alarmId': alarm.id},
      );
    }
    await NotificationService.instance.scheduleIosBackup(alarm, snoozeTime);
  }
}
