import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../models/project.dart';
import '../providers/task_provider.dart';

/// A Kanban board for managing subtask workflow status
class KanbanBoard extends StatelessWidget {
  final Project project;
  final List<Task> tasks;

  const KanbanBoard({
    super.key,
    required this.project,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Get all subtasks with their parent tasks
    final allSubtasks = <({Subtask subtask, Task parentTask})>[];
    for (final task in tasks) {
      for (final subtask in task.subtasks) {
        allSubtasks.add((subtask: subtask, parentTask: task));
      }
    }

    // Group by Kanban status
    final Map<KanbanStatus, List<({Subtask subtask, Task parentTask})>> grouped = {
      for (var status in KanbanStatus.values) status: [],
    };

    for (final item in allSubtasks) {
      final status = item.subtask.kanbanStatus ?? KanbanStatus.backlog;
      grouped[status]!.add(item);
    }

    if (allSubtasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.view_kanban_outlined, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'No subtasks to manage',
              style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 8),
            Text(
              'Add subtasks to your tasks to manage them on the board',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Stats bar
        _buildStatsBar(grouped, allSubtasks.length, theme),
        const Divider(height: 1),
        // Kanban columns
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: KanbanStatus.values.length,
            itemBuilder: (context, index) {
              final status = KanbanStatus.values[index];
              return _KanbanColumn(
                status: status,
                subtasks: grouped[status]!,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatsBar(
    Map<KanbanStatus, List<({Subtask subtask, Task parentTask})>> grouped,
    int total,
    ThemeData theme,
  ) {
    final done = grouped[KanbanStatus.done]!.length;
    final inProgress = grouped[KanbanStatus.inProgress]!.length;
    final progress = total > 0 ? done / total : 0.0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Subtask Progress', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          _statChip('$done/$total', 'Done', Colors.green, theme),
          const SizedBox(width: 12),
          _statChip('$inProgress', 'Active', Colors.blue, theme),
        ],
      ),
    );
  }

  Widget _statChip(String value, String label, Color color, ThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
        ),
      ],
    );
  }
}

/// A single column in the Kanban board
class _KanbanColumn extends StatelessWidget {
  final KanbanStatus status;
  final List<({Subtask subtask, Task parentTask})> subtasks;

  const _KanbanColumn({
    required this.status,
    required this.subtasks,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final columnColor = _getColumnColor(status);

    return Container(
      width: 280,
      margin: const EdgeInsets.all(8),
      child: DragTarget<({Subtask subtask, Task parentTask})>(
        onWillAcceptWithDetails: (details) {
          return details.data.subtask.kanbanStatus != status;
        },
        onAcceptWithDetails: (details) {
          final taskProvider = context.read<TaskProvider>();
          taskProvider.updateSubtaskKanbanStatus(
            details.data.parentTask.id,
            details.data.subtask.id,
            status,
          );
        },
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isHovering
                  ? columnColor.withValues(alpha: 0.2)
                  : theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isHovering ? columnColor : theme.dividerColor,
                width: isHovering ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                // Column header
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: columnColor.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(color: columnColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          status.displayName,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${subtasks.length}',
                          style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                // Subtask cards
                Expanded(
                  child: subtasks.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Drop subtasks here',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: subtasks.length,
                          itemBuilder: (context, index) {
                            return _SubtaskKanbanCard(
                              subtask: subtasks[index].subtask,
                              parentTask: subtasks[index].parentTask,
                              columnColor: columnColor,
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getColumnColor(KanbanStatus status) {
    return switch (status) {
      KanbanStatus.backlog => Colors.grey,
      KanbanStatus.todo => Colors.orange,
      KanbanStatus.inProgress => Colors.blue,
      KanbanStatus.review => Colors.purple,
      KanbanStatus.done => Colors.green,
    };
  }
}

/// A draggable subtask card in the Kanban board
class _SubtaskKanbanCard extends StatelessWidget {
  final Subtask subtask;
  final Task parentTask;
  final Color columnColor;

  const _SubtaskKanbanCard({
    required this.subtask,
    required this.parentTask,
    required this.columnColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: LongPressDraggable<({Subtask subtask, Task parentTask})>(
        data: (subtask: subtask, parentTask: parentTask),
        feedback: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 260,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: columnColor, width: 2),
            ),
            child: Text(
              subtask.title,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: _buildCard(context, theme),
        ),
        child: _buildCard(context, theme),
      ),
    );
  }

  Widget _buildCard(BuildContext context, ThemeData theme) {
    return GestureDetector(
      onTap: () => _showSubtaskDetails(context, theme),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Parent task badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.folder, size: 10, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        parentTask.name,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (subtask.priority == Priority.high)
                  Icon(Icons.flag, size: 16, color: Colors.red.shade400),
              ],
            ),
            const SizedBox(height: 8),
            // Subtask title
            Text(
              subtask.title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            // Description preview
            if (subtask.description?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                subtask.description!,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            // Footer with metadata
            Row(
              children: [
                if (subtask.timeEstimate != null) ...[
                  Icon(Icons.timer_outlined, size: 14, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(
                    _formatDuration(subtask.timeEstimate!),
                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
                  ),
                  const SizedBox(width: 12),
                ],
                if (subtask.deadline != null) ...[
                  Icon(
                    Icons.event_outlined,
                    size: 14,
                    color: subtask.isOverdue ? Colors.red : theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(subtask.deadline!),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: subtask.isOverdue ? Colors.red : theme.colorScheme.outline,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSubtaskDetails(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Parent task
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.folder, size: 14, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      parentTask.name,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Subtask title
              Row(
                children: [
                  Icon(
                    subtask.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: subtask.isCompleted ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(subtask.title, style: theme.textTheme.headlineSmall),
                  ),
                ],
              ),
              if (subtask.description?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  subtask.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              // Details
              if (subtask.timeEstimate != null)
                _detailTile(Icons.timer, 'Time Estimate', _formatDuration(subtask.timeEstimate!), theme),
              if (subtask.startDate != null)
                _detailTile(Icons.play_arrow, 'Start Date', _formatFullDate(subtask.startDate!), theme),
              if (subtask.deadline != null)
                _detailTile(Icons.event, 'Deadline', _formatFullDate(subtask.deadline!), theme),
              if (subtask.priority != null)
                _detailTile(Icons.priority_high, 'Priority', subtask.priority!.name.toUpperCase(), theme),
              const SizedBox(height: 16),
              // Status changer
              Text('Change Status', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: KanbanStatus.values.map((status) {
                  final isSelected = subtask.kanbanStatus == status;
                  return ChoiceChip(
                    label: Text(status.displayName),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        context.read<TaskProvider>().updateSubtaskKanbanStatus(
                              parentTask.id,
                              subtask.id,
                              status,
                            );
                        Navigator.pop(context);
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailTile(IconData icon, String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
              ),
              Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0 && mins > 0) return '${hours}h ${mins}m';
    if (hours > 0) return '${hours}h';
    return '${mins}m';
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}';
  String _formatFullDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}
