import 'dart:io';

import 'package:flutter/services.dart';

class DeviceSound {
  const DeviceSound({required this.title, required this.uri});

  final String title;
  final String uri;

  factory DeviceSound.fromMap(Map<dynamic, dynamic> map) {
    return DeviceSound(
      title: map['title'] as String? ?? 'Phone sound',
      uri: map['uri'] as String,
    );
  }
}

class NativeBridge {
  NativeBridge._();
  static final NativeBridge instance = NativeBridge._();

  static const _channel = MethodChannel('com.outtabed.outta_bed/native');
  static void Function(String alarmId)? onAlarmLaunched;

  static void installHandler() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onAlarmLaunched') {
        final alarmId = call.arguments as String?;
        if (alarmId != null) onAlarmLaunched?.call(alarmId);
      }
    });
  }

  Future<String?> getLaunchAlarmId() async {
    if (!Platform.isAndroid) return null;
    return _channel.invokeMethod<String>('getLaunchAlarmId');
  }

  Future<void> scheduleAlarm({
    required String alarmId,
    required DateTime triggerAt,
    required String label,
    String? soundUri,
    required double volume,
  }) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('scheduleAlarm', {
      'alarmId': alarmId,
      'triggerAt': triggerAt.millisecondsSinceEpoch,
      'label': label,
      'soundUri': soundUri,
      'volume': volume,
    });
  }

  Future<void> cancelAlarm(String alarmId) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('cancelAlarm', {'alarmId': alarmId});
  }

  Future<void> stopNativeAlarm() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('stopNativeAlarm');
  }

  Future<void> triggerAlarmNow({
    required String alarmId,
    required String label,
    String? soundUri,
    required double volume,
  }) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('triggerAlarmNow', {
      'alarmId': alarmId,
      'label': label,
      'soundUri': soundUri,
      'volume': volume,
    });
  }

  Future<DeviceSound?> pickDeviceAlarmSound() async {
    if (!Platform.isAndroid) return null;
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'pickDeviceAlarmSound',
    );
    if (result == null) return null;
    return DeviceSound.fromMap(result);
  }

  Future<List<DeviceSound>> getDeviceAlarmSounds() async {
    if (!Platform.isAndroid) return [];
    final result = await _channel.invokeMethod<List<dynamic>>(
      'getDeviceAlarmSounds',
    );
    return result?.map((e) => DeviceSound.fromMap(e as Map<dynamic, dynamic>)).toList() ?? [];
  }

  Future<bool> isBluetoothAudioConnected() async {
    if (!Platform.isAndroid) return false;
    final result = await _channel.invokeMethod<bool>('isBluetoothAudioConnected');
    return result ?? false;
  }

  Future<void> openBatterySettings() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('openBatterySettings');
  }
}
