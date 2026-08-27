import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/alarm.dart';
import '../services/alarm_audio_player.dart';
import '../services/alarm_scheduler.dart';
import '../services/alarm_storage.dart';
import '../services/alarm_vibration.dart';
import '../services/native_bridge.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/cute_widgets.dart';
import '../widgets/wake_challenge.dart';

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
  bool _showChallenge = false;

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
      _startRinging();
    }
    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _startRinging() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await WakelockPlus.enable();
    await AlarmVibration.instance.start();
    if (!Platform.isAndroid) {
      await AlarmAudioPlayer.instance.play(widget.alarm);
    }
  }

  Future<void> _stopRinging() async {
    if (widget.previewOnly) return;
    await AlarmVibration.instance.stop();
    await NativeBridge.instance.stopNativeAlarm();
    await AlarmAudioPlayer.instance.stop();
    await WakelockPlus.disable();
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await AlarmStorage.instance.setRingingAlarmId(null);
    await NotificationService.instance.cancelAlarmNotification(widget.alarm.id);
  }

  void _requestDismiss() {
    if (widget.previewOnly) return;
    HapticFeedback.mediumImpact();
    setState(() => _showChallenge = true);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => WakeChallengeSheet(
        onPassed: () async {
          Navigator.of(context).pop();
          await _stopRinging();
          if (!mounted) return;
          Navigator.of(context).pop();
        },
      ),
    ).whenComplete(() => setState(() => _showChallenge = false));
  }

  Future<void> _snooze() async {
    if (widget.previewOnly) return;
    HapticFeedback.lightImpact();
    await _stopRinging();
    await AlarmScheduler.instance.scheduleSnooze(widget.alarm);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('snoozed ${widget.alarm.snoozeMinutes} min — no judgment 💤')),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    if (!widget.previewOnly) {
      AlarmAudioPlayer.instance.stop();
      AlarmVibration.instance.stop();
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
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.lime.withValues(alpha: 0.5), width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.hotPink.withValues(alpha: 0.4),
                            blurRadius: 40,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        '!',
                        style: AppTheme.display(72, weight: FontWeight.w800)
                            .copyWith(color: AppColors.lime),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.alarm.label,
                    style: AppTheme.display(28, weight: FontWeight.w800)
                        .copyWith(color: AppColors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.alarm.timeLabel,
                    style: AppTheme.display(64, weight: FontWeight.w800).copyWith(
                      color: AppColors.lime,
                      letterSpacing: -2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  StickerBadge(
                    text: 'SPEAKER + VIBRATE',
                    color: AppColors.hotPink,
                    tilt: 0.05,
                  ),
                  const Spacer(),
                  if (!_showChallenge) ...[
                    SizedBox(
                      width: double.infinity,
                      child: PillButton(
                        label: '5 more min pls',
                        filled: false,
                        light: true,
                        onPressed: _snooze,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: PillButton(
                        label: "i'm up",
                        icon: Icons.bolt_rounded,
                        onPressed: _requestDismiss,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
