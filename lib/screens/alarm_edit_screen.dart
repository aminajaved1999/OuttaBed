import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/alarm.dart';

class AlarmEditScreen extends StatefulWidget {
  const AlarmEditScreen({super.key, this.alarm});

  final Alarm? alarm;

  @override
  State<AlarmEditScreen> createState() => _AlarmEditScreenState();
}

class _AlarmEditScreenState extends State<AlarmEditScreen> {
  late TimeOfDay _time;
  late TextEditingController _labelController;
  late Set<int> _repeatDays;
  late double _volume;
  late int _snoozeMinutes;
  late AlarmSound _sound;

  bool get _isEditing => widget.alarm != null;

  @override
  void initState() {
    super.initState();
    final alarm = widget.alarm;
    _time = alarm != null
        ? TimeOfDay(hour: alarm.hour, minute: alarm.minute)
        : const TimeOfDay(hour: 7, minute: 0);
    _labelController = TextEditingController(text: alarm?.label ?? 'Wake up');
    _repeatDays = Set<int>.from(alarm?.repeatDays ?? {1, 2, 3, 4, 5});
    _volume = alarm?.volume ?? 1.0;
    _snoozeMinutes = alarm?.snoozeMinutes ?? 9;
    _sound = alarm?.sound ?? AlarmSound.classic;
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  void _toggleDay(int day) {
    setState(() {
      if (_repeatDays.contains(day)) {
        _repeatDays.remove(day);
      } else {
        _repeatDays.add(day);
      }
    });
  }

  void _save() {
    final alarm = Alarm(
      id: widget.alarm?.id ?? const Uuid().v4(),
      hour: _time.hour,
      minute: _time.minute,
      label: _labelController.text.trim().isEmpty
          ? 'Alarm'
          : _labelController.text.trim(),
      enabled: widget.alarm?.enabled ?? true,
      repeatDays: Set<int>.from(_repeatDays),
      volume: _volume,
      snoozeMinutes: _snoozeMinutes,
      sound: _sound,
    );
    Navigator.of(context).pop(alarm);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit alarm' : 'New alarm'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          InkWell(
            onTap: _pickTime,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              child: Center(
                child: Text(
                  _formatTime(_time),
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _labelController,
            decoration: const InputDecoration(
              labelText: 'Label',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Text('Repeat', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: List.generate(7, (index) {
              final selected = _repeatDays.contains(index);
              return FilterChip(
                label: Text(Alarm.dayLabels[index]),
                selected: selected,
                onSelected: (_) => _toggleDay(index),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            _repeatDays.isEmpty ? 'One-time alarm' : 'Repeating alarm',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Text('Alarm sound', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ...AlarmSound.values.map(
            (sound) => ListTile(
              title: Text(sound.label),
              leading: Radio<AlarmSound>(
                value: sound,
                groupValue: _sound,
                onChanged: (value) {
                  if (value != null) setState(() => _sound = value);
                },
              ),
              onTap: () => setState(() => _sound = sound),
            ),
          ),
          const SizedBox(height: 16),
          Text('Volume', style: theme.textTheme.titleMedium),
          Slider(
            value: _volume,
            onChanged: (value) => setState(() => _volume = value),
            divisions: 10,
            label: '${(_volume * 100).round()}%',
          ),
          const SizedBox(height: 16),
          Text('Snooze duration', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 5, label: Text('5 min')),
              ButtonSegment(value: 9, label: Text('9 min')),
              ButtonSegment(value: 15, label: Text('15 min')),
            ],
            selected: {_snoozeMinutes},
            onSelectionChanged: (selection) {
              setState(() => _snoozeMinutes = selection.first);
            },
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _save,
            child: Text(_isEditing ? 'Save changes' : 'Create alarm'),
          ),
        ],
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}
