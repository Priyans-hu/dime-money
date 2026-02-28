# Dime Money — LLM Context

This file provides context for AI assistants working on this codebase.

## What is this?

Dime Money is a cross-platform (Android + iOS) personal finance tracker built with Flutter. It's fully local — no backend, no auth, no network calls.

## Stack

- **Flutter** (Dart) — UI framework
- **Riverpod** — state management
- **Drift** (SQLite) — local database with code generation
- **GoRouter** — declarative routing with StatefulShellRoute for bottom nav
- **fl_chart** — pie/donut charts
- **flutter_animate** — declarative animations
- **local_auth** — biometric lock (fingerprint/Face ID)

## Architecture

Feature-first structure. Each feature has:
```
features/<name>/
├── data/
│   ├── tables/        # Drift table definitions
│   └── repositories/  # Data access layer
└── presentation/
    ├── screens/       # Full-page widgets
    ├── widgets/       # Feature-specific widgets
    └── providers/     # Riverpod providers
```

Shared code lives in `core/` (database, theme, router, utils) and `shared/widgets/`.

## Database

5 Drift tables: `Categories`, `Accounts`, `Transactions`, `Budgets`, `RecurringRules`.

On first launch, seeds 8 default categories + 1 Cash account.

After changing any table, run: `dart run build_runner build --delete-conflicting-outputs`

## Key Design Decisions

- **Amounts are always positive** — `TransactionType` (expense/income/transfer) determines direction
- **Transfers** use `accountId` (from) + `toAccountId` (to), no category
- **Budgets** reset monthly, no rollover
- **Recurring** processes on app open only (no background isolate)
- **Income** is opt-in via settings toggle
- **Currency** is a configurable symbol, not a full currency system

## Navigation

Bottom nav with 4 tabs (Home, History, Budgets, Settings) + center FAB for quick add. Modal bottom sheets for most interactions.

## Settings stored in SharedPreferences

- `theme_mode` — system/light/dark
- `income_enabled` — bool
- `currency_symbol` — string
- `biometric_enabled` — bool
