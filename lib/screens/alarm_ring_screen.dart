import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/alarm.dart';
import '../services/alarm_audio_player.dart';
import '../services/alarm_scheduler.dart';
import '../services/alarm_storage.dart';
import '../services/notification_service.dart';

class AlarmRingScreen extends StatefulWidget {
  const AlarmRingScreen({super.key, required this.alarm});

  final Alarm alarm;

  @override
  State<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen> {
  @override
  void initState() {
    super.initState();
    _startRinging();
  }

  Future<void> _startRinging() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await WakelockPlus.enable();
    await AlarmAudioPlayer.instance.play(widget.alarm);
  }

  Future<void> _stopRinging() async {
    await AlarmAudioPlayer.instance.stop();
    await WakelockPlus.disable();
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await AlarmStorage.instance.setRingingAlarmId(null);
    await NotificationService.instance.cancelAlarmNotification(widget.alarm.id);
  }

  Future<void> _dismiss() async {
    await _stopRinging();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _snooze() async {
    await _stopRinging();
    await AlarmScheduler.instance.scheduleSnooze(widget.alarm);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Snoozed for ${widget.alarm.snoozeMinutes} minutes',
        ),
      ),
    );
  }

  @override
  void dispose() {
    AlarmAudioPlayer.instance.stop();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                Icon(
                  Icons.speaker_phone_rounded,
                  size: 80,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  widget.alarm.label,
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.alarm.timeLabel,
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.w200,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Playing through phone speaker',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: _snooze,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: Text('Snooze (${widget.alarm.snoozeMinutes} min)'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _dismiss,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: const Text('Dismiss'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
