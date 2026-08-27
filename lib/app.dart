import 'package:flutter/material.dart';

import 'screens/alarm_ring_screen.dart';
import 'screens/home_screen.dart';
import 'services/alarm_storage.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

class OuttaBedApp extends StatefulWidget {
  const OuttaBedApp({super.key, this.initialAlarmId});

  final String? initialAlarmId;

  @override
  State<OuttaBedApp> createState() => _OuttaBedAppState();
}

class _OuttaBedAppState extends State<OuttaBedApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    AlarmTriggerBridge.alarmIdNotifier.addListener(_onAlarmTriggered);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openRingScreenIfNeeded(widget.initialAlarmId);
      _openRingScreenIfNeeded(AlarmTriggerBridge.consumePending());
    });
  }

  @override
  void dispose() {
    AlarmTriggerBridge.alarmIdNotifier.removeListener(_onAlarmTriggered);
    super.dispose();
  }

  void _onAlarmTriggered() {
    _openRingScreenIfNeeded(AlarmTriggerBridge.alarmIdNotifier.value);
  }

  Future<void> _openRingScreenIfNeeded(String? alarmId) async {
    if (alarmId == null || alarmId.isEmpty) return;

    final alarm = await AlarmStorage.instance.getAlarm(alarmId);
    if (alarm == null) return;

    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;

    final isAlreadyOpen = navigator.canPop();
    if (isAlreadyOpen) return;

    await navigator.push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AlarmRingScreen(alarm: alarm),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'OuttaBed',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomeScreen(),
    );
  }
}
