import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';

class GraphNode {
  final String id;
  final String title;
  final bool isGoal;
  final bool isCompleted;
  final String? parentId;
  double x;
  double y;

  GraphNode({
    required this.id,
    required this.title,
    required this.isGoal,
    required this.isCompleted,
    this.parentId,
    required this.x,
    required this.y,
  });
}

class GoalGraphView extends StatefulWidget {
  const GoalGraphView({super.key});

  @override
  State<GoalGraphView> createState() => _GoalGraphViewState();
}

class _GoalGraphViewState extends State<GoalGraphView> {
  final TransformationController _transformController = TransformationController();
  String? _selectedNodeId;
  String? _draggedNodeId;

  final List<GraphNode> _nodes = [];

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _buildGraphNodes();
  }

  void _buildGraphNodes() {
    final taskProvider = context.watch<TaskProvider>();
    final goals = taskProvider.goals;

    _nodes.clear();

    // Starting position for first goal
    double currentX = 200.0;
    double currentY = 200.0;
    final horizontalSpacing = 400.0;
    final verticalSpacing = 500.0;

    int goalIndex = 0;
    for (var goal in goals) {
      // Calculate position in a grid layout
      final row = goalIndex ~/ 2; // 2 goals per row
      final col = goalIndex % 2;

      final goalX = currentX + (col * horizontalSpacing);
      final goalY = currentY + (row * verticalSpacing);

      // Add goal node
      _nodes.add(GraphNode(
        id: goal.id,
        title: goal.name,
        isGoal: true,
        isCompleted: goal.isCompleted,
        x: goalX,
        y: goalY,
      ));

      // Add subtask nodes in a circle around the goal
      if (goal.subtasks.isNotEmpty) {
        final radius = 120.0;
        final angleStep = (2 * pi) / goal.subtasks.length;

        for (int i = 0; i < goal.subtasks.length; i++) {
          final subtask = goal.subtasks[i];
          final angle = i * angleStep - (pi / 2); // Start from top

          final subtaskX = goalX + radius * cos(angle);
          final subtaskY = goalY + radius * sin(angle);

          _nodes.add(GraphNode(
            id: subtask.id,
            title: subtask.title,
            isGoal: false,
            isCompleted: subtask.isCompleted,
            parentId: goal.id,
            x: subtaskX,
            y: subtaskY,
          ));
        }
      }

      goalIndex++;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_nodes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_tree_outlined,
              size: 80,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 24),
            Text(
              'No goals to visualize',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create goals with subtasks to see the graph',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // Graph canvas
        InteractiveViewer(
          transformationController: _transformController,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          minScale: 0.3,
          maxScale: 2.0,
          child: SizedBox(
            width: 2000,
            height: 2000,
            child: CustomPaint(
              painter: GraphPainter(
                nodes: _nodes,
                selectedNodeId: _selectedNodeId,
                colorScheme: colorScheme,
              ),
              child: GestureDetector(
                onTapUp: (details) => _handleTap(details.localPosition),
                onPanStart: (details) => _handlePanStart(details.localPosition),
                onPanUpdate: (details) => _handlePanUpdate(details.localPosition),
                onPanEnd: (_) => _handlePanEnd(),
              ),
            ),
          ),
        ),

        // Legend
        Positioned(
          top: 16,
          right: 16,
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Legend',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _LegendItem(
                    color: colorScheme.primary,
                    size: 60,
                    label: 'Goal',
                  ),
                  const SizedBox(height: 4),
                  _LegendItem(
                    color: colorScheme.secondary,
                    size: 40,
                    label: 'Subtask',
                  ),
                  const SizedBox(height: 4),
                  _LegendItem(
                    color: colorScheme.tertiary,
                    size: 40,
                    label: 'Completed',
                  ),
                ],
              ),
            ),
          ),
        ),

        // Controls hint
        Positioned(
          bottom: 16,
          left: 16,
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                '🔍 Pinch to zoom • 👆 Drag to pan • Tap nodes to select',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handleTap(Offset position) {
    // Find tapped node
    GraphNode? tappedNode;
    for (var node in _nodes) {
      final dx = position.dx - node.x;
      final dy = position.dy - node.y;
      final distance = sqrt(dx * dx + dy * dy);
      final radius = node.isGoal ? 30.0 : 20.0;

      if (distance <= radius) {
        tappedNode = node;
        break;
      }
    }

    if (tappedNode != null) {
      final node = tappedNode;
      setState(() {
        _selectedNodeId = _selectedNodeId == node.id ? null : node.id;
      });

      // If subtask is tapped, toggle completion
      if (!node.isGoal && node.parentId != null) {
        context.read<TaskProvider>().toggleSubtask(
          node.parentId!,
          node.id,
        );
      }
    } else {
      setState(() {
        _selectedNodeId = null;
      });
    }
  }

  void _handlePanStart(Offset position) {
    // Find node to drag
    for (var node in _nodes) {
      final dx = position.dx - node.x;
      final dy = position.dy - node.y;
      final distance = sqrt(dx * dx + dy * dy);
      final radius = node.isGoal ? 30.0 : 20.0;

      if (distance <= radius) {
        _draggedNodeId = node.id;
        break;
      }
    }
  }

  void _handlePanUpdate(Offset position) {
    if (_draggedNodeId != null) {
      setState(() {
        final node = _nodes.firstWhere((n) => n.id == _draggedNodeId);
        node.x = position.dx;
        node.y = position.dy;

        // If it's a goal being dragged, move its subtasks too
        if (node.isGoal) {
          final subtasks = _nodes.where((n) => n.parentId == node.id).toList();
          // Recalculate subtask positions around new goal position
          if (subtasks.isNotEmpty) {
            final radius = 120.0;
            final angleStep = (2 * pi) / subtasks.length;

            for (int i = 0; i < subtasks.length; i++) {
              final angle = i * angleStep - (pi / 2);
              subtasks[i].x = node.x + radius * cos(angle);
              subtasks[i].y = node.y + radius * sin(angle);
            }
          }
        }
      });
    }
  }

  void _handlePanEnd() {
    _draggedNodeId = null;
  }
}

class GraphPainter extends CustomPainter {
  final List<GraphNode> nodes;
  final String? selectedNodeId;
  final ColorScheme colorScheme;

  GraphPainter({
    required this.nodes,
    required this.selectedNodeId,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw connections first (behind nodes)
    _drawConnections(canvas);

    // Draw nodes on top
    _drawNodes(canvas);
  }

  void _drawConnections(Canvas canvas) {
    final linePaint = Paint()
      ..color = colorScheme.outline.withValues(alpha: 0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (var node in nodes) {
      if (!node.isGoal && node.parentId != null) {
        // Find parent node
        final parent = nodes.firstWhere((n) => n.id == node.parentId);

        // Draw line from parent to subtask
        canvas.drawLine(
          Offset(parent.x, parent.y),
          Offset(node.x, node.y),
          linePaint,
        );
      }
    }
  }

  void _drawNodes(Canvas canvas) {
    for (var node in nodes) {
      final isSelected = node.id == selectedNodeId;
      final radius = node.isGoal ? 30.0 : 20.0;

      // Determine color
      Color nodeColor;
      if (node.isCompleted) {
        nodeColor = colorScheme.tertiary;
      } else if (node.isGoal) {
        nodeColor = colorScheme.primary;
      } else {
        nodeColor = colorScheme.secondary;
      }

      // Draw node shadow
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(
        Offset(node.x + 2, node.y + 2),
        radius,
        shadowPaint,
      );

      // Draw node circle
      final nodePaint = Paint()
        ..color = nodeColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(node.x, node.y),
        radius,
        nodePaint,
      );

      // Draw selection ring
      if (isSelected) {
        final selectionPaint = Paint()
          ..color = Colors.white
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(
          Offset(node.x, node.y),
          radius + 4,
          selectionPaint,
        );
      }

      // Draw completion checkmark
      if (node.isCompleted) {
        final checkPaint = Paint()
          ..color = Colors.white
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

        final checkPath = Path()
          ..moveTo(node.x - 8, node.y)
          ..lineTo(node.x - 3, node.y + 5)
          ..lineTo(node.x + 8, node.y - 5);

        canvas.drawPath(checkPath, checkPaint);
      }

      // Draw label
      final textPainter = TextPainter(
        text: TextSpan(
          text: node.title,
          style: TextStyle(
            color: Colors.white,
            fontSize: node.isGoal ? 11 : 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: radius * 2 - 8);

      textPainter.paint(
        canvas,
        Offset(
          node.x - textPainter.width / 2,
          node.y - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(GraphPainter oldDelegate) => true;
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final double size;
  final String label;

  const _LegendItem({
    required this.color,
    required this.size,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size / 3,
          height: size / 3,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
