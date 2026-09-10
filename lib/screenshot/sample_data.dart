import '../models/alarm.dart';

abstract final class SampleAlarms {
  static List<Alarm> get list => [
        Alarm(
          id: '1',
          hour: 5,
          minute: 0,
          label: 'morning run (why)',
          repeatDays: {1, 2, 3, 4, 5},
          sound: AlarmSound.classic,
        ),
        Alarm(
          id: '2',
          hour: 7,
          minute: 30,
          label: 'brunch era',
          repeatDays: {0, 6},
          enabled: false,
          sound: AlarmSound.digital,
        ),
      ];

  static Alarm get ring => list.first;
}
