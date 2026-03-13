<p align="center">
  <img src="don3txt_logo.png" alt="don3txt" width="400">
</p>

<h1 align="center">don3txt</h1>

<p align="center">
  Gestor de tareas basado en <a href="http://todotxt.org/">todo.txt</a> para Android
  <br>
  <a href="https://quiqueporta.com/don3txt/">quiqueporta.com/don3txt</a>
</p>

---

Aplicación móvil para gestionar tareas basada en el formato [todo.txt](http://todotxt.org/), diseñada para usuarios que prefieren texto plano, control total de sus datos y flujos de trabajo simples.

## Funcionalidades

### Gestión de tareas

- **Crear tareas** con parsing automático de proyectos (`+nombre`), contextos (`@nombre`) y metadata (`clave:valor`)
- **Completar/descompletar** tareas con un toque. La fecha de completado se asigna automáticamente
- **Prioridades** de la `(A)` a la `(Z)` siguiendo el estándar todo.txt
- **Fechas de creación** asignadas automáticamente al crear una tarea
- **Fechas de vencimiento** (`due:YYYY-MM-DD`) con selector de calendario integrado
- **Fechas de inicio** (`t:YYYY-MM-DD`) con selector de calendario — las tareas con fecha de inicio futura se ocultan automáticamente de todas las vistas excepto Recurring

### Tareas recurrentes

- **Recurrencia flexible**: la próxima fecha se calcula desde la fecha de completado (ej: `rec:2w`)
- **Recurrencia estricta**: la próxima fecha se calcula desde la fecha de inicio (`t:`) original (ej: `rec:+2w`). Si no tiene `t:`, se comporta como recurrencia flexible
- Unidades soportadas: días (`d`), semanas (`w`), meses (`m`), años (`y`)
- Selector visual para configurar la recurrencia al crear la tarea
- Al completar una tarea recurrente, se crea automáticamente la siguiente ocurrencia con la nueva fecha

### Vistas y filtros

- **Inbox**: muestra todas las tareas pendientes
- **Hoy**: muestra tareas con vencimiento hoy o anterior (atrasadas), con badges de conteo en el sidebar
- **Mis Proyectos**: filtra por proyecto (`+nombre`), generados dinámicamente desde las tareas pendientes
- **Mis Contextos**: filtra por contexto (`@nombre`), generados dinámicamente desde las tareas pendientes
- **Recurring**: muestra todas las tareas recurrentes (con `rec:`), incluyendo las que tienen fecha de inicio futura

### Gestión de ficheros

- Trabaja con ficheros `todo.txt` en texto plano estándar
- **Seleccionar fichero** existente desde cualquier ubicación del dispositivo
- **Crear fichero** nuevo en una ubicación personalizada
- **Restaurar** al fichero por defecto en cualquier momento
- Compatible con herramientas de sincronización como **Syncthing**, **Dropbox**, etc.

### Ajustes

- **Tema**: Sistema (por defecto), Claro u Oscuro — Material Design 3
- **Primer día de la semana**: Lunes o Domingo (afecta al selector de fechas)
- **Ruta del fichero todo.txt**: configurable desde ajustes

## Formato todo.txt

La app sigue el [estándar todo.txt](http://todotxt.org/). Ejemplos:

```
Call Mom
(A) Call Mom
(A) 2011-03-02 Call Mom +Family @phone
x 2011-03-03 2011-03-01 Review PR +Project @github
Buy milk due:2024-01-15
Pay rent due:2024-02-01 rec:1m
Review report due:2024-03-01 t:2024-02-25 rec:+1m
```

| Componente | Formato | Ejemplo |
|---|---|---|
| Completitud | `x` al inicio | `x 2024-01-16 ...` |
| Prioridad | `(A)` a `(Z)` | `(A) Tarea urgente` |
| Fecha de creación | `YYYY-MM-DD` | `2024-01-15 Tarea` |
| Proyecto | `+nombre` | `+Familia` |
| Contexto | `@nombre` | `@teléfono` |
| Fecha de vencimiento | `due:YYYY-MM-DD` | `due:2024-01-20` |
| Fecha de inicio | `t:YYYY-MM-DD` | `t:2024-01-18` |
| Recurrencia | `rec:[+]Nu` | `rec:2w`, `rec:+1m` |
| Metadata genérica | `clave:valor` | `esfuerzo:alto` |

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
