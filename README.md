# bu66le

A minimalist **bubble level** (spirit level) for your phone, built with Flutter.
Lay the device on a surface and a glowing bubble drifts toward the raised side —
it turns green when you're level.

## Features

- **2D bubble level** — a circular vial with crosshair and target ring; the
  bubble drifts toward the high corner like a real spirit level.
- **Single-axis tracks** — separate horizontal (X) and vertical (Y) tracks for
  dialing in one axis at a time.
- **Live numeric readout** — X/Y tilt in degrees, turning green within ±1° of
  level.
- **Record & review** — snapshot the current angles to a running list, newest
  first, and clear them when done.

## How it works

It reads the device **accelerometer** (via
[`sensors_plus`](https://pub.dev/packages/sensors_plus)). The raw vector is
smoothed with an exponential moving average to damp noise, then tilt angles are
derived with `atan2` of each axis against the others (gravity vector). Those
angles position the bubble and drive the readouts.

## Running it

Best on a **physical device** (emulators don't have a real accelerometer).

```sh
flutter pub get
flutter run
```

## App icon

The launcher icon (a glowing green bubble on a dark dial) is authored in
`assets/icon.svg` and expanded to all platforms with
[`flutter_launcher_icons`](https://pub.dev/packages/flutter_launcher_icons):

```sh
dart run flutter_launcher_icons
```

## Stack

- Flutter / Dart
- [`sensors_plus`](https://pub.dev/packages/sensors_plus) — accelerometer stream
- [`flutter_launcher_icons`](https://pub.dev/packages/flutter_launcher_icons)
