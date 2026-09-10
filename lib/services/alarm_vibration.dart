import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

import 'native_bridge.dart';

class AlarmVibration {
  AlarmVibration._();
  static final AlarmVibration instance = AlarmVibration._();

  Timer? _pulseTimer;
  bool _running = false;

  Future<void> start({String label = 'OuttaBed'}) async {
    if (_running) return;
    _running = true;

    if (Platform.isAndroid) {
      // Start native vibration BEFORE any alarm audio (Samsung blocks vibrator during playback).
      await NativeBridge.instance.startNativeVibration(label: label);
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }

    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      _pulseTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) async {
        if (!_running) return;
        await Vibration.vibrate(duration: 800, amplitude: 255);
        await HapticFeedback.heavyImpact();
      });
      await Vibration.vibrate(duration: 800, amplitude: 255);
    } else {
      _pulseTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
        if (!_running) return;
        await HapticFeedback.heavyImpact();
      });
    }
  }

  Future<void> stop() async {
    _running = false;
    _pulseTimer?.cancel();
    _pulseTimer = null;
    if (Platform.isAndroid) {
      await NativeBridge.instance.stopNativeVibration();
    }
    await Vibration.cancel();
  }
}
