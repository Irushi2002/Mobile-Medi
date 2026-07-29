import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class SettingsProvider extends ChangeNotifier {
  static const _keyNotificationsEnabled = 'notifications_enabled';
  static const _keySoundEnabled = 'sound_enabled';

  bool _notificationsEnabled = true;
  bool _soundEnabled = true;

  bool get notificationsEnabled => _notificationsEnabled;
  bool get soundEnabled => _soundEnabled;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool(_keyNotificationsEnabled) ?? true;
    _soundEnabled = prefs.getBool(_keySoundEnabled) ?? true;
    notifyListeners();
  }

  /// Toggle master notification switch.
  /// When disabled, all pending notifications are cancelled.
  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, value);
    notifyListeners();

    if (!value) {
      await NotificationService().cancelAllNotifications();
    }
    // Re-scheduling when re-enabled is handled by MedicationProvider
    // (which listens to Firestore and re-schedules on data changes).
  }

  /// Toggle notification sound.
  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySoundEnabled, value);
    notifyListeners();
  }
}
