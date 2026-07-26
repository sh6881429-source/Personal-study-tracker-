# 🤝 Contributing to PrepTracker By Yash

First off, thank you for considering contributing to PrepTracker! Every contribution — big or small — is valued and makes this project better.

---

## 📜 Code of Conduct

By participating in this project, you agree to maintain a respectful, inclusive, and harassment-free environment. Be kind, be constructive, and treat others the way you'd want to be treated.

---

## 🐛 Reporting Bugs

Found a bug? Please help us squash it!

1. **Search existing issues** first to avoid duplicates.
2. **Open a new issue** with the `bug` label.
3. Include the following details:
   - **Description** — Clear and concise description of the bug.
   - **Steps to Reproduce** — Numbered steps to reproduce the behavior.
   - **Expected Behavior** — What you expected to happen.
   - **Actual Behavior** — What actually happened.
   - **Screenshots/Logs** — If applicable.
   - **Environment** — Device, OS, Flutter version, Dart version.

---

## 💡 Suggesting Features

Have an idea? We'd love to hear it!

1. **Search existing issues** to see if it's already been suggested.
2. **Open a new issue** with the `enhancement` label.
3. Describe:
   - **The problem** your feature would solve.
   - **Your proposed solution** with as much detail as possible.
   - **Alternatives** you've considered.
   - **Mockups/wireframes** if you have them.

---

## 🛠️ Development Setup

### Prerequisites

- Flutter SDK `>= 3.44.6`
- Dart SDK `>= 3.12.2`
- A Supabase project (free tier)
- A Google Gemini API key (free tier)
- Git

### Setup

```bash
# 1. Fork and clone the repository
git clone https://github.com/YOUR_USERNAME/preptracker.git
cd preptracker

# 2. Add upstream remote
git remote add upstream https://github.com/yourusername/preptracker.git

# 3. Create environment file
cp .env.example .env
# Fill in your API keys

# 4. Install dependencies
flutter pub get

# 5. Run the app
flutter run

# 6. Run tests
flutter test
```

---

## 📐 Coding Standards

### Dart Style

- Follow the official [Dart Style Guide](https://dart.dev/effective-dart/style).
- Use `dart format` before committing.
- Run `dart analyze` to catch lint issues — zero warnings is the goal.

### Architecture Principles

- **Feature-first structure** — All feature code lives in `lib/features/<feature_name>/`.
- **SOLID principles** — Single responsibility, open-closed, Liskov substitution, interface segregation, dependency inversion.
- **Repository pattern** — Data access is abstracted behind repository interfaces.
- **Riverpod patterns** — Use `Notifier` / `AsyncNotifier` for state management. Avoid `StateProvider` for complex state.

### Naming Conventions

| Type | Convention | Example |
|---|---|---|
| Files | `snake_case` | `study_timer_screen.dart` |
| Classes | `PascalCase` | `StudyTimerScreen` |
| Variables / Functions | `camelCase` | `startTimer()` |
| Constants | `camelCase` | `defaultSessionDuration` |
| Providers | `camelCase` + `Provider` suffix | `studyTimerProvider` |

### Neo Brutalism Design Rules

- All interactive cards and containers must use `3px` solid black borders.
- Offset shadows use `4px` horizontal and `4px` vertical offset.
- Buttons must have press-down animation (translate shadow on press).
- Use the defined color palette — no ad-hoc colors.
- Typography follows the type scale defined in the theme.

---

## 🔀 Pull Request Process

1. **Create a feature branch** from `main` (see branch naming below).
2. **Make your changes** following the coding standards above.
3. **Write/update tests** for your changes.
4. **Run all checks**:
   ```bash
   dart format .
   dart analyze
   flutter test
   ```
5. **Commit your changes** using conventional commits (see below).
6. **Push your branch** and open a PR against `main`.
7. **Fill out the PR template** with a clear description.
8. **Request review** and address any feedback.

### PR Checklist

- [ ] Code follows project coding standards
- [ ] `dart format` and `dart analyze` pass with no issues
- [ ] Tests added/updated for changes
- [ ] All existing tests pass
- [ ] Documentation updated if needed
- [ ] No unrelated changes included

---

## 📝 Commit Message Format

We follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/):

```
<type>(<scope>): <short description>

[optional body]

[optional footer]
```

### Types

| Type | Description |
|---|---|
| `feat` | A new feature |
| `fix` | A bug fix |
| `docs` | Documentation changes |
| `style` | Code style changes (formatting, no logic change) |
| `refactor` | Code refactoring (no feature or fix) |
| `perf` | Performance improvements |
| `test` | Adding or updating tests |
| `chore` | Maintenance tasks (deps, build config, etc.) |
| `ci` | CI/CD configuration changes |

### Scopes

Use the feature name as scope: `auth`, `study-timer`, `gym-tracker`, `home`, `theme`, `router`, `analytics`, etc.

### Examples

```
feat(study-timer): add subject tagging to study sessions
fix(auth): handle token refresh on session expiry
docs(readme): update getting started instructions
style(theme): adjust Neo Brutalism shadow offset values
refactor(gym-tracker): extract workout repository interface
test(analytics): add unit tests for streak calculation
chore(deps): bump supabase_flutter to 2.10.0
```

---

## 🌿 Branch Naming Conventions

```
<type>/<short-description>
```

### Examples

```
feat/google-oauth
fix/timer-reset-bug
docs/update-readme
refactor/study-timer-repository
test/gym-tracker-unit-tests
chore/upgrade-flutter-sdk
```

---

## 📬 Questions?

If you have any questions about contributing, feel free to open a [Discussion](https://github.com/yourusername/preptracker/discussions) or reach out!

---

Thank you for helping make PrepTracker better! 🚀
