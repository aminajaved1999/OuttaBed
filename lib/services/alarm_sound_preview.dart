import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/alarm.dart';
import 'speaker_routing.dart';

/// Plays alarm sounds once for preview in the editor (separate from alarm playback).
class AlarmSoundPreview {
  AlarmSoundPreview._();
  static final AlarmSoundPreview instance = AlarmSoundPreview._();

  final AudioPlayer _player = AudioPlayer();
  final ValueNotifier<AlarmSound?> previewingSound = ValueNotifier(null);
  StreamSubscription<PlayerState>? _stateSub;
  double _volume = 1.0;

  bool isPreviewing(AlarmSound sound) =>
      previewingSound.value == sound && _player.playing;

  Future<void> togglePreview(AlarmSound sound, {required double volume}) async {
    if (isPreviewing(sound)) {
      await stop();
      return;
    }
    await play(sound, volume: volume);
  }

  Future<void> play(AlarmSound sound, {required double volume}) async {
    await stop();
    _volume = volume.clamp(0.0, 1.0);

    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.duckOthers,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.sonification,
        usage: AndroidAudioUsage.alarm,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
    ));

    await SpeakerRouting.routeAlarmToSpeaker();

    await _player.setAsset(sound.assetPath);
    await _player.setLoopMode(LoopMode.off);
    await _player.setVolume(_volume);
    previewingSound.value = sound;

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
    previewingSound.value = null;
    await SpeakerRouting.restoreAudioRouting();
  }

  Future<void> dispose() async {
    await stop();
    await _player.dispose();
  }
}
