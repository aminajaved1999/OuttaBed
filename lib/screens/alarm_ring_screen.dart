import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/alarm.dart';
import '../services/alarm_audio_player.dart';
import '../services/alarm_scheduler.dart';
import '../services/alarm_storage.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/cute_widgets.dart';

class AlarmRingScreen extends StatefulWidget {
  const AlarmRingScreen({super.key, required this.alarm, this.previewOnly = false});

  final Alarm alarm;
  final bool previewOnly;

  @override
  State<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.previewOnly) {
      _pulseController.value = 0.5;
    } else {
      _pulseController.repeat(reverse: true);
    }
    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (!widget.previewOnly) _startRinging();
  }

  Future<void> _startRinging() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await WakelockPlus.enable();
    await AlarmAudioPlayer.instance.play(widget.alarm);
  }

  Future<void> _stopRinging() async {
    if (widget.previewOnly) return;
    await AlarmAudioPlayer.instance.stop();
    await WakelockPlus.disable();
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await AlarmStorage.instance.setRingingAlarmId(null);
    await NotificationService.instance.cancelAlarmNotification(widget.alarm.id);
  }

  Future<void> _dismiss() async {
    await _stopRinging();
    if (!mounted || widget.previewOnly) return;
    Navigator.of(context).pop();
  }

  Future<void> _snooze() async {
    await _stopRinging();
    if (widget.previewOnly) return;
    await AlarmScheduler.instance.scheduleSnooze(widget.alarm);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Snoozed for ${widget.alarm.snoozeMinutes} min 💤')),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    if (!widget.previewOnly) {
      AlarmAudioPlayer.instance.stop();
      WakelockPlus.disable();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.previewOnly,
      child: GradientBackground(
        gradient: AppGradients.ring,
        blobs: false,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  const Spacer(),
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.peach.withValues(alpha: 0.9),
                            AppColors.coral,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.coral.withValues(alpha: 0.5),
                            blurRadius: 40,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('☀️', style: TextStyle(fontSize: 56)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    widget.alarm.label,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.alarm.timeLabel,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w200,
                          letterSpacing: -2,
                        ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: const Text(
                      '📱  Playing from phone speaker',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: PillButton(
                      label: 'Snooze ${widget.alarm.snoozeMinutes} min',
                      filled: false,
                      light: true,
                      onPressed: _snooze,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: PillButton(
                      label: 'I\'m awake! 🎉',
                      icon: Icons.wb_sunny_rounded,
                      onPressed: _dismiss,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
