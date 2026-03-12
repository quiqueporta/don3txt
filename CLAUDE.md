# don3txt

Gestor de tareas basado en el formato estándar abierto [todo.txt](http://todotxt.org/), construido con Flutter para Android.

## Stack tecnológico

- **Flutter** (Dart) con Material Design 3
- **Provider** para state management (`ChangeNotifier`)
- **path_provider** para acceso al sistema de ficheros
- **google_fonts** (Inter)

## Arquitectura

Clean Architecture con separación en capas:

- `lib/domain/` — Value Objects (`TodoItem`), Agregados (`TodoFile`), funciones puras de parsing (`todo_parser.dart`)
- `lib/infrastructure/` — Repositorio de ficheros (`FileTodoRepository`). Contiene también las interfaces de dominio (son solo abstracciones, no implementaciones concretas)
- `lib/application/` — Estado reactivo (`TodoListNotifier` con `ChangeNotifier`)
- `lib/ui/` — Tema, pantallas y widgets

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

- `test/domain/` — Tests unitarios de modelos y parsing
- `test/infrastructure/` — Tests de integración del repositorio (directorio temporal)
- `test/application/` — Tests del notifier con `InMemoryTodoRepository`
- `test/ui/` — Tests de widgets

## Formato todo.txt

```
(A) 2024-01-15 Llamar a mamá +Familia @teléfono due:2024-01-20
x 2024-01-16 2024-01-15 Revisar PR +Proyecto @github
```

Componentes: completitud (`x`), prioridad (`(A)`-`(Z)`), fechas (`YYYY-MM-DD`), proyectos (`+nombre`), contextos (`@nombre`), metadata (`clave:valor`).
