import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/project.dart';

/// A horizontal Gantt chart showing subtasks grouped by parent tasks
class GanttChart extends StatefulWidget {
  final Project project;
  final List<Task> tasks;

  const GanttChart({
    super.key,
    required this.project,
    required this.tasks,
  });

  @override
  State<GanttChart> createState() => _GanttChartState();
}

class _GanttChartState extends State<GanttChart> {
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _labelScrollController = ScrollController();

  static const double _rowHeight = 44.0;
  static const double _parentRowHeight = 36.0;
  static const double _taskLabelWidth = 180.0;
  static const double _dayWidth = 40.0;
  static const double _headerHeight = 60.0;

  @override
  void initState() {
    super.initState();
    // Sync vertical scrolling between labels and chart
    _verticalScrollController.addListener(_syncLabelScroll);
  }

  void _syncLabelScroll() {
    if (_labelScrollController.hasClients) {
      _labelScrollController.jumpTo(_verticalScrollController.offset);
    }
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    _labelScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Get tasks that have subtasks (parent tasks)
    final tasksWithSubtasks = widget.tasks
        .where((task) => task.subtasks.isNotEmpty)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    if (tasksWithSubtasks.isEmpty) {
      return _buildEmptyState(theme);
    }

    final startDate = widget.project.startDate;
    final endDate = widget.project.endDate;
    final totalDays = endDate.difference(startDate).inDays + 1;

    // Build the row structure: parent tasks with their subtasks
    final rows = _buildRowStructure(tasksWithSubtasks);

    return Column(
      children: [
        // Legend
        _buildLegend(theme),
        const Divider(height: 1),
        // Chart
        Expanded(
          child: Row(
            children: [
              // Task labels column (fixed)
              SizedBox(
                width: _taskLabelWidth,
                child: Column(
                  children: [
                    _buildLabelHeader(theme),
                    Expanded(
                      child: ListView.builder(
                        controller: _labelScrollController,
                        itemCount: rows.length,
                        itemBuilder: (context, index) =>
                            _buildRowLabel(rows[index], theme),
                      ),
                    ),
                  ],
                ),
              ),
              // Timeline area (scrollable)
              Expanded(
                child: SingleChildScrollView(
                  controller: _horizontalScrollController,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: totalDays * _dayWidth,
                    child: Column(
                      children: [
                        _buildDateHeaders(startDate, totalDays, theme),
                        Expanded(
                          child: ListView.builder(
                            controller: _verticalScrollController,
                            itemCount: rows.length,
                            itemBuilder: (context, index) => _buildRowBar(
                              rows[index],
                              startDate,
                              totalDays,
                              theme,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timeline_outlined, size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            'No tasks with subtasks',
            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.outline),
          ),
          const SizedBox(height: 8),
          Text(
            'Add subtasks to your tasks to see them on the timeline',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<_GanttRow> _buildRowStructure(List<Task> tasks) {
    final rows = <_GanttRow>[];
    for (final task in tasks) {
      // Add parent task row
      rows.add(_GanttRow.parent(task));
      // Add subtask rows
      for (final subtask in task.subtasks) {
        rows.add(_GanttRow.subtask(subtask, task));
      }
    }
    return rows;
  }

  Widget _buildLabelHeader(ThemeData theme) {
    return Container(
      height: _headerHeight,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
          right: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Center(
        child: Text('Tasks / Subtasks', style: theme.textTheme.titleSmall),
      ),
    );
  }

  Widget _buildRowLabel(_GanttRow row, ThemeData theme) {
    if (row.isParent) {
      return Container(
        height: _parentRowHeight,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
          border: Border(
            bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
            right: BorderSide(color: theme.dividerColor),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Icon(Icons.folder, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                row.parentTask!.name,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${row.parentTask!.subtasks.length}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Subtask row
    final subtask = row.subtask!;
    return Container(
      height: _rowHeight,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
          right: BorderSide(color: theme.dividerColor),
        ),
      ),
      padding: const EdgeInsets.only(left: 24, right: 8),
      child: Row(
        children: [
          Icon(
            subtask.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: subtask.isCompleted ? Colors.green : theme.colorScheme.outline,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              subtask.title,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
                color: subtask.isCompleted ? theme.colorScheme.outline : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 16,
        children: [
          _legendItem(Colors.blue.shade400, 'In Progress', theme),
          _legendItem(Colors.green.shade400, 'Completed', theme),
          _legendItem(Colors.orange.shade400, 'Pending', theme),
          _legendItem(Colors.red.shade400, 'Overdue', theme),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _buildDateHeaders(DateTime startDate, int totalDays, ThemeData theme) {
    return Container(
      height: _headerHeight,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      child: Row(
        children: List.generate(totalDays, (index) {
          final date = startDate.add(Duration(days: index));
          final isWeekend = date.weekday >= 6;
          final isToday = _isSameDay(date, DateTime.now());

          return Container(
            width: _dayWidth,
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3))),
              color: isToday
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                  : isWeekend
                      ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                      : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _getDayOfWeek(date.weekday),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isToday ? theme.colorScheme.primary : theme.colorScheme.outline,
                  ),
                ),
                Text(
                  '${date.day}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isToday ? FontWeight.bold : null,
                    color: isToday ? theme.colorScheme.primary : null,
                  ),
                ),
                if (date.day == 1 || index == 0)
                  Text(
                    _getMonthAbbrev(date.month),
                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRowBar(_GanttRow row, DateTime projectStart, int totalDays, ThemeData theme) {
    final height = row.isParent ? _parentRowHeight : _rowHeight;

    if (row.isParent) {
      // Parent row - just show grid background
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
          border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3))),
        ),
        child: _buildGridLines(projectStart, totalDays, theme),
      );
    }

    // Subtask row - show the bar
    final subtask = row.subtask!;
    final taskStart = subtask.effectiveStartDate;
    final startOffset = taskStart.difference(projectStart).inDays;
    final duration = subtask.durationDays;

    final clampedStart = startOffset < 0 ? 0 : startOffset;
    final clampedEnd = (startOffset + duration) > totalDays ? totalDays : startOffset + duration;
    final clampedDuration = clampedEnd - clampedStart;

    final barColor = _getSubtaskBarColor(subtask);

    return Container(
      height: height,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3))),
      ),
      child: Stack(
        children: [
          _buildGridLines(projectStart, totalDays, theme),
          if (clampedDuration > 0)
            Positioned(
              left: clampedStart * _dayWidth + 2,
              top: 8,
              child: GestureDetector(
                onTap: () => _showSubtaskDetails(subtask, row.parentTask!, theme),
                child: Container(
                  width: clampedDuration * _dayWidth - 4,
                  height: height - 16,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: barColor.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      subtask.timeEstimate != null ? '${subtask.timeEstimate! ~/ 60}h' : '',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGridLines(DateTime projectStart, int totalDays, ThemeData theme) {
    return Row(
      children: List.generate(totalDays, (index) {
        final date = projectStart.add(Duration(days: index));
        final isWeekend = date.weekday >= 6;
        final isToday = _isSameDay(date, DateTime.now());

        return Container(
          width: _dayWidth,
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2))),
            color: isToday
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.1)
                : isWeekend
                    ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2)
                    : null,
          ),
        );
      }),
    );
  }

  Color _getSubtaskBarColor(Subtask subtask) {
    if (subtask.isCompleted) return Colors.green.shade400;
    if (subtask.isOverdue) return Colors.red.shade400;
    if (subtask.kanbanStatus == KanbanStatus.inProgress) return Colors.blue.shade400;
    return Colors.orange.shade400;
  }

  void _showSubtaskDetails(Subtask subtask, Task parentTask, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  subtask.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: subtask.isCompleted ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(subtask.title, style: theme.textTheme.titleLarge)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Part of: ${parentTask.name}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 12),
            if (subtask.description?.isNotEmpty == true) ...[
              Text(subtask.description!, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),
            ],
            _detailRow(Icons.calendar_today, 'Start', _formatDate(subtask.effectiveStartDate)),
            _detailRow(Icons.event, 'End', _formatDate(subtask.effectiveEndDate)),
            if (subtask.timeEstimate != null)
              _detailRow(Icons.timer, 'Estimate', '${subtask.timeEstimate! ~/ 60}h ${subtask.timeEstimate! % 60}m'),
            if (subtask.kanbanStatus != null)
              _detailRow(Icons.view_kanban, 'Status', subtask.kanbanStatus!.displayName),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
  String _getDayOfWeek(int weekday) => ['M', 'T', 'W', 'T', 'F', 'S', 'S'][weekday - 1];
  String _getMonthAbbrev(int month) =>
      ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][month - 1];
  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Represents a row in the Gantt chart - either a parent task or a subtask
class _GanttRow {
  final bool isParent;
  final Task? parentTask;
  final Subtask? subtask;

  _GanttRow._({required this.isParent, this.parentTask, this.subtask});

  factory _GanttRow.parent(Task task) => _GanttRow._(isParent: true, parentTask: task);
  factory _GanttRow.subtask(Subtask subtask, Task parent) =>
      _GanttRow._(isParent: false, subtask: subtask, parentTask: parent);
}
