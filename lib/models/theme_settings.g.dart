// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ThemeSettingsAdapter extends TypeAdapter<ThemeSettings> {
  @override
  final int typeId = 17;

  @override
  ThemeSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ThemeSettings(
      themeMode: fields[0] as ThemeMode,
      seedColorValue: fields[1] as int,
      fontSizePreference: fields[2] as FontSizePreference,
    );
  }

  @override
  void write(BinaryWriter writer, ThemeSettings obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.themeMode)
      ..writeByte(1)
      ..write(obj.seedColorValue)
      ..writeByte(2)
      ..write(obj.fontSizePreference);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ThemeModeAdapter extends TypeAdapter<ThemeMode> {
  @override
  final int typeId = 15;

  @override
  ThemeMode read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ThemeMode.light;
      case 1:
        return ThemeMode.dark;
      case 2:
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }

  @override
  void write(BinaryWriter writer, ThemeMode obj) {
    switch (obj) {
      case ThemeMode.light:
        writer.writeByte(0);
        break;
      case ThemeMode.dark:
        writer.writeByte(1);
        break;
      case ThemeMode.system:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeModeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FontSizePreferenceAdapter extends TypeAdapter<FontSizePreference> {
  @override
  final int typeId = 16;

  @override
  FontSizePreference read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return FontSizePreference.small;
      case 1:
        return FontSizePreference.medium;
      case 2:
        return FontSizePreference.large;
      default:
        return FontSizePreference.small;
    }
  }

  @override
  void write(BinaryWriter writer, FontSizePreference obj) {
    switch (obj) {
      case FontSizePreference.small:
        writer.writeByte(0);
        break;
      case FontSizePreference.medium:
        writer.writeByte(1);
        break;
      case FontSizePreference.large:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FontSizePreferenceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
