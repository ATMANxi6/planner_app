import '../models/task.dart';

/// Represents the state of a scheduled task during a drag operation.
///
/// This immutable state object tracks the original position, current position,
/// and drag status of a scheduled task being manipulated in the continuous timeline.
class TimelineDragState {
  /// The scheduled task being dragged
  final Task task;

  /// The original start time before drag began (for cancellation)
  final DateTime originalStartTime;

  /// The current start time during drag (updated continuously, no snapping)
  final DateTime currentStartTime;

  /// Whether the task is currently being dragged
  final bool isDragging;

  TimelineDragState({
    required this.task,
    required this.originalStartTime,
    required this.currentStartTime,
    this.isDragging = true,
  });

  /// Creates a copy with updated fields (immutable pattern)
  TimelineDragState copyWith({
    DateTime? currentStartTime,
    bool? isDragging,
  }) {
    return TimelineDragState(
      task: task,
      originalStartTime: originalStartTime,
      currentStartTime: currentStartTime ?? this.currentStartTime,
      isDragging: isDragging ?? this.isDragging,
    );
  }

  /// Calculates the duration of the scheduled task in minutes
  int get durationMinutes => task.scheduledDurationMinutes!;

  /// Calculates the current end time based on current start time and duration
  DateTime get currentEndTime => currentStartTime.add(Duration(minutes: durationMinutes));
}
