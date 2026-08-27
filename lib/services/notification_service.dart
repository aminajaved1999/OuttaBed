import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/alarm.dart';
import '../utils/alarm_calculator.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const _channelId = 'outta_bed_alarms';
  static const _channelName = 'OuttaBed Alarms';
  static const _channelDescription =
      'Wake-up alarms that play through your phone speaker';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    final timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: _onNotificationTapped,
    );

    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.max,
          playSound: false,
          enableVibration: true,
        ),
      );
    }

    _initialized = true;
  }

  @pragma('vm:entry-point')
  static void _onNotificationTapped(NotificationResponse response) {
    final alarmId = response.payload;
    if (alarmId != null && alarmId.isNotEmpty) {
      AlarmTriggerBridge.pendingAlarmId = alarmId;
    }
  }

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.requestExactAlarmsPermission();
      return granted ?? true;
    }

    if (Platform.isIOS) {
      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  Future<void> showAlarmNotification(Alarm alarm) async {
    await init();

    final notificationId = alarmNotificationId(alarm.id);
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      ongoing: true,
      autoCancel: false,
      playSound: false,
      enableVibration: true,
      visibility: NotificationVisibility.public,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'snooze',
          'Snooze',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'dismiss',
          'Dismiss',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    await _plugin.show(
      notificationId,
      alarm.label,
      'Tap to open — alarm plays through phone speaker',
      NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: alarm.id,
    );
  }

  Future<void> cancelAlarmNotification(String alarmId) async {
    await _plugin.cancel(alarmNotificationId(alarmId));
  }

  Future<void> scheduleIosBackup(Alarm alarm, DateTime scheduledAt) async {
    if (!Platform.isIOS) return;
    await init();

    final notificationId = alarmNotificationId(alarm.id);
    await _plugin.zonedSchedule(
      notificationId,
      alarm.label,
      'Wake up! Alarm plays through phone speaker.',
      tz.TZDateTime.from(scheduledAt, tz.local),
      const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: false,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: alarm.id,
    );
  }

  Future<void> cancelIosBackup(String alarmId) async {
    if (!Platform.isIOS) return;
    await _plugin.cancel(alarmNotificationId(alarmId));
  }
}

/// Bridges alarm triggers from background isolates to the UI layer.
class AlarmTriggerBridge {
  static String? pendingAlarmId;
  static final ValueNotifier<String?> alarmIdNotifier =
      ValueNotifier<String?>(null);

  static void notify(String alarmId) {
    pendingAlarmId = alarmId;
    alarmIdNotifier.value = alarmId;
  }

  static String? consumePending() {
    final id = pendingAlarmId;
    pendingAlarmId = null;
    return id;
  }
}
