import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/planning_node.dart';

/// CustomPainter for drawing dependency arrows between planning nodes
class PlanningCanvasConnectionPainter extends CustomPainter {
  final List<PlanningNode> nodes;
  final String? selectedNodeId;
  final Map<String, Offset> dragPositions; // Transient positions during drag

  // Cache for expensive arrowhead path calculations
  final Map<String, Path> _arrowCache = {};

  PlanningCanvasConnectionPainter({
    required this.nodes,
    this.selectedNodeId,
    this.dragPositions = const {},
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Create a map of node IDs to nodes for quick lookup
    final nodeMap = {for (var node in nodes) node.id: node};

    // Draw connections for each node's dependencies
    for (final node in nodes) {
      if (!node.isPositioned) continue;

      // Draw arrows from dependencies to this node
      for (final depId in node.dependencyIds) {
        final depNode = nodeMap[depId];
        if (depNode == null || !depNode.isPositioned) continue;

        _drawConnection(
          canvas,
          depNode,
          node,
          isHighlighted: selectedNodeId == node.id || selectedNodeId == depNode.id,
        );
      }
    }
  }

  void _drawConnection(
    Canvas canvas,
    PlanningNode from,
    PlanningNode to, {
    required bool isHighlighted,
  }) {
    // Node dimensions (matching PlanningCanvasNode)
    const double nodeWidth = 140.0;
    const double nodeHeight = 100.0;

    // Use transient drag position if available, otherwise persisted position
    final fromPos = dragPositions[from.id] ?? Offset(from.x!, from.y!);
    final toPos = dragPositions[to.id] ?? Offset(to.x!, to.y!);

    // Connection points (bottom of 'from' node to top of 'to' node)
    final fromPoint = Offset(
      fromPos.dx + nodeWidth / 2, // Center horizontally
      fromPos.dy + nodeHeight,     // Bottom of node
    );

    final toPoint = Offset(
      toPos.dx + nodeWidth / 2,   // Center horizontally
      toPos.dy,                    // Top of node
    );

    // Draw bezier curve
    final path = Path();
    path.moveTo(fromPoint.dx, fromPoint.dy);

    // Control points for smooth curve
    final controlPoint1 = Offset(
      fromPoint.dx,
      fromPoint.dy + (toPoint.dy - fromPoint.dy) / 3,
    );

    final controlPoint2 = Offset(
      toPoint.dx,
      toPoint.dy - (toPoint.dy - fromPoint.dy) / 3,
    );

    path.cubicTo(
      controlPoint1.dx, controlPoint1.dy,
      controlPoint2.dx, controlPoint2.dy,
      toPoint.dx, toPoint.dy,
    );

    // Paint for the connection line
    final paint = Paint()
      ..color = isHighlighted
          ? Colors.blue.withValues(alpha: 0.8)
          : Colors.grey.withValues(alpha: 0.5)
      ..strokeWidth = isHighlighted ? 3.0 : 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, paint);

    // Draw arrowhead at the end point
    _drawArrowhead(canvas, controlPoint2, toPoint, paint);
  }

  void _drawArrowhead(
    Canvas canvas,
    Offset controlPoint,
    Offset endPoint,
    Paint paint,
  ) {
    const arrowSize = 10.0;

    // Generate cache key based on integer position (slight inaccuracy acceptable for arrows)
    final cacheKey = '${controlPoint.dx.toInt()}_${controlPoint.dy.toInt()}_${endPoint.dx.toInt()}_${endPoint.dy.toInt()}';

    // Check cache first
    Path? cachedPath = _arrowCache[cacheKey];

    if (cachedPath == null) {
      // Calculate angle only if not cached
      final dx = endPoint.dx - controlPoint.dx;
      final dy = endPoint.dy - controlPoint.dy;
      final angle = atan2(dy, dx);

      // Calculate arrowhead points
      cachedPath = Path();
      cachedPath.moveTo(endPoint.dx, endPoint.dy);
      cachedPath.lineTo(
        endPoint.dx - arrowSize * cos(angle - pi / 6),
        endPoint.dy - arrowSize * sin(angle - pi / 6),
      );
      cachedPath.lineTo(
        endPoint.dx - arrowSize * cos(angle + pi / 6),
        endPoint.dy - arrowSize * sin(angle + pi / 6),
      );
      cachedPath.close();

      // Cache for future use (limit cache size)
      if (_arrowCache.length < 1000) {
        _arrowCache[cacheKey] = cachedPath;
      }
    }

    // Draw the cached or newly calculated arrowhead
    canvas.drawPath(
      cachedPath,
      Paint()
        ..color = paint.color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(PlanningCanvasConnectionPainter oldDelegate) {
    // Selection change always requires repaint (for highlighting)
    if (oldDelegate.selectedNodeId != selectedNodeId) return true;

    // Drag positions changed - need to repaint arrows
    if (oldDelegate.dragPositions.length != dragPositions.length) return true;
    for (final entry in dragPositions.entries) {
      final oldPos = oldDelegate.dragPositions[entry.key];
      if (oldPos != entry.value) return true;
    }

    // Quick check: list length changed
    if (oldDelegate.nodes.length != nodes.length) return true;

    // Deep equality check - O(n) cheaper than O(n²) repaint of all connections
    for (int i = 0; i < nodes.length; i++) {
      final oldNode = oldDelegate.nodes[i];
      final newNode = nodes[i];

      // Check if position or dependencies changed (affects connections)
      if (oldNode.id != newNode.id ||
          oldNode.x != newNode.x ||
          oldNode.y != newNode.y ||
          !_listEquals(oldNode.dependencyIds, newNode.dependencyIds)) {
        return true;
      }
    }

    return false;
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
