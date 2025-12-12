import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/planning_node.dart';
import '../../providers/planning_provider.dart';
import 'planning_node_card.dart';
import 'connection_line_painter.dart';
import 'planning_constants.dart';

/// Recursive widget that displays a planning node and its children
class PlanningNodeTree extends StatelessWidget {
  final PlanningNode node;
  final int level;

  const PlanningNodeTree({
    super.key,
    required this.node,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    // Use Selector to only rebuild when this specific node's children change
    return Selector<PlanningProvider, List<PlanningNode>>(
      selector: (context, provider) => provider.getChildren(node.id),
      builder: (context, children, _) {
        final hasChildren = children.isNotEmpty;

        return _buildNodeTree(context, children, hasChildren);
      },
    );
  }

  Widget _buildNodeTree(BuildContext context, List<PlanningNode> children, bool hasChildren) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The node card
        Padding(
          padding: EdgeInsets.only(left: level * PlanningLayout.indentationPerLevel),
          child: PlanningNodeCard(node: node, level: level),
        ),

        // Connection line visual
        if (hasChildren && !node.isCollapsed)
          Padding(
            padding: EdgeInsets.only(left: level * PlanningLayout.indentationPerLevel),
            child: CustomPaint(
              painter: ConnectionLinePainter(
                level: level,
                hasChildren: true,
                color: Color(node.colorValue).withValues(alpha: PlanningChip.connectionLineOpacity),
              ),
              child: const SizedBox(
                height: PlanningLayout.connectionLineHeight,
                width: double.infinity,
              ),
            ),
          ),

        // Children (recursive)
        if (!node.isCollapsed)
          ...children.map((child) {
            return PlanningNodeTree(
              key: ValueKey(child.id),
              node: child,
              level: level + 1,
            );
          }),

        // Spacing after node tree
        const SizedBox(height: PlanningLayout.sectionSpacing),
      ],
    );
  }
}
