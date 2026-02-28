# Contributing to Dime Money

Thanks for your interest in contributing! Here's how to get started.

## Getting Started

1. Fork the repo and clone your fork
2. Install [Flutter](https://docs.flutter.dev/get-started/install) 3.11+
3. Run the project:
   ```bash
   flutter pub get
   dart run build_runner build
   flutter run
   ```

## Development Workflow

1. Create a branch from `main`: `git checkout -b feat/my-feature`
2. Make your changes
3. Run checks:
   ```bash
   flutter analyze
   flutter test
   ```
4. Commit with a clear message (see conventions below)
5. Push and open a PR against `main`

## Commit Conventions

Use prefixes:

- `feat:` — new feature
- `fix:` — bug fix
- `docs:` — documentation only
- `chore:` — maintenance, deps, CI
- `refactor:` — code change that doesn't fix a bug or add a feature

## Code Style

- Follow existing patterns in the codebase
- Feature-first architecture: new features go in `lib/features/<name>/`
- Use Riverpod for state management
- Run `flutter analyze` — zero warnings before submitting
- Keep PRs focused and small

## Code Generation

This project uses Drift for the database. After changing any table or database class:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Reporting Issues

- Use GitHub Issues
- Include steps to reproduce, expected vs actual behavior
- Include Flutter version (`flutter --version`)

## Pull Requests

- Keep them small and focused on one thing
- Reference related issues if applicable
- All PRs must pass CI (analyze + test + build)
- Stale review approvals are automatically dismissed
