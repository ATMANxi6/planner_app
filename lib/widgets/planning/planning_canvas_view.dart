import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/planning_node.dart';
import '../../providers/planning_provider.dart';
import 'planning_canvas_node.dart';
import 'planning_canvas_connection_painter.dart';

/// Interactive canvas view for planning nodes with pan/zoom and visual connections
class PlanningCanvasView extends StatefulWidget {
  const PlanningCanvasView({super.key});

  @override
  State<PlanningCanvasView> createState() => _PlanningCanvasViewState();
}

class _PlanningCanvasViewState extends State<PlanningCanvasView> {
  final TransformationController _transformController = TransformationController();
  String? _selectedNodeId;
  String? _connectingFromId;
  bool _isInitialized = false;

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
  void initState() {
    super.initState();
    // Auto-layout will be triggered after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCanvasPositions();
    });
  }

  @override
  void dispose() {
    _dragSaveTimer?.cancel();
    _dragCheckpointTimer?.cancel();
    _transformController.dispose();
    super.dispose();
  }

  /// Initialize canvas positions for nodes that don't have them yet
  Future<void> _initializeCanvasPositions() async {
    if (_isInitialized) return;

    final provider = context.read<PlanningProvider>();
    final rootNodes = provider.getRootNodes();

    // Check if any nodes need positioning
    final needsLayout = rootNodes.any((node) => !node.isPositioned);

    if (needsLayout && mounted) {
      // Import auto-layout engine and run layout
      await _runAutoLayout(rootNodes);

      // Fit to screen after layout
      _fitToScreen();

      setState(() {
        _isInitialized = true;
      });
    } else {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  /// Run auto-layout algorithm for root nodes and their children
  Future<void> _runAutoLayout(List<PlanningNode> rootNodes) async {
    final provider = context.read<PlanningProvider>();

    // Simple hierarchical layout for now
    // TODO: Replace with proper Sugiyama algorithm
    double currentY = 200.0; // Start 200px from top
    const double verticalSpacing = 180.0;
    const double horizontalSpacing = 150.0;

    for (final rootNode in rootNodes) {
      // Position root node
      if (!rootNode.isPositioned) {
        rootNode.moveTo(200.0, currentY);
      }

      // Position children in a vertical layout
      final children = provider.getChildren(rootNode.id);
      double childY = currentY;

      for (int i = 0; i < children.length; i++) {
        final child = children[i];
        if (!child.isPositioned) {
          child.moveTo(
            200.0 + horizontalSpacing * (child.hierarchyLevel),
            childY,
          );
        }
        childY += verticalSpacing;

        // Position grandchildren recursively
        _layoutChildrenRecursively(provider, child, childY, child.hierarchyLevel);
      }

      currentY += (children.isEmpty ? verticalSpacing : childY);
    }
  }

  /// Recursively layout children nodes
  void _layoutChildrenRecursively(
    PlanningProvider provider,
    PlanningNode parent,
    double startY,
    int level,
  ) {
    final children = provider.getChildren(parent.id);
    if (children.isEmpty) return;

    const double verticalSpacing = 180.0;
    const double horizontalSpacing = 150.0;
    double childY = startY;

    for (final child in children) {
      if (!child.isPositioned) {
        child.moveTo(
          200.0 + horizontalSpacing * (level + 1),
          childY,
        );
      }
      childY += verticalSpacing;

      // Recurse for grandchildren
      _layoutChildrenRecursively(provider, child, childY, level + 1);
    }
  }

  /// Calculate dynamic canvas size based on node positions
  Size _calculateCanvasSize(List<PlanningNode> nodes) {
    if (nodes.isEmpty || nodes.where((n) => n.isPositioned).isEmpty) {
      return Size(minCanvasWidth, minCanvasHeight);
    }

    final positionedNodes = nodes.where((n) => n.isPositioned).toList();

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    const double nodeWidth = 140.0;
    const double nodeHeight = 100.0;

    for (final node in positionedNodes) {
      minX = minX < node.x! ? minX : node.x!;
      minY = minY < node.y! ? minY : node.y!;
      maxX = maxX > (node.x! + nodeWidth) ? maxX : (node.x! + nodeWidth);
      maxY = maxY > (node.y! + nodeHeight) ? maxY : (node.y! + nodeHeight);
    }

    final width = (maxX - minX + (canvasPadding * 2)).clamp(minCanvasWidth, double.infinity);
    final height = (maxY - minY + (canvasPadding * 2)).clamp(minCanvasHeight, double.infinity);

    return Size(width, height);
  }

  /// Fit all nodes to screen by calculating bounding box
  void _fitToScreen() {
    final provider = context.read<PlanningProvider>();
    final allNodes = provider.allNodes.where((node) => node.isPositioned).toList();

    if (allNodes.isEmpty) {
      _transformController.value = Matrix4.identity();
      return;
    }

    // Calculate bounding box of all positioned nodes
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    const double nodeWidth = 140.0;
    const double nodeHeight = 100.0;

    for (final node in allNodes) {
      minX = minX < node.x! ? minX : node.x!;
      minY = minY < node.y! ? minY : node.y!;
      maxX = maxX > (node.x! + nodeWidth) ? maxX : (node.x! + nodeWidth);
      maxY = maxY > (node.y! + nodeHeight) ? maxY : (node.y! + nodeHeight);
    }

    // Add padding around content
    const padding = 100.0;
    minX -= padding;
    minY -= padding;
    maxX += padding;
    maxY += padding;

    // Calculate viewport size
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      _transformController.value = Matrix4.identity();
      return;
    }

    final viewportWidth = renderBox.size.width;
    final viewportHeight = renderBox.size.height;

    // Calculate content dimensions
    final contentWidth = maxX - minX;
    final contentHeight = maxY - minY;

    // Calculate scale to fit content in viewport
    final scaleX = viewportWidth / contentWidth;
    final scaleY = viewportHeight / contentHeight;
    final scale = (scaleX < scaleY ? scaleX : scaleY).clamp(0.3, 2.0);

    // Calculate translation to center content
    final translateX = (viewportWidth / scale - contentWidth) / 2 - minX;
    final translateY = (viewportHeight / scale - contentHeight) / 2 - minY;

    // Apply transformation using non-deprecated methods
    final matrix = Matrix4.diagonal3Values(scale, scale, 1.0);
    matrix.setTranslationRaw(translateX * scale, translateY * scale, 0);
    _transformController.value = matrix;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main canvas with pan/zoom
        InteractiveViewer(
          transformationController: _transformController,
          boundaryMargin: const EdgeInsets.all(400),
          minScale: 0.3,
          maxScale: 2.0,
          child: Consumer<PlanningProvider>(
            builder: (context, provider, _) {
              final allNodes = provider.allNodes;

              // Recalculate canvas size when nodes change
              _canvasSize = _calculateCanvasSize(allNodes);

              return SizedBox(
                width: _canvasSize!.width,
                height: _canvasSize!.height,
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: PlanningCanvasConnectionPainter(
                      nodes: allNodes,
                      selectedNodeId: _selectedNodeId,
                      dragPositions: _dragPositions,
                    ),
                    child: Stack(
                      children: allNodes
                          .where((node) => node.isPositioned)
                          .map((node) => _buildCanvasNode(context, node, provider))
                          .toList(),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Connection mode indicator
        if (_connectingFromId != null)
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.link, size: 20),
                      const SizedBox(width: 8),
                      const Text('Tap another node to create dependency'),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _connectingFromId = null),
                        iconSize: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Zoom controls (bottom-right)
        Positioned(
          right: 16,
          bottom: 16,
          child: Card(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _zoomIn,
                  tooltip: 'Zoom In',
                ),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: _zoomOut,
                  tooltip: 'Zoom Out',
                ),
                IconButton(
                  icon: const Icon(Icons.fit_screen),
                  onPressed: _fitToScreen,
                  tooltip: 'Fit to Screen',
                ),
              ],
            ),
          ),
        ),

        // Loading indicator
        if (!_isInitialized)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }

  Widget _buildCanvasNode(
    BuildContext context,
    PlanningNode node,
    PlanningProvider provider,
  ) {
    if (!node.isPositioned) return const SizedBox.shrink();

    // Use transient drag position if dragging, otherwise persisted position
    final position = _dragPositions[node.id] ?? Offset(node.x!, node.y!);
    final isSelected = _selectedNodeId == node.id;
    final isConnecting = _connectingFromId == node.id;

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: RepaintBoundary(
        child: PlanningCanvasNode(
          key: ValueKey(node.id),
          node: node,
          isSelected: isSelected,
          isConnecting: isConnecting,
          onPanStart: () => _handleDragStart(node.id),
          onPanUpdate: (details) => _handleDragUpdate(
            node.id,
            position.dx + details.delta.dx,
            position.dy + details.delta.dy,
          ),
          onPanEnd: () => _handleDragEnd(node.id, provider),
          onTap: () => _handleNodeTap(node, provider),
          onLongPress: () => _handleNodeLongPress(context, node, provider),
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
  void _handleDragEnd(String nodeId, PlanningProvider provider) {
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

    final provider = context.read<PlanningProvider>();
    final node = provider.getNode(nodeId);
    if (node == null) return;

    // Update model and save to Hive
    node.moveTo(position.dx, position.dy);

    // Clear transient state only if not a checkpoint
    if (!isCheckpoint) {
      setState(() => _dragPositions.remove(nodeId));
    }
  }

  void _handleNodeTap(PlanningNode node, PlanningProvider provider) {
    if (_connectingFromId != null) {
      // Complete connection
      if (_connectingFromId != node.id) {
        // Check for cycles before adding dependency
        if (!provider.wouldCreateCycle(_connectingFromId!, node.id)) {
          provider.addDependency(_connectingFromId!, node.id);
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dependency created'),
              duration: Duration(seconds: 1),
            ),
          );
        } else {
          HapticFeedback.heavyImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot create dependency - would cause circular reference'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      setState(() => _connectingFromId = null);
    } else {
      // Select/deselect node
      HapticFeedback.selectionClick();
      setState(() {
        _selectedNodeId = _selectedNodeId == node.id ? null : node.id;
      });
    }
  }

  void _handleNodeLongPress(
    BuildContext context,
    PlanningNode node,
    PlanningProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Create Dependency'),
              subtitle: const Text('Tap another node to create a dependency link'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _connectingFromId = node.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.select_all),
              title: const Text('Select Node'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _selectedNodeId = node.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle),
              title: Text(node.isCompleted ? 'Mark Incomplete' : 'Mark Complete'),
              onTap: () {
                Navigator.pop(ctx);
                provider.toggleNode(node.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _zoomIn() {
    final currentScale = _transformController.value.getMaxScaleOnAxis();
    final newScale = (currentScale * 1.2).clamp(0.3, 2.0);
    _transformController.value = Matrix4.diagonal3Values(newScale, newScale, 1.0);
  }

  void _zoomOut() {
    final currentScale = _transformController.value.getMaxScaleOnAxis();
    final newScale = (currentScale / 1.2).clamp(0.3, 2.0);
    _transformController.value = Matrix4.diagonal3Values(newScale, newScale, 1.0);
  }
}
