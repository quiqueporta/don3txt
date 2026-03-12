import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:don3txt/domain/start_of_week.dart';
import 'package:don3txt/infrastructure/shared_preferences_settings_repository.dart';

void main() {
  group('SharedPreferencesSettingsRepository', () {
    late SharedPreferencesSettingsRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repository = SharedPreferencesSettingsRepository();
    });

    test('loadStartOfWeek returns monday by default', () async {
      final result = await repository.loadStartOfWeek();

      expect(result, StartOfWeek.monday);
    });

    test('saveStartOfWeek persists sunday', () async {
      await repository.saveStartOfWeek(StartOfWeek.sunday);

      final result = await repository.loadStartOfWeek();

      expect(result, StartOfWeek.sunday);
    });

    test('saveStartOfWeek persists monday', () async {
      await repository.saveStartOfWeek(StartOfWeek.sunday);
      await repository.saveStartOfWeek(StartOfWeek.monday);

      final result = await repository.loadStartOfWeek();

      expect(result, StartOfWeek.monday);
    });

    test('loadTodoFilePath returns null by default', () async {
      final result = await repository.loadTodoFilePath();

      expect(result, isNull);
    });

    test('saveTodoFilePath persists path', () async {
      await repository.saveTodoFilePath('/storage/todo.txt');

      final result = await repository.loadTodoFilePath();

      expect(result, '/storage/todo.txt');
    });

    test('saveTodoFilePath with null clears path', () async {
      await repository.saveTodoFilePath('/storage/todo.txt');
      await repository.saveTodoFilePath(null);

      final result = await repository.loadTodoFilePath();

      expect(result, isNull);
    });
  });
}
