import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:outta_bed/screens/alarm_edit_screen.dart';
import 'package:outta_bed/screens/alarm_ring_screen.dart';
import 'package:outta_bed/screens/home_screen.dart';
import 'package:outta_bed/screenshot/sample_data.dart';
import 'package:outta_bed/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const phoneSize = Size(390, 844);

  Widget wrap(Widget child) {
    return RepaintBoundary(
      key: const ValueKey('screenshot'),
      child: MaterialApp(
        theme: AppTheme.dark,
        home: MediaQuery(
          data: const MediaQueryData(size: phoneSize),
          child: child,
        ),
      ),
    );
  }

  testWidgets('home with alarms', (tester) async {
    await tester.binding.setSurfaceSize(phoneSize);
    await tester.pumpWidget(wrap(HomeScreen(previewAlarms: SampleAlarms.list, previewBudsConnected: true)));
    await expectLater(
      find.byKey(const ValueKey('screenshot')),
      matchesGoldenFile('../screenshots/01_home.png'),
    );
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('home empty', (tester) async {
    await tester.binding.setSurfaceSize(phoneSize);
    await tester.pumpWidget(wrap(const HomeScreen(previewAlarms: [])));
    await expectLater(
      find.byKey(const ValueKey('screenshot')),
      matchesGoldenFile('../screenshots/02_home_empty.png'),
    );
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('alarm edit', (tester) async {
    await tester.binding.setSurfaceSize(phoneSize);
    await tester.pumpWidget(wrap(const AlarmEditScreen(previewOnly: true)));
    await expectLater(
      find.byKey(const ValueKey('screenshot')),
      matchesGoldenFile('../screenshots/03_alarm_edit.png'),
    );
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('alarm ring', (tester) async {
    await tester.binding.setSurfaceSize(phoneSize);
    await tester.pumpWidget(
      wrap(AlarmRingScreen(alarm: SampleAlarms.ring, previewOnly: true)),
    );
    await expectLater(
      find.byKey(const ValueKey('screenshot')),
      matchesGoldenFile('../screenshots/04_alarm_ring.png'),
    );
    await tester.binding.setSurfaceSize(null);
  });
}
