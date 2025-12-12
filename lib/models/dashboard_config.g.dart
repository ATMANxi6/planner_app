// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_config.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DashboardConfigAdapter extends TypeAdapter<DashboardConfig> {
  @override
  final int typeId = 14;

  @override
  DashboardConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DashboardConfig(
      timeSlotInterval: fields[0] as TimeSlotInterval,
      dayStartHour: fields[1] as int,
      dayEndHour: fields[2] as int,
      showDailyTasksWidget: fields[4] as bool,
      showStatsWidget: fields[5] as bool,
      showStreaksWidget: fields[6] as bool,
      showProjectsWidget: fields[7] as bool,
      showDeadlinesWidget: fields[8] as bool,
      showGoalProgressWidget: fields[15] as bool,
      showFocusModeWidget: fields[16] as bool,
      showQuickWinsWidget: fields[17] as bool,
      showCanvasProgressWidget: fields[18] as bool,
      defaultToWeeklyView: fields[9] as bool,
      defaultToCanvasView: fields[19] as bool,
      createdAt: fields[10] as DateTime?,
      updatedAt: fields[11] as DateTime?,
      widgetOrder: (fields[12] as List?)?.cast<String>(),
      hourHeight: fields[13] as double,
      snapIntervalMinutes: fields[14] as int,
    );
  }

  @override
  void write(BinaryWriter writer, DashboardConfig obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.timeSlotInterval)
      ..writeByte(1)
      ..write(obj.dayStartHour)
      ..writeByte(2)
      ..write(obj.dayEndHour)
      ..writeByte(4)
      ..write(obj.showDailyTasksWidget)
      ..writeByte(5)
      ..write(obj.showStatsWidget)
      ..writeByte(6)
      ..write(obj.showStreaksWidget)
      ..writeByte(7)
      ..write(obj.showProjectsWidget)
      ..writeByte(8)
      ..write(obj.showDeadlinesWidget)
      ..writeByte(9)
      ..write(obj.defaultToWeeklyView)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.updatedAt)
      ..writeByte(12)
      ..write(obj.widgetOrder)
      ..writeByte(13)
      ..write(obj.hourHeight)
      ..writeByte(14)
      ..write(obj.snapIntervalMinutes)
      ..writeByte(15)
      ..write(obj.showGoalProgressWidget)
      ..writeByte(16)
      ..write(obj.showFocusModeWidget)
      ..writeByte(17)
      ..write(obj.showQuickWinsWidget)
      ..writeByte(18)
      ..write(obj.showCanvasProgressWidget)
      ..writeByte(19)
      ..write(obj.defaultToCanvasView);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TimeSlotIntervalAdapter extends TypeAdapter<TimeSlotInterval> {
  @override
  final int typeId = 13;

  @override
  TimeSlotInterval read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TimeSlotInterval.fifteenMinutes;
      case 1:
        return TimeSlotInterval.thirtyMinutes;
      case 2:
        return TimeSlotInterval.sixtyMinutes;
      default:
        return TimeSlotInterval.fifteenMinutes;
    }
  }

  @override
  void write(BinaryWriter writer, TimeSlotInterval obj) {
    switch (obj) {
      case TimeSlotInterval.fifteenMinutes:
        writer.writeByte(0);
        break;
      case TimeSlotInterval.thirtyMinutes:
        writer.writeByte(1);
        break;
      case TimeSlotInterval.sixtyMinutes:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeSlotIntervalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
