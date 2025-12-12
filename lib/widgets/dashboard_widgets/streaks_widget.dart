import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';

/// Modular Streaks Widget for dashboard
class StreaksWidget extends StatelessWidget {
  const StreaksWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final practices = taskProvider.practices;
        final distractions = taskProvider.distractions;

        final topPractices = practices
            .where((t) => t.streakCount > 0)
            .toList()
          ..sort((a, b) => b.streakCount.compareTo(a.streakCount));

        final topDistractions = distractions
            .where((t) => t.streakCount > 0)
            .toList()
          ..sort((a, b) => b.streakCount.compareTo(a.streakCount));

        final hasStreaks = topPractices.isNotEmpty || topDistractions.isNotEmpty;

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
                      Icons.local_fire_department,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Active Streaks',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Content
                if (!hasStreaks)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        children: [
                          Icon(
                            Icons.emoji_events_outlined,
                            size: 48,
                            color: colorScheme.outline,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No active streaks yet',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.outline,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Complete tasks to build streaks!',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Practice streaks
                      if (topPractices.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.fitness_center,
                              size: 16,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Practice Streaks',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...topPractices.take(3).map((task) {
                          return _buildStreakItem(
                            context,
                            task,
                            Colors.blue,
                            'days completed',
                          );
                        }),
                        const SizedBox(height: 12),
                      ],

                      // Distraction avoidance streaks
                      if (topDistractions.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.block,
                              size: 16,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Avoidance Streaks',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...topDistractions.take(3).map((task) {
                          return _buildStreakItem(
                            context,
                            task,
                            Colors.red,
                            'days avoided',
                          );
                        }),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStreakItem(
    BuildContext context,
    Task task,
    Color color,
    String label,
  ) {
    final theme = Theme.of(context);
    // streakCount is never null (has default value of 0)
    final streakCount = task.streakCount;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Streak count
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$streakCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Task info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$streakCount $label',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Medal icon for high streaks
            if (streakCount >= 7)
              Icon(
                streakCount >= 30
                    ? Icons.military_tech
                    : Icons.emoji_events,
                color: streakCount >= 30
                    ? Colors.amber
                    : Colors.orange,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
