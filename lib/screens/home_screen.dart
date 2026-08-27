import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/alarm.dart';
import '../services/alarm_scheduler.dart';
import '../services/alarm_storage.dart';
import '../services/native_bridge.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/cute_widgets.dart';
import 'alarm_edit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.previewAlarms, this.previewBudsConnected = false});

  final List<Alarm>? previewAlarms;
  final bool previewBudsConnected;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  List<Alarm> _alarms = [];
  bool _loading = true;
  bool _budsConnected = false;
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    if (widget.previewAlarms != null) {
      _alarms = widget.previewAlarms!;
      _loading = false;
      _budsConnected = widget.previewBudsConnected;
    } else {
      _loadAlarms();
      _checkBuds();
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _checkBuds() async {
    final connected = await NativeBridge.instance.isBluetoothAudioConnected();
    if (mounted) setState(() => _budsConnected = connected);
  }

  Future<void> _loadAlarms() async {
    final alarms = await AlarmStorage.instance.loadAlarms();
    alarms.sort((a, b) {
      final aMinutes = a.hour * 60 + a.minute;
      final bMinutes = b.hour * 60 + b.minute;
      return aMinutes.compareTo(bMinutes);
    });
    if (mounted) {
      setState(() {
        _alarms = alarms;
        _loading = false;
      });
    }
  }

  Future<void> _toggleAlarm(Alarm alarm, bool enabled) async {
    HapticFeedback.selectionClick();
    if (widget.previewAlarms != null) {
      setState(() {
        final i = _alarms.indexWhere((a) => a.id == alarm.id);
        if (i >= 0) _alarms[i] = alarm.copyWith(enabled: enabled);
      });
      return;
    }
    final updated = alarm.copyWith(enabled: enabled);
    await _upsertAlarm(updated);
    if (enabled) {
      await AlarmScheduler.instance.scheduleAlarm(updated);
    } else {
      await AlarmScheduler.instance.cancelAlarm(updated.id);
    }
  }

  Future<void> _upsertAlarm(Alarm alarm) async {
    final index = _alarms.indexWhere((a) => a.id == alarm.id);
    final updated = List<Alarm>.from(_alarms);
    if (index >= 0) {
      updated[index] = alarm;
    } else {
      updated.add(alarm);
    }
    updated.sort((a, b) {
      final aMinutes = a.hour * 60 + a.minute;
      final bMinutes = b.hour * 60 + b.minute;
      return aMinutes.compareTo(bMinutes);
    });
    await AlarmStorage.instance.saveAlarms(updated);
    setState(() => _alarms = updated);
  }

  Future<void> _deleteAlarm(Alarm alarm) async {
    if (widget.previewAlarms != null) {
      setState(() => _alarms = _alarms.where((a) => a.id != alarm.id).toList());
      return;
    }
    await AlarmScheduler.instance.cancelAlarm(alarm.id);
    final updated = _alarms.where((a) => a.id != alarm.id).toList();
    await AlarmStorage.instance.saveAlarms(updated);
    setState(() => _alarms = updated);
  }

  Future<void> _openEditor([Alarm? alarm]) async {
    if (widget.previewAlarms != null) return;
    HapticFeedback.lightImpact();
    final result = await Navigator.of(context).push<Alarm>(
      MaterialPageRoute(builder: (_) => AlarmEditScreen(alarm: alarm)),
    );
    if (result == null) return;
    await _upsertAlarm(result);
    if (result.enabled) {
      await AlarmScheduler.instance.scheduleAlarm(result);
    } else {
      await AlarmScheduler.instance.cancelAlarm(result.id);
    }
  }

  Future<void> _requestPermissions() async {
    if (widget.previewAlarms != null) return;
    await NotificationService.instance.requestPermissions();
    await Permission.notification.request();
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
    await NativeBridge.instance.openBatterySettings();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      gradient: AppGradients.home,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.lime))
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _HomeHeader(onSettings: _requestPermissions)),
                    SliverToBoxAdapter(child: _BudsStatusCard(connected: _budsConnected)),
                    if (_alarms.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyState(onAdd: () => _openEditor()),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                        sliver: SliverList.separated(
                          itemCount: _alarms.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final alarm = _alarms[index];
                            return _AlarmCard(
                              alarm: alarm,
                              onToggle: (v) => _toggleAlarm(alarm, v),
                              onTap: () => _openEditor(alarm),
                              onDelete: () => _deleteAlarm(alarm),
                            );
                          },
                        ),
                      ),
                  ],
                ),
        ),
        floatingActionButton: widget.previewAlarms != null
            ? null
            : Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _CuteFab(onPressed: () => _openEditor()),
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.onSettings});

  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StickerBadge(text: 'NO SNOOZE LOST', color: AppColors.hotPink, tilt: -0.08),
              const Spacer(),
              IconButton(
                onPressed: onSettings,
                icon: const Icon(Icons.tune_rounded, color: AppColors.lime),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(color: AppColors.stroke),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'outta\nbed',
            style: AppTheme.display(52, weight: FontWeight.w800).copyWith(
              color: AppColors.white,
              height: 0.95,
              letterSpacing: -2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'earbuds stay connected.\nalarm still hits the speaker.',
            style: AppTheme.body(16, weight: FontWeight.w500).copyWith(height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _BudsStatusCard extends StatelessWidget {
  const _BudsStatusCard({required this.connected});

  final bool connected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: SoftCard(
        padding: const EdgeInsets.all(20),
        tilt: connected ? -0.02 : 0.02,
        accent: connected ? AppColors.electric : AppColors.lime,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              connected ? '🎧 buds detected' : '🔊 speaker locked',
              style: AppTheme.display(20, weight: FontWeight.w800).copyWith(color: AppColors.white),
            ),
            const SizedBox(height: 8),
            Text(
              connected
                  ? "don't worry. i've got the morning."
                  : 'no buds rn — alarm still screams from your phone.',
              style: AppTheme.body(15, weight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Zzz', style: AppTheme.display(80, weight: FontWeight.w800).copyWith(color: AppColors.stroke)),
          const SizedBox(height: 8),
          Text('no alarms', style: AppTheme.display(28, weight: FontWeight.w800).copyWith(color: AppColors.white)),
          const SizedBox(height: 10),
          Text(
            'set one before the doomscroll wins.',
            textAlign: TextAlign.center,
            style: AppTheme.body(16),
          ),
          const SizedBox(height: 28),
          PillButton(label: 'create alarm', icon: Icons.add_rounded, onPressed: onAdd),
        ],
      ),
    );
  }
}

class _AlarmCard extends StatelessWidget {
  const _AlarmCard({
    required this.alarm,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
  });

  final Alarm alarm;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final muted = !alarm.enabled;

    return Dismissible(
      key: ValueKey(alarm.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppColors.rose, AppColors.coral]),
          borderRadius: BorderRadius.circular(32),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.white, size: 28),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                title: const Text('delete this alarm?'),
                content: Text('${alarm.timeLabel} is gonna vanish'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('nah')),
                  FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('yeet')),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => onDelete(),
      child: SoftCard(
        onTap: onTap,
        tilt: alarm.enabled ? 0.015 : -0.01,
        accent: alarm.enabled ? AppColors.lime : AppColors.stroke,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alarm.timeLabel,
                    style: AppTheme.display(44, weight: FontWeight.w800).copyWith(
                      color: muted ? AppColors.muted : AppColors.lime,
                      letterSpacing: -2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alarm.label,
                    style: AppTheme.display(18, weight: FontWeight.w700).copyWith(
                      color: muted ? AppColors.muted : AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _TagChip(text: alarm.repeatSummary, emoji: '🔁'),
                      _TagChip(text: alarm.soundLabel, emoji: '🎵'),
                    ],
                  ),
                ],
              ),
            ),
            CuteToggle(value: alarm.enabled, onChanged: onToggle),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.text, required this.emoji});
  final String text;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Text(
        '$emoji $text',
        style: AppTheme.body(11, weight: FontWeight.w700).copyWith(color: AppColors.muted),
      ),
    );
  }
}

class _CuteFab extends StatelessWidget {
  const _CuteFab({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(32),
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppGradients.fab,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AppColors.lime.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, color: AppColors.voidBlack, size: 26),
                const SizedBox(width: 10),
                Text(
                  '+ alarm',
                  style: AppTheme.display(18, weight: FontWeight.w800)
                      .copyWith(color: AppColors.voidBlack),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
