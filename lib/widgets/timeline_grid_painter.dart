import 'package:flutter/material.dart';
import '../models/dashboard_config.dart';

/// Custom painter for drawing the timeline grid with hour lines and current time indicator.
///
/// Adapts grid density based on zoom level:
/// - Default: Hour lines only
/// - Zoomed in (>80px/hour): 30-minute subdivisions
/// - Very zoomed in (>150px/hour): 15-minute subdivisions
class TimelineGridPainter extends CustomPainter {
  /// Configuration with hour height and working hours
  final DashboardConfig config;

  /// The date being displayed (for "today" detection)
  final DateTime date;

  /// Whether to show the current time indicator (red line)
  final bool showCurrentTime;

  /// Theme brightness for adaptive colors
  final Brightness brightness;

  TimelineGridPainter({
    required this.config,
    required this.date,
    this.showCurrentTime = true,
    this.brightness = Brightness.light,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final hourHeight = config.hourHeight;
    final totalHours = config.totalHours;
    final isDark = brightness == Brightness.dark;

    // Color scheme based on theme - minimal and subtle
    final hourLineColor = isDark
        ? Colors.grey.shade800.withValues(alpha: 0.4)
        : Colors.grey.shade200.withValues(alpha: 0.6);
    final halfHourLineColor = hourLineColor.withValues(alpha: 0.3);
    final quarterHourLineColor = hourLineColor.withValues(alpha: 0.15);
    final textColor = isDark ? Colors.grey.shade500 : Colors.grey.shade500;

    // Paint for hour lines - lighter stroke
    final hourPaint = Paint()
      ..color = hourLineColor
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Paint for subdivision lines - very subtle
    final subdivisionPaint = Paint()
      ..strokeWidth = 0.3
      ..style = PaintingStyle.stroke;

    // Text painter for hour labels
    final textPainter = TextPainter(
      textAlign: TextAlign.right,
      textDirection: TextDirection.ltr,
    );

    // Draw hour lines and labels
    for (int hour = 0; hour <= totalHours; hour++) {
      final actualHour = config.dayStartHour + hour;
      final y = hour * hourHeight;

      // Draw main hour line
      canvas.drawLine(
        Offset(70, y),
        Offset(size.width, y),
        hourPaint,
      );

      // Draw hour label (e.g., "9 AM", "2 PM")
      if (hour < totalHours) {
        final timeLabel = _formatHourLabel(actualHour);
        textPainter.text = TextSpan(
          text: timeLabel,
          style: TextStyle(
            color: textColor,
            fontSize: 11,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.3,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(60 - textPainter.width, y + 4),
        );
      }

      // Draw 30-minute subdivision if zoomed in enough
      if (hourHeight > 80 && hour < totalHours) {
        final halfY = y + (hourHeight / 2);
        canvas.drawLine(
          Offset(70, halfY),
          Offset(size.width, halfY),
          subdivisionPaint..color = halfHourLineColor,
        );

        // Optionally draw ":30" label at high zoom
        if (hourHeight > 120) {
          textPainter.text = TextSpan(
            text: ':30',
            style: TextStyle(
              color: textColor.withValues(alpha: 0.5),
              fontSize: 10,
              fontWeight: FontWeight.w300,
              letterSpacing: 0.2,
            ),
          );
          textPainter.layout();
          textPainter.paint(
            canvas,
            Offset(60 - textPainter.width, halfY + 2),
          );
        }
      }

      // Draw 15-minute subdivisions if very zoomed in
      if (hourHeight > 150 && hour < totalHours) {
        for (int quarter = 1; quarter < 4; quarter++) {
          if (quarter == 2) continue; // Skip 30-min (already drawn)
          final quarterY = y + (hourHeight * quarter / 4);
          canvas.drawLine(
            Offset(70, quarterY),
            Offset(size.width, quarterY),
            subdivisionPaint..color = quarterHourLineColor,
          );
        }
      }
    }

    // Draw current time indicator (red line with circle) - minimal style
    if (showCurrentTime && _isToday(date)) {
      final now = DateTime.now();
      final currentY = config.timeToPixel(now);

      // Only draw if within visible working hours
      if (currentY >= 0 && currentY <= size.height) {
        // Softer red horizontal line
        canvas.drawLine(
          Offset(70, currentY),
          Offset(size.width, currentY),
          Paint()
            ..color = Colors.red.shade400.withValues(alpha: 0.8)
            ..strokeWidth = 1.5
            ..style = PaintingStyle.stroke,
        );

        // Smaller, more elegant red circle indicator
        canvas.drawCircle(
          Offset(70, currentY),
          4.0,
          Paint()
            ..color = Colors.red.shade400
            ..style = PaintingStyle.fill,
        );

        // Current time label with lighter weight
        final currentTimeLabel = _formatCurrentTimeLabel(now);
        textPainter.text = TextSpan(
          text: currentTimeLabel,
          style: TextStyle(
            color: Colors.red.shade400,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(60 - textPainter.width, currentY - 16),
        );
      }
    }
  }

  /// Formats an hour (0-23) into a readable label (e.g., "9 AM", "2 PM")
  String _formatHourLabel(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }

  /// Formats the current time with minutes (e.g., "2:34 PM")
  String _formatCurrentTimeLabel(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');

    if (hour == 0) return '12:$minute AM';
    if (hour < 12) return '$hour:$minute AM';
    if (hour == 12) return '12:$minute PM';
    return '${hour - 12}:$minute PM';
  }

  /// Checks if the given date is today
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  bool shouldRepaint(TimelineGridPainter oldDelegate) {
    // Repaint if hour height, date, or theme changes
    return oldDelegate.config.hourHeight != config.hourHeight ||
        oldDelegate.date != date ||
        oldDelegate.showCurrentTime != showCurrentTime ||
        oldDelegate.brightness != brightness;
  }
}
