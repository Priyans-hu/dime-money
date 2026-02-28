# Dime Money

A minimal, beautiful personal finance tracker for Android and iOS. Install and start tracking — no sign-up, no cloud, fully local.

Inspired by [Dime](https://github.com/fabiangruss/dime) (iOS-only) and [Ivy Wallet](https://github.com/Ivy-Apps/ivy-wallet) (Android-only) — bridging the gap between both platforms with one minimal, cross-platform app.

## Features

- **Quick expense entry** — 3 taps: amount, category, done
- **8 default categories** with icons & colors (fully customizable)
- **Multiple accounts** — cash, bank, card + transfers between them
- **Monthly budgets** per category with color-coded progress bars
- **Dashboard** — balance overview, spending donut chart, period toggle (day/week/month)
- **Recurring transactions** — daily, weekly, biweekly, monthly, yearly
- **Search** transaction history by note
- **Dark & light mode** — follows system, or pick manually
- **Biometric lock** — fingerprint / Face ID
- **CSV import & export** — backup, restore, or migrate from other apps
- **Income tracking** — opt-in via settings
- **Configurable currency symbol**

Everything stays on your device. No accounts, no servers, no tracking.

## Install

### From GitHub Releases (recommended)

1. Go to [Releases](https://github.com/Priyans-hu/dime-money/releases)
2. Download the latest `.apk` (Android) or build from source for iOS
3. Install and open — no setup required

### Build from source

**Prerequisites:** [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.11+)

```bash
git clone https://github.com/Priyans-hu/dime-money.git
cd dime-money

flutter pub get
dart run build_runner build

# Run on connected device / emulator
flutter run

# Build release APK (Android)
flutter build apk --release

# Build release IPA (iOS, requires Xcode + Apple Developer account)
flutter build ipa --release
```

The release APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

## Tech Stack

| Layer | Choice |
|-------|--------|
| Framework | Flutter (Android + iOS) |
| State | Riverpod |
| Database | Drift (SQLite) |
| Navigation | GoRouter |
| Charts | fl_chart |
| Animations | flutter_animate |

## Project Structure

Feature-first architecture:

```
lib/
├── core/           # Database, theme, router, providers, utils
├── features/       # transactions, categories, accounts, budgets,
│                   # recurring, dashboard, settings
└── shared/widgets/ # Reusable UI components
```

## License

[GPL-3.0](LICENSE)
