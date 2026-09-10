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
    }

    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      // Repeating one-shot pulses are more reliable than patterns on Samsung.
      _pulseTimer = Timer.periodic(const Duration(milliseconds: 1100), (_) async {
        if (!_running) return;
        await Vibration.vibrate(duration: 700);
        await HapticFeedback.heavyImpact();
      });
      await Vibration.vibrate(duration: 700);
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
