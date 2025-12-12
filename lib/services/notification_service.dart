import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/task.dart';
import '../services/storage_service.dart';

/// Service for managing local notifications for task reminders
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final fln.FlutterLocalNotificationsPlugin _notifications = fln.FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone database
    tz.initializeTimeZones();

    // Android initialization settings
    const androidSettings = fln.AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const iosSettings = fln.DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = fln.InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize with settings
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  /// Request notification permissions (required for iOS, optional for Android)
  Future<bool> requestPermissions() async {
    if (!_initialized) await initialize();

    // Android 13+ requires permission
    final androidImplementation = _notifications.resolvePlatformSpecificImplementation<
        fln.AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    // iOS permissions
    final iosImplementation = _notifications.resolvePlatformSpecificImplementation<
        fln.IOSFlutterLocalNotificationsPlugin>();

    if (iosImplementation != null) {
      final granted = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  /// Schedule a notification for a task reminder
  Future<void> scheduleTaskReminder(Task task) async {
    if (!_initialized) await initialize();
    if (task.reminderTime == null) return;

    // Cancel any existing notification for this task
    await cancelTaskReminder(task.id);

    // Don't schedule if reminder time is in the past
    if (task.reminderTime!.isBefore(DateTime.now())) return;

    final notificationId = task.id.hashCode;
    final scheduledDate = tz.TZDateTime.from(task.reminderTime!, tz.local);

    // Notification details
    final androidDetails = fln.AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      channelDescription: 'Notifications for task reminders',
      importance: fln.Importance.high,
      priority: fln.Priority.high,
      showWhen: true,
    );

    const iosDetails = fln.DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = fln.NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule the notification
    await _notifications.zonedSchedule(
      notificationId,
      _getNotificationTitle(task),
      _getNotificationBody(task),
      scheduledDate,
      notificationDetails,
      androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          fln.UILocalNotificationDateInterpretation.absoluteTime,
      payload: task.id,
    );
  }

  /// Cancel a task reminder notification
  Future<void> cancelTaskReminder(String taskId) async {
    if (!_initialized) await initialize();
    final notificationId = taskId.hashCode;
    await _notifications.cancel(notificationId);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    if (!_initialized) await initialize();
    await _notifications.cancelAll();
  }

  /// Get all pending notifications
  Future<List<fln.PendingNotificationRequest>> getPendingNotifications() async {
    if (!_initialized) await initialize();
    return await _notifications.pendingNotificationRequests();
  }

  /// Show an immediate notification (for testing or instant reminders)
  Future<void> showInstantNotification(Task task) async {
    if (!_initialized) await initialize();

    final notificationId = task.id.hashCode;

    final androidDetails = fln.AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      channelDescription: 'Notifications for task reminders',
      importance: fln.Importance.high,
      priority: fln.Priority.high,
      showWhen: true,
    );

    const iosDetails = fln.DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = fln.NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      notificationId,
      _getNotificationTitle(task),
      _getNotificationBody(task),
      notificationDetails,
      payload: task.id,
    );
  }

  /// Generate notification title based on task type
  String _getNotificationTitle(Task task) {
    return switch (task.type) {
      TaskType.distraction => '🚫 Avoid: ${task.name}',
      TaskType.practice => '💪 Practice: ${task.name}',
      TaskType.goal => '🎯 Goal: ${task.name}',
    };
  }

  /// Generate notification body with task details and goal context
  String _getNotificationBody(Task task) {
    final parts = <String>[];

    // Add goal context for practices (Smart Habit Builder connection)
    if (task.type == TaskType.practice && task.supportingGoals.isNotEmpty) {
      final storage = StorageService();
      final goals = task.supportingGoals
          .map((goalId) => storage.tasksBox.get(goalId))
          .whereType<Task>()
          .take(2) // Show max 2 goals to avoid long notification
          .toList();

      if (goals.isNotEmpty) {
        final goalNames = goals.map((g) => g.name).join(', ');
        parts.add('💡 Supports: $goalNames');
      }
    }

    // Add streak context for practices and distractions
    if (task.type == TaskType.practice && task.streakCount > 0) {
      parts.add('🔥 ${task.streakCount}-day streak');
    } else if (task.type == TaskType.distraction && task.streakCount > 0) {
      parts.add('✅ ${task.streakCount} days avoided');
    }

    if (task.description.isNotEmpty) {
      parts.add(task.description);
    }

    if (task.scheduledStart != null) {
      final time = task.formattedScheduledTime;
      parts.add('Scheduled: $time');
    }

    if (task.timeEstimate != null) {
      final hours = task.timeEstimate! ~/ 60;
      final minutes = task.timeEstimate! % 60;
      if (hours > 0) {
        parts.add('Duration: ${hours}h ${minutes}m');
      } else {
        parts.add('Duration: ${minutes}m');
      }
    }

    return parts.isEmpty ? 'Tap to view details' : parts.join(' • ');
  }

  // ========== Intelligent Notifications ==========

  /// Schedule a streak protection notification (before end of day)
  /// Reminds users to complete practices before losing their streak
  Future<void> scheduleStreakProtectionNotification(Task task, {int hoursBeforeEOD = 2}) async {
    if (!_initialized) await initialize();
    if (task.type != TaskType.practice && task.type != TaskType.distraction) return;
    if (task.streakCount == 0) return; // No streak to protect
    if (task.isCompleted) return; // Already completed

    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 22, 0); // 10 PM
    final notificationTime = endOfDay.subtract(Duration(hours: hoursBeforeEOD));

    // Only schedule if notification time is in the future
    if (notificationTime.isBefore(now)) return;

    final notificationId = '${task.id}_streak'.hashCode;
    final scheduledDate = tz.TZDateTime.from(notificationTime, tz.local);

    // Loss aversion messaging
    final title = task.type == TaskType.practice
        ? '🔥 Don\'t break your ${task.streakCount}-day streak!'
        : '✅ Keep your ${task.streakCount}-day avoidance going!';

    final body = task.type == TaskType.practice
        ? 'Complete "${task.name}" before end of day'
        : 'Stay strong! Avoid "${task.name}" today';

    final androidDetails = fln.AndroidNotificationDetails(
      'streak_protection',
      'Streak Protection',
      channelDescription: 'Reminders to maintain your streaks',
      importance: fln.Importance.high,
      priority: fln.Priority.high,
      showWhen: true,
    );

    const iosDetails = fln.DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = fln.NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      notificationId,
      title,
      body,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          fln.UILocalNotificationDateInterpretation.absoluteTime,
      payload: task.id,
    );
  }

  /// Show celebration notification for milestone achievements
  Future<void> showCelebrationNotification({
    required String title,
    required String body,
    String? taskId,
  }) async {
    if (!_initialized) await initialize();

    final notificationId = '${taskId ?? "celebration"}_${DateTime.now().millisecondsSinceEpoch}'.hashCode;

    final androidDetails = fln.AndroidNotificationDetails(
      'celebrations',
      'Celebrations',
      channelDescription: 'Achievement and milestone celebrations',
      importance: fln.Importance.max,
      priority: fln.Priority.max,
      showWhen: true,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = fln.DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = fln.NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      notificationId,
      title,
      body,
      notificationDetails,
      payload: taskId,
    );
  }

  /// Schedule morning motivation notification
  Future<void> scheduleMorningMotivation() async {
    if (!_initialized) await initialize();

    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final morningTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 8, 0); // 8 AM
    final scheduledDate = tz.TZDateTime.from(morningTime, tz.local);

    // Get practices count
    final storage = StorageService();
    final practices = storage.tasksBox.values
        .where((task) => task.type == TaskType.practice && !task.isCompleted)
        .toList();

    if (practices.isEmpty) return;

    final notificationId = 'morning_motivation'.hashCode;

    final title = '☀️ Good Morning!';
    final body = 'You have ${practices.length} practice${practices.length == 1 ? "" : "s"} to build today. Let\'s make it count!';

    final androidDetails = fln.AndroidNotificationDetails(
      'daily_motivation',
      'Daily Motivation',
      channelDescription: 'Morning and evening motivational messages',
      importance: fln.Importance.defaultImportance,
      priority: fln.Priority.defaultPriority,
      showWhen: true,
    );

    const iosDetails = fln.DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = fln.NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      notificationId,
      title,
      body,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          fln.UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Schedule evening review notification
  Future<void> scheduleEveningReview() async {
    if (!_initialized) await initialize();

    final now = DateTime.now();
    final eveningTime = DateTime(now.year, now.month, now.day, 20, 0); // 8 PM

    // Only schedule if evening time is in the future
    if (eveningTime.isBefore(now)) return;

    final scheduledDate = tz.TZDateTime.from(eveningTime, tz.local);

    // Get completion stats
    final storage = StorageService();
    final allTasks = storage.tasksBox.values.toList();
    final completedToday = allTasks.where((task) => task.isCompleted).length;

    final notificationId = 'evening_review'.hashCode;

    final title = '🌙 Evening Review';
    final body = completedToday > 0
        ? 'Great job! You completed $completedToday task${completedToday == 1 ? "" : "s"} today. 🎉'
        : 'How did your day go? Review your progress and plan for tomorrow.';

    final androidDetails = fln.AndroidNotificationDetails(
      'daily_motivation',
      'Daily Motivation',
      channelDescription: 'Morning and evening motivational messages',
      importance: fln.Importance.defaultImportance,
      priority: fln.Priority.defaultPriority,
      showWhen: true,
    );

    const iosDetails = fln.DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = fln.NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      notificationId,
      title,
      body,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          fln.UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Handle notification tap
  void _onNotificationTapped(fln.NotificationResponse response) {
    // Payload contains the task ID
    final taskId = response.payload;
    if (taskId != null) {
      // TODO: Navigate to task details
      // This will be handled by the main app navigation
      debugPrint('📬 Notification tapped for task: $taskId');
    }
  }
}
