import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../widgets/task_dialog.dart';
import '../widgets/continuous_timeline_view.dart';
import 'package:intl/intl.dart';

/// Schedule screen - Calendar view of scheduled tasks and time blocks
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _showWeeklyView = false;
  bool _showTimeBlockCalendar = false; // Default to list view

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: _showTimeBlockCalendar
          ? ContinuousTimelineView(
              key: const ValueKey('timeblock-calendar'),
              initialDate: _selectedDate,
              onViewModeToggle: () {
                setState(() {
                  _showTimeBlockCalendar = false;
                });
              },
            )
          : Consumer<TaskProvider>(
              builder: (context, taskProvider, child) {
                return Column(
                  children: [
                    _buildDateSelector(colorScheme),
                    const Divider(height: 1),
                    Expanded(
                      child: _showWeeklyView
                          ? _buildWeeklyView(taskProvider, colorScheme)
                          : _buildDailyView(taskProvider, colorScheme),
                    ),
                  ],
                );
              },
            ),
      floatingActionButton: _showTimeBlockCalendar
          ? null
          : Consumer<TaskProvider>(
              builder: (context, taskProvider, child) {
                // Get tasks based on current view mode
                final tasks = _showWeeklyView
                    ? taskProvider.getScheduledTasksForWeek(_getMonday(_selectedDate))
                    : taskProvider.getScheduledTasksForDate(_selectedDate);

                // Only show FAB if there are tasks (empty state has its own button)
                if (tasks.isEmpty) {
                  return const SizedBox.shrink();
                }

                return FloatingActionButton.extended(
                  onPressed: () => _showScheduleTaskDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Schedule Task'),
                );
              },
            ),
    );
  }

  Widget _buildDateSelector(ColorScheme colorScheme) {
    final today = DateTime.now();
    final isToday = _isSameDay(_selectedDate, today);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.1),
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
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w300,
                  letterSpacing: 0.5,
                ),
              ),
              // Action buttons grouped on right
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Timeline view toggle
                  _buildActionButton(
                    icon: Icons.calendar_view_day,
                    tooltip: 'Show timeline',
                    onPressed: () {
                      setState(() {
                        _showTimeBlockCalendar = true;
                      });
                    },
                  ),
                  const SizedBox(width: 6),
                  // Go to today button
                  if (!isToday)
                    _buildActionButton(
                      icon: Icons.today_outlined,
                      tooltip: 'Go to Today',
                      onPressed: () {
                        setState(() => _selectedDate = today);
                      },
                      isPrimary: true,
                    ),
                  // View mode toggle (Daily/Weekly)
                  if (!isToday) const SizedBox(width: 6),
                  _buildActionButton(
                    icon: _showWeeklyView ? Icons.calendar_today : Icons.calendar_view_week,
                    tooltip: _showWeeklyView ? 'Show daily view' : 'Show weekly view',
                    onPressed: () {
                      setState(() {
                        _showWeeklyView = !_showWeeklyView;
                      });
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
              // Previous navigation button
              IconButton(
                icon: Icon(
                  Icons.chevron_left,
                  size: 28,
                  color: colorScheme.onSurfaceVariant,
                ),
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.subtract(
                      Duration(days: _showWeeklyView ? 7 : 1),
                    );
                  });
                },
                tooltip: _showWeeklyView ? 'Previous week' : 'Previous day',
              ),
              const SizedBox(width: 8),
              // Date display
              Flexible(
                child: GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: isToday && !_showWeeklyView
                        ? BoxDecoration(
                            color: colorScheme.primaryContainer.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.primary.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          )
                        : null,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Prominent date
                        Text(
                          _showWeeklyView
                              ? _formatWeekRange(_selectedDate)
                              : _formatDateShort(_selectedDate),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                            color: isToday && !_showWeeklyView
                                ? colorScheme.primary
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
                                colorScheme.primary.withValues(alpha: 0.0),
                                colorScheme.primary.withValues(alpha: isToday && !_showWeeklyView ? 0.8 : 0.6),
                                colorScheme.primary.withValues(alpha: 0.0),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        // Current time display (only when viewing today)
                        if (isToday && !_showWeeklyView) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('h:mm a').format(today),
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.primary,
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
              // Next navigation button
              IconButton(
                icon: Icon(
                  Icons.chevron_right,
                  size: 28,
                  color: colorScheme.onSurfaceVariant,
                ),
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.add(
                      Duration(days: _showWeeklyView ? 7 : 1),
                    );
                  });
                },
                tooltip: _showWeeklyView ? 'Next week' : 'Next day',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds a minimal action button matching calendar view style
  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: isPrimary
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          size: 18,
          color: isPrimary ? colorScheme.primary : null,
        ),
        tooltip: tooltip,
        onPressed: onPressed,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
      ),
    );
  }

  /// Format date in short form to match calendar view
  String _formatDateShort(DateTime date) {
    final weekday = _getWeekdayNameShort(date.weekday);
    final month = DateFormat('MMM').format(date);
    return '$weekday, $month ${date.day}, ${date.year}';
  }

  /// Get short weekday name
  String _getWeekdayNameShort(int weekday) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[weekday - 1];
  }

  Widget _buildDailyView(TaskProvider provider, ColorScheme colorScheme) {
    final tasks = provider.getScheduledTasksForDate(_selectedDate);

    if (tasks.isEmpty) {
      return _buildEmptySchedule(colorScheme);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _buildScheduledTaskCard(task, provider, colorScheme);
      },
    );
  }

  Widget _buildWeeklyView(TaskProvider provider, ColorScheme colorScheme) {
    final weekStart = _getMonday(_selectedDate);
    final weekTasks = provider.getScheduledTasksForWeek(weekStart);

    // Group tasks by day
    final tasksByDay = <int, List<Task>>{};
    for (int i = 0; i < 7; i++) {
      tasksByDay[i] = [];
    }

    for (final task in weekTasks) {
      final dayIndex = task.scheduledStart!.weekday - 1;
      if (dayIndex >= 0 && dayIndex < 7) {
        tasksByDay[dayIndex]!.add(task);
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive column count based on screen width
        final isTablet = constraints.maxWidth > 600;
        final crossAxisCount = isTablet ? 7 : 3;

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: isTablet ? 0.55 : 0.7,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: 7,
          itemBuilder: (context, index) {
            final date = weekStart.add(Duration(days: index));
            final dayTasks = tasksByDay[index]!;
            return _buildDayColumn(date, dayTasks, colorScheme, provider);
          },
        );
      },
    );
  }

  Widget _buildDayColumn(DateTime date, List<Task> tasks, ColorScheme colorScheme, TaskProvider provider) {
    final isToday = _isSameDay(date, DateTime.now());

    return Semantics(
      label: '${DateFormat('EEEE, MMM d').format(date)}, ${tasks.length} tasks scheduled',
      container: true,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border.all(
            color: isToday
                ? colorScheme.primary.withValues(alpha: 0.3)
                : colorScheme.outline.withValues(alpha: 0.08),
            width: isToday ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Minimal day header
            InkWell(
              onTap: () {
                setState(() {
                  _selectedDate = date;
                  _showWeeklyView = false;
                });
              },
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: BoxDecoration(
                  color: isToday
                      ? colorScheme.primaryContainer.withValues(alpha: 0.15)
                      : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                ),
                child: Column(
                  children: [
                    // Abbreviated day name
                    Text(
                      DateFormat('EEE').format(date),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isToday
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Date number
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isToday ? colorScheme.primary : colorScheme.onSurface,
                        height: 1.0,
                      ),
                    ),
                    // Task count badge (minimal)
                    if (tasks.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: isToday
                              ? colorScheme.primary.withValues(alpha: 0.15)
                              : colorScheme.outline.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${tasks.length}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isToday
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Tasks list
            Expanded(
              child: tasks.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.check_circle_outline,
                          size: 24,
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return _buildMiniTaskCard(task, colorScheme, provider);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniTaskCard(Task task, ColorScheme colorScheme, TaskProvider provider) {
    final color = Color(task.scheduleColorValue ?? _getDefaultColorForType(task.type));
    final timeStr = DateFormat('h:mm a').format(task.scheduledStart!);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () => _showTaskDetails(task, provider),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.06),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Minimal color indicator
              Container(
                width: 3,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
              const SizedBox(width: 6),
              // Task content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Task name
                    Text(
                      task.name,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: task.isCompleted
                            ? colorScheme.onSurfaceVariant.withValues(alpha: 0.6)
                            : colorScheme.onSurface,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        height: 1.2,
                        letterSpacing: 0.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Time and duration - with overflow protection
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 9,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            (task.scheduledDurationMinutes ?? 0) > 0
                                ? '$timeStr • ${task.scheduledDurationMinutes}m'
                                : timeStr,
                            style: TextStyle(
                              fontSize: 9,
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0,
                              height: 1.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Compact completion indicator
              if (task.isCompleted)
                Icon(
                  Icons.check_circle,
                  size: 14,
                  color: colorScheme.primary.withValues(alpha: 0.6),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduledTaskCard(Task task, TaskProvider provider, ColorScheme colorScheme) {
    final color = Color(task.scheduleColorValue ?? _getDefaultColorForType(task.type));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showTaskDetails(task, provider),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(color: color, width: 3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Minimal icon
                  Container(
                    width: 6,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.1,
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: task.isCompleted
                                ? colorScheme.onSurfaceVariant
                                : colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              task.formattedScheduledTime ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: colorScheme.onSurfaceVariant,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.timer_outlined,
                              size: 14,
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${task.scheduledDurationMinutes}m',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: colorScheme.onSurfaceVariant,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Compact checkbox
                  if (task.isCompleted)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        color: colorScheme.primary,
                        size: 16,
                      ),
                    )
                  else
                    InkWell(
                      onTap: () => provider.toggleTask(task.id),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.circle_outlined,
                          size: 20,
                          color: colorScheme.outline.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                ],
              ),
              // Description (if present)
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Text(
                    task.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      height: 1.4,
                      letterSpacing: 0.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySchedule(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Minimal icon container
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.event_available,
                size: 56,
                color: colorScheme.primary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 32),
            // Minimal title
            Text(
              'No Tasks Scheduled',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 12),
            // Subtle description
            Text(
              _showWeeklyView
                  ? 'No tasks scheduled for this week.\nStart planning your time to stay organized.'
                  : 'No tasks scheduled for this day.\nAdd tasks to your schedule to maximize productivity.',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                height: 1.5,
                letterSpacing: 0.1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Minimal button
            FilledButton.icon(
              onPressed: () => _showScheduleTaskDialog(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Schedule a Task'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTaskDetails(Task task, TaskProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(task.description),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => TaskDialog(task: task),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      provider.toggleTask(task.id);
                      Navigator.pop(context);
                    },
                    icon: Icon(task.isCompleted ? Icons.undo : Icons.check),
                    label: Text(task.isCompleted ? 'Undo' : 'Complete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showScheduleTaskDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskDialog(
        initialScheduledDate: _selectedDate,
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _getMonday(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  String _formatWeekRange(DateTime date) {
    final monday = _getMonday(date);
    final sunday = monday.add(const Duration(days: 6));
    return '${DateFormat('MMM d').format(monday)} - ${DateFormat('MMM d, yyyy').format(sunday)}';
  }

  int _getDefaultColorForType(TaskType type) {
    return switch (type) {
      TaskType.distraction => 0xFFE57373,
      TaskType.practice => 0xFF64B5F6,
      TaskType.goal => 0xFF81C784,
    };
  }
}
