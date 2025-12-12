import 'package:hive/hive.dart';

part 'dashboard_config.g.dart';

/// Time slot interval options for time blocking
@HiveType(typeId: 13)
enum TimeSlotInterval {
  @HiveField(0)
  fifteenMinutes,
  @HiveField(1)
  thirtyMinutes,
  @HiveField(2)
  sixtyMinutes,
}

extension TimeSlotIntervalExtension on TimeSlotInterval {
  int get minutes {
    return switch (this) {
      TimeSlotInterval.fifteenMinutes => 15,
      TimeSlotInterval.thirtyMinutes => 30,
      TimeSlotInterval.sixtyMinutes => 60,
    };
  }

  String get displayName {
    return switch (this) {
      TimeSlotInterval.fifteenMinutes => '15 minutes',
      TimeSlotInterval.thirtyMinutes => '30 minutes',
      TimeSlotInterval.sixtyMinutes => '1 hour',
    };
  }
}

/// Dashboard configuration and user preferences
@HiveType(typeId: 14)
class DashboardConfig extends HiveObject {
  @HiveField(0)
  TimeSlotInterval timeSlotInterval;

  @HiveField(1)
  int dayStartHour; // e.g., 6 for 6 AM

  @HiveField(2)
  int dayEndHour; // e.g., 23 for 11 PM

  // HiveField(3) removed - was showTimeBlockWidget

  @HiveField(4)
  bool showDailyTasksWidget;

  @HiveField(5)
  bool showStatsWidget;

  @HiveField(6)
  bool showStreaksWidget;

  @HiveField(7)
  bool showProjectsWidget;

  @HiveField(8)
  bool showDeadlinesWidget;

  @HiveField(9)
  bool defaultToWeeklyView; // false = daily view, true = weekly view

  @HiveField(10)
  final DateTime createdAt;

  @HiveField(11)
  DateTime? updatedAt;

  @HiveField(12)
  List<String> widgetOrder; // Order of widgets: 'time_block', 'daily_tasks', 'stats', 'streaks', 'projects', 'deadlines'

  @HiveField(13)
  double hourHeight; // Pixels per hour for continuous timeline (default: 60.0, range: 30-300)

  @HiveField(14)
  int snapIntervalMinutes; // Snap precision when dropping blocks (5, 15, 30 minutes)

  @HiveField(15)
  bool showGoalProgressWidget; // Show goal progress with supporting practices

  @HiveField(16)
  bool showFocusModeWidget; // Show current/next time block for immediate focus

  @HiveField(17)
  bool showQuickWinsWidget; // Show easiest tasks first for quick momentum

  @HiveField(18)
  bool showCanvasProgressWidget; // Show Planning Canvas progress overview

  @HiveField(19)
  bool defaultToCanvasView; // false = list view, true = canvas view (for Planning Canvas screen)

  DashboardConfig({
    this.timeSlotInterval = TimeSlotInterval.thirtyMinutes,
    this.dayStartHour = 6,
    this.dayEndHour = 23,
    this.showDailyTasksWidget = true,
    this.showStatsWidget = true,
    this.showStreaksWidget = true,
    this.showProjectsWidget = true,
    this.showDeadlinesWidget = true,
    this.showGoalProgressWidget = true,
    this.showFocusModeWidget = true,
    this.showQuickWinsWidget = true,
    this.showCanvasProgressWidget = true,
    this.defaultToWeeklyView = false,
    this.defaultToCanvasView = false,
    DateTime? createdAt,
    this.updatedAt,
    List<String>? widgetOrder,
    this.hourHeight = 60.0,
    this.snapIntervalMinutes = 5,
  }) : createdAt = createdAt ?? DateTime.now(),
       widgetOrder = widgetOrder ?? ['focus_mode', 'quick_wins', 'canvas_progress', 'daily_tasks', 'goal_progress', 'stats', 'streaks', 'projects', 'deadlines'];

  /// Total hours displayed in the timeline
  int get totalHours => dayEndHour - dayStartHour;

  /// Total time slots in a day based on the interval
  int get slotsPerDay {
    return (totalHours * 60) ~/ timeSlotInterval.minutes;
  }

  /// Pixels per minute for continuous timeline positioning
  double get pixelsPerMinute => hourHeight / 60.0;

  /// Total height of the timeline in pixels
  double get totalTimelineHeight => totalHours * hourHeight;

  /// Get the DateTime for a specific slot index on a given date
  DateTime getSlotStartTime(DateTime date, int slotIndex) {
    final minutesFromStart = slotIndex * timeSlotInterval.minutes;
    return DateTime(
      date.year,
      date.month,
      date.day,
      dayStartHour,
    ).add(Duration(minutes: minutesFromStart));
  }

  /// Get the slot index for a given time
  int? getSlotIndex(DateTime time) {
    // Calculate total minutes from start of day
    final minutesFromStart = (time.hour - dayStartHour) * 60 + time.minute;

    // Check if time is before working hours
    if (minutesFromStart < 0) {
      return null;
    }

    // Check if time is at or after end of working hours
    final workingMinutes = (dayEndHour - dayStartHour) * 60;
    if (minutesFromStart >= workingMinutes) {
      return null;
    }

    return minutesFromStart ~/ timeSlotInterval.minutes;
  }

  /// Snap a DateTime to the nearest slot boundary
  DateTime snapToSlot(DateTime time) {
    final slotIndex = getSlotIndex(time);
    if (slotIndex == null) {
      // If outside range, return closest boundary
      if (time.hour < dayStartHour) {
        return DateTime(time.year, time.month, time.day, dayStartHour);
      } else {
        return DateTime(time.year, time.month, time.day, dayEndHour);
      }
    }
    return getSlotStartTime(time, slotIndex);
  }

  /// Convert pixel Y position to DateTime (for continuous timeline)
  DateTime pixelToTime(DateTime date, double pixelY) {
    final minutesFromDayStart = (pixelY / pixelsPerMinute).round();
    return DateTime(
      date.year,
      date.month,
      date.day,
      dayStartHour,
    ).add(Duration(minutes: minutesFromDayStart));
  }

  /// Convert DateTime to pixel Y position (for continuous timeline)
  double timeToPixel(DateTime time) {
    final minutesFromDayStart = (time.hour - dayStartHour) * 60 + time.minute;
    return minutesFromDayStart * pixelsPerMinute;
  }

  /// Snap DateTime to the nearest interval (for continuous timeline drops)
  /// BUGFIX #2: Snaps relative to dayStartHour instead of midnight
  /// This ensures blocks align with the visual grid shown in the timeline
  DateTime snapToInterval(DateTime time) {
    // Calculate base time (start of working day)
    final dayStart = DateTime(time.year, time.month, time.day, dayStartHour);

    // Get minutes from day start (not midnight!)
    final minutesFromDayStart = time.difference(dayStart).inMinutes;

    // Snap to nearest interval relative to day start
    final snappedMinutes = (minutesFromDayStart / snapIntervalMinutes).round() * snapIntervalMinutes;

    // Return snapped time
    return dayStart.add(Duration(minutes: snappedMinutes));
  }

  /// Clamp time to working hours (prevent out-of-bounds times)
  DateTime clampToWorkingHours(DateTime time) {
    final startOfDay = DateTime(time.year, time.month, time.day, dayStartHour);
    final endOfDay = DateTime(time.year, time.month, time.day, dayEndHour);

    if (time.isBefore(startOfDay)) return startOfDay;
    if (time.isAfter(endOfDay)) return endOfDay;
    return time;
  }

  /// Update configuration and mark as modified
  void update({
    TimeSlotInterval? timeSlotInterval,
    int? dayStartHour,
    int? dayEndHour,
    bool? showDailyTasksWidget,
    bool? showStatsWidget,
    bool? showStreaksWidget,
    bool? showProjectsWidget,
    bool? showDeadlinesWidget,
    bool? showGoalProgressWidget,
    bool? showFocusModeWidget,
    bool? showQuickWinsWidget,
    bool? showCanvasProgressWidget,
    bool? defaultToWeeklyView,
    bool? defaultToCanvasView,
    List<String>? widgetOrder,
    double? hourHeight,
    int? snapIntervalMinutes,
  }) {
    if (timeSlotInterval != null) this.timeSlotInterval = timeSlotInterval;
    if (dayStartHour != null) this.dayStartHour = dayStartHour;
    if (dayEndHour != null) this.dayEndHour = dayEndHour;
    if (showDailyTasksWidget != null) this.showDailyTasksWidget = showDailyTasksWidget;
    if (showStatsWidget != null) this.showStatsWidget = showStatsWidget;
    if (showStreaksWidget != null) this.showStreaksWidget = showStreaksWidget;
    if (showProjectsWidget != null) this.showProjectsWidget = showProjectsWidget;
    if (showDeadlinesWidget != null) this.showDeadlinesWidget = showDeadlinesWidget;
    if (showGoalProgressWidget != null) this.showGoalProgressWidget = showGoalProgressWidget;
    if (showFocusModeWidget != null) this.showFocusModeWidget = showFocusModeWidget;
    if (showQuickWinsWidget != null) this.showQuickWinsWidget = showQuickWinsWidget;
    if (showCanvasProgressWidget != null) this.showCanvasProgressWidget = showCanvasProgressWidget;
    if (defaultToWeeklyView != null) this.defaultToWeeklyView = defaultToWeeklyView;
    if (defaultToCanvasView != null) this.defaultToCanvasView = defaultToCanvasView;
    if (widgetOrder != null) this.widgetOrder = widgetOrder;
    if (hourHeight != null) this.hourHeight = hourHeight.clamp(30.0, 300.0);
    if (snapIntervalMinutes != null) this.snapIntervalMinutes = snapIntervalMinutes;

    updatedAt = DateTime.now();
    save();
  }

  /// Reorder widget in the dashboard
  void reorderWidget(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = widgetOrder.removeAt(oldIndex);
    widgetOrder.insert(newIndex, item);
    updatedAt = DateTime.now();
    save();
  }

  /// Create default configuration
  factory DashboardConfig.defaultConfig() {
    return DashboardConfig();
  }
}
