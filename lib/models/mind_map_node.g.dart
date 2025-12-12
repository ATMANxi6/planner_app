// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mind_map_node.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MindMapNodeAdapter extends TypeAdapter<MindMapNode> {
  @override
  final int typeId = 2;

  @override
  MindMapNode read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MindMapNode(
      id: fields[0] as String,
      title: fields[1] as String,
      x: fields[2] as double,
      y: fields[3] as double,
      connections: (fields[4] as List).cast<String>(),
      color: fields[5] as int,
      linkedTaskId: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MindMapNode obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.x)
      ..writeByte(3)
      ..write(obj.y)
      ..writeByte(4)
      ..write(obj.connections)
      ..writeByte(5)
      ..write(obj.color)
      ..writeByte(6)
      ..write(obj.linkedTaskId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MindMapNodeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
