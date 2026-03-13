# Changelog

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
