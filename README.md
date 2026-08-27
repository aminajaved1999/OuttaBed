# OuttaBed

Wake up reliably — even when your Bluetooth earbuds fall out overnight and stay connected to your phone.

OuttaBed is a Flutter alarm clock for **Android** and **iOS** that routes alarm audio to your **phone speaker** instead of connected Bluetooth earbuds, so you never sleep through an alarm because sound went to a device across the room.

## The problem

You fall asleep with wireless earbuds connected. They fall out during the night but remain paired. In the morning, your phone alarm plays through the earbuds — not the phone speaker — and you miss your wake-up time.

## How OuttaBed helps

1. Set your wake-up time (with recurring days, custom label, volume, and sound).
2. At alarm time, the app wakes your device and opens a full-screen alarm screen.
3. Audio is **forced to the phone speaker** via platform-specific routing (speakerphone on Android, speaker override on iOS).
4. Snooze or dismiss when you're awake.

## Features

- Set alarm time with AM/PM picker
- Recurring alarms (select days of the week)
- Two built-in alarm sounds
- Adjustable volume
- Snooze (5 / 9 / 15 minutes)
- Works when the phone is locked (full-screen intent on Android)
- Survives reboot (alarms rescheduled on boot)
- Bluetooth-aware speaker routing

## Run on your Samsung Galaxy A53 (Android)

### Quick install (no build required)

Download and install the prebuilt APK from the repo:

**[`apk/OuttaBed.apk`](apk/OuttaBed.apk)**

Copy it to your phone and open it to install. See [`apk/README.md`](apk/README.md) for details.

### Build from source

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel)
- Android Studio or Android SDK with platform tools
- USB debugging enabled on your phone

### Steps

```bash
# Clone and enter the project
git clone <your-repo-url>
cd OuttaBed

# Install dependencies
flutter pub get

# Connect your Galaxy A53 via USB, then:
flutter devices
flutter run
```

### First launch permissions

On first run, grant:

- **Notifications** — required to show the alarm
- **Alarms & reminders** (exact alarms) — required for precise wake-up time on Android 12+
- **Full-screen intent** — allows the alarm screen over the lock screen (Settings → Apps → OuttaBed → Allow full screen)

### Build a release APK

```bash
flutter build apk --release
```

The APK will be at `build/app/outputs/flutter-apk/app-release.apk`. Transfer and install it on your phone.

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
  alarm_callback.dart       # Background alarm trigger (Android)
  models/alarm.dart         # Alarm data model
  services/
    alarm_storage.dart      # Persist alarms locally
    alarm_scheduler.dart    # Schedule exact alarms
    alarm_audio_player.dart # Loop alarm sound
    notification_service.dart
    speaker_routing.dart    # Platform channel for speaker output
  screens/
    home_screen.dart        # Alarm list
    alarm_edit_screen.dart  # Create / edit alarm
    alarm_ring_screen.dart  # Full-screen ringing UI
```

## Technical notes

- **Android**: Uses `android_alarm_manager_plus` for exact alarms, `flutter_local_notifications` with full-screen intent, and native Kotlin code to enable speakerphone and stop Bluetooth SCO before playback.
- **iOS**: Uses scheduled local notifications and `AVAudioSession.overrideOutputAudioPort(.speaker)` for speaker routing.
- Alarm audio uses `AndroidAudioUsage.alarm` so it respects the alarm stream volume.

## License

MIT
