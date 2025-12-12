import 'package:flutter/material.dart';

/// Custom painter for drawing connection lines between parent and children
class ConnectionLinePainter extends CustomPainter {
  final int level;
  final bool hasChildren;
  final Color color;

  ConnectionLinePainter({
    required this.level,
    required this.hasChildren,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!hasChildren) return;

    final dashPaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw vertical line from top to bottom
    const startX = 12.0;
    final path = Path();
    path.moveTo(startX, 0);
    path.lineTo(startX, size.height);

    // Draw dashed line
    _drawDashedPath(canvas, path, dashPaint, 4, 4);
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint,
    double dashWidth,
    double dashSpace,
  ) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final length = draw ? dashWidth : dashSpace;
        if (distance + length > metric.length) {
          if (draw) {
            canvas.drawPath(
              metric.extractPath(distance, metric.length),
              paint,
            );
          }
          break;
        }
        if (draw) {
          canvas.drawPath(
            metric.extractPath(distance, distance + length),
            paint,
          );
        }
        distance += length;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(covariant ConnectionLinePainter oldDelegate) {
    return oldDelegate.level != level ||
        oldDelegate.hasChildren != hasChildren ||
        oldDelegate.color != color;
  }
}
