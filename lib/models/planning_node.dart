import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'planning_node.g.dart';

/// Type of planning node for different visualization and behavior
@HiveType(typeId: 19)
enum PlanningNodeType {
  @HiveField(0)
  goal, // Large strategic objectives
  @HiveField(1)
  milestone, // Phase markers with time estimates
  @HiveField(2)
  task, // Actionable work items
  @HiveField(3)
  note, // Context and documentation
  @HiveField(4)
  decision, // Decision points with branches
}

/// Type of connection between nodes
@HiveType(typeId: 20)
enum ConnectionType {
  @HiveField(0)
  sequential, // Must complete before next
  @HiveField(1)
  parallel, // Can do simultaneously
  @HiveField(2)
  conditional, // If/then relationship
  @HiveField(3)
  optional, // Nice to have, not required
}

/// Represents a connection between two planning nodes
@HiveType(typeId: 21)
class NodeConnection extends HiveObject {
  @HiveField(0)
  String fromNodeId;

  @HiveField(1)
  String toNodeId;

  @HiveField(2)
  ConnectionType type;

  NodeConnection({
    required this.fromNodeId,
    required this.toNodeId,
    this.type = ConnectionType.sequential,
  });
}

/// Node in the planning canvas with hierarchy and dependencies
@HiveType(typeId: 22)
class PlanningNode extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  PlanningNodeType type;

  @HiveField(4)
  String? parentId; // Parent node in hierarchy

  @HiveField(5)
  List<String> childIds; // Children nodes

  @HiveField(6)
  int hierarchyLevel; // 0=root, 1=child, 2=grandchild, etc.

  @HiveField(7)
  bool isCollapsed; // UI state for expand/collapse

  @HiveField(8)
  int colorValue; // Color for visual distinction

  @HiveField(9)
  String? linkedTaskId; // Link to Task model

  @HiveField(18)
  String? linkedProjectId; // Link to Project model (meaningful only for root nodes)

  @HiveField(19)
  double? x; // Canvas X position (null = not yet positioned)

  @HiveField(20)
  double? y; // Canvas Y position (null = not yet positioned)

  @HiveField(10)
  DateTime? deadline;

  @HiveField(11)
  int? timeEstimateMinutes;

  @HiveField(12)
  bool isCompleted;

  @HiveField(13)
  List<String> dependencyIds; // IDs of nodes this depends on

  @HiveField(14)
  int sortOrder; // Manual ordering within parent

  @HiveField(15)
  final DateTime createdAt;

  @HiveField(16)
  DateTime? completedAt;

  @HiveField(17)
  DateTime? updatedAt;

  PlanningNode({
    required this.id,
    required this.title,
    this.description,
    this.type = PlanningNodeType.task,
    this.parentId,
    List<String>? childIds,
    this.hierarchyLevel = 0,
    this.isCollapsed = false,
    this.colorValue = 0xFF6200EE,
    this.linkedTaskId,
    this.linkedProjectId,
    this.x,
    this.y,
    this.deadline,
    this.timeEstimateMinutes,
    this.isCompleted = false,
    List<String>? dependencyIds,
    this.sortOrder = 0,
    DateTime? createdAt,
    this.completedAt,
    this.updatedAt,
  })  : childIds = childIds ?? [],
        dependencyIds = dependencyIds ?? [],
        createdAt = createdAt ?? DateTime.now();

  /// Get count of completed children
  int getCompletedChildrenCount(Box<PlanningNode> nodesBox) {
    return childIds.where((id) {
      final child = nodesBox.get(id);
      return child != null && child.isCompleted;
    }).length;
  }

  /// Get total children count
  int get totalChildrenCount => childIds.length;

  /// Calculate progress percentage (0.0 to 1.0)
  double getProgressPercentage(Box<PlanningNode> nodesBox) {
    if (totalChildrenCount == 0) {
      return isCompleted ? 1.0 : 0.0;
    }
    return getCompletedChildrenCount(nodesBox) / totalChildrenCount;
  }

  /// Check if node is blocked by incomplete dependencies
  bool isBlocked(Box<PlanningNode> nodesBox) {
    if (dependencyIds.isEmpty) return false;

    return dependencyIds.any((depId) {
      final dep = nodesBox.get(depId);
      return dep != null && !dep.isCompleted;
    });
  }

  /// Get list of blocking dependencies
  List<PlanningNode> getBlockingDependencies(Box<PlanningNode> nodesBox) {
    return dependencyIds
        .map((id) => nodesBox.get(id))
        .where((node) => node != null && !node.isCompleted)
        .cast<PlanningNode>()
        .toList();
  }

  /// Toggle completion status
  void toggleComplete() {
    isCompleted = !isCompleted;
    completedAt = isCompleted ? DateTime.now() : null;
    updatedAt = DateTime.now();
    save();
  }

  /// Add a child node
  void addChild(String childId) {
    if (!childIds.contains(childId)) {
      childIds = [...childIds, childId];
      updatedAt = DateTime.now();
      save();
    }
  }

  /// Remove a child node
  void removeChild(String childId) {
    childIds = childIds.where((id) => id != childId).toList();
    updatedAt = DateTime.now();
    save();
  }

  /// Add a dependency
  void addDependency(String dependencyId) {
    if (!dependencyIds.contains(dependencyId)) {
      dependencyIds = [...dependencyIds, dependencyId];
      updatedAt = DateTime.now();
      save();
    }
  }

  /// Remove a dependency
  void removeDependency(String dependencyId) {
    dependencyIds = dependencyIds.where((id) => id != dependencyId).toList();
    updatedAt = DateTime.now();
    save();
  }

  /// Toggle collapse state
  void toggleCollapse() {
    isCollapsed = !isCollapsed;
    save();
  }

  /// Update node details
  void updateDetails({
    String? title,
    String? description,
    PlanningNodeType? type,
    int? colorValue,
    DateTime? deadline,
    int? timeEstimateMinutes,
  }) {
    if (title != null) this.title = title;
    if (description != null) this.description = description;
    if (type != null) this.type = type;
    if (colorValue != null) this.colorValue = colorValue;
    if (deadline != null) this.deadline = deadline;
    if (timeEstimateMinutes != null) {
      this.timeEstimateMinutes = timeEstimateMinutes;
    }
    updatedAt = DateTime.now();
    save();
  }

  /// Move node to new canvas position
  void moveTo(double newX, double newY) {
    x = newX;
    y = newY;
    updatedAt = DateTime.now();
    save();
  }

  /// Check if node has been positioned on canvas
  bool get isPositioned => x != null && y != null;

  /// Get canvas position as Offset (null if not positioned)
  Offset? get position => (x != null && y != null) ? Offset(x!, y!) : null;

  /// Get icon for node type
  static IconData getIconForType(PlanningNodeType type) {
    switch (type) {
      case PlanningNodeType.goal:
        return Icons.flag;
      case PlanningNodeType.milestone:
        return Icons.beenhere;
      case PlanningNodeType.task:
        return Icons.task_alt;
      case PlanningNodeType.decision:
        return Icons.call_split;
      case PlanningNodeType.note:
        return Icons.note;
    }
  }

  /// Get color for node type
  static int getDefaultColorForType(PlanningNodeType type) {
    switch (type) {
      case PlanningNodeType.goal:
        return 0xFF4CAF50; // Green
      case PlanningNodeType.milestone:
        return 0xFF2196F3; // Blue
      case PlanningNodeType.task:
        return 0xFF9C27B0; // Purple
      case PlanningNodeType.decision:
        return 0xFFFF9800; // Orange
      case PlanningNodeType.note:
        return 0xFF607D8B; // Blue Grey
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PlanningNode) return false;

    // Compare only fields that affect visual rendering
    return other.id == id &&
        other.x == x &&
        other.y == y &&
        other.isCompleted == isCompleted &&
        _listEquals(other.dependencyIds, dependencyIds) &&
        _listEquals(other.childIds, childIds);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      x,
      y,
      isCompleted,
      Object.hashAll(dependencyIds),
      Object.hashAll(childIds),
    );
  }

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
