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
    if (scheduledAt.isAfter(DateTime.now().add(const Duration(days: 365)))) {
      await cancelAlarm(alarm.id);
      return;
    }

    if (Platform.isAndroid) {
      final canSchedule = await NativeBridge.instance.canScheduleExactAlarms();
      if (!canSchedule) {
        // Still attempt schedule — native code has inexact fallback.
      }
      await NativeBridge.instance.scheduleAlarm(
        alarmId: alarm.id,
        triggerAt: scheduledAt,
        label: alarm.label,
        soundUri: alarm.nativeSoundUri,
        volume: alarm.volume,
      );
    }

    await NotificationService.instance.schedulePlatformBackup(alarm, scheduledAt);
  }

  Future<void> cancelAlarm(String alarmId) async {
    if (Platform.isAndroid) {
      await NativeBridge.instance.cancelAlarm(alarmId);
    }
    await NotificationService.instance.cancelPlatformBackup(alarmId);
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
    await NotificationService.instance.schedulePlatformBackup(alarm, snoozeTime);
  }

  Future<void> onAlarmDismissed(Alarm alarm) async {
    if (alarm.scheduleMode == AlarmScheduleMode.once) {
      await cancelAlarm(alarm.id);
      final alarms = await AlarmStorage.instance.loadAlarms();
      final index = alarms.indexWhere((a) => a.id == alarm.id);
      if (index >= 0) {
        alarms[index] = alarm.copyWith(enabled: false);
        await AlarmStorage.instance.saveAlarms(alarms);
      }
      return;
    }
    await scheduleAlarm(alarm);
  }
}
