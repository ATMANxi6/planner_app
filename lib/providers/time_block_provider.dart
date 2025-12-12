import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/time_block.dart';
import '../models/dashboard_config.dart';
import '../models/task.dart';
import '../services/storage_service.dart';

/// Provider for managing time blocks and dashboard configuration
class TimeBlockProvider extends ChangeNotifier {
  final StorageService _storage;
  final _uuid = const Uuid();

  TimeBlockProvider(this._storage);

  // ========== Getters ==========

  /// Get all time blocks
  List<TimeBlock> get allTimeBlocks => _storage.timeBlocksBox.values.toList();

  /// Get dashboard configuration (create default if doesn't exist)
  DashboardConfig get config {
    final configBox = _storage.dashboardConfigBox;
    if (configBox.isEmpty) {
      final defaultConfig = DashboardConfig.defaultConfig();
      configBox.put('config', defaultConfig);
      return defaultConfig;
    }
    return configBox.get('config')!;
  }

  // ========== Time Block CRUD ==========

  /// Create a new time block
  Future<TimeBlock> createTimeBlock({
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    required int colorValue,
    String? linkedTaskId,
    String? linkedSubtaskId,
    String? category,
    String? description,
  }) async {
    // Snap times to slot boundaries
    final snappedStart = config.snapToSlot(startTime);
    final snappedEnd = config.snapToSlot(endTime);

    final block = TimeBlock(
      id: _uuid.v4(),
      title: title,
      startTime: snappedStart,
      endTime: snappedEnd,
      colorValue: colorValue,
      linkedTaskId: linkedTaskId,
      linkedSubtaskId: linkedSubtaskId,
      category: category,
      description: description,
    );

    await _storage.timeBlocksBox.put(block.id, block);
    notifyListeners();
    return block;
  }

  /// Create a time block from a task
  Future<TimeBlock> createTimeBlockFromTask(
    Task task,
    DateTime startTime, {
    DateTime? endTime,
  }) async {
    // Calculate end time based on task time estimate if not provided
    final duration = task.timeEstimate ?? 60; // Default 1 hour
    final calculatedEndTime =
        endTime ?? startTime.add(Duration(minutes: duration));

    return createTimeBlock(
      title: task.name,
      startTime: startTime,
      endTime: calculatedEndTime,
      colorValue: _getTaskTypeColor(task.type),
      linkedTaskId: task.id,
      category: task.category?.name,
      description: task.description,
    );
  }

  /// Create a time block from a subtask
  Future<TimeBlock> createTimeBlockFromSubtask(
    Subtask subtask,
    Task parentTask,
    DateTime startTime, {
    DateTime? endTime,
  }) async {
    final duration = subtask.timeEstimate ?? 30; // Default 30 min
    final calculatedEndTime =
        endTime ?? startTime.add(Duration(minutes: duration));

    return createTimeBlock(
      title: subtask.title,
      startTime: startTime,
      endTime: calculatedEndTime,
      colorValue: _getTaskTypeColor(parentTask.type),
      linkedTaskId: parentTask.id,
      linkedSubtaskId: subtask.id,
      category: parentTask.category?.name,
      description: subtask.description,
    );
  }

  /// Update a time block
  Future<void> updateTimeBlock(TimeBlock block) async {
    await block.save();
    notifyListeners();
  }

  /// Delete a time block
  Future<void> deleteTimeBlock(String id) async {
    await _storage.timeBlocksBox.delete(id);
    notifyListeners();
  }

  /// Move a time block to a new start time (preserving duration)
  Future<void> moveTimeBlock(String id, DateTime newStartTime) async {
    final block = _storage.timeBlocksBox.get(id);
    if (block == null) return;

    final snappedStart = config.snapToSlot(newStartTime);
    block.moveToTime(snappedStart);
    notifyListeners();
  }

  /// Move a time block with continuous positioning (for Google Calendar-style drag)
  /// Set [snap] to false for real-time dragging, true for snap-on-drop
  Future<void> moveTimeBlockContinuous(
    String id,
    DateTime newStartTime, {
    bool snap = true,
  }) async {
    final block = _storage.timeBlocksBox.get(id);
    if (block == null) return;

    final targetTime = snap ? config.snapToInterval(newStartTime) : newStartTime;

    // Clamp to working hours to prevent out-of-bounds positioning
    final clampedTime = config.clampToWorkingHours(targetTime);

    block.moveToTime(clampedTime);
    notifyListeners();
  }

  /// Resize a time block
  Future<void> resizeTimeBlock(String id, DateTime newEndTime) async {
    final block = _storage.timeBlocksBox.get(id);
    if (block == null) return;

    final snappedEnd = config.snapToSlot(newEndTime);
    block.resizeTo(snappedEnd);
    notifyListeners();
  }

  /// Toggle time block completion
  Future<void> toggleTimeBlock(String id) async {
    final block = _storage.timeBlocksBox.get(id);
    if (block == null) return;

    block.toggleComplete();
    notifyListeners();
  }

  // ========== Filtering & Queries ==========

  /// Get time blocks for a specific date
  List<TimeBlock> getBlocksForDate(DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);
    return allTimeBlocks
        .where((block) => _isSameDay(block.date, targetDate))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  /// Get time blocks for a date range (for weekly view)
  List<TimeBlock> getBlocksForDateRange(DateTime start, DateTime end) {
    return allTimeBlocks
        .where((block) =>
            !block.startTime.isBefore(start) && block.startTime.isBefore(end))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  /// Get time blocks for the current week
  List<TimeBlock> getBlocksForWeek(DateTime date) {
    final monday = _getMonday(date);
    final sunday = monday.add(const Duration(days: 7));
    return getBlocksForDateRange(monday, sunday);
  }

  /// Get time blocks linked to a specific task
  List<TimeBlock> getBlocksForTask(String taskId) {
    return allTimeBlocks
        .where((block) => block.linkedTaskId == taskId)
        .toList();
  }

  /// Get time blocks linked to a specific subtask
  List<TimeBlock> getBlocksForSubtask(String taskId, String subtaskId) {
    return allTimeBlocks
        .where((block) =>
            block.linkedTaskId == taskId &&
            block.linkedSubtaskId == subtaskId)
        .toList();
  }

  /// Check if a time block has conflicts
  bool hasConflicts(TimeBlock block) {
    final blocksOnSameDay = getBlocksForDate(block.date);
    return blocksOnSameDay
        .where((other) => other.id != block.id)
        .any((other) => block.conflictsWith(other));
  }

  /// Get conflicting time blocks
  List<TimeBlock> getConflicts(TimeBlock block) {
    final blocksOnSameDay = getBlocksForDate(block.date);
    return blocksOnSameDay
        .where((other) => other.id != block.id && block.conflictsWith(other))
        .toList();
  }

  // ========== Dashboard Configuration ==========

  /// Update dashboard configuration
  Future<void> updateConfig({
    TimeSlotInterval? timeSlotInterval,
    int? dayStartHour,
    int? dayEndHour,
    bool? showDailyTasksWidget,
    bool? showStatsWidget,
    bool? showStreaksWidget,
    bool? showProjectsWidget,
    bool? showDeadlinesWidget,
    bool? defaultToWeeklyView,
  }) async {
    config.update(
      timeSlotInterval: timeSlotInterval,
      dayStartHour: dayStartHour,
      dayEndHour: dayEndHour,
      showDailyTasksWidget: showDailyTasksWidget,
      showStatsWidget: showStatsWidget,
      showStreaksWidget: showStreaksWidget,
      showProjectsWidget: showProjectsWidget,
      showDeadlinesWidget: showDeadlinesWidget,
      defaultToWeeklyView: defaultToWeeklyView,
    );
    notifyListeners();
  }

  // ========== Statistics ==========

  /// Get total scheduled time for a date (in minutes)
  int getTotalScheduledTime(DateTime date) {
    final blocks = getBlocksForDate(date);
    return blocks.fold(0, (sum, block) => sum + block.durationMinutes);
  }

  /// Get completed time for a date (in minutes)
  int getCompletedTime(DateTime date) {
    final blocks = getBlocksForDate(date);
    return blocks
        .where((block) => block.isCompleted)
        .fold(0, (sum, block) => sum + block.durationMinutes);
  }

  /// Get completion percentage for a date
  double getCompletionPercentage(DateTime date) {
    final total = getTotalScheduledTime(date);
    if (total == 0) return 0.0;
    return getCompletedTime(date) / total;
  }

  // ========== Helpers ==========

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _getMonday(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  int _getTaskTypeColor(TaskType type) {
    return switch (type) {
      TaskType.distraction => 0xFFE57373, // Red
      TaskType.practice => 0xFF64B5F6, // Blue
      TaskType.goal => 0xFF81C784, // Green
    };
  }
}
