import 'package:hive/hive.dart';

part 'time_block.g.dart';

/// Represents a scheduled time block on the dashboard for time blocking
@HiveType(typeId: 12)
class TimeBlock extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  DateTime startTime;

  @HiveField(3)
  DateTime endTime;

  @HiveField(4)
  int colorValue; // Store as int for Hive compatibility

  @HiveField(5)
  String? linkedTaskId; // Optional link to a task

  @HiveField(6)
  String? linkedSubtaskId; // Optional link to a subtask

  @HiveField(7)
  String? category; // e.g., "Work", "Personal", "Break"

  @HiveField(8)
  String? description;

  @HiveField(9)
  bool isCompleted;

  @HiveField(10)
  final DateTime createdAt;

  TimeBlock({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.colorValue,
    this.linkedTaskId,
    this.linkedSubtaskId,
    this.category,
    this.description,
    this.isCompleted = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Duration of the time block in minutes
  int get durationMinutes {
    return endTime.difference(startTime).inMinutes;
  }

  /// Duration formatted as "2h 30m"
  String get formattedDuration {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;

    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }

  /// Date of this time block (ignores time component)
  DateTime get date {
    return DateTime(startTime.year, startTime.month, startTime.day);
  }

  /// Check if this block is happening now
  bool get isHappeningNow {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  /// Check if this block is in the past
  bool get isPast {
    return DateTime.now().isAfter(endTime);
  }

  /// Check if this block is in the future
  bool get isFuture {
    return DateTime.now().isBefore(startTime);
  }

  /// Check if this block is linked to a task or subtask
  bool get isLinked {
    return linkedTaskId != null || linkedSubtaskId != null;
  }

  /// Get the start time formatted as "9:00 AM"
  String get formattedStartTime {
    final hour = startTime.hour;
    final minute = startTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  /// Get the end time formatted as "11:00 AM"
  String get formattedEndTime {
    final hour = endTime.hour;
    final minute = endTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  /// Get time range formatted as "9:00 AM - 11:00 AM"
  String get formattedTimeRange {
    return '$formattedStartTime - $formattedEndTime';
  }

  /// Check if this block conflicts with another block
  bool conflictsWith(TimeBlock other) {
    // Check if they're on the same day
    if (!_isSameDay(date, other.date)) return false;

    // Check for time overlap
    return startTime.isBefore(other.endTime) && endTime.isAfter(other.startTime);
  }

  /// Move the block to a new start time (preserving duration)
  void moveToTime(DateTime newStartTime) {
    final duration = durationMinutes;
    startTime = newStartTime;
    endTime = newStartTime.add(Duration(minutes: duration));
    save();
  }

  /// Resize the block by changing the end time
  void resizeTo(DateTime newEndTime) {
    if (newEndTime.isAfter(startTime)) {
      endTime = newEndTime;
      save();
    }
  }

  /// Toggle completion status
  void toggleComplete() {
    isCompleted = !isCompleted;
    save();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Create a copy of this time block with modified fields
  TimeBlock copyWith({
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    int? colorValue,
    String? linkedTaskId,
    String? linkedSubtaskId,
    String? category,
    String? description,
    bool? isCompleted,
  }) {
    return TimeBlock(
      id: id,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      colorValue: colorValue ?? this.colorValue,
      linkedTaskId: linkedTaskId ?? this.linkedTaskId,
      linkedSubtaskId: linkedSubtaskId ?? this.linkedSubtaskId,
      category: category ?? this.category,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }
}
