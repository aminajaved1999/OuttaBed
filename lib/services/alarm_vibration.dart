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

  Future<void> start() async {
    if (_running) return;
    _running = true;

    if (Platform.isAndroid) {
      await NativeBridge.instance.startNativeVibration();
      return;
    }

    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator != true) return;

    final hasAmplitude = await Vibration.hasAmplitudeControl();
    const pattern = [0, 600, 300, 600, 300, 800];

    if (hasAmplitude == true) {
      await Vibration.vibrate(
        pattern: pattern,
        intensities: [0, 200, 0, 255, 0, 255],
        repeat: 0,
      );
    } else {
      await Vibration.vibrate(pattern: pattern, repeat: 0);
    }

    _pulseTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!_running) return;
      await HapticFeedback.heavyImpact();
    });
  }

  Future<void> stop() async {
    _running = false;
    _pulseTimer?.cancel();
    _pulseTimer = null;
    if (Platform.isAndroid) {
      await NativeBridge.instance.stopNativeVibration();
    } else {
      await Vibration.cancel();
    }
  }
}
