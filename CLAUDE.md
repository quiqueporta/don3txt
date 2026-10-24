# don3txt

Task manager based on the open standard [todo.txt](http://todotxt.org/) format, built with Flutter for Android and Linux.

## Tech stack

- **Flutter** (Dart) with Material Design 3
- **Provider** for state management (`ChangeNotifier`)
- **path_provider** + **file_picker** for filesystem access
- **shared_preferences** for settings persistence
- **google_fonts** (Inter)

## Architecture

Clean Architecture with layer separation:

- `lib/domain/` — Value Objects (`TodoItem`, `Tag`, `AppThemeMode`, `TextSize`, `StartOfWeek`), Aggregates (`TodoFile`), pure parsing functions (`todo_parser.dart`), recurrence logic (`recurrence.dart`)
- `lib/infrastructure/` — Repositories (`FileTodoRepository`, `SharedPreferencesSettingsRepository`) and platform services (`AndroidStoragePermission`, `UnrestrictedStoragePermission`). Also contains domain interfaces (abstractions only, no concrete implementations): `TodoRepository`, `SettingsRepository`, `StoragePermission`
- `lib/application/` — Reactive state (`TodoListNotifier`, `SettingsNotifier` with `ChangeNotifier`)
- `lib/ui/` — Theme, screens (`TaskListScreen`, `SettingsScreen`) and widgets (`SidebarDrawer`, `TaskTile`, `AddTaskField`, `EditTaskField`, `TaskInputBar`, `TagPickerSheet`)

## Main features

- CRUD task management with standard todo.txt format
- Priorities `(A)`-`(Z)`, projects (`+name`), contexts (`@name`), metadata (`key:value`)
- Due dates (`due:`) with calendar picker
- Threshold dates (`t:`) with calendar picker — marks tasks as "deferred until" a date. Tasks with future `t:` are hidden only from the action views Past and Today. They remain visible (with reduced opacity) in Inbox, Project, Context, Tag, and Recurring views. In Past, Today and Upcoming, `t:` acts as a fallback reference date when the task has no `due:`
- Recurring tasks (`rec:`) with flexible and strict (`+`) modes. Strict requires `t:` to calculate from original date; without `t:` falls back to flexible
- Visual project and context pickers: `@` and `+` buttons in the editor icon bar open a `ModalBottomSheet` (`TagPickerSheet`) with existing tags as selectable chips and a field to create new ones. Selected tags are shown as removable chips before saving. Compatible with manual typing: if the user types `@context` directly in the text, it merges without duplicates with those selected via UI
- Views: Today (default, tasks with reference date equal to today, grey badge), Past (tasks with reference date before today, red badge), Inbox, Upcoming (tasks from tomorrow to N days, configurable period), filter by Project (collapsible), filter by Context (collapsible), filter by Tag (collapsible), Recurring (tasks with `rec:`, no threshold filter), Completed (completed tasks, sorted by completion date descending). The reference date is `due:`, falling back to `t:` when there is no `due:`
- Free tags: any `key:value` metadata whose key the app does not give meaning to (`due`, `t`, `rec` are reserved), e.g. `waiting:quique` or `next:yes`. The task list shows them below each task with a label icon, next to projects and contexts; when editing, they appear in the text. The sidebar lists each key (all tasks with that key) and, when a key has several values, each value nested below it; the entry being shown is highlighted. A task added from a tag view gets that tag as a removable chip (from a key-only view, only when all its tasks share a single value, e.g. `next` → `next:yes`). Tasks with future `t:` stay visible with reduced opacity, as in Project and Context. The filter sheet offers the same tags as chips (`next`, `waiting`, `waiting:ana`…), matching tasks with any of the chosen tags
- Task deletion from three-dot menu with Snackbar and Undo
- Snackbar with Undo when completing a task
- Free-text search across task descriptions, available in all views
- Select todo.txt file from any location on the device
- Light/dark/system theme, configurable text size (small, normal, large, extra large; multiplies the system text scale), configurable upcoming period, configurable task sort order (multi-level chain), configurable priority colors (A–F)
- Multi-language UI: English, Spanish, French, Italian, Portuguese (selector in Settings with "System default" option)
- Safe to share the same `todo.txt` between devices through a sync tool: every operation rereads the file before changing it and identifies tasks by content (not position), saves are atomic (temporary file `.syncthing.don3txt-<name>.tmp` renamed over the original), the list reloads when the file changes on disk (`TodoRepository.changes`) and when the app returns to the foreground, and the user is warned when a task or the raw file was changed on another device
- Linux desktop build distributed as AppImage and tarball (`linux/packaging/`). The AppImage `AppRun` asks once (with `zenity`) whether to add a menu entry and supports `--remove-desktop-entry`

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

# Install on a connected device keeping the app data (never use `flutter install`: it uninstalls first)
adb install -r build/app/outputs/flutter-apk/app-release.apk

# Build Linux and package AppImage + tarball into build/linux/dist/
flutter build linux --release
linux/packaging/package.sh X.Y.Z
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

Components: completion (`x`), priority (`(A)`-`(Z)`), dates (`YYYY-MM-DD`), projects (`+name`), contexts (`@name`), metadata (`key:value`, where the key must be a name starting with a letter, so times like `10:30` stay in the description), recurrence (`rec:[+]Nu`), threshold date (`t:YYYY-MM-DD`).

## Release process

When it's time to bump the version, follow these steps in order:

1. **Update version** in these files:
   - `pubspec.yaml` → `version:` field
   - `lib/ui/widgets/sidebar_drawer.dart` → `applicationVersion:` field
   - `docs/index.html` → `"softwareVersion"` field in the JSON-LD block
   - `docs/index.html` → `<p class="cta-version">Current version: vX.Y.Z</p>`
2. **Update `CHANGELOG.md`** — add a new entry at the top with date and changes (Added/Changed/Fixed sections as appropriate)
3. **Run tests** — `flutter test` and confirm all pass
4. **Commit** with message `Bump version to X.Y.Z`
5. **Create tag** — `git tag vX.Y.Z`
6. **Push** — `git push origin main && git push origin vX.Y.Z`
7. **Build APK** — `flutter build apk --release && cp build/app/outputs/flutter-apk/app-release.apk build/don3txt-vX.Y.Z.apk`
8. **Create GitHub Release** — `gh release create vX.Y.Z build/don3txt-vX.Y.Z.apk --title "vX.Y.Z"` with changelog notes
9. **Check the Linux build** — publishing the release triggers `.github/workflows/release-linux.yml`, which attaches `don3txt-vX.Y.Z-x86_64.AppImage` and `don3txt-vX.Y.Z-linux-x86_64.tar.gz` to it. Wait for it with `gh run watch` and confirm both files are in the release
