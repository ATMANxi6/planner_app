import 'package:hive/hive.dart';

part 'project.g.dart';

@HiveType(typeId: 11)
class Project extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String description;

  @HiveField(3)
  int colorValue; // Store color as int for Hive compatibility

  @HiveField(4)
  DateTime startDate;

  @HiveField(5)
  DateTime endDate;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  DateTime? updatedAt;

  Project({
    required this.id,
    required this.name,
    this.description = '',
    required this.colorValue,
    required this.startDate,
    required this.endDate,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Calculate project duration in days
  int get durationDays => endDate.difference(startDate).inDays + 1;

  /// Check if project is overdue
  bool get isOverdue => DateTime.now().isAfter(endDate);

  /// Check if project is active (started but not ended)
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  /// Days remaining until end date
  int get daysRemaining {
    final remaining = endDate.difference(DateTime.now()).inDays;
    return remaining < 0 ? 0 : remaining;
  }

  /// Progress percentage based on time elapsed
  double get timeProgress {
    final totalDays = durationDays;
    if (totalDays <= 0) return 1.0;

    final elapsed = DateTime.now().difference(startDate).inDays;
    if (elapsed <= 0) return 0.0;
    if (elapsed >= totalDays) return 1.0;

    return elapsed / totalDays;
  }
}
