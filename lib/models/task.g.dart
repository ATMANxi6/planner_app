// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SubtaskAdapter extends TypeAdapter<Subtask> {
  @override
  final int typeId = 7;

  @override
  Subtask read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Subtask(
      id: fields[0] as String,
      title: fields[1] as String,
      isCompleted: fields[2] as bool,
      kanbanStatus: fields[3] as KanbanStatus?,
      startDate: fields[4] as DateTime?,
      deadline: fields[5] as DateTime?,
      timeEstimate: fields[6] as int?,
      completedAt: fields[7] as DateTime?,
      description: fields[8] as String?,
      priority: fields[9] as Priority?,
    );
  }

  @override
  void write(BinaryWriter writer, Subtask obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.isCompleted)
      ..writeByte(3)
      ..write(obj.kanbanStatus)
      ..writeByte(4)
      ..write(obj.startDate)
      ..writeByte(5)
      ..write(obj.deadline)
      ..writeByte(6)
      ..write(obj.timeEstimate)
      ..writeByte(7)
      ..write(obj.completedAt)
      ..writeByte(8)
      ..write(obj.description)
      ..writeByte(9)
      ..write(obj.priority);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubtaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MilestoneAdapter extends TypeAdapter<Milestone> {
  @override
  final int typeId = 8;

  @override
  Milestone read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Milestone(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      targetDate: fields[3] as DateTime?,
      isCompleted: fields[4] as bool,
      completedAt: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Milestone obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.targetDate)
      ..writeByte(4)
      ..write(obj.isCompleted)
      ..writeByte(5)
      ..write(obj.completedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MilestoneAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 1;

  @override
  Task read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Task(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      type: fields[3] as TaskType,
      createdAt: fields[4] as DateTime?,
      completedAt: fields[5] as DateTime?,
      isCompleted: fields[6] as bool,
      priority: fields[7] as Priority,
      reminderTime: fields[8] as DateTime?,
      timeEstimate: fields[9] as int?,
      frequency: fields[11] as Frequency?,
      deadline: fields[12] as DateTime?,
      category: fields[16] as Category?,
      replacementBehavior: fields[20] as String?,
      commonTriggers: (fields[21] as List?)?.cast<String>(),
      costImpact: fields[22] as String?,
      streakCount: fields[23] as int,
      progressMetric: fields[24] as String?,
      resourcesNeeded: (fields[26] as List?)?.cast<String>(),
      reflectionPrompt: fields[27] as String?,
      milestones: (fields[28] as List?)?.cast<Milestone>(),
      whyPurpose: fields[29] as String?,
      successCriteria: fields[30] as String?,
      relatedHabits: (fields[31] as List?)?.cast<String>(),
      subtasks: (fields[32] as List?)?.cast<Subtask>(),
      projectId: fields[33] as String?,
      dependencies: (fields[34] as List?)?.cast<String>(),
      kanbanStatus: fields[35] as KanbanStatus?,
      startDate: fields[36] as DateTime?,
      scheduledStart: fields[37] as DateTime?,
      scheduledEnd: fields[38] as DateTime?,
      scheduleColorValue: fields[39] as int?,
      supportingGoals: (fields[40] as List?)?.cast<String>(),
      supportingPractices: (fields[41] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(34)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.completedAt)
      ..writeByte(6)
      ..write(obj.isCompleted)
      ..writeByte(7)
      ..write(obj.priority)
      ..writeByte(8)
      ..write(obj.reminderTime)
      ..writeByte(9)
      ..write(obj.timeEstimate)
      ..writeByte(11)
      ..write(obj.frequency)
      ..writeByte(12)
      ..write(obj.deadline)
      ..writeByte(16)
      ..write(obj.category)
      ..writeByte(20)
      ..write(obj.replacementBehavior)
      ..writeByte(21)
      ..write(obj.commonTriggers)
      ..writeByte(22)
      ..write(obj.costImpact)
      ..writeByte(23)
      ..write(obj.streakCount)
      ..writeByte(24)
      ..write(obj.progressMetric)
      ..writeByte(26)
      ..write(obj.resourcesNeeded)
      ..writeByte(27)
      ..write(obj.reflectionPrompt)
      ..writeByte(28)
      ..write(obj.milestones)
      ..writeByte(29)
      ..write(obj.whyPurpose)
      ..writeByte(30)
      ..write(obj.successCriteria)
      ..writeByte(31)
      ..write(obj.relatedHabits)
      ..writeByte(32)
      ..write(obj.subtasks)
      ..writeByte(33)
      ..write(obj.projectId)
      ..writeByte(34)
      ..write(obj.dependencies)
      ..writeByte(35)
      ..write(obj.kanbanStatus)
      ..writeByte(36)
      ..write(obj.startDate)
      ..writeByte(37)
      ..write(obj.scheduledStart)
      ..writeByte(38)
      ..write(obj.scheduledEnd)
      ..writeByte(39)
      ..write(obj.scheduleColorValue)
      ..writeByte(40)
      ..write(obj.supportingGoals)
      ..writeByte(41)
      ..write(obj.supportingPractices);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TaskTypeAdapter extends TypeAdapter<TaskType> {
  @override
  final int typeId = 0;

  @override
  TaskType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TaskType.distraction;
      case 1:
        return TaskType.practice;
      case 2:
        return TaskType.goal;
      default:
        return TaskType.distraction;
    }
  }

  @override
  void write(BinaryWriter writer, TaskType obj) {
    switch (obj) {
      case TaskType.distraction:
        writer.writeByte(0);
        break;
      case TaskType.practice:
        writer.writeByte(1);
        break;
      case TaskType.goal:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PriorityAdapter extends TypeAdapter<Priority> {
  @override
  final int typeId = 3;

  @override
  Priority read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Priority.high;
      case 1:
        return Priority.medium;
      case 2:
        return Priority.low;
      default:
        return Priority.high;
    }
  }

  @override
  void write(BinaryWriter writer, Priority obj) {
    switch (obj) {
      case Priority.high:
        writer.writeByte(0);
        break;
      case Priority.medium:
        writer.writeByte(1);
        break;
      case Priority.low:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriorityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FrequencyAdapter extends TypeAdapter<Frequency> {
  @override
  final int typeId = 4;

  @override
  Frequency read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Frequency.daily;
      case 1:
        return Frequency.weekly;
      case 2:
        return Frequency.monthly;
      case 3:
        return Frequency.custom;
      default:
        return Frequency.daily;
    }
  }

  @override
  void write(BinaryWriter writer, Frequency obj) {
    switch (obj) {
      case Frequency.daily:
        writer.writeByte(0);
        break;
      case Frequency.weekly:
        writer.writeByte(1);
        break;
      case Frequency.monthly:
        writer.writeByte(2);
        break;
      case Frequency.custom:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FrequencyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CategoryAdapter extends TypeAdapter<Category> {
  @override
  final int typeId = 6;

  @override
  Category read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Category.work;
      case 1:
        return Category.health;
      case 2:
        return Category.relationships;
      case 3:
        return Category.learning;
      case 4:
        return Category.personal;
      default:
        return Category.work;
    }
  }

  @override
  void write(BinaryWriter writer, Category obj) {
    switch (obj) {
      case Category.work:
        writer.writeByte(0);
        break;
      case Category.health:
        writer.writeByte(1);
        break;
      case Category.relationships:
        writer.writeByte(2);
        break;
      case Category.learning:
        writer.writeByte(3);
        break;
      case Category.personal:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class KanbanStatusAdapter extends TypeAdapter<KanbanStatus> {
  @override
  final int typeId = 10;

  @override
  KanbanStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return KanbanStatus.backlog;
      case 1:
        return KanbanStatus.todo;
      case 2:
        return KanbanStatus.inProgress;
      case 3:
        return KanbanStatus.review;
      case 4:
        return KanbanStatus.done;
      default:
        return KanbanStatus.backlog;
    }
  }

  @override
  void write(BinaryWriter writer, KanbanStatus obj) {
    switch (obj) {
      case KanbanStatus.backlog:
        writer.writeByte(0);
        break;
      case KanbanStatus.todo:
        writer.writeByte(1);
        break;
      case KanbanStatus.inProgress:
        writer.writeByte(2);
        break;
      case KanbanStatus.review:
        writer.writeByte(3);
        break;
      case KanbanStatus.done:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KanbanStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
