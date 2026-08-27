import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/alarm.dart';
import '../services/alarm_scheduler.dart';
import '../services/alarm_storage.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/cute_widgets.dart';
import 'alarm_edit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.previewAlarms});

  /// When set, skips storage and shows these alarms (for screenshots/dev).
  final List<Alarm>? previewAlarms;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Alarm> _alarms = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.previewAlarms != null) {
      _alarms = widget.previewAlarms!;
      _loading = false;
    } else {
      _loadAlarms();
    }
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
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      gradient: AppGradients.home,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.coral),
                )
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _HomeHeader(onSettings: _requestPermissions)),
                    SliverToBoxAdapter(child: _TipCard()),
                    if (_alarms.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyState(onAdd: () => _openEditor()),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
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
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🌙', style: TextStyle(fontSize: 36)),
                const SizedBox(height: 4),
                Text(
                  'OuttaBed',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.plum,
                        letterSpacing: -0.5,
                      ),
                ),
                Text(
                  'Sweet dreams, loud mornings ✨',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.plumSoft,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: onSettings,
            icon: const Icon(Icons.tune_rounded, size: 22),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.white.withValues(alpha: 0.85),
              foregroundColor: AppColors.plum,
            ),
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: SoftCard(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lavender.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text('📱', style: TextStyle(fontSize: 26)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Alarms always play from your phone speaker — earbuds can stay connected!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.plum,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
              ),
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
          const Text('😴', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 20),
          Text(
            'No alarms yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.plum,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'Set a cozy wake-up time and we\'ll make sure you actually hear it.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.plumSoft,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 28),
          PillButton(
            label: 'Create alarm',
            icon: Icons.add_rounded,
            onPressed: onAdd,
          ),
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
          gradient: LinearGradient(
            colors: [AppColors.rose, AppColors.coral],
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.white, size: 28),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                title: const Text('Delete alarm? 🗑️'),
                content: Text('Remove ${alarm.timeLabel}?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Nope')),
                  FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => onDelete(),
      child: SoftCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alarm.timeLabel,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w300,
                          color: muted
                              ? AppColors.plumSoft.withValues(alpha: 0.5)
                              : AppColors.plum,
                          letterSpacing: -1,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alarm.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: muted
                              ? AppColors.plumSoft.withValues(alpha: 0.5)
                              : AppColors.plum,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _TagChip(text: alarm.repeatSummary, emoji: '🔁'),
                      _TagChip(text: alarm.sound.label, emoji: alarm.sound.emoji),
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
        color: AppColors.blush.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$emoji $text',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.plumSoft,
        ),
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
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppGradients.fab,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.coral.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: AppColors.white, size: 26),
                SizedBox(width: 10),
                Text(
                  'New alarm',
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
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
