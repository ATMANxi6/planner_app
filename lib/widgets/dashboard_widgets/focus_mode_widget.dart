import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/time_block.dart';
import '../../services/storage_service.dart';

/// Focus Mode Widget - Shows current or next time block for immediate focus
class FocusModeWidget extends StatelessWidget {
  const FocusModeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final storage = Provider.of<StorageService>(context);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Get all blocks for today
    final allBlocks = storage.timeBlocksBox.values.toList();
    final todayBlocks = allBlocks
        .where((block) => _isSameDay(block.date, today))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    // Find current block or next block
    final currentBlock = todayBlocks.firstWhere(
      (block) => block.isHappeningNow,
      orElse: () => TimeBlock(
        id: '',
        title: '',
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        colorValue: 0,
      ),
    );

    final hasCurrentBlock = currentBlock.id.isNotEmpty;

    final nextBlock = hasCurrentBlock
        ? null
        : todayBlocks.firstWhere(
            (block) => block.isFuture,
            orElse: () => TimeBlock(
              id: '',
              title: '',
              startTime: DateTime.now(),
              endTime: DateTime.now(),
              colorValue: 0,
            ),
          );

    final hasNextBlock = nextBlock?.id.isNotEmpty ?? false;
    final activeBlock = hasCurrentBlock ? currentBlock : nextBlock;
    final hasActiveBlock = hasCurrentBlock || hasNextBlock;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.center_focus_strong,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Focus Mode',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (hasActiveBlock)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: hasCurrentBlock
                          ? colorScheme.primaryContainer
                          : colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      hasCurrentBlock ? 'NOW' : 'NEXT',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: hasCurrentBlock
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Content
            if (!hasActiveBlock)
              _buildEmptyState(context)
            else
              _buildActiveBlock(
                context,
                activeBlock!,
                hasCurrentBlock,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(
              Icons.event_available,
              size: 48,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 8),
            Text(
              'No time blocks scheduled',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                // Navigate to Schedule screen
                // This will be handled by the navigation system
              },
              icon: const Icon(Icons.add),
              label: const Text('Schedule Time Block'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveBlock(
    BuildContext context,
    TimeBlock block,
    bool isCurrent,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final now = DateTime.now();

    // Calculate time remaining or until start
    final Duration timeValue;
    final String timeLabel;

    if (isCurrent) {
      timeValue = block.endTime.difference(now);
      timeLabel = 'Time Remaining';
    } else {
      timeValue = block.startTime.difference(now);
      timeLabel = 'Starts In';
    }

    final hours = timeValue.inHours;
    final minutes = timeValue.inMinutes.remainder(60);

    // Calculate progress for current block
    double? progress;
    if (isCurrent) {
      final totalDuration = block.endTime.difference(block.startTime).inMinutes;
      final elapsed = now.difference(block.startTime).inMinutes;
      progress = elapsed / totalDuration;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time block info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(block.colorValue).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Color(block.colorValue).withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                children: [
                  Expanded(
                    child: Text(
                      block.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Time range
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    block.formattedTimeRange,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.timer,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    block.formattedDuration,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

              // Category
              if (block.category != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(block.colorValue).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    block.category!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Color(block.colorValue),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],

              // Description
              if (block.description != null && block.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  block.description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Progress bar for current block
              if (isCurrent && progress != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(block.colorValue),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Time countdown
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isCurrent
                ? colorScheme.primaryContainer
                : colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isCurrent ? Icons.timer : Icons.access_time,
                color: isCurrent
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSecondaryContainer,
                size: 20,
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  Text(
                    timeLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isCurrent
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hours > 0
                        ? '${hours}h ${minutes}m'
                        : '${minutes}m',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isCurrent
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Action button
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              // Navigate to Schedule screen
              // This will be handled by the navigation system
            },
            icon: const Icon(Icons.calendar_month),
            label: const Text('View Full Schedule'),
          ),
        ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
