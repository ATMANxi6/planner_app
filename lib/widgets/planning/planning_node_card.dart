import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/planning_node.dart';
import '../../providers/planning_provider.dart';
import '../../providers/project_provider.dart';
import '../../services/storage_service.dart';
import 'node_menu_dialog.dart';
import 'planning_utils.dart';
import 'planning_constants.dart';

/// Smart card component that adapts based on planning node type
class PlanningNodeCard extends StatelessWidget {
  final PlanningNode node;
  final int level;

  const PlanningNodeCard({
    super.key,
    required this.node,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(node.id),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Swipe left to delete
          return await _confirmDelete(context);
        } else if (direction == DismissDirection.startToEnd) {
          // Swipe right for quick actions
          if (context.mounted) {
            _showQuickActions(context);
          }
          return false;
        }
        return false;
      },
      background: _buildSwipeBackground(DismissDirection.startToEnd),
      secondaryBackground: _buildSwipeBackground(DismissDirection.endToStart),
      child: Card(
        margin: const EdgeInsets.only(bottom: PlanningLayout.cardBottomMargin),
        elevation: node.isBlocked(context.read<StorageService>().planningNodesBox) ? 1 : 2,
        child: InkWell(
          onTap: () => _handleTap(context),
          onDoubleTap: () => _toggleCollapse(context),
          onLongPress: () => _showNodeMenu(context),
          borderRadius: BorderRadius.circular(PlanningBorders.radiusLarge),
          child: _buildCardContent(context),
        ),
      ),
    );
  }

  Widget _buildCardContent(BuildContext context) {
    switch (node.type) {
      case PlanningNodeType.goal:
        return _GoalCard(node: node);
      case PlanningNodeType.milestone:
        return _MilestoneCard(node: node);
      case PlanningNodeType.task:
        return _TaskCard(node: node);
      case PlanningNodeType.decision:
        return _DecisionCard(node: node);
      case PlanningNodeType.note:
        return _NoteCard(node: node);
    }
  }

  Widget _buildSwipeBackground(DismissDirection direction) {
    final isDelete = direction == DismissDirection.endToStart;

    return Container(
      alignment: isDelete ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: PlanningGestures.swipeHorizontalPadding),
      decoration: BoxDecoration(
        color: isDelete ? Colors.red[400] : Colors.blue[400],
        borderRadius: BorderRadius.circular(PlanningBorders.radiusLarge),
      ),
      child: Icon(
        isDelete ? Icons.delete : Icons.menu,
        color: Colors.white,
        size: PlanningGestures.swipeIconSize,
      ),
    );
  }

  void _handleTap(BuildContext context) {
    // Could expand to show details or edit
  }

  void _toggleCollapse(BuildContext context) {
    if (node.childIds.isNotEmpty) {
      context.read<PlanningProvider>().toggleCollapse(node.id);
    }
  }

  void _showNodeMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => NodeMenuDialog(node: node),
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => NodeMenuDialog(node: node, quickActionsMode: true),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Node'),
            content: Text(
              node.childIds.isEmpty
                  ? 'Delete "${node.title}"?'
                  : 'Delete "${node.title}" and all its children (${node.childIds.length} items)?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

// ========== Goal Card ==========

class _GoalCard extends StatelessWidget {
  final PlanningNode node;

  const _GoalCard({required this.node});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final storage = context.read<StorageService>();
    final provider = context.read<PlanningProvider>();
    final projectProvider = context.watch<ProjectProvider>();

    final progress = node.getProgressPercentage(storage.planningNodesBox);
    final isBlocked = node.isBlocked(storage.planningNodesBox);

    // Get linked project for root nodes
    final linkedProject = (node.parentId == null && node.linkedProjectId != null)
        ? projectProvider.getProjectById(node.linkedProjectId!)
        : null;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: Color(node.colorValue),
            width: 4,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  PlanningNode.getIconForType(node.type),
                  color: Color(node.colorValue),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    node.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      decoration:
                          node.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                if (node.childIds.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      node.isCollapsed ? Icons.expand_more : Icons.expand_less,
                    ),
                    onPressed: () => provider.toggleCollapse(node.id),
                  ),
              ],
            ),

            if (node.description != null && node.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                node.description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Progress bar
            if (node.totalChildrenCount > 0) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(node.colorValue),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${node.getCompletedChildrenCount(storage.planningNodesBox)}/${node.totalChildrenCount} completed',
                style: theme.textTheme.bodySmall,
              ),
            ],

            // Metadata row
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (linkedProject != null)
                  _MetadataChip(
                    icon: Icons.account_tree,
                    label: linkedProject.name,
                    color: Color(linkedProject.colorValue),
                  ),
                if (node.deadline != null)
                  _MetadataChip(
                    icon: Icons.calendar_today,
                    label: formatDateRelative(node.deadline!),
                    color: getDeadlineColor(node.deadline!),
                  ),
                if (isBlocked)
                  const _MetadataChip(
                    icon: Icons.lock,
                    label: 'Blocked',
                    color: Colors.orange,
                  ),
                if (node.linkedTaskId != null)
                  _MetadataChip(
                    icon: Icons.link,
                    label: 'Linked',
                    color: colorScheme.primary,
                  ),
              ],
            ),

            // Quick actions
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: node.isCompleted,
                  onChanged: (_) => provider.toggleNode(node.id),
                ),
                const SizedBox(width: 4),
                Text(
                  node.isCompleted ? 'Completed' : 'Mark complete',
                  style: theme.textTheme.bodyMedium,
                ),
                if (node.linkedTaskId != null) ...[
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _navigateToTask(context, node.linkedTaskId!),
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('View Task'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
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

  void _navigateToTask(BuildContext context, String taskId) {
    // Navigate to Tasks tab (index 0 in home screen)
    Navigator.of(context).popUntil((route) => route.isFirst);

    // Show snackbar to help user locate the task
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Navigated to Tasks tab'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }
}

// ========== Milestone Card ==========

class _MilestoneCard extends StatelessWidget {
  final PlanningNode node;

  const _MilestoneCard({required this.node});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.read<PlanningProvider>();
    final storage = context.read<StorageService>();
    final isBlocked = node.isBlocked(storage.planningNodesBox);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: Color(node.colorValue),
            width: 4,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  PlanningNode.getIconForType(node.type),
                  color: Color(node.colorValue),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    node.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      decoration:
                          node.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                if (node.childIds.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      node.isCollapsed ? Icons.expand_more : Icons.expand_less,
                      size: 20,
                    ),
                    onPressed: () => provider.toggleCollapse(node.id),
                  ),
                Checkbox(
                  value: node.isCompleted,
                  onChanged: (_) => provider.toggleNode(node.id),
                ),
              ],
            ),
            if (node.timeEstimateMinutes != null ||
                node.deadline != null ||
                isBlocked)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 28),
                child: Wrap(
                  spacing: 8,
                  children: [
                    if (node.timeEstimateMinutes != null)
                      _MetadataChip(
                        icon: Icons.timer,
                        label: formatDuration(node.timeEstimateMinutes!),
                        color: Colors.blue,
                      ),
                    if (node.deadline != null)
                      _MetadataChip(
                        icon: Icons.calendar_today,
                        label: formatDateShort(node.deadline!),
                        color: Colors.grey,
                      ),
                    if (isBlocked)
                      const _MetadataChip(
                        icon: Icons.lock,
                        label: 'Blocked',
                        color: Colors.orange,
                      ),
                    if (node.linkedTaskId != null)
                      const _MetadataChip(
                        icon: Icons.link,
                        label: 'Linked',
                        color: Colors.blue,
                      ),
                  ],
                ),
              ),
            if (node.linkedTaskId != null)
              Padding(
                padding: const EdgeInsets.only(left: 28, top: 8),
                child: TextButton.icon(
                  onPressed: () => _navigateToTask(context, node.linkedTaskId!),
                  icon: const Icon(Icons.arrow_forward, size: 14),
                  label: const Text('View Task'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _navigateToTask(BuildContext context, String taskId) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigated to Tasks tab'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

// ========== Task Card ==========

class _TaskCard extends StatelessWidget {
  final PlanningNode node;

  const _TaskCard({required this.node});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.read<PlanningProvider>();
    final storage = context.read<StorageService>();
    final isBlocked = node.isBlocked(storage.planningNodesBox);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Checkbox
          Checkbox(
            value: node.isCompleted,
            onChanged: isBlocked ? null : (_) => provider.toggleNode(node.id),
          ),

          const SizedBox(width: 8),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      PlanningNode.getIconForType(node.type),
                      size: 14,
                      color: Color(node.colorValue),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        node.title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          decoration: node.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
                if (node.timeEstimateMinutes != null ||
                    node.deadline != null ||
                    isBlocked ||
                    node.linkedTaskId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        if (node.timeEstimateMinutes != null)
                          _MetadataChip(
                            icon: Icons.timer,
                            label: formatDuration(node.timeEstimateMinutes!),
                            color: Colors.blue,
                            small: true,
                          ),
                        if (node.deadline != null)
                          _MetadataChip(
                            icon: Icons.calendar_today,
                            label: formatDateShort(node.deadline!),
                            color: Colors.grey,
                            small: true,
                          ),
                        if (isBlocked)
                          const _MetadataChip(
                            icon: Icons.lock,
                            label: 'Blocked',
                            color: Colors.orange,
                            small: true,
                          ),
                        if (node.linkedTaskId != null)
                          const _MetadataChip(
                            icon: Icons.link,
                            label: 'Linked',
                            color: Colors.blue,
                            small: true,
                          ),
                      ],
                    ),
                  ),
                if (node.linkedTaskId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: TextButton.icon(
                      onPressed: () => _navigateToTask(context, node.linkedTaskId!),
                      icon: const Icon(Icons.arrow_forward, size: 12),
                      label: const Text('View Task'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        visualDensity: VisualDensity.compact,
                        textStyle: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToTask(BuildContext context, String taskId) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigated to Tasks tab'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

// ========== Decision Card ==========

class _DecisionCard extends StatelessWidget {
  final PlanningNode node;

  const _DecisionCard({required this.node});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.read<PlanningProvider>();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Color(node.colorValue),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.call_split,
                  color: Color(node.colorValue),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    node.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Color(node.colorValue),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (node.childIds.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      node.isCollapsed ? Icons.expand_more : Icons.expand_less,
                      size: 20,
                    ),
                    onPressed: () => provider.toggleCollapse(node.id),
                  ),
              ],
            ),
            if (node.description != null && node.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                node.description!,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ========== Note Card ==========

class _NoteCard extends StatelessWidget {
  final PlanningNode node;

  const _NoteCard({required this.node});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Color(node.colorValue).withValues(alpha: 0.1),
        border: Border.all(
          color: Color(node.colorValue).withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.note,
              color: Color(node.colorValue),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (node.title.isNotEmpty)
                    Text(
                      node.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (node.description != null && node.description!.isNotEmpty) ...[
                    if (node.title.isNotEmpty) const SizedBox(height: 4),
                    Text(
                      node.description!,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========== Metadata Chip ==========

class _MetadataChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool small;

  const _MetadataChip({
    required this.icon,
    required this.label,
    required this.color,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 8,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(small ? 6 : 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: small ? 10 : 12,
            color: color,
          ),
          SizedBox(width: small ? 3 : 4),
          Text(
            label,
            style: TextStyle(
              fontSize: small ? 10 : 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
