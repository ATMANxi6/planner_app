import 'package:flutter/foundation.dart' hide Category;
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

class TaskProvider extends ChangeNotifier {
  final StorageService _storage;
  final NotificationService _notificationService;
  final _uuid = const Uuid();

  TaskProvider(this._storage, this._notificationService);

  List<Task> get allTasks => _storage.tasksBox.values.toList();

  List<Task> getTasksByType(TaskType type) =>
      allTasks.where((task) => task.type == type).toList();

  List<Task> get distractions => getTasksByType(TaskType.distraction);
  List<Task> get practices => getTasksByType(TaskType.practice);
  List<Task> get goals => getTasksByType(TaskType.goal);

  Future<void> addTask(Task task) async {
    await _storage.tasksBox.put(task.id, task);
    // Schedule notification if task has a reminder time
    if (task.reminderTime != null) {
      await _notificationService.scheduleTaskReminder(task);
    }
    notifyListeners();
  }

  Future<Task> createTask({
    required String name,
    required String description,
    required TaskType type,
    Priority priority = Priority.medium,
    DateTime? reminderTime,
    int? timeEstimate,
    Frequency? frequency,
    DateTime? deadline,
    Category? category,
    // Scheduling fields
    DateTime? scheduledStart,
    DateTime? scheduledEnd,
    int? scheduleColorValue,
    // Distraction-specific
    String? replacementBehavior,
    List<String>? commonTriggers,
    String? costImpact,
    // Practice-specific
    String? progressMetric,
    List<String>? resourcesNeeded,
    String? reflectionPrompt,
    // Goal-specific
    List<Milestone>? milestones,
    String? whyPurpose,
    String? successCriteria,
    List<String>? relatedHabits,
    List<Subtask>? subtasks,
  }) async {
    final task = Task(
      id: _uuid.v4(),
      name: name,
      description: description,
      type: type,
      priority: priority,
      reminderTime: reminderTime,
      timeEstimate: timeEstimate,
      frequency: frequency,
      deadline: deadline,
      category: category,
      scheduledStart: scheduledStart,
      scheduledEnd: scheduledEnd,
      scheduleColorValue: scheduleColorValue ?? (scheduledStart != null ? _getTaskTypeColor(type) : null),
      replacementBehavior: replacementBehavior,
      commonTriggers: commonTriggers,
      costImpact: costImpact,
      progressMetric: progressMetric,
      resourcesNeeded: resourcesNeeded,
      reflectionPrompt: reflectionPrompt,
      milestones: milestones,
      whyPurpose: whyPurpose,
      successCriteria: successCriteria,
      relatedHabits: relatedHabits,
      subtasks: subtasks,
    );
    await addTask(task);
    return task;
  }

  Future<void> updateTask(Task task) async {
    await task.save();
    // Reschedule notification (cancel old one and schedule new one if reminder exists)
    if (task.reminderTime != null) {
      await _notificationService.scheduleTaskReminder(task);
    } else {
      // Cancel notification if reminder was removed
      await _notificationService.cancelTaskReminder(task.id);
    }
    notifyListeners();
  }

  Future<void> deleteTask(String id) async {
    // Cancel any scheduled notification
    await _notificationService.cancelTaskReminder(id);
    await _storage.tasksBox.delete(id);
    notifyListeners();
  }

  /// Get a task by ID
  Task? getTask(String id) {
    return _storage.tasksBox.get(id);
  }

  Future<void> toggleTask(String id) async {
    final task = _storage.tasksBox.get(id);
    if (task == null) return;

    final wasCompleted = task.isCompleted;
    task.toggleComplete();

    // Trigger intelligent notifications when completing tasks
    if (!wasCompleted && task.isCompleted) {
      await _handleTaskCompletion(task);
    }

    notifyListeners();
  }

  /// Handle intelligent notifications when a task is completed
  Future<void> _handleTaskCompletion(Task task) async {
    // Celebration for streak milestones
    if (task.type == TaskType.practice || task.type == TaskType.distraction) {
      final milestones = [7, 14, 30, 50, 100, 365];
      if (milestones.contains(task.streakCount)) {
        final emoji = task.type == TaskType.practice ? '🔥' : '✅';
        await _notificationService.showCelebrationNotification(
          title: '$emoji ${task.streakCount}-Day Milestone!',
          body: '${task.name} - Keep up the amazing work!',
          taskId: task.id,
        );
      }
    }

    // Celebration when all practices complete for a goal
    if (task.type == TaskType.practice && task.supportingGoals.isNotEmpty) {
      for (final goalId in task.supportingGoals) {
        final goal = getTask(goalId);
        if (goal == null) continue;

        final allPractices = getPracticesForGoal(goalId);
        final allComplete = allPractices.every((p) => p.isCompleted);

        if (allComplete && allPractices.isNotEmpty) {
          await _notificationService.showCelebrationNotification(
            title: '🎯 Goal Practices Complete!',
            body: 'All practices supporting "${goal.name}" are done today! 🎉',
            taskId: goalId,
          );
        }
      }
    }

    // Celebration for completing goals
    if (task.type == TaskType.goal) {
      await _notificationService.showCelebrationNotification(
        title: '🎉 Goal Achieved!',
        body: 'Congratulations on completing "${task.name}"!',
        taskId: task.id,
      );
    }
  }

  // Subtask management methods
  Future<void> addSubtask(String taskId, String subtaskTitle) async {
    final task = _storage.tasksBox.get(taskId);
    if (task == null || task.type != TaskType.goal) return;

    final subtask = Subtask(
      id: _uuid.v4(),
      title: subtaskTitle,
    );

    task.subtasks = [...task.subtasks, subtask];
    await task.save();
    notifyListeners();
  }

  Future<void> updateSubtask(String taskId, String subtaskId, String newTitle) async {
    final task = _storage.tasksBox.get(taskId);
    if (task == null || task.type != TaskType.goal) return;

    final subtaskIndex = task.subtasks.indexWhere((s) => s.id == subtaskId);
    if (subtaskIndex == -1) return;

    task.subtasks[subtaskIndex].title = newTitle;
    await task.save();
    notifyListeners();
  }

  Future<void> deleteSubtask(String taskId, String subtaskId) async {
    final task = _storage.tasksBox.get(taskId);
    if (task == null || task.type != TaskType.goal) return;

    task.subtasks = task.subtasks.where((s) => s.id != subtaskId).toList();
    await task.save();
    notifyListeners();
  }

  Future<void> toggleSubtask(String taskId, String subtaskId) async {
    final task = _storage.tasksBox.get(taskId);
    if (task == null || task.type != TaskType.goal) return;

    final subtask = task.subtasks.firstWhere((s) => s.id == subtaskId);
    subtask.isCompleted = !subtask.isCompleted;

    // Auto-complete the goal if all subtasks are completed
    if (task.allSubtasksCompleted && !task.isCompleted) {
      task.isCompleted = true;
      task.completedAt = DateTime.now();
    }
    // Uncomplete the goal if a subtask is uncompleted
    else if (!task.allSubtasksCompleted && task.isCompleted) {
      task.isCompleted = false;
      task.completedAt = null;
    }

    await task.save();
    notifyListeners();
  }

  // Reset recurring tasks if their recurrence period has passed
  Future<void> resetRecurringTasks() async {
    bool anyReset = false;
    for (var task in allTasks) {
      if (task.shouldResetForRecurrence()) {
        task.resetForRecurrence();
        anyReset = true;
      }
    }
    if (anyReset) {
      notifyListeners();
    }

    // Schedule daily intelligent notifications
    await _scheduleDailyNotifications();
  }

  /// Schedule daily intelligent notifications (morning, evening, streak protection)
  Future<void> _scheduleDailyNotifications() async {
    // Schedule morning motivation
    await _notificationService.scheduleMorningMotivation();

    // Schedule evening review
    await _notificationService.scheduleEveningReview();

    // Schedule streak protection for practices with active streaks
    final practicesWithStreaks = practices.where((p) =>
      p.streakCount > 0 && !p.isCompleted
    ).toList();

    for (final practice in practicesWithStreaks) {
      await _notificationService.scheduleStreakProtectionNotification(practice);
    }

    // Schedule streak protection for distractions being avoided
    final distractionsWithStreaks = distractions.where((d) =>
      d.streakCount > 0
    ).toList();

    for (final distraction in distractionsWithStreaks) {
      await _notificationService.scheduleStreakProtectionNotification(distraction);
    }
  }

  // ========== Habit-Goal Connection Methods (Smart Habit Builder) ==========

  /// Link a practice to a goal (bidirectional)
  Future<void> linkPracticeToGoal(String practiceId, String goalId) async {
    final practice = _storage.tasksBox.get(practiceId);
    final goal = _storage.tasksBox.get(goalId);

    if (practice == null || goal == null) return;
    if (practice.type != TaskType.practice) return;
    if (goal.type != TaskType.goal) return;

    // Add goal to practice's supportingGoals list
    if (!practice.supportingGoals.contains(goalId)) {
      practice.supportingGoals.add(goalId);
      await practice.save();
    }

    // Add practice to goal's supportingPractices list
    if (!goal.supportingPractices.contains(practiceId)) {
      goal.supportingPractices.add(practiceId);
      await goal.save();
    }

    notifyListeners();
  }

  /// Unlink a practice from a goal (bidirectional)
  Future<void> unlinkPracticeFromGoal(String practiceId, String goalId) async {
    final practice = _storage.tasksBox.get(practiceId);
    final goal = _storage.tasksBox.get(goalId);

    if (practice == null || goal == null) return;

    // Remove goal from practice's supportingGoals list
    practice.supportingGoals.remove(goalId);
    await practice.save();

    // Remove practice from goal's supportingPractices list
    goal.supportingPractices.remove(practiceId);
    await goal.save();

    notifyListeners();
  }

  /// Get all practices that support a specific goal
  List<Task> getPracticesForGoal(String goalId) {
    final goal = _storage.tasksBox.get(goalId);
    if (goal == null || goal.type != TaskType.goal) return [];

    return goal.supportingPractices
        .map((practiceId) => _storage.tasksBox.get(practiceId))
        .whereType<Task>()
        .toList();
  }

  /// Get all goals supported by a specific practice
  List<Task> getGoalsForPractice(String practiceId) {
    final practice = _storage.tasksBox.get(practiceId);
    if (practice == null || practice.type != TaskType.practice) return [];

    return practice.supportingGoals
        .map((goalId) => _storage.tasksBox.get(goalId))
        .whereType<Task>()
        .toList();
  }

  /// Get practice completion rate for a goal (% of practices completed today)
  double getPracticeCompletionRateForGoal(String goalId) {
    final practices = getPracticesForGoal(goalId);
    if (practices.isEmpty) return 0.0;

    final completedToday = practices.where((p) => p.isCompleted).length;
    return completedToday / practices.length;
  }

  // ========== Project Visualization Methods ==========

  /// Get all tasks for a specific project
  List<Task> getTasksByProject(String projectId) {
    return allTasks.where((task) => task.projectId == projectId).toList();
  }

  /// Get tasks not assigned to any project
  List<Task> get unassignedTasks {
    return allTasks.where((task) => task.projectId == null).toList();
  }

  /// Assign a task to a project
  Future<void> assignTaskToProject(String taskId, String? projectId) async {
    final task = _storage.tasksBox.get(taskId);
    if (task == null) return;

    task.projectId = projectId;
    await task.save();
    notifyListeners();
  }

  /// Update task's Kanban status
  Future<void> updateKanbanStatus(String taskId, KanbanStatus status) async {
    final task = _storage.tasksBox.get(taskId);
    if (task == null) return;

    task.kanbanStatus = status;

    // Auto-complete task when moved to 'done' column
    if (status == KanbanStatus.done && !task.isCompleted) {
      task.isCompleted = true;
      task.completedAt = DateTime.now();
    }
    // Uncomplete task when moved out of 'done' column
    else if (status != KanbanStatus.done && task.isCompleted) {
      task.isCompleted = false;
      task.completedAt = null;
    }

    await task.save();
    notifyListeners();
  }

  /// Update task's start date (for Gantt chart)
  Future<void> updateTaskStartDate(String taskId, DateTime startDate) async {
    final task = _storage.tasksBox.get(taskId);
    if (task == null) return;

    task.startDate = startDate;
    await task.save();
    notifyListeners();
  }

  /// Update task's deadline/end date
  Future<void> updateTaskDeadline(String taskId, DateTime? deadline) async {
    final task = _storage.tasksBox.get(taskId);
    if (task == null) return;

    task.deadline = deadline;
    await task.save();
    notifyListeners();
  }

  /// Add a dependency to a task
  Future<void> addDependency(String taskId, String dependencyTaskId) async {
    final task = _storage.tasksBox.get(taskId);
    if (task == null) return;
    if (task.dependencies.contains(dependencyTaskId)) return;

    task.dependencies = [...task.dependencies, dependencyTaskId];
    await task.save();
    notifyListeners();
  }

  /// Remove a dependency from a task
  Future<void> removeDependency(String taskId, String dependencyTaskId) async {
    final task = _storage.tasksBox.get(taskId);
    if (task == null) return;

    task.dependencies = task.dependencies
        .where((id) => id != dependencyTaskId)
        .toList();
    await task.save();
    notifyListeners();
  }

  /// Get tasks that this task depends on
  List<Task> getDependencies(String taskId) {
    final task = _storage.tasksBox.get(taskId);
    if (task == null) return [];

    return task.dependencies
        .map((id) => _storage.tasksBox.get(id))
        .where((t) => t != null)
        .cast<Task>()
        .toList();
  }

  /// Get tasks that depend on this task
  List<Task> getDependents(String taskId) {
    return allTasks
        .where((task) => task.dependencies.contains(taskId))
        .toList();
  }

  /// Check if all dependencies of a task are completed
  bool areDependenciesComplete(String taskId) {
    final dependencies = getDependencies(taskId);
    return dependencies.every((task) => task.isCompleted);
  }

  /// Update task time estimate
  Future<void> updateTimeEstimate(String taskId, int? minutes) async {
    final task = _storage.tasksBox.get(taskId);
    if (task == null) return;

    task.timeEstimate = minutes;
    await task.save();
    notifyListeners();
  }

  // ========== Subtask Visualization Methods ==========

  /// Get all subtasks for tasks in a specific project
  List<({Subtask subtask, Task parentTask})> getSubtasksForProject(String projectId) {
    final projectTasks = getTasksByProject(projectId);
    final result = <({Subtask subtask, Task parentTask})>[];

    for (final task in projectTasks) {
      for (final subtask in task.subtasks) {
        result.add((subtask: subtask, parentTask: task));
      }
    }

    return result;
  }

  /// Get subtasks grouped by Kanban status for a project
  Map<KanbanStatus, List<({Subtask subtask, Task parentTask})>> getSubtasksByKanbanStatus(
    String projectId,
  ) {
    final subtasks = getSubtasksForProject(projectId);
    final Map<KanbanStatus, List<({Subtask subtask, Task parentTask})>> grouped = {
      for (var status in KanbanStatus.values) status: [],
    };

    for (final item in subtasks) {
      final status = item.subtask.kanbanStatus ?? KanbanStatus.backlog;
      grouped[status]!.add(item);
    }

    return grouped;
  }

  /// Get subtasks sorted by start date for Gantt chart
  List<({Subtask subtask, Task parentTask})> getSubtasksForGantt(String projectId) {
    final subtasks = getSubtasksForProject(projectId);
    subtasks.sort((a, b) =>
        a.subtask.effectiveStartDate.compareTo(b.subtask.effectiveStartDate));
    return subtasks;
  }

  /// Update a subtask's Kanban status
  Future<void> updateSubtaskKanbanStatus(
    String taskId,
    String subtaskId,
    KanbanStatus status,
  ) async {
    final task = _storage.tasksBox.get(taskId);
    if (task == null) return;

    final subtaskIndex = task.subtasks.indexWhere((s) => s.id == subtaskId);
    if (subtaskIndex == -1) return;

    final subtask = task.subtasks[subtaskIndex];
    subtask.kanbanStatus = status;

    // Auto-complete subtask when moved to 'done'
    if (status == KanbanStatus.done && !subtask.isCompleted) {
      subtask.isCompleted = true;
      subtask.completedAt = DateTime.now();
    } else if (status != KanbanStatus.done && subtask.isCompleted) {
      subtask.isCompleted = false;
      subtask.completedAt = null;
    }

    // Check if all subtasks are now complete
    if (task.allSubtasksCompleted && !task.isCompleted) {
      task.isCompleted = true;
      task.completedAt = DateTime.now();
    } else if (!task.allSubtasksCompleted && task.isCompleted) {
      task.isCompleted = false;
      task.completedAt = null;
    }

    await task.save();
    notifyListeners();
  }

  /// Update subtask visualization fields
  Future<void> updateSubtaskVisualization(
    String taskId,
    String subtaskId, {
    DateTime? startDate,
    DateTime? deadline,
    int? timeEstimate,
    Priority? priority,
    String? description,
  }) async {
    final task = _storage.tasksBox.get(taskId);
    if (task == null) return;

    final subtaskIndex = task.subtasks.indexWhere((s) => s.id == subtaskId);
    if (subtaskIndex == -1) return;

    final subtask = task.subtasks[subtaskIndex];
    if (startDate != null) subtask.startDate = startDate;
    if (deadline != null) subtask.deadline = deadline;
    if (timeEstimate != null) subtask.timeEstimate = timeEstimate;
    if (priority != null) subtask.priority = priority;
    if (description != null) subtask.description = description;

    await task.save();
    notifyListeners();
  }

  /// Create a new subtask with visualization fields
  Future<Subtask> createSubtaskWithDetails(
    String taskId, {
    required String title,
    String? description,
    DateTime? startDate,
    DateTime? deadline,
    int? timeEstimate,
    Priority? priority,
    KanbanStatus? kanbanStatus,
  }) async {
    final task = _storage.tasksBox.get(taskId);
    if (task == null) throw Exception('Task not found');

    final subtask = Subtask(
      id: _uuid.v4(),
      title: title,
      description: description,
      startDate: startDate,
      deadline: deadline,
      timeEstimate: timeEstimate,
      priority: priority,
      kanbanStatus: kanbanStatus ?? KanbanStatus.backlog,
    );

    task.subtasks = [...task.subtasks, subtask];
    await task.save();
    notifyListeners();

    return subtask;
  }

  /// Calculate total time estimate for all subtasks in a project
  int getProjectSubtaskTotalTime(String projectId) {
    final subtasks = getSubtasksForProject(projectId);
    return subtasks.fold<int>(
      0,
      (sum, item) => sum + (item.subtask.timeEstimate ?? 0),
    );
  }

  /// Calculate remaining time estimate for incomplete subtasks
  int getProjectSubtaskRemainingTime(String projectId) {
    final subtasks = getSubtasksForProject(projectId);
    return subtasks.fold<int>(
      0,
      (sum, item) => sum + item.subtask.remainingTimeEstimate,
    );
  }

  /// Get project completion based on subtasks
  double getProjectSubtaskCompletion(String projectId) {
    final subtasks = getSubtasksForProject(projectId);
    if (subtasks.isEmpty) return 0.0;

    final completed = subtasks.where((s) => s.subtask.isCompleted).length;
    return completed / subtasks.length;
  }

  // ========== SCHEDULING METHODS (formerly TimeBlockProvider) ==========

  /// Get all scheduled tasks
  List<Task> get scheduledTasks =>
      allTasks.where((task) => task.isScheduled).toList();

  /// Get all unscheduled tasks
  List<Task> get unscheduledTasks =>
      allTasks.where((task) => !task.isScheduled).toList();

  /// Schedule a task
  Future<void> scheduleTask({
    required String taskId,
    required DateTime start,
    required DateTime end,
    int? colorValue,
  }) async {
    final task = _storage.tasksBox.get(taskId);
    if (task == null) return;

    task.scheduledStart = start;
    task.scheduledEnd = end;
    task.scheduleColorValue = colorValue ?? _getTaskTypeColor(task.type);

    await task.save();
    notifyListeners();
  }

  /// Unschedule a task (remove scheduling)
  Future<void> unscheduleTask(String taskId) async {
    final task = _storage.tasksBox.get(taskId);
    if (task == null) return;

    task.scheduledStart = null;
    task.scheduledEnd = null;
    task.scheduleColorValue = null;

    await task.save();
    notifyListeners();
  }

  /// Reschedule a task (move to new time)
  Future<void> rescheduleTask({
    required String taskId,
    required DateTime newStart,
    DateTime? newEnd,
  }) async {
    final task = _storage.tasksBox.get(taskId);
    if (task == null) return;

    final duration = task.scheduledDurationMinutes ?? 60; // Default 1 hour
    task.scheduledStart = newStart;
    task.scheduledEnd = newEnd ?? newStart.add(Duration(minutes: duration));

    await task.save();
    notifyListeners();
  }

  /// Get scheduled tasks for a specific date
  List<Task> getScheduledTasksForDate(DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);
    return scheduledTasks.where((task) {
      final taskDate = DateTime(
        task.scheduledStart!.year,
        task.scheduledStart!.month,
        task.scheduledStart!.day,
      );
      return taskDate.isAtSameMomentAs(targetDate);
    }).toList()
      ..sort((a, b) => a.scheduledStart!.compareTo(b.scheduledStart!));
  }

  /// Get scheduled tasks for a date range
  List<Task> getScheduledTasksForDateRange(DateTime start, DateTime end) {
    return scheduledTasks.where((task) {
      return !task.scheduledStart!.isBefore(start) &&
          task.scheduledStart!.isBefore(end);
    }).toList()
      ..sort((a, b) => a.scheduledStart!.compareTo(b.scheduledStart!));
  }

  /// Get scheduled tasks for the current week
  List<Task> getScheduledTasksForWeek(DateTime date) {
    final monday = _getMonday(date);
    final sunday = monday.add(const Duration(days: 7));
    return getScheduledTasksForDateRange(monday, sunday);
  }

  /// Check if a task has scheduling conflicts with other tasks
  bool hasSchedulingConflicts(String taskId) {
    final task = _storage.tasksBox.get(taskId);
    if (task == null || !task.isScheduled) return false;

    final tasksOnSameDay = getScheduledTasksForDate(task.scheduledStart!);
    return tasksOnSameDay
        .where((other) => other.id != taskId)
        .any((other) => _tasksConflict(task, other));
  }

  /// Get tasks that conflict with the given task
  List<Task> getConflictingTasks(String taskId) {
    final task = _storage.tasksBox.get(taskId);
    if (task == null || !task.isScheduled) return [];

    final tasksOnSameDay = getScheduledTasksForDate(task.scheduledStart!);
    return tasksOnSameDay
        .where((other) => other.id != taskId && _tasksConflict(task, other))
        .toList();
  }

  /// Check if two tasks have conflicting schedules
  bool _tasksConflict(Task task1, Task task2) {
    if (!task1.isScheduled || !task2.isScheduled) return false;
    return task1.scheduledStart!.isBefore(task2.scheduledEnd!) &&
        task1.scheduledEnd!.isAfter(task2.scheduledStart!);
  }

  /// Check if a time slot has conflicts with existing scheduled tasks
  bool hasTimeSlotConflict({
    required DateTime start,
    required DateTime end,
    String? excludeTaskId,
  }) {
    final tasksOnDay = getScheduledTasksForDate(start);
    return tasksOnDay.where((task) {
      if (excludeTaskId != null && task.id == excludeTaskId) return false;
      return start.isBefore(task.scheduledEnd!) && end.isAfter(task.scheduledStart!);
    }).isNotEmpty;
  }

  /// Get tasks that conflict with a specific time slot
  List<Task> getTimeSlotConflicts({
    required DateTime start,
    required DateTime end,
    String? excludeTaskId,
  }) {
    final tasksOnDay = getScheduledTasksForDate(start);
    return tasksOnDay.where((task) {
      if (excludeTaskId != null && task.id == excludeTaskId) return false;
      return start.isBefore(task.scheduledEnd!) && end.isAfter(task.scheduledStart!);
    }).toList();
  }

  /// Find the next available time slot for a given duration
  DateTime? findNextAvailableSlot({
    required DateTime startingFrom,
    required int durationMinutes,
    int dayStartHour = 6,
    int dayEndHour = 23,
  }) {
    final date = DateTime(startingFrom.year, startingFrom.month, startingFrom.day);
    final tasksOnDay = getScheduledTasksForDate(date);

    if (tasksOnDay.isEmpty) {
      return DateTime(date.year, date.month, date.day, dayStartHour);
    }

    // Sort tasks by start time
    tasksOnDay.sort((a, b) => a.scheduledStart!.compareTo(b.scheduledStart!));

    // Check gap before first task
    final firstTaskStart = tasksOnDay.first.scheduledStart!;
    final dayStart = DateTime(date.year, date.month, date.day, dayStartHour);
    if (firstTaskStart.difference(dayStart).inMinutes >= durationMinutes) {
      return dayStart;
    }

    // Check gaps between tasks
    for (int i = 0; i < tasksOnDay.length - 1; i++) {
      final currentTaskEnd = tasksOnDay[i].scheduledEnd!;
      final nextTaskStart = tasksOnDay[i + 1].scheduledStart!;
      final gapMinutes = nextTaskStart.difference(currentTaskEnd).inMinutes;

      if (gapMinutes >= durationMinutes) {
        return currentTaskEnd;
      }
    }

    // Check gap after last task
    final lastTaskEnd = tasksOnDay.last.scheduledEnd!;
    final dayEnd = DateTime(date.year, date.month, date.day, dayEndHour);
    if (dayEnd.difference(lastTaskEnd).inMinutes >= durationMinutes) {
      return lastTaskEnd;
    }

    return null; // No available slot found
  }

  /// Get total scheduled time for a date (in minutes)
  int getTotalScheduledTime(DateTime date) {
    final tasks = getScheduledTasksForDate(date);
    return tasks.fold(0, (sum, task) => sum + (task.scheduledDurationMinutes ?? 0));
  }

  /// Get completed scheduled time for a date (in minutes)
  int getCompletedScheduledTime(DateTime date) {
    final tasks = getScheduledTasksForDate(date);
    return tasks
        .where((task) => task.isCompleted)
        .fold(0, (sum, task) => sum + (task.scheduledDurationMinutes ?? 0));
  }

  /// Get schedule completion percentage for a date
  double getScheduleCompletionPercentage(DateTime date) {
    final total = getTotalScheduledTime(date);
    if (total == 0) return 0.0;
    return getCompletedScheduledTime(date) / total;
  }

  /// Get default color for a task type
  int _getTaskTypeColor(TaskType type) {
    return switch (type) {
      TaskType.distraction => 0xFFE57373, // Red
      TaskType.practice => 0xFF64B5F6,    // Blue
      TaskType.goal => 0xFF81C784,        // Green
    };
  }

  /// Get Monday of the week containing the given date
  DateTime _getMonday(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  /// Create a task with scheduling in one step
  Future<Task> createScheduledTask({
    required String name,
    required String description,
    required TaskType type,
    required DateTime scheduledStart,
    required DateTime scheduledEnd,
    int? scheduleColorValue,
    Priority priority = Priority.medium,
    Category? category,
    int? timeEstimate,
    DateTime? deadline,
  }) async {
    final task = Task(
      id: _uuid.v4(),
      name: name,
      description: description,
      type: type,
      priority: priority,
      category: category,
      timeEstimate: timeEstimate ?? scheduledEnd.difference(scheduledStart).inMinutes,
      deadline: deadline,
      scheduledStart: scheduledStart,
      scheduledEnd: scheduledEnd,
      scheduleColorValue: scheduleColorValue ?? _getTaskTypeColor(type),
    );

    await addTask(task);
    return task;
  }
}
