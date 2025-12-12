import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/mind_map_node.dart';
import '../providers/mind_map_provider.dart';

class MindMapCanvas extends StatefulWidget {
  const MindMapCanvas({super.key});

  @override
  State<MindMapCanvas> createState() => _MindMapCanvasState();
}

class _MindMapCanvasState extends State<MindMapCanvas> {
  final TransformationController _transformController =
      TransformationController();
  String? _selectedNodeId;
  String? _connectingFromId;

  // Transient drag state - tracks positions during drag without persisting
  Map<String, Offset> _dragPositions = {};
  Timer? _dragSaveTimer;
  Timer? _dragCheckpointTimer;
  String? _currentDragNodeId;

  // Configuration
  static const Duration _dragSaveDelay = Duration(milliseconds: 300);
  static const Duration _dragCheckpointInterval = Duration(seconds: 2);

  // Canvas dimensions - dynamic sizing based on node positions
  static const double minCanvasWidth = 2000;
  static const double minCanvasHeight = 2000;
  static const double canvasPadding = 500;

  Size? _canvasSize;

  @override
  void dispose() {
    _dragSaveTimer?.cancel();
    _dragCheckpointTimer?.cancel();
    _transformController.dispose();
    super.dispose();
  }

  /// Calculate dynamic canvas size based on node positions
  Size _calculateCanvasSize(List<MindMapNode> nodes) {
    if (nodes.isEmpty) {
      return Size(minCanvasWidth, minCanvasHeight);
    }

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    const double nodeSize = 80.0; // Node width and height

    for (final node in nodes) {
      minX = minX < node.x ? minX : node.x;
      minY = minY < node.y ? minY : node.y;
      maxX = maxX > (node.x + nodeSize) ? maxX : (node.x + nodeSize);
      maxY = maxY > (node.y + nodeSize) ? maxY : (node.y + nodeSize);
    }

    final width = (maxX - minX + (canvasPadding * 2)).clamp(minCanvasWidth, double.infinity);
    final height = (maxY - minY + (canvasPadding * 2)).clamp(minCanvasHeight, double.infinity);

    return Size(width, height);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InteractiveViewer(
          transformationController: _transformController,
          boundaryMargin: const EdgeInsets.all(400),
          minScale: 0.5,
          maxScale: 2.0,
          child: Consumer<MindMapProvider>(
            builder: (context, provider, _) {
              final allNodes = provider.allNodes;

              // Recalculate canvas size when nodes change
              _canvasSize = _calculateCanvasSize(allNodes);

              return SizedBox(
                width: _canvasSize!.width,
                height: _canvasSize!.height,
                child: CustomPaint(
                  painter: ConnectionPainter(allNodes, dragPositions: _dragPositions),
                  child: Stack(
                    children: allNodes
                        .map((node) => _buildNode(context, node, provider))
                        .toList(),
                  ),
                ),
              );
            },
          ),
        ),
        if (_connectingFromId != null)
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Chip(
                label: const Text('Tap another node to connect'),
                deleteIcon: const Icon(Icons.close),
                onDeleted: () => setState(() => _connectingFromId = null),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNode(
    BuildContext context,
    MindMapNode node,
    MindMapProvider provider,
  ) {
    // Use transient drag position if dragging, otherwise persisted position
    final position = _dragPositions[node.id] ?? Offset(node.x, node.y);
    final isSelected = _selectedNodeId == node.id;
    final isConnecting = _connectingFromId == node.id;

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onPanStart: (_) => _handleDragStart(node.id),
        onPanUpdate: (details) => _handleDragUpdate(
          node.id,
          position.dx + details.delta.dx,
          position.dy + details.delta.dy,
        ),
        onPanEnd: (_) => _handleDragEnd(node.id, provider),
        onTap: () {
          if (_connectingFromId != null) {
            if (_connectingFromId != node.id) {
              provider.connectNodes(_connectingFromId!, node.id);
            }
            setState(() => _connectingFromId = null);
          } else {
            setState(() => _selectedNodeId = isSelected ? null : node.id);
          }
        },
        onLongPress: () => _showNodeMenu(context, node, provider),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Color(node.color),
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected || isConnecting ? Colors.white : Colors.transparent,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                node.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Start dragging - initialize transient state
  void _handleDragStart(String nodeId) {
    _currentDragNodeId = nodeId;
    _dragSaveTimer?.cancel();

    // Safety: periodic checkpoint during long drags
    _dragCheckpointTimer?.cancel();
    _dragCheckpointTimer = Timer.periodic(_dragCheckpointInterval, (_) {
      if (_currentDragNodeId != null) {
        _saveNodePosition(_currentDragNodeId!, isCheckpoint: true);
      }
    });

    HapticFeedback.mediumImpact();
  }

  /// Update drag - modify transient state only (no persistence)
  void _handleDragUpdate(String nodeId, double newX, double newY) {
    setState(() {
      _dragPositions[nodeId] = Offset(newX, newY);
    });
    // NO save() call here - this eliminates the 60 writes/sec!
  }

  /// End drag - debounced save to Hive
  void _handleDragEnd(String nodeId, MindMapProvider provider) {
    _currentDragNodeId = null;
    _dragCheckpointTimer?.cancel();

    // Debounced save - wait 300ms for quick successive drags
    _dragSaveTimer?.cancel();
    _dragSaveTimer = Timer(_dragSaveDelay, () {
      _saveNodePosition(nodeId, isCheckpoint: false);
    });
  }

  /// Persist node position to Hive
  void _saveNodePosition(String nodeId, {required bool isCheckpoint}) {
    final position = _dragPositions[nodeId];
    if (position == null) return;

    final provider = context.read<MindMapProvider>();
    final node = provider.allNodes.firstWhere(
      (n) => n.id == nodeId,
      orElse: () => throw StateError('Node not found'),
    );

    // Update model and save to Hive
    node.moveTo(position.dx, position.dy);

    // Clear transient state only if not a checkpoint
    if (!isCheckpoint) {
      setState(() => _dragPositions.remove(nodeId));
    }
  }

  void _showNodeMenu(
    BuildContext context,
    MindMapNode node,
    MindMapProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Connect to another node'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _connectingFromId = node.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete node'),
              onTap: () {
                Navigator.pop(ctx);
                provider.deleteNode(node.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ConnectionPainter extends CustomPainter {
  final List<MindMapNode> nodes;
  final Map<String, Offset> dragPositions; // Transient positions during drag

  ConnectionPainter(this.nodes, {this.dragPositions = const {}});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.6)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final arrowPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    for (var node in nodes) {
      // Use transient drag position if available, otherwise persisted position
      final fromPos = dragPositions[node.id] ?? Offset(node.x, node.y);
      final fromCenter = Offset(fromPos.dx + 40, fromPos.dy + 40);

      for (var toId in node.connections) {
        final toNode = nodes.firstWhere((n) => n.id == toId);
        final toPos = dragPositions[toNode.id] ?? Offset(toNode.x, toNode.y);
        final toCenter = Offset(toPos.dx + 40, toPos.dy + 40);

        // Draw line
        canvas.drawLine(fromCenter, toCenter, linePaint);

        // Draw arrowhead
        _drawArrowHead(canvas, fromCenter, toCenter, arrowPaint);
      }
    }
  }

  void _drawArrowHead(Canvas canvas, Offset from, Offset to, Paint paint) {
    const arrowSize = 12.0;
    const arrowAngle = 25 * 3.14159 / 180; // 25 degrees in radians

    // Calculate direction vector
    final direction = to - from;
    final distance = direction.distance;
    if (distance == 0) return;

    final unitDirection = direction / distance;

    // Position arrowhead slightly before the target point
    final arrowTip = to - (unitDirection * 40); // 40 is the radius of the circle

    // Calculate angle of the line
    final angle = direction.direction;

    // Calculate arrowhead points
    final arrowPoint1 = Offset(
      arrowTip.dx - arrowSize * cos(angle - arrowAngle),
      arrowTip.dy - arrowSize * sin(angle - arrowAngle),
    );

    final arrowPoint2 = Offset(
      arrowTip.dx - arrowSize * cos(angle + arrowAngle),
      arrowTip.dy - arrowSize * sin(angle + arrowAngle),
    );

    // Draw arrowhead triangle
    final path = Path()
      ..moveTo(arrowTip.dx, arrowTip.dy)
      ..lineTo(arrowPoint1.dx, arrowPoint1.dy)
      ..lineTo(arrowPoint2.dx, arrowPoint2.dy)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(ConnectionPainter oldDelegate) {
    // Drag positions changed - need to repaint arrows
    if (oldDelegate.dragPositions.length != dragPositions.length) return true;
    for (final entry in dragPositions.entries) {
      final oldPos = oldDelegate.dragPositions[entry.key];
      if (oldPos != entry.value) return true;
    }

    // Quick check: list length changed
    if (oldDelegate.nodes.length != nodes.length) return true;

    // Deep equality check for positions and connections
    for (int i = 0; i < nodes.length; i++) {
      final oldNode = oldDelegate.nodes[i];
      final newNode = nodes[i];

      if (oldNode.id != newNode.id ||
          oldNode.x != newNode.x ||
          oldNode.y != newNode.y ||
          oldNode.connections.length != newNode.connections.length) {
        return true;
      }
    }

    return false;
  }
}
