import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';

/// Goal Progress Widget - Shows goals with supporting practices
/// Leverages Smart Habit Builder connections to display motivation context
class GoalProgressWidget extends StatelessWidget {
  const GoalProgressWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        // Get all goals that have supporting practices
        final goalsWithPractices = taskProvider.goals
            .where((goal) => goal.supportingPractices.isNotEmpty)
            .toList();

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
                      Icons.track_changes,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Goal Progress',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    // Time-aware greeting
                    Text(
                      _getTimeBasedMessage(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Content
                if (goalsWithPractices.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        children: [
                          Icon(
                            Icons.flag_outlined,
                            size: 48,
                            color: colorScheme.outline,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No goals with practices yet',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.outline,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Link practices to your goals to see progress!',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.outline,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    children: goalsWithPractices.map((goal) {
                      return _buildGoalProgressCard(
                        context,
                        goal,
                        taskProvider,
                        theme,
                        colorScheme,
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Get time-aware message for the widget header
  String _getTimeBasedMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Morning Focus';
    } else if (hour < 17) {
      return 'Afternoon Check-in';
    } else {
      return 'Evening Review';
    }
  }

  Widget _buildGoalProgressCard(
    BuildContext context,
    Task goal,
    TaskProvider provider,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final practices = provider.getPracticesForGoal(goal.id);
    if (practices.isEmpty) return const SizedBox.shrink();

    final completedToday = practices.where((p) => p.isCompleted).length;
    final totalPractices = practices.length;
    final completionRate = completedToday / totalPractices;

    // Determine status color and message
    final bool allComplete = completedToday == totalPractices;
    final bool noneComplete = completedToday == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: allComplete
            ? Colors.green.withValues(alpha: 0.1)
            : const Color(0xFF81C784).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: allComplete
              ? Colors.green.withValues(alpha: 0.3)
              : const Color(0xFF81C784).withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Goal name and completion indicator
          Row(
            children: [
              Icon(
                allComplete ? Icons.check_circle : Icons.flag,
                size: 18,
                color: allComplete ? Colors.green : const Color(0xFF81C784),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  goal.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Completion badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: allComplete
                      ? Colors.green
                      : (noneComplete
                          ? colorScheme.surfaceContainerHighest
                          : const Color(0xFF64B5F6)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$completedToday/$totalPractices',
                  style: TextStyle(
                    color: allComplete || !noneComplete
                        ? Colors.white
                        : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: completionRate,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(
                allComplete ? Colors.green : const Color(0xFF64B5F6),
              ),
              minHeight: 6,
            ),
          ),

          const SizedBox(height: 10),

          // Motivational message
          Text(
            _getMotivationalMessage(completionRate, allComplete),
            style: theme.textTheme.bodySmall?.copyWith(
              color: allComplete ? Colors.green : colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
            ),
          ),

          const SizedBox(height: 10),

          // Practice list
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: practices.map((practice) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: practice.isCompleted
                      ? Colors.green.withValues(alpha: 0.15)
                      : colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: practice.isCompleted
                        ? Colors.green.withValues(alpha: 0.4)
                        : colorScheme.outline.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      practice.isCompleted
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 14,
                      color: practice.isCompleted
                          ? Colors.green
                          : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      practice.name,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: practice.isCompleted
                            ? Colors.green
                            : colorScheme.onSurfaceVariant,
                        fontWeight: practice.isCompleted
                            ? FontWeight.w600
                            : FontWeight.w500,
                        decoration: practice.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
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
    );
  }

  /// Get motivational message based on completion rate
  String _getMotivationalMessage(double rate, bool allComplete) {
    if (allComplete) {
      return '🎉 All practices complete! Great work on this goal!';
    } else if (rate >= 0.66) {
      return '💪 Almost there! Just a few more practices to go.';
    } else if (rate >= 0.33) {
      return '👍 Good progress! Keep the momentum going.';
    } else if (rate > 0) {
      return '🌱 Started! Complete more practices to move forward.';
    } else {
      return '🎯 Ready to start? These practices support your goal.';
    }
  }
}
