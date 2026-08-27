import 'package:flutter/widgets.dart';

import 'services/alarm_scheduler.dart';
import 'services/alarm_storage.dart';
import 'services/notification_service.dart';

@pragma('vm:entry-point')
Future<void> alarmFireCallback(int id, Map<String, dynamic>? params) async {
  WidgetsFlutterBinding.ensureInitialized();
  await AlarmStorage.instance.init();
  await NotificationService.instance.init();

  final alarmId = params?['alarmId'] as String?;
  if (alarmId == null) return;

  final alarm = await AlarmStorage.instance.getAlarm(alarmId);
  if (alarm == null || !alarm.enabled) return;

  await AlarmStorage.instance.setRingingAlarmId(alarmId);
  await NotificationService.instance.showAlarmNotification(alarm);
  AlarmTriggerBridge.notify(alarmId);

  if (alarm.isRepeating) {
    await AlarmScheduler.instance.scheduleAlarm(alarm);
  }
}
