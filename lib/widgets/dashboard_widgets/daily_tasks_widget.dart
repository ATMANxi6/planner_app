import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';

/// Modular Daily Tasks Widget for dashboard
class DailyTasksWidget extends StatelessWidget {
  const DailyTasksWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final today = DateTime.now();
        final dailyTasks = _getTodayTasks(taskProvider.allTasks, today);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.today,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Today\'s Tasks',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${dailyTasks.where((t) => t.isCompleted).length}/${dailyTasks.length}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Content
                if (dailyTasks.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 48,
                            color: colorScheme.outline,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No tasks for today',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    children: dailyTasks.take(5).map((task) {
                      return _buildTaskItem(context, task, taskProvider);
                    }).toList(),
                  ),

                if (dailyTasks.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Center(
                      child: Text(
                        '+${dailyTasks.length - 5} more tasks',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTaskItem(
    BuildContext context,
    Task task,
    TaskProvider provider,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color getTypeColor() {
      switch (task.type) {
        case TaskType.distraction:
          return Colors.red;
        case TaskType.practice:
          return Colors.blue;
        case TaskType.goal:
          return Colors.green;
      }
    }

    IconData getTypeIcon() {
      switch (task.type) {
        case TaskType.distraction:
          return Icons.block;
        case TaskType.practice:
          return Icons.fitness_center;
        case TaskType.goal:
          return Icons.flag;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          // Could navigate to task details
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: task.isCompleted
                ? colorScheme.surfaceContainerHighest
                : colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Type indicator
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: getTypeColor(),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),

              // Task info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          getTypeIcon(),
                          size: 14,
                          color: getTypeColor(),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            task.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Priority is always set (never null, has default value)
                        Icon(
                          Icons.flag,
                          size: 12,
                          color: _getPriorityColor(task.priority),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          task.priority.name.toUpperCase(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _getPriorityColor(task.priority),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (task.deadline != null) ...[
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: colorScheme.outline,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(task.deadline!),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.outline,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Checkbox
              Checkbox(
                value: task.isCompleted,
                onChanged: (value) {
                  provider.toggleTask(task.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Task> _getTodayTasks(List<Task> allTasks, DateTime today) {
    return allTasks.where((task) {
      // Include tasks with deadline today
      if (task.deadline != null) {
        final deadline = task.deadline!;
        if (deadline.year == today.year &&
            deadline.month == today.month &&
            deadline.day == today.day) {
          return true;
        }
      }

      // Include tasks with reminder today
      if (task.reminderTime != null) {
        final reminder = task.reminderTime!;
        if (reminder.year == today.year &&
            reminder.month == today.month &&
            reminder.day == today.day) {
          return true;
        }
      }

      // Include daily tasks
      if (task.frequency == Frequency.daily && !task.isCompleted) {
        return true;
      }

      return false;
    }).toList()
      ..sort((a, b) {
        // Sort by completion, then priority, then deadline
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        // Priority is never null (has default value)
        if (a.priority != b.priority) {
          return a.priority.index.compareTo(b.priority.index);
        }
        // Deadline is nullable
        final aDeadline = a.deadline;
        final bDeadline = b.deadline;
        if (aDeadline != bDeadline) {
          if (aDeadline == null) return 1;
          if (bDeadline == null) return -1;
          return aDeadline.compareTo(bDeadline);
        }
        return 0;
      });
  }

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.low:
        return Colors.green;
      case Priority.medium:
        return Colors.orange;
      case Priority.high:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);

    if (targetDate == today) {
      return 'Today';
    } else if (targetDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}
