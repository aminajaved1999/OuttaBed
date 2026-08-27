import 'package:flutter_test/flutter_test.dart';
import 'package:outta_bed/models/alarm.dart';
import 'package:outta_bed/utils/alarm_calculator.dart';

void main() {
  test('next alarm is today when time is in the future', () {
    final alarm = Alarm(
      id: '1',
      hour: 23,
      minute: 0,
      repeatDays: {},
    );
    final from = DateTime(2026, 1, 1, 10);
    final next = nextAlarmDateTime(alarm, from: from);
    expect(next, DateTime(2026, 1, 1, 23));
  });

  test('next alarm rolls to tomorrow for one-time alarms', () {
    final alarm = Alarm(
      id: '1',
      hour: 7,
      minute: 0,
      repeatDays: {},
    );
    final from = DateTime(2026, 1, 1, 8);
    final next = nextAlarmDateTime(alarm, from: from);
    expect(next, DateTime(2026, 1, 2, 7));
  });
}
