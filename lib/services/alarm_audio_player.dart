import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

import '../models/alarm.dart';
import 'speaker_routing.dart';

class AlarmAudioPlayer {
  AlarmAudioPlayer._();
  static final AlarmAudioPlayer instance = AlarmAudioPlayer._();

  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  Future<void> play(Alarm alarm) async {
    await stop();

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
    await _setSource(alarm);
    await _player.setLoopMode(LoopMode.one);
    await _player.setVolume(alarm.volume.clamp(0.0, 1.0));
    await _player.play();
    _isPlaying = true;
  }

  Future<void> _setSource(Alarm alarm) async {
    if (alarm.soundSource == AlarmSoundSource.device &&
        alarm.deviceSoundUri != null) {
      await _player.setAudioSource(
        AudioSource.uri(Uri.parse(alarm.deviceSoundUri!)),
      );
    } else {
      await _player.setAsset(alarm.sound.assetPath);
    }
  }

  Future<void> stop() async {
    if (_player.playing) {
      await _player.stop();
    }
    _isPlaying = false;
    await SpeakerRouting.restoreAudioRouting();
  }

  Future<void> dispose() async {
    await stop();
    await _player.dispose();
  }
}
