import 'dart:io';

import '../models/alarm.dart';
import '../utils/alarm_calculator.dart';
import 'alarm_storage.dart';
import 'native_bridge.dart';
import 'notification_service.dart';

class AlarmScheduler {
  AlarmScheduler._();
  static final AlarmScheduler instance = AlarmScheduler._();

  Future<void> init() async {
    if (Platform.isAndroid) {
      NativeBridge.installHandler();
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
      await NativeBridge.instance.scheduleAlarm(
        alarmId: alarm.id,
        triggerAt: scheduledAt,
        label: alarm.label,
        soundUri: alarm.nativeSoundUri,
        volume: alarm.volume,
      );
    }

    await NotificationService.instance.scheduleIosBackup(alarm, scheduledAt);
  }

  Future<void> cancelAlarm(String alarmId) async {
    if (Platform.isAndroid) {
      await NativeBridge.instance.cancelAlarm(alarmId);
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
      await NativeBridge.instance.scheduleAlarm(
        alarmId: alarm.id,
        triggerAt: snoozeTime,
        label: alarm.label,
        soundUri: alarm.nativeSoundUri,
        volume: alarm.volume,
      );
    }
    await NotificationService.instance.scheduleIosBackup(alarm, snoozeTime);
  }
}
