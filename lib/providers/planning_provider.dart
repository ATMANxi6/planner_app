import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/planning_node.dart';
import '../services/storage_service.dart';

/// Provider for managing planning canvas nodes with hierarchy and dependencies
class PlanningProvider extends ChangeNotifier {
  final StorageService _storage;
  final _uuid = const Uuid();

  // Cache for expensive operations
  List<PlanningNode>? _cachedAllNodes;
  final Map<String, List<PlanningNode>> _childrenCache = {};

  PlanningProvider(this._storage);

  /// Invalidate all caches (called on data changes)
  void _invalidateCaches() {
    _cachedAllNodes = null;
    _childrenCache.clear();
  }

  // ========== Getters ==========

  /// Get all planning nodes (with defensive error handling and caching)
  List<PlanningNode> get allNodes {
    try {
      _cachedAllNodes ??= _storage.planningNodesBox.values.toList();
      return _cachedAllNodes!;
    } catch (e) {
      debugPrint('Error accessing planning nodes box: $e');
      return [];
    }
  }

  /// Get a single node by ID (with defensive error handling)
  PlanningNode? getNode(String id) {
    try {
      return _storage.planningNodesBox.get(id);
    } catch (e) {
      debugPrint('Error getting node $id: $e');
      return null;
    }
  }

  /// Get root nodes (no parent) sorted by priority
  List<PlanningNode> getRootNodes() {
    final roots = allNodes.where((n) => n.parentId == null).toList();

    // Sort by:
    // 1. Incomplete first
    // 2. Deadline proximity
    // 3. Manual sort order
    roots.sort((a, b) {
      // Completed nodes go to bottom
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }

      // Deadline sorting
      if (a.deadline != null && b.deadline != null) {
        return a.deadline!.compareTo(b.deadline!);
      }
      if (a.deadline != null) return -1;
      if (b.deadline != null) return 1;

      // Manual order
      return a.sortOrder.compareTo(b.sortOrder);
    });

    return roots;
  }

  /// Get children of a specific node (with caching and defensive checks)
  List<PlanningNode> getChildren(String parentId) {
    // Check cache first
    if (_childrenCache.containsKey(parentId)) {
      return _childrenCache[parentId]!;
    }

    final parent = getNode(parentId);
    if (parent == null) return [];

    try {
      final children = parent.childIds
          .map((id) => getNode(id))
          .whereType<PlanningNode>()
          .toList()
        ..sort((a, b) {
          // Sort children by:
          // 1. Incomplete first
          // 2. Dependencies (blocked items last)
          // 3. Manual sort order
          if (a.isCompleted != b.isCompleted) {
            return a.isCompleted ? 1 : -1;
          }

          final aBlocked = a.isBlocked(_storage.planningNodesBox);
          final bBlocked = b.isBlocked(_storage.planningNodesBox);
          if (aBlocked != bBlocked) {
            return aBlocked ? 1 : -1;
          }

          return a.sortOrder.compareTo(b.sortOrder);
        });

      // Cache the result
      _childrenCache[parentId] = children;
      return children;
    } catch (e) {
      debugPrint('Error getting children for $parentId: $e');
      return [];
    }
  }

  /// Get nodes by type
  List<PlanningNode> getNodesByType(PlanningNodeType type) {
    return allNodes.where((n) => n.type == type).toList();
  }

  // ========== Node CRUD Operations ==========

  /// Create a new planning node
  Future<PlanningNode> createNode({
    required String title,
    String? description,
    PlanningNodeType type = PlanningNodeType.task,
    String? parentId,
    int? colorValue,
    DateTime? deadline,
    int? timeEstimateMinutes,
    String? linkedTaskId,
  }) async {
    // Calculate hierarchy level
    int hierarchyLevel = 0;
    if (parentId != null) {
      final parent = getNode(parentId);
      hierarchyLevel = parent != null ? parent.hierarchyLevel + 1 : 0;
    }

    // Determine sort order (last in parent's children)
    int sortOrder = 0;
    if (parentId != null) {
      final siblings = getChildren(parentId);
      sortOrder = siblings.isNotEmpty
          ? siblings.map((s) => s.sortOrder).reduce((a, b) => a > b ? a : b) + 1
          : 0;
    } else {
      final rootSiblings = getRootNodes();
      sortOrder = rootSiblings.isNotEmpty
          ? rootSiblings
                  .map((s) => s.sortOrder)
                  .reduce((a, b) => a > b ? a : b) +
              1
          : 0;
    }

    final node = PlanningNode(
      id: _uuid.v4(),
      title: title,
      description: description,
      type: type,
      parentId: parentId,
      hierarchyLevel: hierarchyLevel,
      colorValue: colorValue ?? PlanningNode.getDefaultColorForType(type),
      deadline: deadline,
      timeEstimateMinutes: timeEstimateMinutes,
      linkedTaskId: linkedTaskId,
      sortOrder: sortOrder,
    );

    await _storage.planningNodesBox.put(node.id, node);

    // Add to parent's children if has parent
    if (parentId != null) {
      final parent = getNode(parentId);
      parent?.addChild(node.id);
    }

    _invalidateCaches();
    notifyListeners();
    return node;
  }

  /// Update a node's details
  Future<void> updateNode(
    String id, {
    String? title,
    String? description,
    PlanningNodeType? type,
    int? colorValue,
    DateTime? deadline,
    int? timeEstimateMinutes,
  }) async {
    final node = getNode(id);
    if (node == null) return;

    node.updateDetails(
      title: title,
      description: description,
      type: type,
      colorValue: colorValue,
      deadline: deadline,
      timeEstimateMinutes: timeEstimateMinutes,
    );

    _invalidateCaches();
    notifyListeners();
  }

  /// Delete a node and all its children
  Future<void> deleteNode(String id) async {
    final node = getNode(id);
    if (node == null) return;

    // Recursively delete children
    for (final childId in List<String>.from(node.childIds)) {
      await deleteNode(childId);
    }

    // Remove from parent's children
    if (node.parentId != null) {
      final parent = getNode(node.parentId!);
      parent?.removeChild(id);
    }

    // Remove dependencies on this node from other nodes
    for (final otherNode in allNodes) {
      if (otherNode.dependencyIds.contains(id)) {
        otherNode.removeDependency(id);
      }
    }

    await _storage.planningNodesBox.delete(id);
    _invalidateCaches();
    notifyListeners();
  }

  /// Toggle node completion
  Future<void> toggleNode(String id) async {
    final node = getNode(id);
    if (node == null) return;

    node.toggleComplete();

    // Auto-complete parent if all children complete
    if (node.isCompleted && node.parentId != null) {
      final parent = getNode(node.parentId!);
      if (parent != null) {
        final allChildrenComplete = parent.childIds.every((childId) {
          final child = getNode(childId);
          return child?.isCompleted ?? false;
        });

        if (allChildrenComplete && !parent.isCompleted) {
          parent.toggleComplete();
        }
      }
    }

    // Auto-uncomplete children if parent uncompleted
    if (!node.isCompleted && node.childIds.isNotEmpty) {
      for (final childId in node.childIds) {
        final child = getNode(childId);
        if (child != null && child.isCompleted) {
          child.toggleComplete();
        }
      }
    }

    _invalidateCaches();
    notifyListeners();
  }

  /// Toggle collapse state
  Future<void> toggleCollapse(String id) async {
    final node = getNode(id);
    if (node == null) return;

    node.toggleCollapse();
    _invalidateCaches();
    notifyListeners();
  }

  // ========== Hierarchy Management ==========

  /// Move a node to a new parent
  Future<void> moveNode(String nodeId, String? newParentId) async {
    final node = getNode(nodeId);
    if (node == null) return;

    // Remove from old parent
    if (node.parentId != null) {
      final oldParent = getNode(node.parentId!);
      oldParent?.removeChild(nodeId);
    }

    // Update node's parent
    node.parentId = newParentId;

    // Recalculate hierarchy level
    if (newParentId != null) {
      final newParent = getNode(newParentId);
      node.hierarchyLevel = newParent != null ? newParent.hierarchyLevel + 1 : 0;
    } else {
      node.hierarchyLevel = 0;
    }

    // Add to new parent
    if (newParentId != null) {
      final newParent = getNode(newParentId);
      newParent?.addChild(nodeId);
    }

    // Recalculate hierarchy for all descendants
    _recalculateChildHierarchy(nodeId);

    await node.save();
    _invalidateCaches();
    notifyListeners();
  }

  /// Notify listeners after position update (for drag handling)
  /// Does not invalidate caches as position changes don't affect hierarchy
  void notifyPositionUpdate() {
    // Don't invalidate caches - position changes don't affect node relationships
    // Just notify listeners for UI update
    notifyListeners();
  }

  /// Reorder nodes within their parent
  Future<void> reorderNodes(String parentId, int oldIndex, int newIndex) async {
    final children = getChildren(parentId);
    if (oldIndex < 0 ||
        oldIndex >= children.length ||
        newIndex < 0 ||
        newIndex >= children.length) {
      return;
    }

    final movedNode = children[oldIndex];
    children.removeAt(oldIndex);
    children.insert(newIndex, movedNode);

    // Update sort order for all children
    for (int i = 0; i < children.length; i++) {
      children[i].sortOrder = i;
      await children[i].save();
    }

    _invalidateCaches();
    notifyListeners();
  }

  /// Recalculate hierarchy levels for all children recursively
  void _recalculateChildHierarchy(String parentId) {
    final parent = getNode(parentId);
    if (parent == null) return;

    for (final childId in parent.childIds) {
      final child = getNode(childId);
      if (child != null) {
        child.hierarchyLevel = parent.hierarchyLevel + 1;
        child.save();
        _recalculateChildHierarchy(childId);
      }
    }
  }

  // ========== Dependency Management ==========

  /// Add a dependency between nodes
  Future<void> addDependency(String nodeId, String dependsOnId) async {
    final node = getNode(nodeId);
    if (node == null || nodeId == dependsOnId) return;

    // Prevent circular dependencies
    if (wouldCreateCycle(nodeId, dependsOnId)) {
      debugPrint('Cannot add dependency: would create circular dependency');
      return;
    }

    node.addDependency(dependsOnId);
    _invalidateCaches();
    notifyListeners();
  }

  /// Remove a dependency
  Future<void> removeDependency(String nodeId, String dependsOnId) async {
    final node = getNode(nodeId);
    if (node == null) return;

    node.removeDependency(dependsOnId);
    _invalidateCaches();
    notifyListeners();
  }

  /// Check if adding a dependency would create a cycle
  bool wouldCreateCycle(String fromId, String toId) {
    final visited = <String>{};
    final queue = <String>[toId];

    while (queue.isNotEmpty) {
      final currentId = queue.removeAt(0);
      if (currentId == fromId) return true;
      if (visited.contains(currentId)) continue;

      visited.add(currentId);

      final current = getNode(currentId);
      if (current != null) {
        queue.addAll(current.dependencyIds);
      }
    }

    return false;
  }

  // ========== Auto-Layout ==========

  /// Auto-arrange children based on dependencies (topological sort)
  Future<void> autoArrangeChildren(String parentId) async {
    final children = getChildren(parentId);
    if (children.length <= 1) return;

    // Topological sort
    final sorted = _topologicalSort(children);

    // Update sort order
    for (int i = 0; i < sorted.length; i++) {
      sorted[i].sortOrder = i;
      await sorted[i].save();
    }

    _invalidateCaches();
    notifyListeners();
  }

  /// Topological sort using Kahn's algorithm
  List<PlanningNode> _topologicalSort(List<PlanningNode> nodes) {
    final nodeMap = {for (var n in nodes) n.id: n};
    final inDegree = <String, int>{};
    final adjList = <String, List<String>>{};

    // Initialize
    for (final node in nodes) {
      inDegree[node.id] = 0;
      adjList[node.id] = [];
    }

    // Build adjacency list and in-degree
    for (final node in nodes) {
      for (final depId in node.dependencyIds) {
        if (nodeMap.containsKey(depId)) {
          adjList[depId]!.add(node.id);
          inDegree[node.id] = (inDegree[node.id] ?? 0) + 1;
        }
      }
    }

    // Process nodes with no dependencies
    final queue = <String>[];
    for (final entry in inDegree.entries) {
      if (entry.value == 0) {
        queue.add(entry.key);
      }
    }

    final sorted = <PlanningNode>[];
    while (queue.isNotEmpty) {
      final nodeId = queue.removeAt(0);
      sorted.add(nodeMap[nodeId]!);

      for (final neighborId in adjList[nodeId]!) {
        inDegree[neighborId] = inDegree[neighborId]! - 1;
        if (inDegree[neighborId] == 0) {
          queue.add(neighborId);
        }
      }
    }

    // If not all nodes processed, there's a cycle - return original order
    if (sorted.length != nodes.length) {
      return nodes;
    }

    return sorted;
  }

  // ========== Task Integration ==========

  /// Link a node to a task
  Future<void> linkToTask(String nodeId, String taskId) async {
    final node = getNode(nodeId);
    if (node == null) return;

    node.linkedTaskId = taskId;
    await node.save();
    _invalidateCaches();
    notifyListeners();
  }

  /// Unlink a node from its task
  Future<void> unlinkFromTask(String nodeId) async {
    final node = getNode(nodeId);
    if (node == null) return;

    node.linkedTaskId = null;
    await node.save();
    _invalidateCaches();
    notifyListeners();
  }

  /// Get all nodes linked to a specific task
  List<PlanningNode> getNodesForTask(String taskId) {
    return allNodes.where((n) => n.linkedTaskId == taskId).toList();
  }

  // ========== Project Integration ==========

  /// Get the root node (top-level ancestor) for any node
  PlanningNode? getRootNode(String nodeId) {
    var current = getNode(nodeId);
    if (current == null) return null;

    // Traverse up the hierarchy until we find a node with no parent
    while (current!.parentId != null) {
      current = getNode(current.parentId!);
      if (current == null) return null; // Safety check for orphaned nodes
    }

    return current;
  }

  /// Get the project ID associated with a node's canvas (via root node)
  String? getProjectIdForNode(String nodeId) {
    final root = getRootNode(nodeId);
    return root?.linkedProjectId;
  }

  /// Link a root node (canvas) to a project
  Future<void> linkToProject(String rootNodeId, String projectId) async {
    final node = getNode(rootNodeId);
    if (node == null) return;

    // Ensure this is a root node
    if (node.parentId != null) {
      debugPrint('Warning: Attempting to link non-root node $rootNodeId to project. Use root node instead.');
      return;
    }

    node.linkedProjectId = projectId;
    await node.save();
    _invalidateCaches();
    notifyListeners();
  }

  /// Unlink a root node from its project
  Future<void> unlinkFromProject(String rootNodeId) async {
    final node = getNode(rootNodeId);
    if (node == null) return;

    node.linkedProjectId = null;
    await node.save();
    _invalidateCaches();
    notifyListeners();
  }

  /// Get all root nodes linked to a specific project
  List<PlanningNode> getNodesForProject(String projectId) {
    return getRootNodes()
        .where((n) => n.linkedProjectId == projectId)
        .toList();
  }

  // ========== Statistics ==========

  /// Get total node count
  int get totalNodeCount => allNodes.length;

  /// Get completed node count
  int get completedNodeCount =>
      allNodes.where((n) => n.isCompleted).length;

  /// Get completion percentage
  double get completionPercentage {
    if (totalNodeCount == 0) return 0.0;
    return completedNodeCount / totalNodeCount;
  }

  /// Get nodes by deadline (upcoming)
  List<PlanningNode> getUpcomingDeadlines({int daysAhead = 7}) {
    final now = DateTime.now();
    final futureDate = now.add(Duration(days: daysAhead));

    return allNodes
        .where((n) =>
            !n.isCompleted &&
            n.deadline != null &&
            n.deadline!.isAfter(now) &&
            n.deadline!.isBefore(futureDate))
        .toList()
      ..sort((a, b) => a.deadline!.compareTo(b.deadline!));
  }
}
