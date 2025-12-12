import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../providers/planning_provider.dart';
import 'task_dialog.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final bool showScheduleInfo;

  const TaskCard({
    super.key,
    required this.task,
    this.showScheduleInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TaskProvider>();
    final planningProvider = context.read<PlanningProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Check if this task is linked from any Canvas node
    final linkedFromCanvas = planningProvider.allNodes.any((node) => node.linkedTaskId == task.id);

    // Determine priority color for left border accent
    final priorityColor = switch (task.priority) {
      Priority.high => colorScheme.error,
      Priority.medium => colorScheme.tertiary,
      Priority.low => colorScheme.secondary,
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: task.isCompleted
            ? null
            : [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: task.isCompleted
            ? colorScheme.surfaceContainerLow
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showEditDialog(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: task.isCompleted
                      ? colorScheme.outline.withValues(alpha: 0.3)
                      : priorityColor,
                  width: 4,
                ),
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row: Checkbox, Title, Actions
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Checkbox
                    Transform.scale(
                      scale: 1.1,
                      child: Checkbox(
                        value: task.isCompleted,
                        onChanged: (_) => provider.toggleTask(task.id),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title and badges
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: task.isCompleted
                                  ? colorScheme.onSurfaceVariant
                                  : colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),

                          // Badges row (schedule, overdue, streak, etc.)
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              // Priority badge
                              _InfoBadge(
                                icon: Icons.flag,
                                label: _getPriorityLabel(task.priority),
                                color: priorityColor,
                                filled: !task.isCompleted,
                              ),

                              // Schedule badge
                              if (showScheduleInfo && task.isScheduled)
                                _InfoBadge(
                                  icon: Icons.schedule,
                                  label: task.formattedScheduledTime!,
                                  color: colorScheme.primary,
                                  filled: true,
                                ),

                              // Overdue badge
                              if (task.isOverdue)
                                _InfoBadge(
                                  icon: Icons.warning_rounded,
                                  label: 'Overdue',
                                  color: colorScheme.error,
                                  filled: true,
                                ),

                              // Deadline badge
                              if (task.deadline != null &&
                                  !task.isOverdue &&
                                  !task.isCompleted)
                                _InfoBadge(
                                  icon: Icons.calendar_today,
                                  label:
                                      'Due ${task.deadline!.day}/${task.deadline!.month}',
                                  color: colorScheme.onSurfaceVariant,
                                  filled: false,
                                ),

                              // Streak badge
                              if (task.type == TaskType.practice &&
                                  task.streakCount > 0)
                                _InfoBadge(
                                  icon: Icons.local_fire_department,
                                  label: '${task.streakCount} day streak',
                                  color: Colors.orange,
                                  filled: true,
                                ),

                              // Frequency badge
                              if (task.frequency != null)
                                _InfoBadge(
                                  icon: Icons.repeat,
                                  label: _formatFrequency(task.frequency!),
                                  color: colorScheme.primary,
                                  filled: false,
                                ),

                              // Canvas link badge
                              if (linkedFromCanvas)
                                GestureDetector(
                                  onTap: () => _navigateToCanvas(context),
                                  child: _InfoBadge(
                                    icon: Icons.account_tree,
                                    label: 'View in Canvas',
                                    color: Colors.purple,
                                    filled: true,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Action buttons
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditDialog(context);
                        } else if (value == 'delete') {
                          _confirmDelete(context, provider);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18),
                              SizedBox(width: 12),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 18),
                              SizedBox(width: 12),
                              Text('Delete'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Description
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.only(left: 52),
                    child: Text(
                      task.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],

                // Supporting Practices/Goals section
                _buildConnectionsSection(context, provider, theme, colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionsSection(
    BuildContext context,
    TaskProvider provider,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    if (task.type == TaskType.goal && task.supportingPractices.isNotEmpty) {
      // Show linked practices for goals
      final practices = provider.getPracticesForGoal(task.id);
      if (practices.isEmpty) return const SizedBox.shrink();

      final completedToday = practices.where((p) => p.isCompleted).length;
      final completionRate = completedToday / practices.length;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 52),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.fitness_center,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Supporting Practices',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$completedToday/${practices.length} done today',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: completionRate,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(
                      completionRate == 1.0
                          ? Colors.green
                          : const Color(0xFF64B5F6),
                    ),
                    minHeight: 4,
                  ),
                ),

                const SizedBox(height: 8),

                // Practice chips
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: practices.map((practice) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: practice.isCompleted
                            ? Colors.green.withValues(alpha: 0.15)
                            : const Color(0xFF64B5F6).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: practice.isCompleted
                              ? Colors.green.withValues(alpha: 0.3)
                              : const Color(0xFF64B5F6).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (practice.isCompleted)
                            Icon(
                              Icons.check_circle,
                              size: 12,
                              color: Colors.green,
                            )
                          else
                            Icon(
                              Icons.circle_outlined,
                              size: 12,
                              color: const Color(0xFF64B5F6),
                            ),
                          const SizedBox(width: 4),
                          Text(
                            practice.name,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: practice.isCompleted
                                  ? Colors.green
                                  : const Color(0xFF64B5F6),
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      );
    } else if (task.type == TaskType.practice && task.supportingGoals.isNotEmpty) {
      // Show linked goals for practices
      final goals = provider.getGoalsForPractice(task.id);
      if (goals.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 52),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.flag,
                      size: 14,
                      color: colorScheme.tertiary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Supports Goals',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.tertiary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Goal chips
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: goals.map((goal) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF81C784).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF81C784).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.flag,
                            size: 12,
                            color: const Color(0xFF81C784),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            goal.name,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: const Color(0xFF81C784),
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  String _getPriorityLabel(Priority priority) {
    return switch (priority) {
      Priority.high => 'High',
      Priority.medium => 'Medium',
      Priority.low => 'Low',
    };
  }

  void _showEditDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TaskDialog(task: task),
    );
  }

  void _navigateToCanvas(BuildContext context) {
    // Navigate to Canvas tab (index 1 in home screen)
    Navigator.of(context).popUntil((route) => route.isFirst);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigated to Canvas tab'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _formatFrequency(Frequency freq) {
    return switch (freq) {
      Frequency.daily => 'Daily',
      Frequency.weekly => 'Weekly',
      Frequency.monthly => 'Monthly',
      Frequency.custom => 'Custom',
    };
  }

  void _confirmDelete(BuildContext context, TaskProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteTask(task.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Info badge widget for displaying task metadata
class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool filled;

  const _InfoBadge({
    required this.icon,
    required this.label,
    required this.color,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? color.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: filled ? color.withValues(alpha: 0.3) : color.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: filled ? FontWeight.w600 : FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
