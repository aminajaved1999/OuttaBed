import 'package:flutter/material.dart';

import 'app.dart';
import 'services/alarm_scheduler.dart';
import 'services/alarm_storage.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AlarmStorage.instance.init();
  await AlarmScheduler.instance.init();
  await NotificationService.instance.requestPermissions();
  await AlarmScheduler.instance.rescheduleAll();

  final ringingId = await AlarmStorage.instance.getRingingAlarmId();
  final pendingId = AlarmTriggerBridge.consumePending();

  runApp(OuttaBedApp(initialAlarmId: pendingId ?? ringingId));
}
