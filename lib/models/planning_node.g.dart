// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planning_node.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NodeConnectionAdapter extends TypeAdapter<NodeConnection> {
  @override
  final int typeId = 21;

  @override
  NodeConnection read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NodeConnection(
      fromNodeId: fields[0] as String,
      toNodeId: fields[1] as String,
      type: fields[2] as ConnectionType,
    );
  }

  @override
  void write(BinaryWriter writer, NodeConnection obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.fromNodeId)
      ..writeByte(1)
      ..write(obj.toNodeId)
      ..writeByte(2)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NodeConnectionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PlanningNodeAdapter extends TypeAdapter<PlanningNode> {
  @override
  final int typeId = 22;

  @override
  PlanningNode read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlanningNode(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String?,
      type: fields[3] as PlanningNodeType,
      parentId: fields[4] as String?,
      childIds: (fields[5] as List?)?.cast<String>(),
      hierarchyLevel: fields[6] as int,
      isCollapsed: fields[7] as bool,
      colorValue: fields[8] as int,
      linkedTaskId: fields[9] as String?,
      linkedProjectId: fields[18] as String?,
      x: fields[19] as double?,
      y: fields[20] as double?,
      deadline: fields[10] as DateTime?,
      timeEstimateMinutes: fields[11] as int?,
      isCompleted: fields[12] as bool,
      dependencyIds: (fields[13] as List?)?.cast<String>(),
      sortOrder: fields[14] as int,
      createdAt: fields[15] as DateTime?,
      completedAt: fields[16] as DateTime?,
      updatedAt: fields[17] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PlanningNode obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.parentId)
      ..writeByte(5)
      ..write(obj.childIds)
      ..writeByte(6)
      ..write(obj.hierarchyLevel)
      ..writeByte(7)
      ..write(obj.isCollapsed)
      ..writeByte(8)
      ..write(obj.colorValue)
      ..writeByte(9)
      ..write(obj.linkedTaskId)
      ..writeByte(18)
      ..write(obj.linkedProjectId)
      ..writeByte(19)
      ..write(obj.x)
      ..writeByte(20)
      ..write(obj.y)
      ..writeByte(10)
      ..write(obj.deadline)
      ..writeByte(11)
      ..write(obj.timeEstimateMinutes)
      ..writeByte(12)
      ..write(obj.isCompleted)
      ..writeByte(13)
      ..write(obj.dependencyIds)
      ..writeByte(14)
      ..write(obj.sortOrder)
      ..writeByte(15)
      ..write(obj.createdAt)
      ..writeByte(16)
      ..write(obj.completedAt)
      ..writeByte(17)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanningNodeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PlanningNodeTypeAdapter extends TypeAdapter<PlanningNodeType> {
  @override
  final int typeId = 19;

  @override
  PlanningNodeType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PlanningNodeType.goal;
      case 1:
        return PlanningNodeType.milestone;
      case 2:
        return PlanningNodeType.task;
      case 3:
        return PlanningNodeType.note;
      case 4:
        return PlanningNodeType.decision;
      default:
        return PlanningNodeType.goal;
    }
  }

  @override
  void write(BinaryWriter writer, PlanningNodeType obj) {
    switch (obj) {
      case PlanningNodeType.goal:
        writer.writeByte(0);
        break;
      case PlanningNodeType.milestone:
        writer.writeByte(1);
        break;
      case PlanningNodeType.task:
        writer.writeByte(2);
        break;
      case PlanningNodeType.note:
        writer.writeByte(3);
        break;
      case PlanningNodeType.decision:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanningNodeTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ConnectionTypeAdapter extends TypeAdapter<ConnectionType> {
  @override
  final int typeId = 20;

  @override
  ConnectionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ConnectionType.sequential;
      case 1:
        return ConnectionType.parallel;
      case 2:
        return ConnectionType.conditional;
      case 3:
        return ConnectionType.optional;
      default:
        return ConnectionType.sequential;
    }
  }

  @override
  void write(BinaryWriter writer, ConnectionType obj) {
    switch (obj) {
      case ConnectionType.sequential:
        writer.writeByte(0);
        break;
      case ConnectionType.parallel:
        writer.writeByte(1);
        break;
      case ConnectionType.conditional:
        writer.writeByte(2);
        break;
      case ConnectionType.optional:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
