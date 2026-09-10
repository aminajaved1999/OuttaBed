# OuttaBed

Wake up reliably — even when your Bluetooth earbuds fall out overnight and stay connected to your phone.

OuttaBed is a Flutter alarm clock for **Android** and **iOS** that routes alarm audio to your **phone speaker** instead of connected Bluetooth earbuds, so you never sleep through an alarm because sound went to a device across the room.

## The problem

You fall asleep with wireless earbuds connected. They fall out during the night but remain paired. In the morning, your phone alarm plays through the earbuds — not the phone speaker — and you miss your wake-up time.

## How OuttaBed helps

1. Set your wake-up time (type it in or use +/- buttons).
2. Pick weekly repeat days **or** a specific one-time date.
3. At alarm time, the app wakes your device and opens a full-screen alarm screen.
4. Audio is **forced to the phone speaker** with **vibration** (multi-layer playback so it actually rings).
5. Solve a quick math challenge, then snooze or dismiss.

## Features

- **Type or tap** to set hour and minute (no endless +/- tapping)
- Weekly recurring alarms or **pick a specific date** for one-time alarms
- Built-in alarm sounds plus your phone's alarm tones
- Sound preview through earbuds; speaker lock only when the alarm fires
- **Sound + vibration** together during the alarm
- Adjustable volume and snooze (5 / 9 / 15 minutes)
- Wake-up math challenge before dismiss
- Permission prompts on first open (notifications, exact alarms, full-screen, battery)
- Dark neon UI with system fonts
- Works when the phone is locked (full-screen intent on Android)
- Survives reboot (alarms rescheduled on boot)

## Run on your Samsung Galaxy A53 (Android)

### Quick install (no build required)

Download and install the prebuilt APK from the repo:

**[`apk/OuttaBed.apk`](apk/OuttaBed.apk)**

Copy it to your phone and open it to install. See [`apk/README.md`](apk/README.md) for details.

### Build from source

#### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel)
- Android Studio or Android SDK with platform tools
- USB debugging enabled on your phone

#### Steps

```bash
git clone https://github.com/aminajaved1999/OuttaBed.git
cd OuttaBed
flutter pub get
flutter devices
flutter run
```

### First launch permissions

Grant all of these when prompted — alarms will not ring reliably without them:

- **Notifications**
- **Alarms & reminders** (exact alarms)
- **Full-screen intent** (Settings → Apps → OuttaBed → Allow full screen)
- **Battery optimization** — set to Unrestricted for OuttaBed

Also check that your **alarm volume** is not muted (volume rocker → alarm icon).

### Build a release APK

```bash
flutter build apk --release
cp build/app/outputs/flutter-apk/app-release.apk apk/OuttaBed.apk
```

## UI previews

See the [`screenshots/`](screenshots/) folder for app screenshots.

## iOS

```bash
flutter run -d <ios-device-id>
```

iOS alarm timing is less exact than Android due to platform restrictions, but speaker routing and the alarm UI work the same.

## Project structure

```
lib/
  main.dart                 # App entry + initialization
  app.dart                  # Root widget + alarm screen navigation
  models/alarm.dart         # Alarm data model
  services/
    alarm_storage.dart      # Persist alarms locally
    alarm_scheduler.dart    # Schedule exact alarms
    alarm_audio_player.dart # Loop alarm sound (Flutter layer)
    alarm_vibration.dart    # Vibration + haptics
    native_bridge.dart      # Android native alarm + permissions
    notification_service.dart
    permission_service.dart
    speaker_routing.dart
  screens/
    home_screen.dart        # Alarm list
    alarm_edit_screen.dart  # Create / edit alarm
    alarm_ring_screen.dart  # Full-screen ringing UI
  widgets/
    alarm_time_picker.dart  # Type-or-tap time picker
android/.../AlarmRingService.kt   # Foreground alarm service
android/.../AlarmRinger.kt        # In-app sound + vibration
apk/OuttaBed.apk                  # Prebuilt release APK
```

## Technical notes

- **Android**: Uses `AlarmManager.setAlarmClock`, a foreground `AlarmRingService`, `AlarmRinger` for in-app playback, Flutter `just_audio` as a fallback layer, and native vibration. Speakerphone is forced at alarm time only.
- **iOS**: Uses scheduled local notifications and `AVAudioSession.overrideOutputAudioPort(.speaker)` for speaker routing.
- Alarm audio uses `AndroidAudioUsage.alarm` so it respects the alarm stream volume.

## License

MIT
