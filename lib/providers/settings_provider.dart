// lib/providers/settings_provider.dart
// Manages all user preferences: theme, font scale, display name, defaults.
// Persisted locally via LocalStorageService (shared_preferences).

import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';

class SettingsProvider extends ChangeNotifier {
  late String _themeMode;       // 'dark' | 'light' | 'auto'
  late double _fontScale;       // 0.8 – 1.4
  late String _defaultCategory;
  late String _defaultCuisine;
  late String? _displayName;

  bool _initialized = false;

  bool get initialized => _initialized;
  String get themeMode => _themeMode;
  double get fontScale => _fontScale;
  String get defaultCategory => _defaultCategory;
  String get defaultCuisine => _defaultCuisine;
  String? get displayName => _displayName;

  ThemeMode get flutterThemeMode => switch (_themeMode) {
        'light' => ThemeMode.light,
        'auto'  => ThemeMode.system,
        _       => ThemeMode.dark,
      };

  Future<void> initialize() async {
    if (_initialized) return;
    await LocalStorageService.instance.init();
    _themeMode       = LocalStorageService.instance.getThemeMode();
    _fontScale       = LocalStorageService.instance.getFontScale();
    _defaultCategory = LocalStorageService.instance.getDefaultCategory();
    _defaultCuisine  = LocalStorageService.instance.getDefaultCuisine();
    _displayName     = LocalStorageService.instance.getDisplayName();
    _initialized = true;
    notifyListeners();
  }

  Future<void> setThemeMode(String mode) async {
    _themeMode = mode;
    await LocalStorageService.instance.setThemeMode(mode);
    notifyListeners();
  }

  Future<void> setFontScale(double v) async {
    _fontScale = v.clamp(0.8, 1.4);
    await LocalStorageService.instance.setFontScale(_fontScale);
    notifyListeners();
  }

  Future<void> setDefaultCategory(String v) async {
    _defaultCategory = v;
    await LocalStorageService.instance.setDefaultCategory(v);
    notifyListeners();
  }

  Future<void> setDefaultCuisine(String v) async {
    _defaultCuisine = v;
    await LocalStorageService.instance.setDefaultCuisine(v);
    notifyListeners();
  }

  Future<void> setDisplayName(String v) async {
    _displayName = v.trim().isEmpty ? null : v.trim();
    if (_displayName != null) {
      await LocalStorageService.instance.setDisplayName(_displayName!);
    }
    notifyListeners();
  }
}
