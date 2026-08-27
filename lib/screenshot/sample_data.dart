import '../models/alarm.dart';

abstract final class SampleAlarms {
  static List<Alarm> get list => [
        Alarm(
          id: '1',
          hour: 5,
          minute: 0,
          label: 'Morning run',
          repeatDays: {1, 2, 3, 4, 5},
          sound: AlarmSound.classic,
        ),
        Alarm(
          id: '2',
          hour: 7,
          minute: 30,
          label: 'Weekend brunch',
          repeatDays: {0, 6},
          enabled: false,
          sound: AlarmSound.digital,
        ),
        Alarm(
          id: '3',
          hour: 6,
          minute: 15,
          label: 'School day',
          repeatDays: {1, 2, 3, 4, 5},
          volume: 0.85,
          sound: AlarmSound.digital,
        ),
      ];

  static Alarm get ring => list.first;
}
