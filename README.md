# Dime Money

A minimal, beautiful personal finance tracker. Install and start tracking — no sign-up, no cloud, fully local.

Inspired by [Dime](https://github.com/fabiangruss/dime) (iOS) and [Ivy Wallet](https://github.com/Ivy-Apps/ivy-wallet) (Android) — bridging the gap between both platforms with one minimal, cross-platform app.

## What it does

- **Quick expense entry** — 3 taps: amount, category, done
- **8 default categories** with icons & colors (customizable)
- **Multiple accounts** — cash, bank, card + transfers between them
- **Monthly budgets** per category with visual progress bars
- **Dashboard** — balance overview, spending donut chart, period toggle (daily/weekly/monthly)
- **Recurring transactions** — set it once, auto-generates on schedule
- **Search** transaction history by note or category
- **Dark & light mode** — follows system by default
- **Biometric lock** — fingerprint/Face ID to protect your data
- **CSV import & export** — backup, restore, or migrate from other apps
- **Income tracking** — opt-in via settings

Everything stays on your device. No accounts, no servers, no tracking.

## Screenshots

*Coming soon*

## Tech Stack

| Layer | Choice |
|-------|--------|
| Framework | Flutter (Android + iOS) |
| State | Riverpod |
| Database | Drift (SQLite) |
| Navigation | GoRouter |
| Charts | fl_chart |
| Animations | flutter_animate |

## Getting Started

```bash
# Clone
git clone https://github.com/Priyans-hu/dime-money.git
cd dime-money

# Install deps
flutter pub get

# Generate Drift code
dart run build_runner build

# Run
flutter run
```

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
