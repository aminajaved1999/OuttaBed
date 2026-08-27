import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/alarm.dart';
import '../services/alarm_scheduler.dart';
import '../services/alarm_storage.dart';
import '../services/notification_service.dart';
import 'alarm_edit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Alarm> _alarms = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAlarms();
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
    await AlarmScheduler.instance.cancelAlarm(alarm.id);
    final updated = _alarms.where((a) => a.id != alarm.id).toList();
    await AlarmStorage.instance.saveAlarms(updated);
    setState(() => _alarms = updated);
  }

  Future<void> _openEditor([Alarm? alarm]) async {
    final result = await Navigator.of(context).push<Alarm>(
      MaterialPageRoute(
        builder: (_) => AlarmEditScreen(alarm: alarm),
      ),
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
    await NotificationService.instance.requestPermissions();
    await Permission.notification.request();
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('OuttaBed'),
        actions: [
          IconButton(
            tooltip: 'Permissions',
            onPressed: _requestPermissions,
            icon: const Icon(Icons.shield_outlined),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _InfoBanner(theme: theme),
                Expanded(
                  child: _alarms.isEmpty
                      ? _EmptyState(onAdd: () => _openEditor())
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _alarms.length,
                          itemBuilder: (context, index) {
                            final alarm = _alarms[index];
                            return _AlarmTile(
                              alarm: alarm,
                              onToggle: (enabled) => _toggleAlarm(alarm, enabled),
                              onTap: () => _openEditor(alarm),
                              onDelete: () => _deleteAlarm(alarm),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add_alarm),
        label: const Text('New alarm'),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.speaker_phone, color: theme.colorScheme.onPrimaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Alarms play through your phone speaker — even if Bluetooth earbuds stay connected.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.alarm_off,
              size: 72,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No alarms yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Set a wake-up time and OuttaBed will make sure you hear it from your phone.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_alarm),
              label: const Text('Create your first alarm'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlarmTile extends StatelessWidget {
  const _AlarmTile({
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
    final theme = Theme.of(context);
    final textColor = alarm.enabled
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurface.withValues(alpha: 0.45);

    return Dismissible(
      key: ValueKey(alarm.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: theme.colorScheme.error,
        child: Icon(Icons.delete, color: theme.colorScheme.onError),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete alarm?'),
                content: Text('Remove ${alarm.timeLabel}?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => onDelete(),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        title: Text(
          alarm.timeLabel,
          style: theme.textTheme.displaySmall?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w300,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              alarm.label,
              style: theme.textTheme.titleMedium?.copyWith(color: textColor),
            ),
            const SizedBox(height: 4),
            Text(
              '${alarm.repeatSummary} · ${alarm.sound.label}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: Switch(
          value: alarm.enabled,
          onChanged: onToggle,
        ),
      ),
    );
  }
}
