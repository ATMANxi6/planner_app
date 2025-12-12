import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/planning_provider.dart';
import '../../models/planning_node.dart';

/// Canvas Progress Widget - Shows Planning Canvas overview on Dashboard
/// Displays total goals, completion progress, active milestones, and overdue items
class CanvasProgressWidget extends StatelessWidget {
  const CanvasProgressWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<PlanningProvider>(
      builder: (context, planningProvider, child) {
        final allNodes = planningProvider.allNodes;
        final goals = allNodes.where((n) => n.type == PlanningNodeType.goal).toList();
        final milestones = allNodes.where((n) => n.type == PlanningNodeType.milestone).toList();

        final completedGoals = goals.where((g) => g.isCompleted).length;
        final activeMilestones = milestones.where((m) => !m.isCompleted).length;
        final overdueItems = _getOverdueItems(allNodes);

        final hasData = allNodes.isNotEmpty;
        final completionPercentage = goals.isEmpty ? 0.0 : completedGoals / goals.length;

        return Card(
          child: InkWell(
            onTap: () => _navigateToCanvas(context),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(
                        Icons.account_tree,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Planning Canvas',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Content
                  if (!hasData)
                    _buildEmptyState(context, colorScheme, theme)
                  else
                    _buildProgressContent(
                      context,
                      colorScheme,
                      theme,
                      goals.length,
                      completedGoals,
                      completionPercentage,
                      activeMilestones,
                      overdueItems,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(
              Icons.hub_outlined,
              size: 48,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 8),
            Text(
              'No planning data yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.outline,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to create your first goal',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressContent(
    BuildContext context,
    ColorScheme colorScheme,
    ThemeData theme,
    int totalGoals,
    int completedGoals,
    double completionPercentage,
    int activeMilestones,
    int overdueItems,
  ) {
    return Column(
      children: [
        // Progress Ring with Stats
        Row(
          children: [
            // Progress Ring
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 8,
                      color: colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  // Progress circle
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: completionPercentage,
                      strokeWidth: 8,
                      color: colorScheme.primary,
                    ),
                  ),
                  // Percentage text
                  Text(
                    '${(completionPercentage * 100).toInt()}%',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),

            // Stats Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatRow(
                    context,
                    Icons.flag,
                    '$completedGoals / $totalGoals Goals',
                    colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  _buildStatRow(
                    context,
                    Icons.flag_circle,
                    '$activeMilestones Active',
                    Colors.blue,
                  ),
                  if (overdueItems > 0) ...[
                    const SizedBox(height: 8),
                    _buildStatRow(
                      context,
                      Icons.warning,
                      '$overdueItems Overdue',
                      Colors.orange,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  int _getOverdueItems(List<PlanningNode> nodes) {
    final now = DateTime.now();
    return nodes
        .where((node) =>
            !node.isCompleted &&
            node.deadline != null &&
            node.deadline!.isBefore(now))
        .length;
  }

  void _navigateToCanvas(BuildContext context) {
    // Navigate to Canvas tab (index 1)
    Navigator.of(context).popUntil((route) => route.isFirst);
    // TODO: This will navigate to home, but we need a way to switch to Canvas tab
    // For now, user can tap the Canvas button in bottom navigation
  }
}
