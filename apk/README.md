# OuttaBed APK

Install this app directly on your Android phone (Samsung Galaxy A53 and others).

## Install

1. Copy `OuttaBed.apk` to your phone (USB, Google Drive, etc.).
2. On your phone, open the APK file.
3. If prompted, allow **Install from unknown sources** for your file manager.
4. Tap **Install**.

## First launch — required permissions

Open the app and grant **every** permission it asks for:

| Permission | Why |
|------------|-----|
| Notifications | Shows the alarm and keeps the foreground service alive |
| Alarms & reminders | Fires at the exact time you set |
| Full-screen intent | Pops the alarm over the lock screen |
| Battery → Unrestricted | Stops Samsung/Android from killing the alarm |

Also make sure **alarm volume** is turned up (press volume rocker → tap the alarm bell icon).

## What's new in this build

- **Type your time** — tap the hour/minute boxes and type `12` and `30` directly
- **Alarm actually rings** — triple-layer sound (native service + in-app ringer + Flutter audio) plus vibration
- Pick a **specific date** for one-time alarms
- Sound preview plays through earbuds; speaker lock only when alarm fires
- Wake-up math challenge before dismiss

## Version

Built from `main` — September 2026
