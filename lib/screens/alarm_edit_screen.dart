import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/alarm.dart';
import '../theme/app_theme.dart';
import '../widgets/cute_widgets.dart';

class AlarmEditScreen extends StatefulWidget {
  const AlarmEditScreen({super.key, this.alarm, this.previewOnly = false});

  final Alarm? alarm;
  final bool previewOnly;

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
        : const TimeOfDay(hour: 5, minute: 0);
    _labelController = TextEditingController(text: alarm?.label ?? 'Rise & shine');
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
    if (widget.previewOnly) return;
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.coral),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
            child: child!,
          ),
        );
      },
    );
    if (picked != null) setState(() => _time = picked);
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
    if (widget.previewOnly) return;
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
    return GradientBackground(
      gradient: AppGradients.home,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: widget.previewOnly
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
          title: Text(_isEditing ? 'Edit alarm ✏️' : 'New alarm ⏰'),
          actions: [
            if (!widget.previewOnly)
              TextButton(
                onPressed: _save,
                child: const Text(
                  'Save',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            GestureDetector(
              onTap: _pickTime,
              child: SoftCard(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                gradient: LinearGradient(
                  colors: [
                    AppColors.lavender.withValues(alpha: 0.5),
                    AppColors.blush.withValues(alpha: 0.5),
                  ],
                ),
                child: Column(
                  children: [
                    const Text('☀️', style: TextStyle(fontSize: 32)),
                    const SizedBox(height: 8),
                    Text(
                      _formatTime(_time),
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.w200,
                            color: AppColors.plum,
                            letterSpacing: -2,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap to change',
                      style: TextStyle(
                        color: AppColors.plumSoft,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _labelController,
              readOnly: widget.previewOnly,
              style: const TextStyle(fontWeight: FontWeight.w700),
              decoration: const InputDecoration(
                labelText: 'Alarm name',
                prefixIcon: Icon(Icons.label_outline_rounded),
              ),
            ),
            const SizedBox(height: 28),
            const SectionTitle(title: 'Repeat days', emoji: '📅'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                return DayChip(
                  label: Alarm.dayLabels[index],
                  selected: _repeatDays.contains(index),
                  onTap: () => _toggleDay(index),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              _repeatDays.isEmpty ? 'One-time alarm' : 'Repeating alarm',
              style: TextStyle(color: AppColors.plumSoft, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 28),
            const SectionTitle(title: 'Sound', emoji: '🎵'),
            ...AlarmSound.values.map(
              (sound) => SoundOptionCard(
                emoji: sound.emoji,
                label: sound.label,
                selected: _sound == sound,
                onTap: () => setState(() => _sound = sound),
              ),
            ),
            const SizedBox(height: 20),
            const SectionTitle(title: 'Volume', emoji: '🔊'),
            SoftCard(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
              child: Row(
                children: [
                  const Text('🤫', style: TextStyle(fontSize: 20)),
                  Expanded(
                    child: Slider(
                      value: _volume,
                      onChanged: widget.previewOnly
                          ? null
                          : (v) => setState(() => _volume = v),
                    ),
                  ),
                  const Text('📣', style: TextStyle(fontSize: 20)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '${(_volume * 100).round()}% loud',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.plumSoft,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const SectionTitle(title: 'Snooze', emoji: '💤'),
            Row(
              children: [5, 9, 15].map((mins) {
                final selected = _snoozeMinutes == mins;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: mins != 15 ? 8 : 0),
                    child: GestureDetector(
                      onTap: () => setState(() => _snoozeMinutes = mins),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: selected ? AppGradients.cardAccent : null,
                          color: selected ? null : AppColors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: selected ? Colors.transparent : AppColors.blush,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          '$mins min',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: selected ? AppColors.white : AppColors.plumSoft,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (!widget.previewOnly) ...[
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: PillButton(
                  label: _isEditing ? 'Save changes' : 'Create alarm',
                  icon: Icons.check_rounded,
                  onPressed: _save,
                ),
              ),
            ],
          ],
        ),
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
