/// Gesture mode state for the continuous timeline
/// Provides clear gesture priority and prevents conflicts
enum TimelineGestureMode {
  /// No active gesture - idle state
  idle,

  /// Single-finger scrolling the timeline
  scrolling,

  /// Two-finger pinch-to-zoom
  zooming,

  /// Dragging a timeblock to new position
  draggingBlock,
}

/// Extension to check gesture priority
extension TimelineGestureModeExtension on TimelineGestureMode {
  /// Higher priority gestures can interrupt lower priority ones
  int get priority {
    return switch (this) {
      TimelineGestureMode.zooming => 3,       // Highest - two-finger gestures take precedence
      TimelineGestureMode.draggingBlock => 2, // Medium - block manipulation is important
      TimelineGestureMode.scrolling => 1,     // Low - scrolling is default behavior
      TimelineGestureMode.idle => 0,          // No gesture active
    };
  }

  /// Can this gesture mode be interrupted by another?
  bool canBeInterruptedBy(TimelineGestureMode other) {
    return other.priority > priority;
  }

  /// Description for debugging
  String get description {
    return switch (this) {
      TimelineGestureMode.idle => 'Idle',
      TimelineGestureMode.scrolling => 'Scrolling timeline',
      TimelineGestureMode.zooming => 'Pinch-to-zoom',
      TimelineGestureMode.draggingBlock => 'Dragging timeblock',
    };
  }
}
