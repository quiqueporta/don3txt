import 'package:don3txt/domain/start_of_week.dart';

abstract class SettingsRepository {
  Future<StartOfWeek> loadStartOfWeek();
  Future<void> saveStartOfWeek(StartOfWeek value);
}
