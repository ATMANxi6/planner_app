import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
enum TaskType {
  @HiveField(0)
  distraction,
  @HiveField(1)
  practice,
  @HiveField(2)
  goal,
}

@HiveType(typeId: 3)
enum Priority {
  @HiveField(0)
  high,
  @HiveField(1)
  medium,
  @HiveField(2)
  low,
}

@HiveType(typeId: 4)
enum Frequency {
  @HiveField(0)
  daily,
  @HiveField(1)
  weekly,
  @HiveField(2)
  monthly,
  @HiveField(3)
  custom,
}

@HiveType(typeId: 6)
enum Category {
  @HiveField(0)
  work,
  @HiveField(1)
  health,
  @HiveField(2)
  relationships,
  @HiveField(3)
  learning,
  @HiveField(4)
  personal,
}

/// Kanban workflow status for project visualization
@HiveType(typeId: 10)
enum KanbanStatus {
  @HiveField(0)
  backlog,
  @HiveField(1)
  todo,
  @HiveField(2)
  inProgress,
  @HiveField(3)
  review,
  @HiveField(4)
  done,
}

/// Extension for display-friendly Kanban status names
extension KanbanStatusExtension on KanbanStatus {
  String get displayName {
    return switch (this) {
      KanbanStatus.backlog => 'Backlog',
      KanbanStatus.todo => 'To Do',
      KanbanStatus.inProgress => 'In Progress',
      KanbanStatus.review => 'Review',
      KanbanStatus.done => 'Done',
    };
  }
}

@HiveType(typeId: 7)
class Subtask extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  bool isCompleted;

  // Visualization fields for project management
  @HiveField(3)
  KanbanStatus? kanbanStatus;

  @HiveField(4)
  DateTime? startDate;

  @HiveField(5)
  DateTime? deadline;

  @HiveField(6)
  int? timeEstimate; // in minutes

  @HiveField(7)
  DateTime? completedAt;

  @HiveField(8)
  String? description;

  @HiveField(9)
  Priority? priority;

  Subtask({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.kanbanStatus,
    this.startDate,
    this.deadline,
    this.timeEstimate,
    this.completedAt,
    this.description,
    this.priority,
  });

  void toggleComplete() {
    isCompleted = !isCompleted;
    completedAt = isCompleted ? DateTime.now() : null;
    // Auto-update kanban status when toggling completion
    if (isCompleted && kanbanStatus != KanbanStatus.done) {
      kanbanStatus = KanbanStatus.done;
    } else if (!isCompleted && kanbanStatus == KanbanStatus.done) {
      kanbanStatus = KanbanStatus.review;
    }
    save();
  }

  /// Get effective start date (startDate or fallback to now)
  DateTime get effectiveStartDate => startDate ?? DateTime.now();

  /// Get effective end date (deadline or startDate + 1 day)
  DateTime get effectiveEndDate =>
      deadline ?? effectiveStartDate.add(const Duration(days: 1));

  /// Duration in days for Gantt chart
  int get durationDays {
    return effectiveEndDate.difference(effectiveStartDate).inDays.abs() + 1;
  }

  /// Check if overdue
  bool get isOverdue {
    if (deadline == null || isCompleted) return false;
    return DateTime.now().isAfter(deadline!);
  }

  /// Remaining time estimate (0 if completed)
  int get remainingTimeEstimate {
    if (isCompleted) return 0;
    return timeEstimate ?? 0;
  }
}

@HiveType(typeId: 8)
class Milestone extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  DateTime? targetDate;

  @HiveField(4)
  bool isCompleted;

  @HiveField(5)
  DateTime? completedAt;

  Milestone({
    required this.id,
    required this.title,
    this.description = '',
    this.targetDate,
    this.isCompleted = false,
    this.completedAt,
  });

  void toggleComplete() {
    isCompleted = !isCompleted;
    completedAt = isCompleted ? DateTime.now() : null;
    save();
  }
}

@HiveType(typeId: 1)
class Task extends HiveObject {
  // Core required fields
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String description;

  @HiveField(3)
  TaskType type;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  DateTime? completedAt;

  @HiveField(6)
  bool isCompleted;

  // Optional core fields
  @HiveField(7)
  Priority priority;

  @HiveField(8)
  DateTime? reminderTime;

  @HiveField(9)
  int? timeEstimate; // duration in minutes (optional)

  @HiveField(11)
  Frequency? frequency; // recurrence (optional)

  @HiveField(12)
  DateTime? deadline; // date (optional)

  @HiveField(16)
  Category? category; // optional

  // Distraction-specific fields
  @HiveField(20)
  String? replacementBehavior;

  @HiveField(21)
  List<String> commonTriggers;

  @HiveField(22)
  String? costImpact;

  @HiveField(23)
  int streakCount; // Days avoided

  // Practice-specific fields
  @HiveField(24)
  String? progressMetric;

  @HiveField(26)
  List<String> resourcesNeeded;

  @HiveField(27)
  String? reflectionPrompt;

  // Goal-specific fields
  @HiveField(28)
  List<Milestone> milestones;

  @HiveField(29)
  String? whyPurpose;

  @HiveField(30)
  String? successCriteria;

  @HiveField(31)
  List<String> relatedHabits;

  @HiveField(32)
  List<Subtask> subtasks;

  // Project visualization fields
  @HiveField(33)
  String? projectId; // Links task to a project

  @HiveField(34)
  List<String> dependencies; // Task IDs that must complete before this task

  @HiveField(35)
  KanbanStatus? kanbanStatus; // Workflow status for Kanban board

  @HiveField(36)
  DateTime? startDate; // Start date for Gantt chart timeline

  // Scheduling fields (formerly TimeBlock functionality)
  @HiveField(37)
  DateTime? scheduledStart; // When the task is scheduled to start

  @HiveField(38)
  DateTime? scheduledEnd; // When the task is scheduled to end

  @HiveField(39)
  int? scheduleColorValue; // Visual color for the schedule (optional, defaults to type color)

  // Habit-Goal Connection fields (Smart Habit Builder)
  @HiveField(40)
  List<String> supportingGoals; // For practices - IDs of goals this practice supports

  @HiveField(41)
  List<String> supportingPractices; // For goals - IDs of practices that support this goal

  /// Check if this task is scheduled
  bool get isScheduled => scheduledStart != null && scheduledEnd != null;

  /// Get scheduled duration in minutes
  int? get scheduledDurationMinutes {
    if (!isScheduled) return null;
    return scheduledEnd!.difference(scheduledStart!).inMinutes;
  }

  /// Get formatted scheduled time range
  String? get formattedScheduledTime {
    if (!isScheduled) return null;
    final start = _formatTime(scheduledStart!);
    final end = _formatTime(scheduledEnd!);
    return '$start - $end';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  Task({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    DateTime? createdAt,
    this.completedAt,
    this.isCompleted = false,
    this.priority = Priority.medium,
    this.reminderTime,
    this.timeEstimate,
    this.frequency,
    this.deadline,
    this.category,
    // Distraction fields
    this.replacementBehavior,
    List<String>? commonTriggers,
    this.costImpact,
    this.streakCount = 0,
    // Practice fields
    this.progressMetric,
    List<String>? resourcesNeeded,
    this.reflectionPrompt,
    // Goal fields
    List<Milestone>? milestones,
    this.whyPurpose,
    this.successCriteria,
    List<String>? relatedHabits,
    List<Subtask>? subtasks,
    // Project visualization fields
    this.projectId,
    List<String>? dependencies,
    this.kanbanStatus,
    this.startDate,
    // Scheduling fields
    this.scheduledStart,
    this.scheduledEnd,
    this.scheduleColorValue,
    // Habit-Goal Connection fields
    List<String>? supportingGoals,
    List<String>? supportingPractices,
  })  : createdAt = createdAt ?? DateTime.now(),
        commonTriggers = commonTriggers ?? [],
        resourcesNeeded = resourcesNeeded ?? [],
        milestones = milestones ?? [],
        relatedHabits = relatedHabits ?? [],
        subtasks = subtasks ?? [],
        dependencies = dependencies ?? [],
        supportingGoals = supportingGoals ?? [],
        supportingPractices = supportingPractices ?? [];

  void toggleComplete() {
    isCompleted = !isCompleted;
    completedAt = isCompleted ? DateTime.now() : null;

    // Update streak count based on task type
    if (isCompleted) {
      if (type == TaskType.distraction) {
        // For distractions, streak is days avoided (increment when NOT doing it)
        streakCount++;
      } else if (type == TaskType.practice) {
        // For practices, streak is days completed
        streakCount++;
      }
    }

    save();
  }

  // Helper to check if task is overdue
  bool get isOverdue {
    if (deadline == null || isCompleted) return false;
    return DateTime.now().isAfter(deadline!);
  }

  // Helper to get completion percentage for goals (based on milestones)
  double get completionPercentage {
    if (type != TaskType.goal || milestones.isEmpty) return 0.0;
    final completedCount = milestones.where((m) => m.isCompleted).length;
    return completedCount / milestones.length;
  }

  // Helper to get subtask completion percentage
  double get subtaskCompletionPercentage {
    if (type != TaskType.goal || subtasks.isEmpty) return 0.0;
    final completedCount = subtasks.where((s) => s.isCompleted).length;
    return completedCount / subtasks.length;
  }

  // Check if all subtasks are completed
  bool get allSubtasksCompleted {
    if (subtasks.isEmpty) return true;
    return subtasks.every((s) => s.isCompleted);
  }

  // Helper to check if recurring task should be reset
  bool shouldResetForRecurrence() {
    // Only reset completed recurring tasks
    if (!isCompleted || frequency == null || completedAt == null) {
      return false;
    }

    final now = DateTime.now();
    final completedDate = completedAt!;

    return switch (frequency!) {
      Frequency.daily => !_isSameDay(completedDate, now),
      Frequency.weekly => !_isSameWeek(completedDate, now),
      Frequency.monthly => !_isSameMonth(completedDate, now),
      Frequency.custom => false, // Custom frequency requires manual reset
    };
  }

  // Reset task for recurrence
  void resetForRecurrence() {
    isCompleted = false;
    completedAt = null;
    save();
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  bool _isSameWeek(DateTime date1, DateTime date2) {
    // Get Monday of each week for comparison
    final monday1 = date1.subtract(Duration(days: date1.weekday - 1));
    final monday2 = date2.subtract(Duration(days: date2.weekday - 1));
    return _isSameDay(monday1, monday2);
  }

  bool _isSameMonth(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month;
  }

  // ========== Project Visualization Helpers ==========

  /// Get effective start date (startDate or createdAt as fallback)
  DateTime get effectiveStartDate => startDate ?? createdAt;

  /// Get effective end date (deadline or startDate + 1 day as fallback)
  DateTime get effectiveEndDate =>
      deadline ?? effectiveStartDate.add(const Duration(days: 1));

  /// Duration of the task in days (for Gantt chart)
  int get durationDays {
    return effectiveEndDate.difference(effectiveStartDate).inDays.abs() + 1;
  }

  /// Check if this task has dependencies
  bool get hasDependencies => dependencies.isNotEmpty;

  /// Check if task is in a project
  bool get isInProject => projectId != null;

  /// Get remaining time estimate in minutes (0 if completed)
  int get remainingTimeEstimate {
    if (isCompleted) return 0;
    return timeEstimate ?? 0;
  }
}
