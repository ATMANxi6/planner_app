// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'time_block.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TimeBlockAdapter extends TypeAdapter<TimeBlock> {
  @override
  final int typeId = 12;

  @override
  TimeBlock read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TimeBlock(
      id: fields[0] as String,
      title: fields[1] as String,
      startTime: fields[2] as DateTime,
      endTime: fields[3] as DateTime,
      colorValue: fields[4] as int,
      linkedTaskId: fields[5] as String?,
      linkedSubtaskId: fields[6] as String?,
      category: fields[7] as String?,
      description: fields[8] as String?,
      isCompleted: fields[9] as bool,
      createdAt: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, TimeBlock obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.startTime)
      ..writeByte(3)
      ..write(obj.endTime)
      ..writeByte(4)
      ..write(obj.colorValue)
      ..writeByte(5)
      ..write(obj.linkedTaskId)
      ..writeByte(6)
      ..write(obj.linkedSubtaskId)
      ..writeByte(7)
      ..write(obj.category)
      ..writeByte(8)
      ..write(obj.description)
      ..writeByte(9)
      ..write(obj.isCompleted)
      ..writeByte(10)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeBlockAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
