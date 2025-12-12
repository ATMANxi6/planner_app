import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/planning_node.dart';
import '../../services/storage_service.dart';

/// Compact node card for canvas view with expand/collapse functionality
class PlanningCanvasNode extends StatefulWidget {
  final PlanningNode node;
  final bool isSelected;
  final bool isConnecting;
  final VoidCallback onPanStart;
  final Function(DragUpdateDetails) onPanUpdate;
  final VoidCallback onPanEnd;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const PlanningCanvasNode({
    super.key,
    required this.node,
    required this.isSelected,
    required this.isConnecting,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<PlanningCanvasNode> createState() => _PlanningCanvasNodeState();
}

class _PlanningCanvasNodeState extends State<PlanningCanvasNode> {
  bool _isExpanded = false;

  // Node dimensions
  static const double compactWidth = 140.0;
  static const double compactHeight = 100.0;
  static const double expandedWidth = 220.0;
  // Expanded height is variable

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final storage = context.watch<StorageService>();

    final nodeColor = Color(widget.node.colorValue);
    final progress = widget.node.getProgressPercentage(storage.planningNodesBox);
    final isBlocked = widget.node.isBlocked(storage.planningNodesBox);

    return GestureDetector(
      onPanStart: (_) {
        HapticFeedback.mediumImpact();
        widget.onPanStart();
      },
      onPanUpdate: widget.onPanUpdate,
      onPanEnd: (_) => widget.onPanEnd(),
      onTap: widget.onTap,
      onDoubleTap: () {
        HapticFeedback.lightImpact();
        setState(() => _isExpanded = !_isExpanded);
      },
      onLongPress: () {
        HapticFeedback.heavyImpact();
        widget.onLongPress();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: _isExpanded ? expandedWidth : compactWidth,
        constraints: BoxConstraints(
          minHeight: _isExpanded ? 120 : compactHeight,
          maxHeight: _isExpanded ? 300 : compactHeight,
        ),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isSelected || widget.isConnecting
                ? colorScheme.primary
                : nodeColor.withValues(alpha: 0.5),
            width: widget.isSelected || widget.isConnecting ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connection handles
            _buildConnectionHandles(context, nodeColor),

            // Content - Use Flexible instead of Expanded to prevent overflow
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _isExpanded
                    ? _buildExpandedContent(theme, nodeColor, progress, isBlocked)
                    : _buildCompactContent(theme, nodeColor, progress),
              ),
            ),

            // Bottom connection handle
            _buildBottomHandle(context, nodeColor),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionHandles(BuildContext context, Color nodeColor) {
    return Center(
      child: Container(
        width: 24,
        height: 24,
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          color: nodeColor.withValues(alpha: 0.3),
          shape: BoxShape.circle,
          border: Border.all(color: nodeColor, width: 2),
        ),
        child: Icon(
          Icons.arrow_downward,
          size: 14,
          color: nodeColor,
        ),
      ),
    );
  }

  Widget _buildBottomHandle(BuildContext context, Color nodeColor) {
    return Center(
      child: Container(
        width: 24,
        height: 24,
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: nodeColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: const Icon(
          Icons.arrow_upward,
          size: 14,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCompactContent(ThemeData theme, Color nodeColor, double progress) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon + Title
        Row(
          children: [
            Icon(
              PlanningNode.getIconForType(widget.node.type),
              color: nodeColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.node.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  decoration: widget.node.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Progress bar (if has children)
        if (widget.node.totalChildrenCount > 0) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(nodeColor),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(progress * 100).toInt()}%',
            style: theme.textTheme.labelSmall,
          ),
        ],
      ],
    );
  }

  Widget _buildExpandedContent(
    ThemeData theme,
    Color nodeColor,
    double progress,
    bool isBlocked,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon + Title
          Row(
            children: [
              Icon(
                PlanningNode.getIconForType(widget.node.type),
                color: nodeColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.node.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    decoration: widget.node.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // Description
          if (widget.node.description != null &&
              widget.node.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.node.description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // Progress
          if (widget.node.totalChildrenCount > 0) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(nodeColor),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.node.getCompletedChildrenCount(context.read<StorageService>().planningNodesBox)}/${widget.node.totalChildrenCount} completed',
              style: theme.textTheme.labelSmall,
            ),
          ],

          // Metadata chips
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              if (widget.node.deadline != null)
                _MetadataChip(
                  icon: Icons.calendar_today,
                  label: _formatDate(widget.node.deadline!),
                  color: theme.colorScheme.secondary,
                ),
              if (widget.node.timeEstimateMinutes != null)
                _MetadataChip(
                  icon: Icons.timer,
                  label: '${widget.node.timeEstimateMinutes}m',
                  color: theme.colorScheme.tertiary,
                ),
              if (isBlocked)
                const _MetadataChip(
                  icon: Icons.lock,
                  label: 'Blocked',
                  color: Colors.orange,
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now).inDays;

    if (diff < 0) {
      return 'Overdue';
    } else if (diff == 0) {
      return 'Today';
    } else if (diff == 1) {
      return 'Tomorrow';
    } else if (diff < 7) {
      return '$diff days';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}

class _MetadataChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetadataChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
