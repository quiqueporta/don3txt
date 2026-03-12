import 'package:flutter_test/flutter_test.dart';
import 'package:don3txt/domain/start_of_week.dart';
import 'package:don3txt/infrastructure/settings_repository.dart';
import 'package:don3txt/application/settings_notifier.dart';

class InMemorySettingsRepository implements SettingsRepository {
  StartOfWeek _stored = StartOfWeek.monday;
  String? _todoFilePath;

  InMemorySettingsRepository({StartOfWeek? startOfWeek, String? todoFilePath}) {
    if (startOfWeek != null) _stored = startOfWeek;
    _todoFilePath = todoFilePath;
  }

  @override
  Future<StartOfWeek> loadStartOfWeek() async => _stored;

  @override
  Future<void> saveStartOfWeek(StartOfWeek value) async {
    _stored = value;
  }

  @override
  Future<String?> loadTodoFilePath() async => _todoFilePath;

  @override
  Future<void> saveTodoFilePath(String? path) async {
    _todoFilePath = path;
  }
}

void main() {
  late InMemorySettingsRepository repository;
  late SettingsNotifier notifier;

  setUp(() {
    repository = InMemorySettingsRepository();
    notifier = SettingsNotifier(repository);
  });

  group('SettingsNotifier', () {
    test('defaults to monday', () {
      expect(notifier.startOfWeek, StartOfWeek.monday);
    });

    test('load reads from repository', () async {
      repository = InMemorySettingsRepository(startOfWeek: StartOfWeek.sunday);
      notifier = SettingsNotifier(repository);

      await notifier.load();

      expect(notifier.startOfWeek, StartOfWeek.sunday);
    });

    test('setStartOfWeek updates value and persists', () async {
      await notifier.setStartOfWeek(StartOfWeek.sunday);

      expect(notifier.startOfWeek, StartOfWeek.sunday);

      final persisted = await repository.loadStartOfWeek();
      expect(persisted, StartOfWeek.sunday);
    });

    test('notifies listeners on load', () async {
      var notified = false;
      notifier.addListener(() => notified = true);

      await notifier.load();

      expect(notified, true);
    });

    test('notifies listeners on setStartOfWeek', () async {
      var notified = false;
      notifier.addListener(() => notified = true);

      await notifier.setStartOfWeek(StartOfWeek.sunday);

      expect(notified, true);
    });

    test('todoFilePath defaults to null', () {
      expect(notifier.todoFilePath, isNull);
    });

    test('load reads todoFilePath from repository', () async {
      repository = InMemorySettingsRepository(todoFilePath: '/storage/todo.txt');
      notifier = SettingsNotifier(repository);

      await notifier.load();

      expect(notifier.todoFilePath, '/storage/todo.txt');
    });

    test('setTodoFilePath updates and persists', () async {
      await notifier.setTodoFilePath('/storage/todo.txt');

      expect(notifier.todoFilePath, '/storage/todo.txt');

      final persisted = await repository.loadTodoFilePath();
      expect(persisted, '/storage/todo.txt');
    });

    test('setTodoFilePath notifies listeners', () async {
      var notified = false;
      notifier.addListener(() => notified = true);

      await notifier.setTodoFilePath('/storage/todo.txt');

      expect(notified, true);
    });
  });
}
