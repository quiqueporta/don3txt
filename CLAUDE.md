# don3txt

Gestor de tareas basado en el formato estándar abierto [todo.txt](http://todotxt.org/), construido con Flutter para Android.

## Stack tecnológico

- **Flutter** (Dart) con Material Design 3
- **Provider** para state management (`ChangeNotifier`)
- **path_provider** + **file_picker** para acceso al sistema de ficheros
- **shared_preferences** para persistencia de ajustes
- **google_fonts** (Inter)

## Arquitectura

Clean Architecture con separación en capas:

- `lib/domain/` — Value Objects (`TodoItem`, `AppThemeMode`, `StartOfWeek`), Agregados (`TodoFile`), funciones puras de parsing (`todo_parser.dart`), lógica de recurrencia (`recurrence.dart`)
- `lib/infrastructure/` — Repositorios (`FileTodoRepository`, `SharedPreferencesSettingsRepository`). Contiene también las interfaces de dominio (son solo abstracciones, no implementaciones concretas)
- `lib/application/` — Estado reactivo (`TodoListNotifier`, `SettingsNotifier` con `ChangeNotifier`)
- `lib/ui/` — Tema, pantallas (`TaskListScreen`, `SettingsScreen`) y widgets (`SidebarDrawer`, `TaskTile`, `AddTaskField`)

## Funcionalidades principales

- Gestión CRUD de tareas con formato todo.txt estándar
- Prioridades `(A)`-`(Z)`, proyectos (`+nombre`), contextos (`@nombre`), metadata (`clave:valor`)
- Fechas de vencimiento (`due:`) con selector de calendario
- Fechas de inicio/threshold (`t:`) con selector de calendario — oculta tareas con `t:` futuro de todas las vistas excepto Recurring
- Tareas recurrentes (`rec:`) con modo flexible y estricto (`+`). Estricto requiere `t:` para calcular desde fecha original; sin `t:` cae a flexible
- Vistas: Hoy (por defecto, con badges de atrasadas/hoy), Inbox, Upcoming (tareas de mañana a N días, periodo configurable), filtro por Proyecto (colapsable), filtro por Contexto (colapsable), Recurring (tareas con `rec:`, sin filtro threshold), Completed (tareas completadas, ordenadas por fecha de completitud descendente)
- Eliminación de tareas desde menú de tres puntos con Snackbar y Undo
- Snackbar con Undo al completar una tarea
- Búsqueda por texto libre en la descripción de las tareas, disponible en todas las vistas
- Selección de fichero todo.txt desde cualquier ubicación del dispositivo
- Tema claro/oscuro/sistema, primer día de la semana configurable, periodo upcoming configurable

## Comandos

```bash
# Dependencias
flutter pub get

# Tests
flutter test

# Ejecutar
flutter run

# Compilar APK
flutter build apk --release
```

## Tests

Organizados por capa en `test/`:

- `test/domain/` — Tests unitarios de modelos, parsing y recurrencia
- `test/infrastructure/` — Tests de integración del repositorio (directorio temporal)
- `test/application/` — Tests del notifier con `InMemoryTodoRepository`
- `test/ui/` — Tests de widgets

## Formato todo.txt

```
(A) 2024-01-15 Llamar a mamá +Familia @teléfono due:2024-01-20
x 2024-01-16 2024-01-15 Revisar PR +Proyecto @github
Pagar alquiler due:2024-02-01 rec:1m
Revisar informe due:2024-03-01 t:2024-02-25 rec:+1m
```

Componentes: completitud (`x`), prioridad (`(A)`-`(Z)`), fechas (`YYYY-MM-DD`), proyectos (`+nombre`), contextos (`@nombre`), metadata (`clave:valor`), recurrencia (`rec:[+]Nu`), fecha de inicio (`t:YYYY-MM-DD`).

## Proceso de release

Cuando sea conveniente subir versión, seguir estos pasos en orden:

1. **Actualizar versión** en estos dos ficheros:
   - `pubspec.yaml` → campo `version:`
   - `lib/ui/widgets/sidebar_drawer.dart` → campo `applicationVersion:`
2. **Actualizar `CHANGELOG.md`** — añadir nueva entrada al principio con fecha y cambios (secciones Added/Changed/Fixed según corresponda)
3. **Ejecutar tests** — `flutter test` y confirmar que todos pasan
4. **Commit** con mensaje `Bump version to X.Y.Z`
5. **Crear tag** — `git tag vX.Y.Z`
6. **Push** — `git push origin main && git push origin vX.Y.Z`
7. **Compilar APK** — `flutter build apk --release`
8. **Crear GitHub Release** — `gh release create vX.Y.Z build/app/outputs/flutter-apk/app-release.apk#don3txt-vX.Y.Z.apk --title "vX.Y.Z"` con las notas del changelog
