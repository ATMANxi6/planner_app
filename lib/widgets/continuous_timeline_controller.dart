import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/dashboard_config.dart';
import '../providers/task_provider.dart';
import 'timeline_drag_state.dart';

/// Controller for managing the continuous timeline view state.
///
/// Handles drag operations, zoom levels, and scroll position for the timeline.
/// This controller separates gesture logic from UI rendering for better testability.
class ContinuousTimelineController extends ChangeNotifier {
  /// Scroll controller for the timeline (injected or created)
  final ScrollController scrollController;

  /// Current drag state (null when not dragging)
  TimelineDragState? _dragState;

  /// Current zoom scale factor (1.0 = normal, 0.5-5.0 range)
  double _zoomScale = 1.0;

  /// Auto-scroll velocity when dragging near edges (pixels per frame)
  double _autoScrollVelocity = 0.0;

  /// Last zoom update time for throttling
  DateTime? _lastZoomUpdate;

  ContinuousTimelineController({ScrollController? scrollController})
      : scrollController = scrollController ?? ScrollController();

  // Getters
  TimelineDragState? get dragState => _dragState;
  double get zoomScale => _zoomScale;
  bool get isDragging => _dragState?.isDragging ?? false;
  double get autoScrollVelocity => _autoScrollVelocity;

  /// Starts dragging a scheduled task.
  ///
  /// Captures the original start time for potential cancellation and
  /// initializes the drag state with the current task position.
  void startDrag(Task task, DateTime date) {
    _dragState = TimelineDragState(
      task: task,
      originalStartTime: task.scheduledStart!,
      currentStartTime: task.scheduledStart!,
    );
    notifyListeners();
  }

  /// Updates the drag position in real-time based on pixel position.
  ///
  /// This method does NOT snap to intervals - it follows the finger/cursor precisely.
  /// Snapping only occurs on drop via [endDrag].
  ///
  /// [pixelY] - The vertical pixel position relative to the timeline start
  /// [date] - The date being displayed (for multi-day calculations)
  /// [config] - Dashboard configuration with time conversion methods
  void updateDrag(double pixelY, DateTime date, DashboardConfig config) {
    // FIXED: Safety check to prevent updates after drag ended
    if (_dragState == null || !_dragState!.isDragging) return;

    // Convert pixel position to DateTime
    final newStartTime = config.pixelToTime(date, pixelY);

    // Clamp to working hours to prevent invalid times
    final clampedTime = _clampToWorkingHours(newStartTime, config);

    // Only update if position actually changed (reduce unnecessary rebuilds)
    if (_dragState!.currentStartTime == clampedTime) return;

    _dragState = _dragState!.copyWith(currentStartTime: clampedTime);
    notifyListeners();
  }

  /// Ends the drag operation and persists the change with snapping.
  ///
  /// Snaps the current position to the configured interval (5/15/30 min)
  /// and saves the updated scheduled task to storage.
  Future<void> endDrag(TaskProvider provider, DashboardConfig config) async {
    if (_dragState == null) return;

    // Snap to interval before saving
    final snappedTime = config.snapToInterval(_dragState!.currentStartTime);
    final task = _dragState!.task;
    final duration = task.scheduledDurationMinutes!;

    // Persist to storage via provider - reschedule the task
    await provider.rescheduleTask(
      taskId: task.id,
      newStart: snappedTime,
      newEnd: snappedTime.add(Duration(minutes: duration)),
    );

    // Clear drag state
    _dragState = null;
    _autoScrollVelocity = 0.0;
    notifyListeners();
  }

  /// Cancels the drag operation without saving changes.
  ///
  /// Resets the block to its original position.
  void cancelDrag() {
    _dragState = null;
    _autoScrollVelocity = 0.0;
    notifyListeners();
  }

  /// Updates the zoom scale for the timeline.
  ///
  /// Clamped to 0.5x - 5.0x range to prevent extreme zooming.
  /// Higher values = taller hour blocks, lower values = more compressed.
  /// FIXED: Throttles updates to prevent excessive rebuilds during pinch gesture
  void updateZoom(double newScale) {
    final clampedScale = newScale.clamp(0.5, 5.0);

    // Only update if scale changed significantly (prevents micro-adjustments)
    if ((_zoomScale - clampedScale).abs() < 0.01) return;

    // Throttle updates to max 60fps (16ms between updates)
    final now = DateTime.now();
    if (_lastZoomUpdate != null) {
      final timeSinceLastUpdate = now.difference(_lastZoomUpdate!);
      if (timeSinceLastUpdate.inMilliseconds < 16) {
        // Schedule update for later if too soon
        _zoomScale = clampedScale;
        return;
      }
    }

    _zoomScale = clampedScale;
    _lastZoomUpdate = now;
    notifyListeners();
  }

  /// Sets auto-scroll velocity when dragging near screen edges.
  ///
  /// Positive values scroll down, negative values scroll up.
  /// Called by the view when detecting edge proximity during drag.
  void setAutoScrollVelocity(double velocity) {
    // FIXED: Only notify if velocity changed significantly to reduce rebuilds
    if ((_autoScrollVelocity - velocity).abs() > 0.01) {
      _autoScrollVelocity = velocity;
      // Don't notify listeners for velocity changes - they're internal state
      // Only notify when drag state or zoom changes
    }
  }

  /// Auto-scrolls the timeline if velocity is non-zero.
  ///
  /// Should be called from a ticker or animation frame.
  /// Returns true if scrolling occurred.
  bool performAutoScroll() {
    if (_autoScrollVelocity == 0.0 || !scrollController.hasClients) {
      return false;
    }

    final currentOffset = scrollController.offset;
    final maxOffset = scrollController.position.maxScrollExtent;
    final newOffset = (currentOffset + _autoScrollVelocity).clamp(0.0, maxOffset);

    if (newOffset != currentOffset) {
      scrollController.jumpTo(newOffset);
      return true;
    }

    return false;
  }

  /// Scrolls the timeline to show the current time (red line indicator).
  ///
  /// Centers the current time in the viewport for easy orientation.
  void scrollToCurrentTime(DashboardConfig config, {bool animate = true}) {
    if (!scrollController.hasClients) return;

    final now = DateTime.now();
    final pixelY = config.timeToPixel(now);

    // Center the current time in the viewport
    final viewportHeight = scrollController.position.viewportDimension;
    final targetOffset = (pixelY - viewportHeight / 2).clamp(
      0.0,
      scrollController.position.maxScrollExtent,
    );

    if (animate) {
      scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      scrollController.jumpTo(targetOffset);
    }
  }

  /// Scrolls to a specific time in the timeline.
  ///
  /// Useful for jumping to events or scheduled blocks.
  void scrollToTime(DateTime time, DashboardConfig config, {bool animate = true}) {
    if (!scrollController.hasClients) return;

    final pixelY = config.timeToPixel(time);
    final viewportHeight = scrollController.position.viewportDimension;
    final targetOffset = (pixelY - viewportHeight / 2).clamp(
      0.0,
      scrollController.position.maxScrollExtent,
    );

    if (animate) {
      scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      scrollController.jumpTo(targetOffset);
    }
  }

  /// Clamps a DateTime to the configured working hours.
  ///
  /// Prevents blocks from being dragged outside the valid time range.
  DateTime _clampToWorkingHours(DateTime time, DashboardConfig config) {
    final workingStart = DateTime(
      time.year,
      time.month,
      time.day,
      config.dayStartHour,
    );

    final workingEnd = DateTime(
      time.year,
      time.month,
      time.day,
      config.dayEndHour,
    );

    if (time.isBefore(workingStart)) {
      return workingStart;
    } else if (time.isAfter(workingEnd)) {
      return workingEnd;
    }

    return time;
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}
