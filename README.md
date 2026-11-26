# Stillfast

An iPhone fasting tracker with Lock Screen widgets and a one-tap Lock Screen button. In development for the App Store.

- **Start / end a fast** in the app, from a Lock Screen control, from a Home Screen widget, or with Siri ("Start a fast in Stillfast").
- **Lock Screen widgets** show a live timer and progress towards your goal:
  - *Circular*: progress gauge with hours fasted
  - *Rectangular*: live timer, progress bar, and when you'll hit your goal
  - *Inline* (above the clock): live timer
- **Lock Screen control**: put a Fasting toggle in place of the flashlight/camera buttons and start or stop with one tap.
- **History**: a 14-day timeline showing when in each day you were fasting, a bar chart of recent fast lengths against your goal, and stats (average, longest, goal hit rate, streak).
- **Fix mistakes**: edit start and end times, back-date a start ("I started earlier…"), add fasts you forgot to log, swipe to delete.
- **Notification** when you reach your goal.

Fasts are stored on the phone and synced through the user's own private iCloud. There are no accounts and no server.

## Requirements

- A Mac with **Xcode 16 or later**
- An iPhone on **iOS 18 or later**
- A paid Apple Developer Program membership (iCloud sync needs it)

## Install on your iPhone

1. Install XcodeGen: `brew install xcodegen`
2. Run `xcodegen` in this folder, then open `Stillfast.xcodeproj`.
3. In Xcode, select the **Stillfast** project → for **both** the `Stillfast` and `StillfastWidget` targets, open *Signing & Capabilities* and choose your paid Team. (Or put your Team ID in `DEVELOPMENT_TEAM` in `project.yml` before running `xcodegen`.)
4. Connect your iPhone, select it as the run destination, and press ▶︎.
   - First time only: on the phone enable *Settings → Privacy & Security → Developer Mode*, and trust your developer certificate under *Settings → General → VPN & Device Management*.

## Add it to your Lock Screen

**Widget:** long-press the Lock Screen → *Customize* → *Lock Screen* → tap the widget area under the clock → choose **Stillfast** → pick the circular or rectangular style. For the inline version, tap the date above the clock instead.

**One-tap start/stop button:** in the same Customize screen, tap the ⊖ on the flashlight or camera button at the bottom, tap ⊕, and search for **Fasting** (the Stillfast control).

Tapping a Lock Screen widget opens the app. The control starts or stops a fast straight from the Lock Screen.

## Project layout

```
project.yml          XcodeGen spec (generates the .xcodeproj, Info.plists, entitlements)
Packages/FastingCore Logic with no UI, shared by every target and unit-tested
  Fast.swift           Data model + formatting
  FastingStats.swift   Stats and the per-day timeline segments
  DateCompare.swift    Safe Date comparisons (use these, never < > min max on Dates)
Shared/              Compiled into both the app and the widget
  Persistence.swift    The SwiftData database in the App Group, synced with iCloud by the app
  FastRecord.swift     How a fast is stored
  FastStore.swift      Read/write fasts, widget reloads, goal notification
  FastingIntents.swift Start / End / Toggle App Intents
App/                 The iPhone app (timer, history + charts, editor, Siri shortcuts)
Widget/              Lock Screen and Home Screen widgets + the Lock Screen control
.github/workflows    CI: runs the FastingCore tests and builds the app on every push
```

Run the logic tests locally with `swift test --package-path Packages/FastingCore`.
