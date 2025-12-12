import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';

/// Modular Deadlines Widget for dashboard
class DeadlinesWidget extends StatelessWidget {
  const DeadlinesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final allTasks = taskProvider.allTasks;
        final upcomingDeadlines = _getUpcomingDeadlines(allTasks);

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
                      Icons.event,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Upcoming Deadlines',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Content
                if (upcomingDeadlines.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        children: [
                          Icon(
                            Icons.event_available,
                            size: 48,
                            color: colorScheme.outline,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No upcoming deadlines',
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
                    children: upcomingDeadlines.take(5).map((task) {
                      return _buildDeadlineItem(context, task, taskProvider);
                    }).toList(),
                  ),

                if (upcomingDeadlines.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Center(
                      child: Text(
                        '+${upcomingDeadlines.length - 5} more deadlines',
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

  Widget _buildDeadlineItem(
    BuildContext context,
    Task task,
    TaskProvider provider,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final now = DateTime.now();
    final deadline = task.deadline!;
    final daysUntil = deadline.difference(now).inDays;

    Color getUrgencyColor() {
      if (daysUntil < 0) return Colors.red; // Overdue
      if (daysUntil == 0) return Colors.orange; // Today
      if (daysUntil <= 3) return Colors.amber; // Soon
      return colorScheme.outline; // Later
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

    String getDeadlineLabel() {
      if (daysUntil < 0) return 'Overdue by ${-daysUntil} day${-daysUntil == 1 ? '' : 's'}';
      if (daysUntil == 0) return 'Due today';
      if (daysUntil == 1) return 'Due tomorrow';
      if (daysUntil <= 7) return 'Due in $daysUntil days';
      return 'Due ${_formatDate(deadline)}';
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
            color: getUrgencyColor().withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: getUrgencyColor().withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Urgency indicator
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: getUrgencyColor(),
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
                          color: getUrgencyColor(),
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
                        Icon(
                          daysUntil < 0
                              ? Icons.warning
                              : Icons.access_time,
                          size: 12,
                          color: getUrgencyColor(),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          getDeadlineLabel(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: getUrgencyColor(),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Completion status
              if (task.isCompleted)
                Icon(
                  Icons.check_circle,
                  color: colorScheme.primary,
                  size: 20,
                )
              else if (daysUntil < 0)
                Icon(
                  Icons.warning_amber,
                  color: Colors.red,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Task> _getUpcomingDeadlines(List<Task> allTasks) {
    return allTasks
        .where((task) => task.deadline != null && !task.isCompleted)
        .toList()
      ..sort((a, b) => a.deadline!.compareTo(b.deadline!));
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
}
