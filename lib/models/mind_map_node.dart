import 'package:hive/hive.dart';

part 'mind_map_node.g.dart';

@HiveType(typeId: 2)
class MindMapNode extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  double x;

  @HiveField(3)
  double y;

  @HiveField(4)
  List<String> connections;

  @HiveField(5)
  int color;

  @HiveField(6)
  String? linkedTaskId;

  MindMapNode({
    required this.id,
    required this.title,
    this.x = 0,
    this.y = 0,
    this.connections = const [],
    this.color = 0xFF6200EE,
    this.linkedTaskId,
  });

  void moveTo(double newX, double newY) {
    x = newX;
    y = newY;
    save();
  }

  void connectTo(String nodeId) {
    if (!connections.contains(nodeId)) {
      connections = [...connections, nodeId];
      save();
    }
  }

  void disconnect(String nodeId) {
    connections = connections.where((id) => id != nodeId).toList();
    save();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MindMapNode) return false;

    return other.id == id &&
        other.x == x &&
        other.y == y &&
        _listEquals(other.connections, connections);
  }

  @override
  int get hashCode => Object.hash(id, x, y, Object.hashAll(connections));

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
