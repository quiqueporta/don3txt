# Changelog

## [1.11.0] - 2026-06-01

### Changed

- Tasks with a future threshold date (`t:`) now appear in Inbox, project and context views with reduced opacity, instead of being hidden until the threshold date is reached. Today and overdue counter still filter them out so action views stay focused on what is actionable now
- Upcoming view now uses `t:` as a fallback reference date when a task has no `due:`, so deferred tasks become visible as their threshold approaches

## [1.10.0] - 2026-05-23

### Added

- Configurable task ordering in Settings. Build a multi-level sort chain from priority, due date, threshold date and creation date, with drag-to-reorder and add/remove of criteria

### Fixed

- Filter bottom sheet was not scrollable, hiding contexts and priorities when many projects filled the available height
- Recurrent tasks with only a threshold date (`t:`) and no due date could not be marked as completed
- Switching the todo.txt file location from Settings now jumps to Inbox and pops back to the list so the newly loaded tasks are visible immediately

## [1.9.1] - 2026-05-04

### Changed

- New app launcher icon on Android with adaptive icon support
- New favicon set on the documentation site (ico, svg, apple-touch-icon and web app manifest)

## [1.9.0] - 2026-04-24

### Added

- The "+" button pre-fills the due date with today when you are in the Today view
- The "+" button pre-fills the project or context tag when you are viewing a specific project or context
- Configurable priority colors (A-F) in Settings with a red-to-green default palette, applied to priority chips in the task list, editor and priority picker

## [1.8.1] - 2026-04-19

### Fixed

- Date picker always showed labels in Spanish regardless of the selected language. It now inherits the app locale and shows the date UI in the language you chose

### Removed

- "First day of the week" setting. The date picker now follows the locale convention (Monday for Spanish, French, Italian, Portuguese; Sunday for English)

## [1.8.0] - 2026-04-19

### Added

- Multi-language support with translations for Spanish, English, French, Italian and Portuguese
- Language selector in Settings to switch UI language at runtime (with "System default" option that follows the device language)

## [1.7.1] - 2026-03-24

### Fixed

- Upcoming view now shows tasks with future threshold dates when due date is in range, matching standard behavior of apps like Todoist

## [1.7.0] - 2026-03-16

### Added

- Pull-to-refresh to reload tasks from disk by swiping down
- Archive completed tasks to `done.txt` in the same directory as the active `todo.txt`
- Upcoming period indicator in sidebar (e.g. "Upcoming · 7d")

### Fixed

- setState called during build when syncing upcoming days in the sidebar

## [1.6.1] - 2026-03-15

### Fixed

- Tag picker text field hidden behind keyboard when creating new projects or contexts

## [1.6.0] - 2026-03-15

### Added

- Visual project and context tag pickers in task editor with `@` and `+` buttons
- TagPickerSheet with selectable chips for existing tags and field to create new ones
- Selected tags shown as removable chips before saving, compatible with manual typing

### Changed

- Redesigned landing page with mobile-first CSS, scroll spy and fade-in animations

## [1.5.0] - 2026-03-14

### Fixed

- File picker was copying files to app cache instead of working on the original
- App could not access the selected file after restart due to missing storage permission

### Changed

- Unified file selection into a single "select folder" flow using the real directory path

## [1.4.0] - 2026-03-14

### Added

- Delete task with undo support via three-dot menu on each task

## [1.3.0] - 2026-03-14

### Added

- Completed tasks view accessible from the sidebar
- Completion snackbar with undo button when completing a task
- Dividers between tasks in list views
- Collapsible Projects and Contexts sections in the sidebar

### Changed

- Default view changed from Inbox to Today

## [1.2.0] - 2026-03-13

### Added

- Free-text search across tasks in any view, accessible from the AppBar search icon

## [1.1.1] - 2026-03-13

### Changed

- Update file_picker 8.3.7 → 10.3.10
- Update google_fonts 6.3.3 → 8.0.2
- Update flutter_lints 5.0.0 → 6.0.0

## [1.1.0] - 2026-03-13

### Added

- About dialog with author, version, repository link and license information
- Task ordering with priority selector and priority display in task list
- Filtering by project, context and priority in Inbox, Today and Upcoming views

### Fixed

- Bottom padding in task list to prevent last item from being cut off

## [1.0.0] - 2025-12-22

### Added

- Upcoming view with configurable days setting
- Task editing with bottom sheet UI
- Debug screen to edit todo.txt as raw text
- Threshold date (`t:`) support with calendar picker
- Recurring tasks section in sidebar (shows all tasks with `rec:`, unfiltered by threshold)
- Strict recurrence mode (`rec:+`) calculates from original date using `t:`
- Recurrence picker UI for creating recurring tasks
- My Contexts section in sidebar with context filter
- My Projects section in sidebar with project filter
- Overdue tasks shown in Today view with sidebar badges
- Due date display with calendar icon in task list
- Colored icons for project and context tags in task list
- Theme selection (system, light, dark) in settings
- File picker to select external todo.txt file
- Colored icons in sidebar filters
- Configurable first day of week in DatePicker
- GitHub Actions workflow for tests with badge in README

### Fixed

- URLs being stripped from task description

### Initial features
- Full todo.txt format support with CRUD operations
- Priorities `(A)`-`(Z)`, projects (`+name`), contexts (`@name`), metadata (`key:value`)
- Due dates (`due:`) with calendar selector
- Views: Inbox, Today, Upcoming, Project filter, Context filter, Recurring
- Light/dark/system theme
- Configurable upcoming period
