
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for the raw SharedPreferences instance.
/// Must be overridden in main.dart.
final sharedPreferencesInstanceProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences not initialized');
});

/// Service to handle app preferences
class PreferencesService {
  final SharedPreferences _prefs;
  static const _kDisguiseAppKey = 'disguise_app_enabled';

  PreferencesService(this._prefs);

  bool get isDisguiseEnabled => _prefs.getBool(_kDisguiseAppKey) ?? false;

  Future<void> setDisguiseEnabled(bool value) async {
    await _prefs.setBool(_kDisguiseAppKey, value);
  }
}

/// Provider for the PreferencesService
final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  final prefs = ref.watch(sharedPreferencesInstanceProvider);
  return PreferencesService(prefs);
});

/// Notifier to watch and toggle the disguise setting
class DisguiseSettingsNotifier extends StateNotifier<bool> {
  final PreferencesService _service;

  DisguiseSettingsNotifier(this._service) : super(_service.isDisguiseEnabled);

  Future<void> toggle(bool value) async {
    await _service.setDisguiseEnabled(value);
    state = value;
  }
}

/// Provider exposing the current disguise state (reactive)
final disguiseSettingsProvider = StateNotifierProvider<DisguiseSettingsNotifier, bool>((ref) {
  final service = ref.watch(preferencesServiceProvider);
  return DisguiseSettingsNotifier(service);
});