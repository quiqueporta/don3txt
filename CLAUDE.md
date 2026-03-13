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
- Tareas recurrentes (`rec:`) con modo flexible y estricto (`+`)
- Vistas: Inbox, Hoy (con badges de atrasadas/hoy), filtro por Proyecto, filtro por Contexto
- Selección de fichero todo.txt desde cualquier ubicación del dispositivo
- Tema claro/oscuro/sistema, primer día de la semana configurable

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
```

Componentes: completitud (`x`), prioridad (`(A)`-`(Z)`), fechas (`YYYY-MM-DD`), proyectos (`+nombre`), contextos (`@nombre`), metadata (`clave:valor`), recurrencia (`rec:[+]Nu`).
