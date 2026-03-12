# don3txt

Aplicación móvil para gestionar tareas basada en el formato [todo.txt](http://todotxt.org/), diseñada para usuarios que prefieren texto plano, control total de sus datos y flujos de trabajo simples.

Estética inspirada en Things 3: limpia, minimalista, fondo blanco, azul como accent.

## Requisitos

- [Flutter](https://docs.flutter.dev/get-started/install) >= 3.9.2
- Android SDK (solo Android por ahora)

## Instalación de dependencias

```bash
flutter pub get
```

## Tests

```bash
flutter test
```

## Compilar

### Debug (desarrollo)

```bash
flutter build apk --debug
```

El APK se genera en `build/app/outputs/flutter-apk/app-debug.apk`.

### Release

```bash
flutter build apk --release
```

El APK se genera en `build/app/outputs/flutter-apk/app-release.apk`.

## Ejecutar en emulador o dispositivo

```bash
flutter run
```

## Instalar en dispositivo conectado

```bash
# Instalar el APK de release
flutter install
```

O directamente con `adb`:

```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

## Estructura del proyecto

```
lib/
├── main.dart
├── domain/              # Value Objects, Aggregates, funciones puras
├── infrastructure/      # Repositorio: lectura/escritura de fichero
├── application/         # Estado reactivo (ChangeNotifier)
└── ui/                  # Tema, pantallas y widgets
```

## Formato todo.txt

La app trabaja con un fichero `todo.txt` en texto plano almacenado en el directorio de documentos de la app. Ejemplos de formato:

```
Call Mom
(A) Call Mom
(A) 2011-03-02 Call Mom +Family @phone
x 2011-03-03 2011-03-01 Review PR +Project @github
Buy milk due:2024-01-15
```

Más info sobre el formato: http://todotxt.org/
