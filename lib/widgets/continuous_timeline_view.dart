import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/task.dart';
import '../models/dashboard_config.dart';
import '../providers/task_provider.dart';
import '../services/storage_service.dart';
import 'continuous_timeline_controller.dart';
import 'timeline_grid_painter.dart';
import 'timeline_drag_state.dart';
import 'timeline_gesture_mode.dart';

/// Google Calendar-style continuous timeline with smooth dragging and pinch-to-zoom.
///
/// Features:
/// - Pixel-precise drag positioning (no snapping during drag)
/// - Snap-to-interval only on drop
/// - Pinch-to-zoom gesture support
/// - Auto-scroll when dragging near edges
/// - Visual feedback with floating time labels
/// - Haptic feedback on drag start/end
class ContinuousTimelineView extends StatefulWidget {
  /// Initial date to display (defaults to today)
  final DateTime? initialDate;

  /// Callback when user wants to toggle to list view
  final VoidCallback? onViewModeToggle;

  const ContinuousTimelineView({
    super.key,
    this.initialDate,
    this.onViewModeToggle,
  });

  @override
  State<ContinuousTimelineView> createState() => _ContinuousTimelineViewState();
}

class _ContinuousTimelineViewState extends State<ContinuousTimelineView>
    with TickerProviderStateMixin {
  late DateTime _selectedDate;
  late ContinuousTimelineController _controller;

  // Base hour height before zoom is applied
  static const double _baseHourHeight = 60.0;

  // Auto-scroll configuration
  Timer? _autoScrollTimer;
  static const double _edgeScrollThreshold = 80.0; // Pixels from edge
  static const double _maxScrollSpeed = 10.0; // Pixels per frame

  // Zoom gesture state
  double _initialZoomScale = 1.0;
  bool _isZooming = false;
  int _pointerCount = 0; // Track number of active pointers for gesture detection

  // Manual scrolling state (for when GestureDetector consumes events)
  Offset? _lastScrollFocalPoint;

  // Dynamic header height measurement (unified header)
  final GlobalKey _headerKey = GlobalKey();
  double _cachedHeaderHeight = 0.0;

  // Standardized gesture system - prevents conflicts and stuck states
  TimelineGestureMode _gestureMode = TimelineGestureMode.idle;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _controller = ContinuousTimelineController();

    // Scroll to current time after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureHeaderHeights(); // Measure header heights dynamically
      final storage = context.read<StorageService>();
      final config = storage.dashboardConfigBox.get('config') ?? DashboardConfig.defaultConfig();
      _controller.scrollToCurrentTime(config, animate: false);
    });
  }

  /// Measures actual unified header height dynamically
  void _measureHeaderHeights() {
    final headerBox = _headerKey.currentContext?.findRenderObject() as RenderBox?;

    if (headerBox != null) {
      _cachedHeaderHeight = headerBox.size.height;
    }
  }

  /// Gets total header height (unified header)
  double get _totalHeaderHeight => _cachedHeaderHeight;

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      // FIXED: Added Consumer for ContinuousTimelineController to detect drag state changes
      child: Consumer<ContinuousTimelineController>(
        builder: (context, controller, child) {
          return Consumer2<StorageService, TaskProvider>(
            builder: (context, storage, taskProvider, child) {
              final config = _getZoomedConfig(storage.dashboardConfigBox.get('config') ?? DashboardConfig.defaultConfig());
              final scheduledTasks = taskProvider.getScheduledTasksForDate(_selectedDate);

              return Column(
                children: [
                  _buildUnifiedHeader(config, taskProvider),
                  Expanded(
                    child: Listener(
                      onPointerDown: (_) => setState(() => _pointerCount++),
                      onPointerUp: (_) => setState(() => _pointerCount = (_pointerCount - 1).clamp(0, 10)),
                      onPointerCancel: (_) => setState(() => _pointerCount = (_pointerCount - 1).clamp(0, 10)),
                      child: GestureDetector(
                        onScaleStart: _handleUnifiedGestureStart,
                        onScaleUpdate: (details) => _handleUnifiedGestureUpdate(details, config, taskProvider),
                        onScaleEnd: (details) => _handleUnifiedGestureEnd(details, config, taskProvider),
                        child: SingleChildScrollView(
                          controller: _controller.scrollController,
                          // Always disable built-in scrolling - we handle it manually in unified system
                          physics: const NeverScrollableScrollPhysics(),
                          child: _buildTimeline(config, scheduledTasks, taskProvider),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// Builds the unified header with golden ratio layout (two rows)
  Widget _buildUnifiedHeader(DashboardConfig config, TaskProvider taskProvider) {
    final isToday = _isToday(_selectedDate);
    final now = DateTime.now();

    return Container(
      key: _headerKey,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1 (38% emphasis): Title + Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Title
              Text(
                'Schedule',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w300,
                      letterSpacing: 0.5,
                    ),
              ),
              // Action buttons grouped on right
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // List view toggle
                  if (widget.onViewModeToggle != null)
                    _buildActionButton(
                      icon: Icons.list,
                      tooltip: 'Show task list',
                      onPressed: widget.onViewModeToggle!,
                    ),
                  const SizedBox(width: 6),
                  // Go to now button
                  _buildActionButton(
                    icon: Icons.today_outlined,
                    tooltip: 'Go to Now',
                    onPressed: () {
                      setState(() => _selectedDate = DateTime.now());
                      _controller.scrollToCurrentTime(config);
                    },
                    isPrimary: true,
                  ),
                  // Zoom reset button - only shown when zoomed
                  Consumer<ContinuousTimelineController>(
                    builder: (context, controller, _) {
                      if (controller.zoomScale == 1.0) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: _buildActionButton(
                          icon: Icons.zoom_out_map,
                          tooltip: 'Reset Zoom',
                          onPressed: () => controller.updateZoom(1.0),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Row 2 (62% emphasis - Golden Ratio!): Prominent date display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Previous day button
              IconButton(
                icon: Icon(
                  Icons.chevron_left,
                  size: 28,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                  });
                },
                tooltip: 'Previous day',
              ),
              const SizedBox(width: 8),
              // Date display with tap-to-select
              Flexible(
                child: GestureDetector(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: isToday
                        ? BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          )
                        : null,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Prominent date - short format for consistent fit
                        Text(
                          _formatDateHeaderShort(_selectedDate),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.2,
                                color: isToday
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                        ),
                        // Underline accent
                        const SizedBox(height: 6),
                        Container(
                          height: 2,
                          width: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary.withValues(alpha: 0.0),
                                Theme.of(context).colorScheme.primary.withValues(alpha: isToday ? 0.8 : 0.6),
                                Theme.of(context).colorScheme.primary.withValues(alpha: 0.0),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        // Current time display (only when viewing today)
                        if (isToday) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatTime(now),
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.3,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Next day button
              IconButton(
                icon: Icon(
                  Icons.chevron_right,
                  size: 28,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.add(const Duration(days: 1));
                  });
                },
                tooltip: 'Next day',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds a minimal action button
  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isPrimary
            ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
            : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          size: 18,
          color: isPrimary ? Theme.of(context).colorScheme.primary : null,
        ),
        tooltip: tooltip,
        onPressed: onPressed,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
      ),
    );
  }

  /// Checks if the given date is today
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Builds the main timeline with grid and time blocks
  Widget _buildTimeline(
    DashboardConfig config,
    List<Task> scheduledTasks,
    TaskProvider taskProvider,
  ) {
    final totalHeight = config.totalHours * config.hourHeight;
    final brightness = Theme.of(context).brightness;

    return SizedBox(
      height: totalHeight,
      child: Stack(
        children: [
          // Grid background with hour lines
          RepaintBoundary(
            child: CustomPaint(
              size: Size(double.infinity, totalHeight),
              painter: TimelineGridPainter(
                config: config,
                date: _selectedDate,
                showCurrentTime: true,
                brightness: brightness,
              ),
            ),
          ),

          // Time blocks (positioned absolutely)
          ...scheduledTasks.map((task) => _buildTimeBlock(
                task,
                config,
                taskProvider,
              )),

          // Dragging block overlay (if dragging)
          Consumer<ContinuousTimelineController>(
            builder: (context, controller, _) {
              if (controller.dragState == null) {
                return const SizedBox.shrink();
              }
              return _buildDraggingBlockOverlay(
                controller.dragState!,
                config,
                taskProvider,
              );
            },
          ),
        ],
      ),
    );
  }

  /// Builds a single time block with drag gesture detection
  Widget _buildTimeBlock(
    Task task,
    DashboardConfig config,
    TaskProvider taskProvider,
  ) {
    // Check if this task is being dragged
    final isDragging = _controller.dragState?.task.id == task.id;

    // Hide the original task if it's being dragged (overlay handles display)
    if (isDragging) {
      return const SizedBox.shrink();
    }

    // Calculate position and size
    final top = config.timeToPixel(task.scheduledStart!);
    final height = task.scheduledDurationMinutes! * config.pixelsPerMinute;

    return Positioned(
      left: 80,
      top: top,
      right: 16,
      height: height,
      child: GestureDetector(
        // Only initiate drag - unified system handles updates/end
        // This prevents stuck state when dragging outside block bounds
        onPanStart: (details) => _handleBlockDragStart(task),
        child: Container(
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            color: _getBlockColor(task),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getBlockBorderColor(task).withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _buildBlockContent(task, height),
        ),
      ),
    );
  }

  /// Builds the dragging block overlay with visual feedback
  /// BUGFIX: Made fully dynamic to prevent overflow errors on small blocks
  Widget _buildDraggingBlockOverlay(
    TimelineDragState dragState,
    DashboardConfig config,
    TaskProvider taskProvider,
  ) {
    final task = dragState.task;
    final currentTop = config.timeToPixel(dragState.currentStartTime);
    final height = task.scheduledDurationMinutes! * config.pixelsPerMinute;

    // Calculate snapped time for preview
    final snappedTime = config.snapToInterval(dragState.currentStartTime);

    // Use Stack to separate label from block (prevents overflow on small blocks)
    return Stack(
      children: [
        // Semi-transparent block (main dragging element)
        Positioned(
          left: 80,
          top: currentTop,
          right: 16,
          height: height,
          child: Container(
            decoration: BoxDecoration(
              color: _getBlockColor(task).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 30,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _buildBlockContent(task, height),
            ),
          ),
        ),
        // Floating time label (positioned ABOVE the block, not inside)
        // This prevents overflow errors when block height is small
        Positioned(
          left: 80,
          top: currentTop - 32, // Place 32px above the block
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              _formatTimeRange(snappedTime, task.scheduledDurationMinutes!),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the content inside a time block
  Widget _buildBlockContent(Task task, double height) {
    final textColor = Colors.white;

    // Show minimal content if block is too small
    if (height < 40) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          task.name,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      );
    }

    // FIXED: Use Flexible widgets and proper constraints to prevent overflow
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title - takes available space but respects height constraints
          Flexible(
            child: Text(
              task.name,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
                height: 1.3,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: height < 60 ? 1 : 2,
            ),
          ),
          // Only show time range if we have enough space
          if (height >= 55) ...[
            const SizedBox(height: 6),
            Text(
              _formatTimeRange(task.scheduledStart!, task.scheduledDurationMinutes!),
              style: TextStyle(
                color: textColor.withValues(alpha: 0.75),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.2,
              ),
              overflow: TextOverflow.clip,
              maxLines: 1,
            ),
          ],
          // Category (if space allows)
          if (height > 85 && task.category != null) ...[
            const SizedBox(height: 4),
            Text(
              task.category!.name,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.6),
                fontSize: 11,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.3,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ],
      ),
    );
  }

  // ===== Unified Gesture System =====

  /// Handles unified gesture start - detects zoom (2+ fingers) vs drag vs scroll
  void _handleUnifiedGestureStart(ScaleStartDetails details) {
    _initialZoomScale = _controller.zoomScale;
    _lastScrollFocalPoint = details.focalPoint; // Initialize for manual scrolling

    // Detect 2+ finger gestures for zoom
    if (_pointerCount >= 2) {
      if (_gestureMode.canBeInterruptedBy(TimelineGestureMode.zooming)) {
        _transitionToMode(TimelineGestureMode.zooming);
        _isZooming = true;
        // Cancel any ongoing drag
        if (_controller.isDragging) {
          _autoScrollTimer?.cancel();
          _controller.cancelDrag();
        }
      }
    } else if (_pointerCount == 1 && _gestureMode == TimelineGestureMode.idle) {
      // Single finger on empty space = scrolling mode
      _transitionToMode(TimelineGestureMode.scrolling);
    }
    // Block drag is initiated by block's GestureDetector.onPanStart
  }

  /// Handles unified gesture update - routes to zoom or drag based on mode
  void _handleUnifiedGestureUpdate(
    ScaleUpdateDetails details,
    DashboardConfig config,
    TaskProvider provider,
  ) {
    if (_gestureMode == TimelineGestureMode.zooming && _pointerCount >= 2) {
      // Handle pinch-to-zoom
      if ((details.scale - 1.0).abs() > 0.02) {
        final newScale = _initialZoomScale * details.scale;
        _controller.updateZoom(newScale);
      }
    } else if (_gestureMode == TimelineGestureMode.draggingBlock) {
      // Handle block drag using global tracking (prevents stuck state)
      _handleGlobalBlockDrag(details, config, provider);
    } else if (_gestureMode == TimelineGestureMode.scrolling && _lastScrollFocalPoint != null) {
      // Manual scrolling (since GestureDetector consumes events)
      final delta = details.focalPoint - _lastScrollFocalPoint!;
      _lastScrollFocalPoint = details.focalPoint;

      final scrollController = _controller.scrollController;
      if (scrollController.hasClients) {
        final currentOffset = scrollController.offset;
        final newOffset = currentOffset - delta.dy; // Invert for natural scroll
        final maxScroll = scrollController.position.maxScrollExtent;
        final clampedOffset = newOffset.clamp(0.0, maxScroll);
        scrollController.jumpTo(clampedOffset);
      }
    }
  }

  /// Handles unified gesture end - finalizes zoom or drag
  void _handleUnifiedGestureEnd(
    ScaleEndDetails details,
    DashboardConfig config,
    TaskProvider provider,
  ) async {
    if (_gestureMode == TimelineGestureMode.zooming) {
      _isZooming = false;
      _transitionToMode(TimelineGestureMode.idle);
    } else if (_gestureMode == TimelineGestureMode.draggingBlock) {
      // Finalize drag
      await _finalizeBlockDrag(provider, config);
    } else if (_gestureMode == TimelineGestureMode.scrolling) {
      // End scrolling, return to idle
      _transitionToMode(TimelineGestureMode.idle);
    }

    // Reset scroll tracking
    _lastScrollFocalPoint = null;
  }

  /// Transition to a new gesture mode with logging
  void _transitionToMode(TimelineGestureMode newMode) {
    if (_gestureMode != newMode) {
      _gestureMode = newMode;
      if (mounted) setState(() {});
    }
  }

  /// Handles block drag using global gesture detector (prevents stuck state)
  void _handleGlobalBlockDrag(
    ScaleUpdateDetails details,
    DashboardConfig config,
    TaskProvider provider,
  ) {
    if (!_controller.isDragging) return;

    // Get scroll position and viewport
    if (!_controller.scrollController.hasClients) return;

    final scrollOffset = _controller.scrollController.offset;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    // Use focalPoint for reliable positioning across entire timeline
    final localPosition = renderBox.globalToLocal(details.focalPoint);
    final localY = localPosition.dy;

    // Calculate timeline Y position
    final timelineY = scrollOffset + localY - _totalHeaderHeight;

    // Clamp to valid range
    final maxTimelineY = config.totalHours * config.hourHeight;
    final clampedTimelineY = timelineY.clamp(0.0, maxTimelineY);

    // Update drag position
    _controller.updateDrag(clampedTimelineY, _selectedDate, config);

    // Handle auto-scroll at edges
    final viewportHeight = renderBox.size.height;
    final distanceFromTop = localY;
    final distanceFromBottom = viewportHeight - localY;

    if (distanceFromTop < _edgeScrollThreshold && scrollOffset > 0) {
      final intensity = 1.0 - (distanceFromTop / _edgeScrollThreshold);
      _controller.setAutoScrollVelocity(-_maxScrollSpeed * intensity);
    } else if (distanceFromBottom < _edgeScrollThreshold) {
      final intensity = 1.0 - (distanceFromBottom / _edgeScrollThreshold);
      _controller.setAutoScrollVelocity(_maxScrollSpeed * intensity);
    } else {
      _controller.setAutoScrollVelocity(0.0);
    }
  }

  /// Finalizes block drag and persists changes
  Future<void> _finalizeBlockDrag(TaskProvider provider, DashboardConfig config) async {
    if (!_controller.isDragging) return;

    // Clean up auto-scroll
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    _controller.setAutoScrollVelocity(0.0);

    HapticFeedback.lightImpact();
    await _controller.endDrag(provider, config);

    _transitionToMode(TimelineGestureMode.idle);

    if (mounted) {
      setState(() {});
    }
  }

  /// Initiates block drag - called by block's GestureDetector
  /// The global gesture system will handle updates to prevent stuck state
  void _handleBlockDragStart(Task task) {
    // Prevent drag if already zooming or multi-touch active
    if (_gestureMode == TimelineGestureMode.zooming || _pointerCount > 1) return;

    // Transition to dragging mode (highest priority for single-touch)
    _transitionToMode(TimelineGestureMode.draggingBlock);

    HapticFeedback.mediumImpact();
    _controller.startDrag(task, _selectedDate);

    // Start auto-scroll timer
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(
      const Duration(milliseconds: 16), // ~60fps
      (_) => _performAutoScroll(),
    );
  }

  /// Performs auto-scroll if needed during drag
  void _performAutoScroll() {
    // FIXED: Abort if not dragging or if conditions changed
    if (!_controller.isDragging || _isZooming || !mounted) {
      _autoScrollTimer?.cancel();
      return;
    }

    _controller.performAutoScroll();

    // FIXED: Don't recalculate position during auto-scroll
    // The drag position stays fixed in timeline coordinates,
    // so it appears to move on screen as we scroll
    // This prevents the "jumping" effect that occurred before
  }

  // ===== Helper Methods =====

  /// Gets the background color for a scheduled task
  Color _getBlockColor(Task task) {
    final colorScheme = Theme.of(context).colorScheme;

    // Use custom color if specified
    if (task.scheduleColorValue != null) {
      return Color(task.scheduleColorValue!);
    }

    // Otherwise use type-based colors
    return switch (task.type) {
      TaskType.distraction => colorScheme.errorContainer,
      TaskType.practice => colorScheme.primaryContainer,
      TaskType.goal => colorScheme.tertiaryContainer,
    };
  }

  /// Gets the border color for a scheduled task
  Color _getBlockBorderColor(Task task) {
    final colorScheme = Theme.of(context).colorScheme;

    // Use custom color if specified (darker variant for border)
    if (task.scheduleColorValue != null) {
      final baseColor = Color(task.scheduleColorValue!);
      return Color.lerp(baseColor, Colors.black, 0.3)!;
    }

    // Otherwise use type-based border colors
    return switch (task.type) {
      TaskType.distraction => colorScheme.error,
      TaskType.practice => colorScheme.primary,
      TaskType.goal => colorScheme.tertiary,
    };
  }

  /// Creates a config with zoom applied
  DashboardConfig _getZoomedConfig(DashboardConfig baseConfig) {
    final zoomedHourHeight = _baseHourHeight * _controller.zoomScale;

    // Create a modified config with zoomed hour height
    return DashboardConfig(
      timeSlotInterval: baseConfig.timeSlotInterval,
      dayStartHour: baseConfig.dayStartHour,
      dayEndHour: baseConfig.dayEndHour,
      showDailyTasksWidget: baseConfig.showDailyTasksWidget,
      showStatsWidget: baseConfig.showStatsWidget,
      showStreaksWidget: baseConfig.showStreaksWidget,
      showProjectsWidget: baseConfig.showProjectsWidget,
      showDeadlinesWidget: baseConfig.showDeadlinesWidget,
      defaultToWeeklyView: baseConfig.defaultToWeeklyView,
      createdAt: baseConfig.createdAt,
      updatedAt: baseConfig.updatedAt,
      widgetOrder: baseConfig.widgetOrder,
      hourHeight: zoomedHourHeight,
      snapIntervalMinutes: baseConfig.snapIntervalMinutes,
    );
  }

  /// Formats a date in short form for consistent width (e.g., "Mon, Dec 1, 2025")
  String _formatDateHeaderShort(DateTime date) {
    final weekday = _getWeekdayNameShort(date.weekday);
    final month = _getMonthName(date.month);
    return '$weekday, $month ${date.day}, ${date.year}';
  }

  /// Formats a time range (e.g., "2:00 PM - 3:30 PM")
  String _formatTimeRange(DateTime startTime, int durationMinutes) {
    final endTime = startTime.add(Duration(minutes: durationMinutes));
    return '${_formatTime(startTime)} - ${_formatTime(endTime)}';
  }

  /// Formats a single time (e.g., "2:30 PM")
  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');

    if (hour == 0) return '12:$minute AM';
    if (hour < 12) return '$hour:$minute AM';
    if (hour == 12) return '12:$minute PM';
    return '${hour - 12}:$minute PM';
  }

  /// Gets short weekday name from number (1 = Monday)
  String _getWeekdayNameShort(int weekday) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[weekday - 1];
  }

  /// Gets month name from number (1 = January)
  String _getMonthName(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return names[month - 1];
  }

  /// Opens date picker dialog
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }
}
