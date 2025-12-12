import 'package:flutter/material.dart';
import '../models/theme_settings.dart' as model;
import '../services/storage_service.dart';

/// Provider managing theme state and persistence
class ThemeProvider extends ChangeNotifier {
  final StorageService _storage;
  model.ThemeSettings _settings;

  ThemeProvider(this._storage)
      : _settings = model.ThemeSettings.defaultSettings() {
    _loadSettings();
  }

  model.ThemeSettings get settings => _settings;

  /// Load theme settings from Hive
  Future<void> _loadSettings() async {
    final box = _storage.themeSettingsBox;
    if (box.isEmpty) {
      // Create default settings
      _settings = model.ThemeSettings.defaultSettings();
      await box.put('theme', _settings);
    } else {
      _settings = box.get('theme') ?? model.ThemeSettings.defaultSettings();
    }
    notifyListeners();
  }

  /// Save settings to Hive and notify listeners
  Future<void> _saveSettings() async {
    await _storage.themeSettingsBox.put('theme', _settings);
    notifyListeners();
  }

  // Theme mode
  ThemeMode get themeMode {
    return switch (_settings.themeMode) {
      model.ThemeMode.light => ThemeMode.light,
      model.ThemeMode.dark => ThemeMode.dark,
      model.ThemeMode.system => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(model.ThemeMode mode) async {
    _settings.themeMode = mode;
    await _saveSettings();
  }

  // Seed color
  Color get seedColor => _settings.seedColor;

  Future<void> setSeedColor(Color color) async {
    _settings.seedColor = color;
    await _saveSettings();
  }

  // Font size
  model.FontSizePreference get fontSizePreference => _settings.fontSizePreference;

  double get textScaleFactor => _settings.textScaleFactor;

  Future<void> setFontSizePreference(model.FontSizePreference preference) async {
    _settings.fontSizePreference = preference;
    await _saveSettings();
  }

  /// Predefined color palette for user selection
  static const List<ColorOption> colorOptions = [
    ColorOption(name: 'Deep Purple', color: Colors.deepPurple),
    ColorOption(name: 'Blue', color: Colors.blue),
    ColorOption(name: 'Teal', color: Colors.teal),
    ColorOption(name: 'Green', color: Colors.green),
    ColorOption(name: 'Orange', color: Colors.orange),
    ColorOption(name: 'Pink', color: Colors.pink),
    ColorOption(name: 'Red', color: Colors.red),
    ColorOption(name: 'Indigo', color: Colors.indigo),
  ];
}

/// Color option for theme customization
class ColorOption {
  final String name;
  final Color color;

  const ColorOption({required this.name, required this.color});
}
