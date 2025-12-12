import 'package:flutter/material.dart';
import '../models/task.dart';

/// A Material Design 3 segmented button for selecting task type
/// Color-coded: Distraction (Red), Practice (Blue), Goal (Green)
class TaskTypeSelector extends StatelessWidget {
  final TaskType selectedType;
  final ValueChanged<TaskType> onChanged;
  final bool enabled;

  const TaskTypeSelector({
    super.key,
    required this.selectedType,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: 'Task type selector. Currently selected: ${_getTypeLabel(selectedType)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Task Type',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<TaskType>(
            segments: [
              ButtonSegment<TaskType>(
                value: TaskType.distraction,
                label: const Text('Avoid'),
                icon: const Icon(Icons.block, size: 18),
                tooltip: 'Track habits to eliminate',
              ),
              ButtonSegment<TaskType>(
                value: TaskType.practice,
                label: const Text('Practice'),
                icon: const Icon(Icons.fitness_center, size: 18),
                tooltip: 'Build positive daily habits',
              ),
              ButtonSegment<TaskType>(
                value: TaskType.goal,
                label: const Text('Goal'),
                icon: const Icon(Icons.flag, size: 18),
                tooltip: 'Set long-term objectives',
              ),
            ],
            selected: {selectedType},
            onSelectionChanged: enabled
                ? (Set<TaskType> selection) => onChanged(selection.first)
                : null,
            style: ButtonStyle(
              visualDensity: VisualDensity.comfortable,
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return _getColorForType(selectedType, colorScheme);
                }
                return null;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return colorScheme.onSurface;
              }),
            ),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, -0.2),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
            },
            child: _buildTypeDescription(selectedType, theme, colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeDescription(
    TaskType type,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final (icon, title, description, color) = switch (type) {
      TaskType.distraction => (
        Icons.block,
        'Avoid Distraction',
        'Track habits you want to eliminate. Monitor triggers and build replacement behaviors.',
        const Color(0xFFE57373), // Red
      ),
      TaskType.practice => (
        Icons.fitness_center,
        'Build Practice',
        'Develop positive daily habits. Track progress, resources, and maintain streaks.',
        const Color(0xFF64B5F6), // Blue
      ),
      TaskType.goal => (
        Icons.flag,
        'Achieve Goal',
        'Set long-term objectives with milestones and subtasks. Define purpose and success criteria.',
        const Color(0xFF81C784), // Green
      ),
    };

    return Container(
      key: ValueKey(type),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTypeLabel(TaskType type) {
    return switch (type) {
      TaskType.distraction => 'Avoid',
      TaskType.practice => 'Practice',
      TaskType.goal => 'Goal',
    };
  }

  Color _getColorForType(TaskType type, ColorScheme colorScheme) {
    return switch (type) {
      TaskType.distraction => const Color(0xFFE57373), // Red
      TaskType.practice => const Color(0xFF64B5F6),    // Blue
      TaskType.goal => const Color(0xFF81C784),        // Green
    };
  }
}

/// Extension to get color value for task types (used in scheduling)
extension TaskTypeColorExtension on TaskType {
  Color get color {
    return switch (this) {
      TaskType.distraction => const Color(0xFFE57373), // Red
      TaskType.practice => const Color(0xFF64B5F6),    // Blue
      TaskType.goal => const Color(0xFF81C784),        // Green
    };
  }

  int get colorValue => color.toARGB32();
}
