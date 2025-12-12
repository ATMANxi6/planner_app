import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/task.dart';

/// Panel showing unscheduled tasks that can be dragged to the calendar
class UnscheduledTasksPanel extends StatefulWidget {
  final List<Task> unscheduledTasks;
  final VoidCallback onRefresh;

  const UnscheduledTasksPanel({
    super.key,
    required this.unscheduledTasks,
    required this.onRefresh,
  });

  @override
  State<UnscheduledTasksPanel> createState() => _UnscheduledTasksPanelState();
}

class _UnscheduledTasksPanelState extends State<UnscheduledTasksPanel> {
  TaskType? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final filteredTasks = _selectedFilter == null
        ? widget.unscheduledTasks
        : widget.unscheduledTasks.where((t) => t.type == _selectedFilter).toList();

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header with filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.pending_actions,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Unscheduled Tasks',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${filteredTasks.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: widget.onRefresh,
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'All',
                  icon: Icons.all_inclusive,
                  isSelected: _selectedFilter == null,
                  onTap: () => setState(() => _selectedFilter = null),
                  colorScheme: colorScheme,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Avoid',
                  icon: Icons.block,
                  isSelected: _selectedFilter == TaskType.distraction,
                  onTap: () => setState(() => _selectedFilter = TaskType.distraction),
                  colorScheme: colorScheme,
                  color: const Color(0xFFE57373),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Practice',
                  icon: Icons.fitness_center,
                  isSelected: _selectedFilter == TaskType.practice,
                  onTap: () => setState(() => _selectedFilter = TaskType.practice),
                  colorScheme: colorScheme,
                  color: const Color(0xFF64B5F6),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Goals',
                  icon: Icons.flag,
                  isSelected: _selectedFilter == TaskType.goal,
                  onTap: () => setState(() => _selectedFilter = TaskType.goal),
                  colorScheme: colorScheme,
                  color: const Color(0xFF81C784),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Task list
          Flexible(
            child: filteredTasks.isEmpty
                ? _buildEmptyState(colorScheme)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shrinkWrap: true,
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      return _buildDraggableTaskItem(task, colorScheme);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    Color? color,
  }) {
    final effectiveColor = color ?? colorScheme.primary;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : effectiveColor),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: effectiveColor.withValues(alpha: 0.1),
      selectedColor: effectiveColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : effectiveColor,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildDraggableTaskItem(Task task, ColorScheme colorScheme) {
    final color = _getColorForType(task.type);

    return Draggable<Task>(
      data: task,
      feedback: Material(
        elevation: 12,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: 0.95,
          child: _buildTaskCard(task, color, colorScheme, isDragging: true),
        ),
      ),
      childWhenDragging: AnimatedOpacity(
        opacity: 0.25,
        duration: const Duration(milliseconds: 200),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.5),
              width: 2,
              style: BorderStyle.solid,
            ),
          ),
          child: _buildTaskCard(task, color, colorScheme),
        ),
      ),
      onDragStarted: () {
        HapticFeedback.mediumImpact();
      },
      onDragCompleted: () {
        HapticFeedback.lightImpact();
      },
      onDraggableCanceled: (velocity, offset) {
        HapticFeedback.lightImpact();
      },
      child: _buildTaskCard(task, color, colorScheme),
    );
  }

  Widget _buildTaskCard(
    Task task,
    Color color,
    ColorScheme colorScheme, {
    bool isDragging = false,
  }) {
    final width = isDragging ? 300.0 : null;

    return Container(
      width: width,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: isDragging
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getIconForType(task.type),
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (task.timeEstimate != null) ...[
                      Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${task.timeEstimate} min',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (task.priority != Priority.medium) ...[
                      if (task.timeEstimate != null) const SizedBox(width: 8),
                      Icon(
                        task.priority == Priority.high
                            ? Icons.priority_high
                            : Icons.low_priority,
                        size: 14,
                        color: task.priority == Priority.high
                            ? colorScheme.error
                            : colorScheme.tertiary,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.drag_indicator,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 48,
              color: colorScheme.outline.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _selectedFilter == null
                  ? 'All tasks are scheduled!'
                  : 'No unscheduled ${_getFilterName()} tasks',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getFilterName() {
    return switch (_selectedFilter!) {
      TaskType.distraction => 'avoid',
      TaskType.practice => 'practice',
      TaskType.goal => 'goal',
    };
  }

  Color _getColorForType(TaskType type) {
    return switch (type) {
      TaskType.distraction => const Color(0xFFE57373),
      TaskType.practice => const Color(0xFF64B5F6),
      TaskType.goal => const Color(0xFF81C784),
    };
  }

  IconData _getIconForType(TaskType type) {
    return switch (type) {
      TaskType.distraction => Icons.block,
      TaskType.practice => Icons.fitness_center,
      TaskType.goal => Icons.flag,
    };
  }
}
