import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';

/// Quick Wins Widget - Shows easiest tasks first for quick momentum
class QuickWinsWidget extends StatelessWidget {
  const QuickWinsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final quickWins = _getQuickWins(taskProvider);

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
                      Icons.bolt,
                      color: Colors.amber[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Quick Wins',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber[700]?.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Build Momentum',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.amber[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'Easy tasks to get started',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),

                // Content
                if (quickWins.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        children: [
                          Icon(
                            Icons.celebration,
                            size: 48,
                            color: colorScheme.outline,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'All quick wins completed!',
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
                    children: quickWins.take(3).map((task) {
                      return _buildQuickWinItem(context, task, taskProvider);
                    }).toList(),
                  ),

                if (quickWins.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Center(
                      child: Text(
                        '+${quickWins.length - 3} more quick wins',
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

  Widget _buildQuickWinItem(
    BuildContext context,
    Task task,
    TaskProvider provider,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Calculate "ease score" for display
    final easeScore = _calculateEaseScore(task, provider);
    final easePercentage = (easeScore * 100).round();

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
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.amber[700]!.withValues(alpha: 0.1),
                Colors.amber[700]!.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.amber[700]!.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Type indicator
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: getTypeColor().withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      getTypeIcon(),
                      size: 16,
                      color: getTypeColor(),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Task name
                  Expanded(
                    child: Text(
                      task.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

              const SizedBox(height: 8),

              // Task metadata
              Row(
                children: [
                  // Time estimate
                  if (task.timeEstimate != null) ...[
                    Icon(
                      Icons.timer,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDuration(task.timeEstimate!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],

                  // Priority
                  Icon(
                    Icons.flag,
                    size: 14,
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

                  const Spacer(),

                  // Ease indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber[700]?.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bolt,
                          size: 12,
                          color: Colors.amber[700],
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '$easePercentage% Easy',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.amber[900],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get quick win tasks sorted by ease score
  List<Task> _getQuickWins(TaskProvider provider) {
    final incompleteTasks = provider.allTasks
        .where((task) => !task.isCompleted)
        .toList();

    // Calculate ease score for each task and sort
    final tasksWithScores = incompleteTasks.map((task) {
      return MapEntry(task, _calculateEaseScore(task, provider));
    }).toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // Higher score = easier

    return tasksWithScores.map((entry) => entry.key).toList();
  }

  /// Calculate how "easy" a task is (0.0 to 1.0)
  /// Higher score = easier/quicker to complete
  double _calculateEaseScore(Task task, TaskProvider provider) {
    double score = 0.5; // Base score

    // 1. Time estimate (shorter = easier)
    if (task.timeEstimate != null) {
      if (task.timeEstimate! <= 15) {
        score += 0.3; // Very quick tasks
      } else if (task.timeEstimate! <= 30) {
        score += 0.2; // Quick tasks
      } else if (task.timeEstimate! <= 60) {
        score += 0.1; // Medium tasks
      }
      // Longer tasks don't add to ease score
    }

    // 2. Priority (high priority should still be quick wins if otherwise easy)
    switch (task.priority) {
      case Priority.high:
        score += 0.15; // Important quick wins
      case Priority.medium:
        score += 0.1;
      case Priority.low:
        score += 0.05;
    }

    // 3. Complexity (fewer dependencies/subtasks = easier)
    if (task.type == TaskType.goal) {
      final subtaskCount = task.subtasks.length;
      if (subtaskCount == 0) {
        score += 0.15; // No subtasks = simpler
      } else if (subtaskCount <= 2) {
        score += 0.05; // Few subtasks
      }
      // Many subtasks reduce ease
      if (subtaskCount > 5) {
        score -= 0.1;
      }
    }

    // 4. Dependencies (no blockers = easier)
    if (task.dependencies.isEmpty) {
      score += 0.1; // No blockers
    } else {
      // Check if dependencies are complete
      final incompleteDeps = task.dependencies.where((depId) {
        final dep = provider.getTask(depId);
        return dep != null && !dep.isCompleted;
      }).length;

      if (incompleteDeps > 0) {
        score -= 0.2; // Blocked tasks are harder
      }
    }

    // 5. Deadline proximity (due soon = higher priority quick win)
    if (task.deadline != null) {
      final now = DateTime.now();
      final daysUntil = task.deadline!.difference(now).inDays;

      if (daysUntil <= 1) {
        score += 0.2; // Due today/tomorrow
      } else if (daysUntil <= 3) {
        score += 0.1; // Due this week
      }
    }

    // 6. Practices with active streaks (keep momentum going)
    if (task.type == TaskType.practice && task.streakCount > 0) {
      score += 0.15; // Maintain streak
    }

    // 7. Distractions (avoiding is always a quick win)
    if (task.type == TaskType.distraction) {
      score += 0.1; // Quick behavioral win
    }

    // Clamp to 0.0-1.0 range
    return score.clamp(0.0, 1.0);
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

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) {
        return '${hours}h';
      }
      return '${hours}h ${mins}m';
    }
  }
}
