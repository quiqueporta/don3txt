# don3txt

Task manager based on the open standard [todo.txt](http://todotxt.org/) format, built with Flutter for Android.

## Tech stack

- **Flutter** (Dart) with Material Design 3
- **Provider** for state management (`ChangeNotifier`)
- **path_provider** + **file_picker** for filesystem access
- **shared_preferences** for settings persistence
- **google_fonts** (Inter)

## Architecture

Clean Architecture with layer separation:

- `lib/domain/` — Value Objects (`TodoItem`, `AppThemeMode`, `StartOfWeek`), Aggregates (`TodoFile`), pure parsing functions (`todo_parser.dart`), recurrence logic (`recurrence.dart`)
- `lib/infrastructure/` — Repositories (`FileTodoRepository`, `SharedPreferencesSettingsRepository`). Also contains domain interfaces (abstractions only, no concrete implementations)
- `lib/application/` — Reactive state (`TodoListNotifier`, `SettingsNotifier` with `ChangeNotifier`)
- `lib/ui/` — Theme, screens (`TaskListScreen`, `SettingsScreen`) and widgets (`SidebarDrawer`, `TaskTile`, `AddTaskField`, `EditTaskField`, `TaskInputBar`, `TagPickerSheet`)

## Main features

- CRUD task management with standard todo.txt format
- Priorities `(A)`-`(Z)`, projects (`+name`), contexts (`@name`), metadata (`key:value`)
- Due dates (`due:`) with calendar picker
- Threshold dates (`t:`) with calendar picker — hides tasks with future `t:` from action views (Today, Inbox), but they remain visible in Upcoming and Recurring
- Recurring tasks (`rec:`) with flexible and strict (`+`) modes. Strict requires `t:` to calculate from original date; without `t:` falls back to flexible
- Visual project and context pickers: `@` and `+` buttons in the editor icon bar open a `ModalBottomSheet` (`TagPickerSheet`) with existing tags as selectable chips and a field to create new ones. Selected tags are shown as removable chips before saving. Compatible with manual typing: if the user types `@context` directly in the text, it merges without duplicates with those selected via UI
- Views: Today (default, with overdue/today badges), Inbox, Upcoming (tasks from tomorrow to N days, configurable period), filter by Project (collapsible), filter by Context (collapsible), Recurring (tasks with `rec:`, no threshold filter), Completed (completed tasks, sorted by completion date descending)
- Task deletion from three-dot menu with Snackbar and Undo
- Snackbar with Undo when completing a task
- Free-text search across task descriptions, available in all views
- Select todo.txt file from any location on the device
- Light/dark/system theme, configurable first day of the week, configurable upcoming period

## Commands

```bash
# Dependencies
flutter pub get

# Tests
flutter test

# Run
flutter run

# Build APK
flutter build apk --release
```

## Tests

Organized by layer in `test/`:

- `test/domain/` — Unit tests for models, parsing and recurrence
- `test/infrastructure/` — Integration tests for the repository (temporary directory)
- `test/application/` — Notifier tests with `InMemoryTodoRepository`
- `test/ui/` — Widget tests

## todo.txt format

```
(A) 2024-01-15 Call Mom +Family @phone due:2024-01-20
x 2024-01-16 2024-01-15 Review PR +Project @github
Pay rent due:2024-02-01 rec:1m
Review report due:2024-03-01 t:2024-02-25 rec:+1m
```

Components: completion (`x`), priority (`(A)`-`(Z)`), dates (`YYYY-MM-DD`), projects (`+name`), contexts (`@name`), metadata (`key:value`), recurrence (`rec:[+]Nu`), threshold date (`t:YYYY-MM-DD`).

## Release process

When it's time to bump the version, follow these steps in order:

1. **Update version** in these two files:
   - `pubspec.yaml` → `version:` field
   - `lib/ui/widgets/sidebar_drawer.dart` → `applicationVersion:` field
2. **Update `CHANGELOG.md`** — add a new entry at the top with date and changes (Added/Changed/Fixed sections as appropriate)
3. **Run tests** — `flutter test` and confirm all pass
4. **Commit** with message `Bump version to X.Y.Z`
5. **Create tag** — `git tag vX.Y.Z`
6. **Push** — `git push origin main && git push origin vX.Y.Z`
7. **Build APK** — `flutter build apk --release`
8. **Create GitHub Release** — `gh release create vX.Y.Z build/app/outputs/flutter-apk/app-release.apk#don3txt-vX.Y.Z.apk --title "vX.Y.Z"` with changelog notes
