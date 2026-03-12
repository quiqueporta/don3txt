import 'package:flutter_test/flutter_test.dart';
import 'package:don3txt/domain/start_of_week.dart';
import 'package:don3txt/infrastructure/settings_repository.dart';
import 'package:don3txt/application/settings_notifier.dart';

class InMemorySettingsRepository implements SettingsRepository {
  StartOfWeek _stored = StartOfWeek.monday;

  InMemorySettingsRepository([StartOfWeek? initial]) {
    if (initial != null) _stored = initial;
  }

  @override
  Future<StartOfWeek> loadStartOfWeek() async => _stored;

  @override
  Future<void> saveStartOfWeek(StartOfWeek value) async {
    _stored = value;
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
      repository = InMemorySettingsRepository(StartOfWeek.sunday);
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
  });
}
