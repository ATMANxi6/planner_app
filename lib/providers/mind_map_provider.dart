import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/mind_map_node.dart';
import '../services/storage_service.dart';

class MindMapProvider extends ChangeNotifier {
  final StorageService _storage;
  final _uuid = const Uuid();

  MindMapProvider(this._storage);

  List<MindMapNode> get allNodes => _storage.mindMapBox.values.toList();

  Future<MindMapNode> createNode({
    required String title,
    double x = 0,
    double y = 0,
    int color = 0xFF6200EE,
    String? linkedTaskId,
  }) async {
    final node = MindMapNode(
      id: _uuid.v4(),
      title: title,
      x: x,
      y: y,
      color: color,
      linkedTaskId: linkedTaskId,
    );
    await _storage.mindMapBox.put(node.id, node);
    notifyListeners();
    return node;
  }

  Future<void> updateNode(MindMapNode node) async {
    await node.save();
    notifyListeners();
  }

  /// Notify listeners after position update (for drag handling)
  /// Does not require async save as position is already updated in node
  void notifyPositionUpdate() {
    // Just notify listeners for UI update
    notifyListeners();
  }

  Future<void> deleteNode(String id) async {
    // Remove connections to this node from other nodes
    for (var node in allNodes) {
      if (node.connections.contains(id)) {
        node.disconnect(id);
      }
    }
    await _storage.mindMapBox.delete(id);
    notifyListeners();
  }

  Future<void> connectNodes(String fromId, String toId) async {
    final fromNode = _storage.mindMapBox.get(fromId);
    fromNode?.connectTo(toId);
    notifyListeners();
  }

  // Create a goal node with subtask child nodes
  Future<MindMapNode> createGoalNodeWithSubtasks({
    required String title,
    required String taskId,
    required List<Map<String, String>> subtasks,
    double x = 100,
    double y = 100,
    int color = 0xFF6200EE,
  }) async {
    // Create the main goal node
    final goalNode = await createNode(
      title: title,
      x: x,
      y: y,
      color: color,
      linkedTaskId: taskId,
    );

    // Create subtask nodes in a circle around the goal node
    if (subtasks.isNotEmpty) {
      final angleStep = (2 * 3.14159) / subtasks.length;
      final radius = 150.0;

      for (var i = 0; i < subtasks.length; i++) {
        final angle = i * angleStep;
        final subtaskX = x + radius * cos(angle);
        final subtaskY = y + radius * sin(angle);

        final subtaskNode = await createNode(
          title: subtasks[i]['title']!,
          x: subtaskX,
          y: subtaskY,
          color: 0xFF9C27B0, // Purple for subtasks
          linkedTaskId: null,
        );

        // Connect goal node to subtask node
        await connectNodes(goalNode.id, subtaskNode.id);
      }
    }

    return goalNode;
  }
}
