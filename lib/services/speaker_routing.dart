import 'package:flutter/services.dart';

/// Forces alarm audio to the phone speaker instead of connected Bluetooth earbuds.
class SpeakerRouting {
  SpeakerRouting._();

  static const _channel = MethodChannel('com.outtabed.outta_bed/native');

  static Future<void> routeAlarmToSpeaker() async {
    try {
      await _channel.invokeMethod<void>('routeAlarmToSpeaker');
    } on PlatformException {
      // Best-effort on unsupported platforms.
    }
  }

  static Future<void> restoreAudioRouting() async {
    try {
      await _channel.invokeMethod<void>('restoreAudioRouting');
    } on PlatformException {
      // Best-effort on unsupported platforms.
    }
  }

  /// Preview sounds through whatever is connected (earbuds, speaker, etc.).
  static Future<void> useDefaultAudioRoute() async {
    await restoreAudioRouting();
  }
}
