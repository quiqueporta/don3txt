import 'package:shared_preferences/shared_preferences.dart';
import 'package:don3txt/domain/start_of_week.dart';
import 'package:don3txt/infrastructure/settings_repository.dart';

class SharedPreferencesSettingsRepository implements SettingsRepository {
  static const _key = 'start_of_week';

  @override
  Future<StartOfWeek> loadStartOfWeek() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);

    if (value == 'sunday') return StartOfWeek.sunday;

    return StartOfWeek.monday;
  }

  @override
  Future<void> saveStartOfWeek(StartOfWeek value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_key, value.name);
  }
}
