import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/alarm.dart';
import 'speaker_routing.dart';

/// Previews alarm sounds through the default audio route (earbuds if connected).
class AlarmSoundPreview {
  AlarmSoundPreview._();
  static final AlarmSoundPreview instance = AlarmSoundPreview._();

  final AudioPlayer _player = AudioPlayer();
  final ValueNotifier<String?> previewingKey = ValueNotifier(null);
  StreamSubscription<PlayerState>? _stateSub;
  double _volume = 1.0;

  bool isPreviewingKey(String key) =>
      previewingKey.value == key && _player.playing;

  Future<void> previewBuiltin(AlarmSound sound, {required double volume}) async {
    await play(key: sound.name, volume: volume, assetPath: sound.assetPath);
  }

  Future<void> previewDevice(String uri, {required double volume}) async {
    await play(key: uri, volume: volume, deviceUri: uri);
  }

  Future<void> toggleBuiltin(AlarmSound sound, {required double volume}) async {
    if (isPreviewingKey(sound.name)) {
      await stop();
      return;
    }
    await previewBuiltin(sound, volume: volume);
  }

  Future<void> toggleDevice(String uri, {required double volume}) async {
    if (isPreviewingKey(uri)) {
      await stop();
      return;
    }
    await play(key: uri, volume: volume, deviceUri: uri);
  }

  Future<void> play({
    required String key,
    required double volume,
    String? assetPath,
    String? deviceUri,
  }) async {
    await stop();
    _volume = volume.clamp(0.0, 1.0);

    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
    ));

    // Let system route to earbuds / headphones / speaker — no forced speakerphone.
    await SpeakerRouting.useDefaultAudioRoute();

    if (deviceUri != null) {
      await _player.setAudioSource(AudioSource.uri(Uri.parse(deviceUri)));
    } else if (assetPath != null) {
      await _player.setAsset(assetPath);
    }

    await _player.setLoopMode(LoopMode.off);
    await _player.setVolume(_volume);
    previewingKey.value = key;

    _stateSub = _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        unawaited(stop());
      }
    });

    await _player.play();
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    if (_player.playing) {
      await _player.setVolume(_volume);
    }
  }

  Future<void> stop() async {
    await _stateSub?.cancel();
    _stateSub = null;
    if (_player.playing) {
      await _player.stop();
    }
    previewingKey.value = null;
  }
}
