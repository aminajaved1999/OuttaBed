import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../theme/app_theme.dart';
import 'alarm_scheduler.dart';
import 'native_bridge.dart';
import 'notification_service.dart';

class PermissionService {
  PermissionService._();
  static final PermissionService instance = PermissionService._();

  bool _introShownThisSession = false;

  Future<void> ensureAlarmPermissions(BuildContext context) async {
    if (!Platform.isAndroid) {
      await NotificationService.instance.requestPermissions();
      return;
    }

    await NotificationService.instance.init();

    final missing = await _collectMissing();
    if (missing.isEmpty) return;
    if (!context.mounted) return;

    if (!_introShownThisSession) {
      _introShownThisSession = true;
      await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.stroke),
        ),
        title: Text(
          'quick setup',
          style: AppTheme.display(22, weight: FontWeight.w700).copyWith(color: AppColors.white),
        ),
        content: Text(
          'OuttaBed needs a few permissions so your alarm actually fires on time.',
          style: AppTheme.body(15).copyWith(color: AppColors.white),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('continue'),
          ),
        ],
      ),
    );
    }

    if (!context.mounted) return;
    await _requestAll(context, missing);
    await AlarmScheduler.instance.rescheduleAll();
  }

  Future<List<_PermissionStep>> _collectMissing() async {
    final steps = <_PermissionStep>[];

    if (Platform.isAndroid) {
      if (!await NativeBridge.instance.areNotificationsEnabled()) {
        steps.add(_PermissionStep.notifications);
      }
      if (!await NativeBridge.instance.canScheduleExactAlarms()) {
        steps.add(_PermissionStep.exactAlarms);
      }
      if (!await NativeBridge.instance.canUseFullScreenIntent()) {
        steps.add(_PermissionStep.fullScreen);
      }
      if (!await NativeBridge.instance.isIgnoringBatteryOptimizations()) {
        steps.add(_PermissionStep.battery);
      }
    } else {
      final status = await Permission.notification.status;
      if (!status.isGranted) steps.add(_PermissionStep.notifications);
    }

    return steps;
  }

  Future<void> _requestAll(BuildContext context, List<_PermissionStep> steps) async {
    for (final step in steps) {
      if (!context.mounted) return;

      final granted = await _requestStep(step);
      if (granted) continue;

      if (!context.mounted) return;
      final openSettings = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.stroke),
          ),
          title: Text(
            step.title,
            style: AppTheme.display(20, weight: FontWeight.w700).copyWith(color: AppColors.white),
          ),
          content: Text(
            step.body,
            style: AppTheme.body(15).copyWith(color: AppColors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('later'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('open settings'),
            ),
          ],
        ),
      );

      if (openSettings == true) {
        await step.openSettings();
      }
    }
  }

  Future<bool> _requestStep(_PermissionStep step) async {
    switch (step) {
      case _PermissionStep.notifications:
        if (Platform.isAndroid) {
          final status = await Permission.notification.request();
          if (status.isGranted) return true;
          return NativeBridge.instance.requestNotifications();
        }
        return (await Permission.notification.request()).isGranted;
      case _PermissionStep.exactAlarms:
        if (Platform.isAndroid) {
          if (await Permission.scheduleExactAlarm.isGranted) return true;
          final status = await Permission.scheduleExactAlarm.request();
          if (status.isGranted) return true;
          return NativeBridge.instance.requestExactAlarms();
        }
        return (await Permission.scheduleExactAlarm.request()).isGranted;
      case _PermissionStep.fullScreen:
        return NativeBridge.instance.requestFullScreenIntent();
      case _PermissionStep.battery:
        return NativeBridge.instance.requestIgnoreBatteryOptimizations();
    }
  }
}

enum _PermissionStep {
  notifications(
    title: 'notifications',
    body: 'Allows the alarm to pop up on your lock screen when it rings.',
  ),
  exactAlarms(
    title: 'alarms & reminders',
    body: 'Required for the alarm to fire at the exact time you set.',
  ),
  fullScreen(
    title: 'full screen alarm',
    body: 'Lets the alarm take over your screen so you cannot miss it.',
  ),
  battery(
    title: 'battery',
    body: 'Turn off battery limits for OuttaBed so Samsung does not kill the alarm.',
  );

  const _PermissionStep({required this.title, required this.body});
  final String title;
  final String body;

  Future<void> openSettings() => switch (this) {
        _PermissionStep.notifications => openAppSettings(),
        _PermissionStep.exactAlarms => NativeBridge.instance.openExactAlarmSettings(),
        _PermissionStep.fullScreen => NativeBridge.instance.openFullScreenIntentSettings(),
        _PermissionStep.battery => NativeBridge.instance.openBatterySettings(),
      };
}
