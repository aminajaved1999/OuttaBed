# UI Screenshots

Previews of the OuttaBed app interface.

| Home (with alarms) | Empty state |
|---|---|
| ![Home](01_home.png) | ![Empty](02_home_empty.png) |

| New alarm | Alarm ringing |
|---|---|
| ![Edit](03_alarm_edit.png) | ![Ring](04_alarm_ring.png) |

To regenerate after UI changes:

```bash
flutter test --update-goldens test/generate_screenshots_test.dart
```
