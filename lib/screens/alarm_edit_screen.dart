import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../models/alarm.dart';
import '../services/alarm_sound_preview.dart';
import '../services/native_bridge.dart';
import '../theme/app_theme.dart';
import '../widgets/alarm_time_picker.dart';
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
  late AlarmSoundSource _soundSource;
  late AlarmSound _sound;
  String? _deviceUri;
  String? _deviceTitle;
  List<DeviceSound> _deviceSounds = [];
  bool _loadingDeviceSounds = true;

  bool get _isEditing => widget.alarm != null;

  @override
  void initState() {
    super.initState();
    final alarm = widget.alarm;
    _time = alarm != null
        ? TimeOfDay(hour: alarm.hour, minute: alarm.minute)
        : const TimeOfDay(hour: 5, minute: 0);
    _labelController = TextEditingController(text: alarm?.label ?? 'rise & shine bestie');
    _repeatDays = Set<int>.from(alarm?.repeatDays ?? {1, 2, 3, 4, 5});
    _volume = alarm?.volume ?? 1.0;
    _snoozeMinutes = alarm?.snoozeMinutes ?? 9;
    _soundSource = alarm?.soundSource ?? AlarmSoundSource.builtin;
    _sound = alarm?.sound ?? AlarmSound.classic;
    _deviceUri = alarm?.deviceSoundUri;
    _deviceTitle = alarm?.deviceSoundTitle;
    AlarmSoundPreview.instance.previewingKey.addListener(_onPreviewChanged);
    _loadDeviceSounds();
  }

  Future<void> _loadDeviceSounds() async {
    if (widget.previewOnly) {
      setState(() => _loadingDeviceSounds = false);
      return;
    }
    final sounds = await NativeBridge.instance.getDeviceAlarmSounds();
    if (mounted) {
      setState(() {
        _deviceSounds = sounds;
        _loadingDeviceSounds = false;
      });
    }
  }

  @override
  void dispose() {
    AlarmSoundPreview.instance.previewingKey.removeListener(_onPreviewChanged);
    if (!widget.previewOnly) AlarmSoundPreview.instance.stop();
    _labelController.dispose();
    super.dispose();
  }

  void _onPreviewChanged() {
    if (mounted) setState(() {});
  }

  void _selectBuiltin(AlarmSound sound) {
    HapticFeedback.selectionClick();
    setState(() {
      _soundSource = AlarmSoundSource.builtin;
      _sound = sound;
      _deviceUri = null;
      _deviceTitle = null;
    });
    if (!widget.previewOnly) {
      AlarmSoundPreview.instance.previewBuiltin(sound, volume: _volume);
    }
  }

  void _selectDevice(DeviceSound sound) {
    HapticFeedback.selectionClick();
    setState(() {
      _soundSource = AlarmSoundSource.device;
      _deviceUri = sound.uri;
      _deviceTitle = sound.title;
    });
    if (!widget.previewOnly) {
      AlarmSoundPreview.instance.previewDevice(sound.uri, volume: _volume);
    }
  }

  Future<void> _pickFromPhone() async {
    if (widget.previewOnly) return;
    HapticFeedback.lightImpact();
    final picked = await NativeBridge.instance.pickDeviceAlarmSound();
    if (picked == null) return;
    _selectDevice(picked);
    await _loadDeviceSounds();
  }

  void _toggleDay(int day) {
    HapticFeedback.selectionClick();
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
    AlarmSoundPreview.instance.stop();
    final alarm = Alarm(
      id: widget.alarm?.id ?? const Uuid().v4(),
      hour: _time.hour,
      minute: _time.minute,
      label: _labelController.text.trim().isEmpty
          ? 'wake up bestie'
          : _labelController.text.trim(),
      enabled: widget.alarm?.enabled ?? true,
      repeatDays: Set<int>.from(_repeatDays),
      volume: _volume,
      snoozeMinutes: _snoozeMinutes,
      soundSource: _soundSource,
      sound: _sound,
      deviceSoundUri: _deviceUri,
      deviceSoundTitle: _deviceTitle,
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
                  onPressed: () {
                    AlarmSoundPreview.instance.stop();
                    Navigator.pop(context);
                  },
                ),
          title: Text(_isEditing ? 'tweak alarm ✏️' : 'new alarm ⏰'),
          actions: [
            if (!widget.previewOnly)
              TextButton(
                onPressed: _save,
                child: const Text('save', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StickerBadge(text: 'SOUND + VIBRATE', color: AppColors.hotPink, tilt: -0.05),
                StickerBadge(text: 'SPEAKER LOCK', color: AppColors.lime, tilt: 0.07),
              ],
            ),
            const SizedBox(height: 20),
            AlarmTimePicker(
              time: _time,
              readOnly: widget.previewOnly,
              onChanged: (time) => setState(() => _time = time),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _labelController,
              readOnly: widget.previewOnly,
              style: AppTheme.body(16, weight: FontWeight.w700).copyWith(color: AppColors.white),
              decoration: const InputDecoration(
                labelText: 'alarm name',
                prefixIcon: Icon(Icons.label_outline_rounded, color: AppColors.lime),
              ),
            ),
            const SizedBox(height: 28),
            const SectionTitle(title: 'repeat', emoji: '📅'),
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
            const SizedBox(height: 28),
            const SectionTitle(title: 'vibes (sound)', emoji: '🎵'),
            Text(
              'preview plays through your earbuds if connected',
              style: AppTheme.body(13, weight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            ...AlarmSound.values.map(
              (sound) => SoundOptionCard(
                emoji: sound.emoji,
                label: sound.label,
                selected: _soundSource == AlarmSoundSource.builtin && _sound == sound,
                isPlaying: AlarmSoundPreview.instance.isPreviewingKey(sound.name),
                onTap: () => _selectBuiltin(sound),
                onPreview: widget.previewOnly
                    ? null
                    : () => AlarmSoundPreview.instance.toggleBuiltin(sound, volume: _volume),
              ),
            ),
            const SizedBox(height: 16),
            const SectionTitle(title: 'phone sounds', emoji: '📱'),
            if (_loadingDeviceSounds)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator(color: AppColors.lime)),
              )
            else ...[
              ..._deviceSounds.take(8).map(
                (sound) => SoundOptionCard(
                  emoji: '📳',
                  label: sound.title,
                  selected: _soundSource == AlarmSoundSource.device && _deviceUri == sound.uri,
                  isPlaying: AlarmSoundPreview.instance.isPreviewingKey(sound.uri),
                  onTap: () => _selectDevice(sound),
                  onPreview: widget.previewOnly
                      ? null
                      : () => AlarmSoundPreview.instance.toggleDevice(sound.uri, volume: _volume),
                ),
              ),
              if (!widget.previewOnly)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: PillButton(
                    label: 'browse all phone sounds',
                    icon: Icons.library_music_rounded,
                    filled: false,
                    onPressed: _pickFromPhone,
                  ),
                ),
            ],
            const SizedBox(height: 20),
            const SectionTitle(title: 'loudness', emoji: '🔊'),
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
                          : (v) {
                              setState(() => _volume = v);
                              AlarmSoundPreview.instance.setVolume(v);
                            },
                    ),
                  ),
                  const Text('📣', style: TextStyle(fontSize: 20)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const SectionTitle(title: 'snooze', emoji: '💤'),
            Row(
              children: [5, 9, 15].map((mins) {
                final selected = _snoozeMinutes == mins;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: mins != 15 ? 8 : 0),
                    child: GestureDetector(
                      onTap: widget.previewOnly
                          ? null
                          : () {
                              HapticFeedback.selectionClick();
                              setState(() => _snoozeMinutes = mins);
                            },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: selected ? AppGradients.cardAccent : null,
                          color: selected ? null : AppColors.surface,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: selected ? AppColors.lime : AppColors.stroke,
                            width: 2,
                          ),
                          boxShadow: selected
                              ? [BoxShadow(color: AppColors.lime.withValues(alpha: 0.25), blurRadius: 12)]
                              : null,
                        ),
                        child: Text(
                          '$mins min',
                          textAlign: TextAlign.center,
                          style: AppTheme.display(15, weight: FontWeight.w800).copyWith(
                            color: selected ? AppColors.voidBlack : AppColors.muted,
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
                  label: _isEditing ? 'save changes' : 'lock it in',
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
}
