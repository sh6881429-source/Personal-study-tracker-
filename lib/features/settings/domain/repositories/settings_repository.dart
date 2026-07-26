import 'package:prep_tracker/features/settings/data/models/settings_model.dart';

/// ── User Settings Repository Contract ──
abstract interface class SettingsRepository {
  /// Stream of user app settings.
  Stream<UserSettingsModel?> watchSettings(String userId);

  /// Fetch user settings row from database.
  Future<UserSettingsModel?> getSettings(String userId);

  /// Create or update user settings parameters.
  Future<UserSettingsModel> saveSettings(UserSettingsModel settings);
}
