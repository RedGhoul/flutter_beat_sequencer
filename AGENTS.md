# Repository Guidelines

## Project Structure & Module Organization
- `lib/` holds all Dart source. Entry point is `lib/main.dart`, UI in `lib/pages/` and `lib/widgets/`, services in `lib/services/`.
- `assets/` contains bundled audio samples (`assets/sounds/*.wav`), referenced from `pubspec.yaml`.
- `test/` contains Flutter tests (currently a placeholder in `test/widget_test.dart`).
- Platform folders: `android/`, `ios/`, `macos/`, `web/` for native integration.
- `docs/` contains built web artifacts for hosting demos.

## Build, Test, and Development Commands
- `flutter pub get` fetches dependencies.
- `flutter run -d <device-id>` launches the app on a connected device or emulator.
- `flutter analyze` runs static analysis (uses `extra_pedantic` lints).
- `flutter format lib/ test/` formats Dart code with standard style.
- `flutter test` runs unit/widget tests.
- `flutter build apk --release` or `flutter build ios --release` produces release builds.

## Coding Style & Naming Conventions
- Use Dart formatter defaults (2-space indentation, trailing commas for layout).
- Files are `snake_case.dart`, classes `PascalCase`, members `camelCase`, privates `_leadingUnderscore`.
- Prefer `const` constructors and keep widgets decomposed; see patterns in `lib/pages/` and `lib/widgets/`.

## Testing Guidelines
- Framework: `flutter_test`. Tests live under `test/` and follow `*_test.dart` naming.
- Current coverage is minimal; add focused unit tests for new logic and keep widget tests lightweight.
- Run `flutter test` before submitting changes.

## Commit & Pull Request Guidelines
- Commit messages follow conventional commits (e.g., `feat:`, `fix:`, `docs:`), per recent history.
- Branches may use the `claude/<description>-<session-id>` format when working with AI tooling.
- PRs should include a concise summary, test results (commands + outcomes), and screenshots for UI changes.

## Agent-Specific Notes
- Review `CLAUDE.md` and `APP_GUIDE.md` for architecture and workflow details before large changes.
