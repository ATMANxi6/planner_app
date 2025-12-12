import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/planning_view_mode.dart';
import '../models/dashboard_config.dart';
import '../providers/planning_provider.dart';
import '../services/storage_service.dart';
import '../widgets/planning/planning_node_tree.dart';
import '../widgets/planning/planning_canvas_view.dart';
import '../widgets/planning/add_node_dialog.dart';

/// Main screen for Planning Canvas with dual view mode (List/Canvas)
class PlanningCanvasScreen extends StatefulWidget {
  const PlanningCanvasScreen({super.key});

  @override
  State<PlanningCanvasScreen> createState() => _PlanningCanvasScreenState();
}

class _PlanningCanvasScreenState extends State<PlanningCanvasScreen> {
  late PlanningViewMode _viewMode;

  @override
  void initState() {
    super.initState();
    // Load saved preference
    final storage = context.read<StorageService>();
    final config = storage.dashboardConfigBox.get('config') ?? DashboardConfig.defaultConfig();
    _viewMode = config.defaultToCanvasView
        ? PlanningViewMode.canvas
        : PlanningViewMode.list;
  }

  void _onViewModeChanged(PlanningViewMode newMode) {
    setState(() {
      _viewMode = newMode;
    });

    // Save preference
    final storage = context.read<StorageService>();
    final config = storage.dashboardConfigBox.get('config') ?? DashboardConfig.defaultConfig();
    config.update(defaultToCanvasView: newMode == PlanningViewMode.canvas);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planning Canvas'),
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        actions: [
          // View mode toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SegmentedButton<PlanningViewMode>(
              segments: const [
                ButtonSegment(
                  value: PlanningViewMode.list,
                  icon: Icon(Icons.list, size: 18),
                  tooltip: 'List View',
                ),
                ButtonSegment(
                  value: PlanningViewMode.canvas,
                  icon: Icon(Icons.hub, size: 18),
                  tooltip: 'Canvas View',
                ),
              ],
              selected: {_viewMode},
              onSelectionChanged: (selection) => _onViewModeChanged(selection.first),
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
          if (_viewMode == PlanningViewMode.list)
            IconButton(
              icon: const Icon(Icons.sort),
              tooltip: 'Auto-arrange',
              onPressed: () => _showAutoArrangeDialog(context),
            ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _viewMode == PlanningViewMode.list
            ? _buildListView(context)
            : const PlanningCanvasView(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddNodeDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Node'),
      ),
    );
  }

  Widget _buildListView(BuildContext context) {
    return Consumer<PlanningProvider>(
      builder: (context, provider, _) {
        try {
          final rootNodes = provider.getRootNodes();

          if (rootNodes.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            key: const ValueKey('list-view'),
            padding: const EdgeInsets.all(16),
            itemCount: rootNodes.length,
            itemBuilder: (context, index) {
              return PlanningNodeTree(
                node: rootNodes[index],
                level: 0,
              );
            },
          );
        } catch (e, stackTrace) {
          // Handle Hive box access errors or other exceptions
          debugPrint('Planning Canvas error: $e\n$stackTrace');
          return _buildErrorState(context, e);
        }
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hub_outlined,
              size: 120,
              color: colorScheme.outline.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Start Planning',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first goal, milestone, or task\nto begin organizing your ideas',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _showAddNodeDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Create First Node'),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _showQuickStartGuide(context),
              icon: const Icon(Icons.help_outline),
              label: const Text('Quick Start Guide'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Unable to Load Planning Canvas',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'There was a problem loading your planning data.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                // Trigger rebuild by navigating away and back
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
            const SizedBox(height: 16),
            ExpansionTile(
              title: const Text('Technical Details'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    error.toString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddNodeDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: const AddNodeDialog(),
      ),
    );
  }

  void _showAutoArrangeDialog(BuildContext context) {
    final provider = context.read<PlanningProvider>();
    final rootNodes = provider.getRootNodes();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Auto-Arrange'),
        content: const Text(
          'Automatically arrange nodes based on dependencies?\n\nThis will reorder items so that tasks appear after their dependencies.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              // Auto-arrange all root nodes
              for (final node in rootNodes) {
                await provider.autoArrangeChildren(node.id);
              }
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nodes auto-arranged by dependencies'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Auto-Arrange'),
          ),
        ],
      ),
    );
  }

  void _showQuickStartGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lightbulb_outline, color: Theme.of(ctx).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Quick Start Guide'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGuideItem(
                ctx,
                Icons.flag,
                'Goals',
                'Big-picture objectives with progress tracking',
                Colors.green,
              ),
              const SizedBox(height: 12),
              _buildGuideItem(
                ctx,
                Icons.beenhere,
                'Milestones',
                'Phase markers with time estimates',
                Colors.blue,
              ),
              const SizedBox(height: 12),
              _buildGuideItem(
                ctx,
                Icons.task_alt,
                'Tasks',
                'Actionable work items with checkboxes',
                Colors.purple,
              ),
              const SizedBox(height: 12),
              _buildGuideItem(
                ctx,
                Icons.note,
                'Notes',
                'Context, documentation, and ideas',
                Colors.blueGrey,
              ),
              const SizedBox(height: 12),
              _buildGuideItem(
                ctx,
                Icons.call_split,
                'Decisions',
                'Choice points with branching paths',
                Colors.orange,
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                _viewMode == PlanningViewMode.canvas
                    ? 'Canvas Gestures:'
                    : 'Mobile Gestures:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(ctx).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(_viewMode == PlanningViewMode.canvas
                  ? '• Drag nodes to reposition\n• Tap to select node\n• Double-tap to expand details\n• Long-press for menu\n• Pinch to zoom in/out'
                  : '• Tap to select\n• Double-tap to expand/collapse\n• Long-press for menu\n• Swipe for quick actions'),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
