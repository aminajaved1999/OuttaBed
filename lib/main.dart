import 'package:flutter/material.dart';

import 'app.dart';
import 'services/alarm_scheduler.dart';
import 'services/alarm_storage.dart';
import 'services/native_bridge.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  NativeBridge.installHandler();
  await AlarmStorage.instance.init();
  await AlarmScheduler.instance.init();
  await AlarmScheduler.instance.rescheduleAll();

  final nativeLaunch = await NativeBridge.instance.getLaunchAlarmId();
  final ringingId = await AlarmStorage.instance.getRingingAlarmId();
  final pendingId = AlarmTriggerBridge.consumePending();

  runApp(OuttaBedApp(
    initialAlarmId: nativeLaunch ?? pendingId ?? ringingId,
  ));
}
