import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/planning_node.dart';
import '../../models/task.dart';
import '../../providers/planning_provider.dart';
import '../../providers/project_provider.dart';
import '../../providers/task_provider.dart';
import '../task_dialog.dart';
import '../canvas_project_selector_dialog.dart';
import 'edit_node_dialog.dart';
import 'add_node_dialog.dart';

/// Bottom sheet menu for node actions
class NodeMenuDialog extends StatelessWidget {
  final PlanningNode node;
  final bool quickActionsMode;

  const NodeMenuDialog({
    super.key,
    required this.node,
    this.quickActionsMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  PlanningNode.getIconForType(node.type),
                  color: Color(node.colorValue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        node.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        node.type.name.toUpperCase(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Actions
          if (quickActionsMode)
            ..._buildQuickActions(context)
          else
            ..._buildFullActions(context),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  List<Widget> _buildQuickActions(BuildContext context) {
    return [
      ListTile(
        leading: Icon(node.isCompleted ? Icons.undo : Icons.check_circle),
        title: Text(node.isCompleted ? 'Mark Incomplete' : 'Mark Complete'),
        onTap: () {
          context.read<PlanningProvider>().toggleNode(node.id);
          Navigator.pop(context);
        },
      ),
      ListTile(
        leading: const Icon(Icons.add),
        title: const Text('Add Child'),
        onTap: () {
          Navigator.pop(context);
          _showAddChildDialog(context);
        },
      ),
      ListTile(
        leading: const Icon(Icons.edit),
        title: const Text('Edit'),
        onTap: () {
          Navigator.pop(context);
          _showEditDialog(context);
        },
      ),
    ];
  }

  List<Widget> _buildFullActions(BuildContext context) {
    final provider = context.read<PlanningProvider>();

    return [
      // Completion toggle
      ListTile(
        leading: Icon(node.isCompleted ? Icons.undo : Icons.check_circle),
        title: Text(node.isCompleted ? 'Mark Incomplete' : 'Mark Complete'),
        onTap: () {
          provider.toggleNode(node.id);
          Navigator.pop(context);
        },
      ),

      // Edit
      ListTile(
        leading: const Icon(Icons.edit),
        title: const Text('Edit Details'),
        onTap: () {
          Navigator.pop(context);
          _showEditDialog(context);
        },
      ),

      // Add child
      ListTile(
        leading: const Icon(Icons.add),
        title: const Text('Add Child Node'),
        onTap: () {
          Navigator.pop(context);
          _showAddChildDialog(context);
        },
      ),

      // Collapse/Expand
      if (node.childIds.isNotEmpty)
        ListTile(
          leading: Icon(node.isCollapsed ? Icons.expand_more : Icons.expand_less),
          title: Text(node.isCollapsed ? 'Expand Children' : 'Collapse Children'),
          onTap: () {
            provider.toggleCollapse(node.id);
            Navigator.pop(context);
          },
        ),

      // Create task from node / Unlink task
      if (node.linkedTaskId == null)
        ListTile(
          leading: const Icon(Icons.add_task),
          title: const Text('Create Task from Node'),
          subtitle: const Text('Convert to actionable task'),
          onTap: () {
            Navigator.pop(context);
            _showCreateTaskDialog(context);
          },
        )
      else
        ListTile(
          leading: const Icon(Icons.link_off),
          title: const Text('Unlink Task'),
          subtitle: const Text('Remove task connection'),
          onTap: () {
            Navigator.pop(context);
            provider.unlinkFromTask(node.id);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Task unlinked from node')),
            );
          },
        ),

      const Divider(),

      // Delete
      ListTile(
        leading: const Icon(Icons.delete, color: Colors.red),
        title: const Text('Delete', style: TextStyle(color: Colors.red)),
        onTap: () async {
          Navigator.pop(context);
          final confirmed = await _confirmDelete(context);
          if (confirmed && context.mounted) {
            provider.deleteNode(node.id);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Node deleted')),
            );
          }
        },
      ),
    ];
  }

  void _showEditDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: EditNodeDialog(node: node),
      ),
    );
  }

  void _showAddChildDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: AddNodeDialog(parentId: node.id),
      ),
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

  Future<void> _showCreateTaskDialog(BuildContext context) async {
    final planningProvider = context.read<PlanningProvider>();
    final projectProvider = context.read<ProjectProvider>();
    final taskProvider = context.read<TaskProvider>();

    // Get the root node for this canvas
    final rootNode = planningProvider.getRootNode(node.id);
    if (rootNode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Could not find canvas root')),
      );
      return;
    }

    // Check if this canvas is already linked to a project
    String? projectId = rootNode.linkedProjectId;

    // If no project is linked, show project selector dialog
    if (projectId == null) {
      projectId = await showDialog<String>(
        context: context,
        builder: (ctx) => CanvasProjectSelectorDialog(
          suggestedProjectName: rootNode.title,
          suggestedColor: Color(rootNode.colorValue),
        ),
      );

      // If user cancelled project selection, abort task creation
      if (projectId == null) return;

      // Link the project to the root node
      await planningProvider.linkToProject(rootNode.id, projectId);
    }

    // Determine task type based on planning node type
    TaskType taskType = _mapNodeTypeToTaskType(node.type);

    // Show task creation dialog
    if (!context.mounted) return;
    final createdTask = await showModalBottomSheet<Task>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: TaskDialog(
          initialType: taskType,
          initialTitle: node.title,
          initialDescription: node.description,
        ),
      ),
    );

    // Process created task
    if (createdTask != null && context.mounted) {
      // Link the task to the planning node
      await planningProvider.linkToTask(node.id, createdTask.id);

      // Assign the task to the project
      await taskProvider.assignTaskToProject(createdTask.id, projectId);

      // Show confirmation
      if (context.mounted) {
        final project = projectProvider.getProjectById(projectId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Task "${createdTask.name}" created and linked${project != null ? ' to project "${project.name}"' : ''}',
            ),
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                // Navigate to Tasks tab (index 0)
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ),
        );
      }
    }
  }

  /// Map planning node type to appropriate task type
  TaskType _mapNodeTypeToTaskType(PlanningNodeType nodeType) {
    switch (nodeType) {
      case PlanningNodeType.goal:
        return TaskType.goal;
      case PlanningNodeType.milestone:
      case PlanningNodeType.task:
        return TaskType.practice; // Milestones and tasks become practices (habits to build)
      case PlanningNodeType.decision:
      case PlanningNodeType.note:
        return TaskType.goal; // Decisions and notes become goals by default
    }
  }
}
