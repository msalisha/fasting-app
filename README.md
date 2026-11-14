# Fasting

A small personal iPhone app for logging fasts, with Lock Screen widgets and a one-tap Lock Screen button.

- **Start / end a fast** in the app, from a Lock Screen control, from a Home Screen widget, or with Siri ("Start a fast in Fasting").
- **Lock Screen widgets** show a live timer and progress towards your goal:
  - *Circular*: progress gauge with hours fasted
  - *Rectangular*: live timer, progress bar, and when you'll hit your goal
  - *Inline* (above the clock): live timer
- **Lock Screen control**: put a Fasting toggle in place of the flashlight/camera buttons and start or stop with one tap.
- **History**: a 14-day timeline showing when in each day you were fasting, a bar chart of recent fast lengths against your goal, and stats (average, longest, goal hit rate, streak).
- **Fix mistakes**: edit start and end times, back-date a start ("I started earlier…"), add fasts you forgot to log, swipe to delete.
- **Notification** when you reach your goal.

Data stays on your phone, as a JSON file in a shared App Group container.

## Requirements

- A Mac with **Xcode 16 or later**
- An iPhone on **iOS 18 or later**
- An Apple ID. A free one works, but the app then has to be reinstalled from Xcode every 7 days. A paid developer account ($99/yr) removes that limit.

## Install on your iPhone

1. Install XcodeGen: `brew install xcodegen`
2. In `project.yml`, change `BASE_BUNDLE_ID` from `com.example.fasting` to something unique, e.g. `com.yourname.fasting`.
3. Run `xcodegen` in this folder, then open `Fasting.xcodeproj`.
4. In Xcode, select the **Fasting** project → for **both** the `Fasting` and `FastingWidget` targets, open *Signing & Capabilities* and choose your Team. (Or put your Team ID in `DEVELOPMENT_TEAM` in `project.yml` before running `xcodegen`.)
5. Connect your iPhone, select it as the run destination, and press ▶︎.
   - First time only: on the phone enable *Settings → Privacy & Security → Developer Mode*, and trust your developer certificate under *Settings → General → VPN & Device Management*.

## Add it to your Lock Screen

**Widget:** long-press the Lock Screen → *Customize* → *Lock Screen* → tap the widget area under the clock → choose **Fasting** → pick the circular or rectangular style. For the inline version, tap the date above the clock instead.

**One-tap start/stop button:** in the same Customize screen, tap the ⊖ on the flashlight or camera button at the bottom, tap ⊕, and search for **Fasting**.

Tapping a Lock Screen widget opens the app. The control starts or stops a fast straight from the Lock Screen.

## Project layout

```
project.yml          XcodeGen spec (generates the .xcodeproj, Info.plists, entitlements)
Shared/              Compiled into both the app and the widget
  Fast.swift           Data model + formatting
  FastStore.swift      JSON storage in the App Group, widget reloads, goal notification
  FastingIntents.swift Start / End / Toggle App Intents
App/                 The iPhone app (timer, history + charts, editor, Siri shortcuts)
Widget/              Lock Screen and Home Screen widgets + the Lock Screen control
```
