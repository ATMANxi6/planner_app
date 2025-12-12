import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

/// Utility functions for planning canvas widgets

/// Format duration in minutes to human-readable string
String formatDuration(int minutes) {
  if (minutes < 60) return '${minutes}m';
  final hours = minutes ~/ 60;
  final mins = minutes % 60;
  return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
}

/// Format a date relative to today (Today, Tomorrow, Overdue, or date)
String formatDateRelative(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final targetDate = DateTime(date.year, date.month, date.day);

  if (targetDate == today) {
    return 'Today';
  } else if (targetDate == today.add(const Duration(days: 1))) {
    return 'Tomorrow';
  } else if (targetDate.isBefore(today)) {
    return 'Overdue';
  } else {
    return DateFormat('MMM d').format(date);
  }
}

/// Get color for deadline based on urgency
Color getDeadlineColor(DateTime deadline) {
  final now = DateTime.now();
  final daysUntil = deadline.difference(now).inDays;

  if (daysUntil < 0) return Colors.red; // Overdue
  if (daysUntil <= 1) return Colors.orange; // Due soon
  if (daysUntil <= 3) return Colors.amber; // This week
  return Colors.green; // Future
}

/// Format date as short string (MMM d format)
String formatDateShort(DateTime date) {
  return DateFormat('MMM d').format(date);
}
