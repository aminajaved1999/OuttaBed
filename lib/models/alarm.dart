import 'dart:convert';

enum AlarmSoundSource { builtin, device }

enum AlarmScheduleMode { weekly, once }

enum AlarmSound {
  classic('classic_alarm', 'main character beep', '🔔'),
  digital('digital_alarm', 'chaos pulse', '✨');

  const AlarmSound(this.assetName, this.label, this.emoji);
  final String assetName;
  final String label;
  final String emoji;

  String get assetPath => 'assets/sounds/$assetName.wav';
  String get nativeKey => 'asset://$assetName';
}

class Alarm {
  Alarm({
    required this.id,
    required this.hour,
    required this.minute,
    this.label = 'wake up bestie',
    this.enabled = true,
    this.repeatDays = const {},
    this.scheduleMode = AlarmScheduleMode.weekly,
    this.onceDate,
    this.volume = 1.0,
    this.snoozeMinutes = 9,
    this.soundSource = AlarmSoundSource.builtin,
    this.sound = AlarmSound.classic,
    this.deviceSoundUri,
    this.deviceSoundTitle,
  });

  final String id;
  final int hour;
  final int minute;
  final String label;
  final bool enabled;
  final Set<int> repeatDays;
  final AlarmScheduleMode scheduleMode;
  final DateTime? onceDate;
  final double volume;
  final int snoozeMinutes;
  final AlarmSoundSource soundSource;
  final AlarmSound sound;
  final String? deviceSoundUri;
  final String? deviceSoundTitle;

  static const dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  bool get isRepeating =>
      scheduleMode == AlarmScheduleMode.weekly && repeatDays.isNotEmpty;

  bool get isOnceOnDate =>
      scheduleMode == AlarmScheduleMode.once && onceDate != null;

  String get soundLabel => switch (soundSource) {
        AlarmSoundSource.builtin => sound.label,
        AlarmSoundSource.device => deviceSoundTitle ?? 'phone sound',
      };

  String? get nativeSoundUri => switch (soundSource) {
        AlarmSoundSource.builtin => sound.nativeKey,
        AlarmSoundSource.device => deviceSoundUri,
      };

  String get repeatSummary {
    if (scheduleMode == AlarmScheduleMode.once) {
      if (onceDate == null) return 'pick a date';
      final d = onceDate!;
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[d.month - 1]} ${d.day}, ${d.year}';
    }
    if (repeatDays.isEmpty) return 'no days picked';
    if (repeatDays.length == 7) return 'every day fr';
    if (repeatDays.length == 5 &&
        repeatDays.containsAll({1, 2, 3, 4, 5})) {
      return 'weekday grind';
    }
    if (repeatDays.length == 2 && repeatDays.containsAll({0, 6})) {
      return 'weekend mode';
    }
    final sorted = repeatDays.toList()..sort();
    return sorted.map((d) => dayLabels[d]).join(' ');
  }

  String get timeLabel {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  Alarm copyWith({
    String? id,
    int? hour,
    int? minute,
    String? label,
    bool? enabled,
    Set<int>? repeatDays,
    AlarmScheduleMode? scheduleMode,
    DateTime? onceDate,
    bool clearOnceDate = false,
    double? volume,
    int? snoozeMinutes,
    AlarmSoundSource? soundSource,
    AlarmSound? sound,
    String? deviceSoundUri,
    String? deviceSoundTitle,
    bool clearDeviceSound = false,
  }) {
    return Alarm(
      id: id ?? this.id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      label: label ?? this.label,
      enabled: enabled ?? this.enabled,
      repeatDays: repeatDays ?? this.repeatDays,
      scheduleMode: scheduleMode ?? this.scheduleMode,
      onceDate: clearOnceDate ? null : (onceDate ?? this.onceDate),
      volume: volume ?? this.volume,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      soundSource: soundSource ?? this.soundSource,
      sound: sound ?? this.sound,
      deviceSoundUri: clearDeviceSound ? null : (deviceSoundUri ?? this.deviceSoundUri),
      deviceSoundTitle:
          clearDeviceSound ? null : (deviceSoundTitle ?? this.deviceSoundTitle),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'hour': hour,
        'minute': minute,
        'label': label,
        'enabled': enabled,
        'repeatDays': repeatDays.toList(),
        'scheduleMode': scheduleMode.name,
        if (onceDate != null)
          'onceDate': '${onceDate!.year.toString().padLeft(4, '0')}-'
              '${onceDate!.month.toString().padLeft(2, '0')}-'
              '${onceDate!.day.toString().padLeft(2, '0')}',
        'volume': volume,
        'snoozeMinutes': snoozeMinutes,
        'soundSource': soundSource.name,
        'sound': sound.name,
        'deviceSoundUri': deviceSoundUri,
        'deviceSoundTitle': deviceSoundTitle,
      };

  factory Alarm.fromJson(Map<String, dynamic> json) {
    return Alarm(
      id: json['id'] as String,
      hour: json['hour'] as int,
      minute: json['minute'] as int,
      label: json['label'] as String? ?? 'wake up bestie',
      enabled: json['enabled'] as bool? ?? true,
      repeatDays: (json['repeatDays'] as List<dynamic>? ?? [])
          .map((e) => e as int)
          .toSet(),
      scheduleMode: AlarmScheduleMode.values.firstWhere(
        (m) => m.name == json['scheduleMode'],
        orElse: () => AlarmScheduleMode.weekly,
      ),
      onceDate: _parseOnceDate(json['onceDate'] as String?),
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
      snoozeMinutes: json['snoozeMinutes'] as int? ?? 9,
      soundSource: AlarmSoundSource.values.firstWhere(
        (s) => s.name == json['soundSource'],
        orElse: () => AlarmSoundSource.builtin,
      ),
      sound: AlarmSound.values.firstWhere(
        (s) => s.name == json['sound'],
        orElse: () => AlarmSound.classic,
      ),
      deviceSoundUri: json['deviceSoundUri'] as String?,
      deviceSoundTitle: json['deviceSoundTitle'] as String?,
    );
  }

  static DateTime? _parseOnceDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day);
  }

  static String encodeList(List<Alarm> alarms) =>
      jsonEncode(alarms.map((a) => a.toJson()).toList());

  static List<Alarm> decodeList(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => Alarm.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
