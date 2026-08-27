import 'dart:convert';

enum AlarmSound {
  classic('classic_alarm', 'Classic Beep'),
  digital('digital_alarm', 'Digital Pulse');

  const AlarmSound(this.assetName, this.label);
  final String assetName;
  final String label;

  String get assetPath => 'assets/sounds/$assetName.wav';
}

class Alarm {
  Alarm({
    required this.id,
    required this.hour,
    required this.minute,
    this.label = 'Alarm',
    this.enabled = true,
    this.repeatDays = const {},
    this.volume = 1.0,
    this.snoozeMinutes = 9,
    this.sound = AlarmSound.classic,
  });

  final String id;
  final int hour;
  final int minute;
  final String label;
  final bool enabled;
  final Set<int> repeatDays;
  final double volume;
  final int snoozeMinutes;
  final AlarmSound sound;

  static const dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  bool get isRepeating => repeatDays.isNotEmpty;

  String get repeatSummary {
    if (repeatDays.isEmpty) return 'Once';
    if (repeatDays.length == 7) return 'Every day';
    if (repeatDays.length == 5 &&
        repeatDays.containsAll({1, 2, 3, 4, 5})) {
      return 'Weekdays';
    }
    if (repeatDays.length == 2 && repeatDays.containsAll({0, 6})) {
      return 'Weekends';
    }
    final sorted = repeatDays.toList()..sort();
    return sorted.map((d) => dayLabels[d]).join(', ');
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
    double? volume,
    int? snoozeMinutes,
    AlarmSound? sound,
  }) {
    return Alarm(
      id: id ?? this.id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      label: label ?? this.label,
      enabled: enabled ?? this.enabled,
      repeatDays: repeatDays ?? this.repeatDays,
      volume: volume ?? this.volume,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      sound: sound ?? this.sound,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'hour': hour,
        'minute': minute,
        'label': label,
        'enabled': enabled,
        'repeatDays': repeatDays.toList(),
        'volume': volume,
        'snoozeMinutes': snoozeMinutes,
        'sound': sound.name,
      };

  factory Alarm.fromJson(Map<String, dynamic> json) {
    return Alarm(
      id: json['id'] as String,
      hour: json['hour'] as int,
      minute: json['minute'] as int,
      label: json['label'] as String? ?? 'Alarm',
      enabled: json['enabled'] as bool? ?? true,
      repeatDays: (json['repeatDays'] as List<dynamic>? ?? [])
          .map((e) => e as int)
          .toSet(),
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
      snoozeMinutes: json['snoozeMinutes'] as int? ?? 9,
      sound: AlarmSound.values.firstWhere(
        (s) => s.name == json['sound'],
        orElse: () => AlarmSound.classic,
      ),
    );
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
