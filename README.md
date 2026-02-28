# Dime Money

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![CI](https://github.com/Priyans-hu/dime-money/actions/workflows/ci.yml/badge.svg)](https://github.com/Priyans-hu/dime-money/actions/workflows/ci.yml)
[![Latest Release](https://img.shields.io/github/v/release/Priyans-hu/dime-money)](https://github.com/Priyans-hu/dime-money/releases)
![Downloads](https://img.shields.io/github/downloads/Priyans-hu/dime-money/total)

A minimal, beautiful personal finance tracker for **Android** and **iOS**. No sign-up, no cloud, fully local.

Inspired by [Dime](https://github.com/rarfell/dimeApp) (iOS-only) and [Ivy Wallet](https://github.com/Ivy-Apps/ivy-wallet) (Android-only) — bridging the gap between both platforms with one cross-platform app.

<!-- Screenshots coming soon -->

## Why Dime Money?

Most finance apps are either too simple (just a list) or too complex (50 settings before you start). Dime Money sits in the middle:

- **Know your balance** across all accounts at a glance
- **See where your money goes** with category breakdowns and donut charts
- **Set budgets and stick to them** with color-coded progress bars
- **Your data stays yours** — everything is stored locally on device

## Features

| | |
|---|---|
| **Quick Add** | 3 taps: amount → category → done |
| **Categories** | 8 defaults + fully customizable with 40 icons & 14 colors |
| **Accounts** | Cash, bank, card — with transfers between them |
| **Budgets** | Monthly per-category limits with green/yellow/red progress |
| **Dashboard** | Balance, spending chart, period toggle (day/week/month) |
| **Recurring** | Daily, weekly, biweekly, monthly, yearly — auto-generates |
| **Search** | Find transactions by note |
| **Themes** | Dark & light mode, follows system or manual |
| **Security** | Biometric lock (fingerprint / Face ID) |
| **Backup** | CSV export & import — migrate from any app |
| **Income** | Opt-in via settings |
| **Currency** | Configurable symbol ($, EUR, GBP, INR, etc.) |

## Install

### Download (Android)

Head to [**Releases**](https://github.com/Priyans-hu/dime-money/releases) and grab the latest `.apk`.

### Build from source

Requires [Flutter](https://docs.flutter.dev/get-started/install) 3.11+

```bash
git clone https://github.com/Priyans-hu/dime-money.git
cd dime-money
flutter pub get
dart run build_runner build
flutter run
```

**Release builds:**

```bash
# Android APK
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk

# iOS (requires Xcode + Apple Developer account)
flutter build ipa --release
```

## Tech Stack

| | |
|---|---|
| **Framework** | Flutter (Dart) — Android + iOS from one codebase |
| **State** | Riverpod |
| **Database** | Drift (SQLite), fully local |
| **Navigation** | GoRouter with StatefulShellRoute |
| **Charts** | fl_chart |
| **Animations** | flutter_animate |
| **Auth** | local_auth (biometrics) |

## Architecture

Feature-first structure with clean separation:

```
lib/
├── core/            # Database, theme, router, providers, utils
│   ├── database/    # Drift tables, migrations, seed data
│   ├── theme/       # Material 3 light + dark themes
│   ├── router/      # GoRouter config
│   └── providers/   # App-wide providers
├── features/
│   ├── transactions/  # Quick add, history, search
│   ├── categories/    # CRUD, icon/color picker
│   ├── accounts/      # Manage, transfers, balances
│   ├── budgets/       # Per-category monthly budgets
│   ├── recurring/     # Rules + auto-processor
│   ├── dashboard/     # Balance, charts, overview
│   └── settings/      # Preferences, export/import
└── shared/widgets/  # GlassCard, AmountText, EmptyState
```

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

This project is licensed under the [GNU General Public License v3.0](LICENSE).
