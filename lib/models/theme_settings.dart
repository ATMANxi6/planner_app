import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

part 'theme_settings.g.dart';

/// Theme mode preference
@HiveType(typeId: 15)
enum ThemeMode {
  @HiveField(0)
  light,
  @HiveField(1)
  dark,
  @HiveField(2)
  system,
}

/// Font size preference
@HiveType(typeId: 16)
enum FontSizePreference {
  @HiveField(0)
  small,
  @HiveField(1)
  medium,
  @HiveField(2)
  large,
}

/// User theme preferences stored in Hive
@HiveType(typeId: 17)
class ThemeSettings extends HiveObject {
  @HiveField(0)
  ThemeMode themeMode;

  @HiveField(1)
  int seedColorValue; // Color.value stored as int

  @HiveField(2)
  FontSizePreference fontSizePreference;

  ThemeSettings({
    required this.themeMode,
    required this.seedColorValue,
    required this.fontSizePreference,
  });

  /// Default theme settings
  factory ThemeSettings.defaultSettings() {
    return ThemeSettings(
      themeMode: ThemeMode.system,
      seedColorValue: Colors.deepPurple.toARGB32(),
      fontSizePreference: FontSizePreference.medium,
    );
  }

  /// Get Color object from stored value
  Color get seedColor => Color(seedColorValue);

  /// Set Color object by storing its value
  set seedColor(Color color) {
    seedColorValue = color.toARGB32();
  }

  /// Get text scale factor based on font size preference
  double get textScaleFactor {
    return switch (fontSizePreference) {
      FontSizePreference.small => 0.9,
      FontSizePreference.medium => 1.0,
      FontSizePreference.large => 1.15,
    };
  }

  ThemeSettings copyWith({
    ThemeMode? themeMode,
    int? seedColorValue,
    FontSizePreference? fontSizePreference,
  }) {
    return ThemeSettings(
      themeMode: themeMode ?? this.themeMode,
      seedColorValue: seedColorValue ?? this.seedColorValue,
      fontSizePreference: fontSizePreference ?? this.fontSizePreference,
    );
  }
}
