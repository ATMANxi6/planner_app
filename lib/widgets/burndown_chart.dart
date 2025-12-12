import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/task.dart';
import '../models/project.dart';

/// A burndown chart showing remaining subtask work over time
class BurndownChart extends StatelessWidget {
  final Project project;
  final List<Task> tasks;

  const BurndownChart({
    super.key,
    required this.project,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Collect all subtasks from tasks
    final allSubtasks = <({Subtask subtask, Task parentTask})>[];
    for (final task in tasks) {
      for (final subtask in task.subtasks) {
        allSubtasks.add((subtask: subtask, parentTask: task));
      }
    }

    if (allSubtasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart_outlined, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'No subtasks to track',
              style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 8),
            Text(
              'Add subtasks with time estimates to see the burndown',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Calculate burndown data based on subtasks
    final burndownData = _calculateBurndownData(allSubtasks);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatsRow(burndownData, theme),
          const SizedBox(height: 24),
          _buildLegend(theme),
          const SizedBox(height: 16),
          Expanded(child: _buildChart(burndownData, theme)),
          const SizedBox(height: 16),
          _buildSummary(burndownData, allSubtasks.length, theme),
        ],
      ),
    );
  }

  _BurndownData _calculateBurndownData(
    List<({Subtask subtask, Task parentTask})> subtasks,
  ) {
    final startDate = project.startDate;
    final endDate = project.endDate;
    final totalDays = endDate.difference(startDate).inDays + 1;
    final now = DateTime.now();

    // Total time estimate in hours from subtasks
    final totalEstimate = subtasks.fold<int>(
      0,
      (sum, item) => sum + (item.subtask.timeEstimate ?? 0),
    );
    final totalHours = totalEstimate / 60.0;

    // Build ideal burndown line
    final idealPoints = <FlSpot>[];
    for (int i = 0; i <= totalDays; i++) {
      final remaining = totalHours * (1 - i / totalDays);
      idealPoints.add(FlSpot(i.toDouble(), remaining));
    }

    // Build actual burndown line based on completed subtasks
    final actualPoints = <FlSpot>[];

    // Group completed subtasks by date
    final completedByDate = <DateTime, int>{};
    for (final item in subtasks) {
      final subtask = item.subtask;
      if (subtask.isCompleted && subtask.completedAt != null) {
        final completedDate = DateTime(
          subtask.completedAt!.year,
          subtask.completedAt!.month,
          subtask.completedAt!.day,
        );
        completedByDate[completedDate] =
            (completedByDate[completedDate] ?? 0) + (subtask.timeEstimate ?? 0);
      }
    }

    // Calculate cumulative remaining work for each day
    double remainingWork = totalHours;
    for (int i = 0; i <= totalDays; i++) {
      final currentDate = startDate.add(Duration(days: i));

      // Only add points up to today
      if (currentDate.isAfter(now)) break;

      // Subtract completed work for this day
      final dayStart = DateTime(currentDate.year, currentDate.month, currentDate.day);
      if (completedByDate.containsKey(dayStart)) {
        remainingWork -= completedByDate[dayStart]! / 60.0;
        if (remainingWork < 0) remainingWork = 0;
      }

      actualPoints.add(FlSpot(i.toDouble(), remainingWork));
    }

    // Calculate current progress
    final currentDay = now.difference(startDate).inDays;
    final daysElapsed = currentDay.clamp(0, totalDays);
    final expectedProgress = daysElapsed / totalDays;
    final actualProgress = totalHours > 0 ? 1 - (remainingWork / totalHours) : 0.0;

    return _BurndownData(
      totalHours: totalHours,
      remainingHours: remainingWork,
      idealPoints: idealPoints,
      actualPoints: actualPoints,
      totalDays: totalDays,
      daysElapsed: daysElapsed,
      startDate: startDate,
      expectedProgress: expectedProgress,
      actualProgress: actualProgress,
    );
  }

  Widget _buildStatsRow(_BurndownData data, ThemeData theme) {
    final progressDiff = data.actualProgress - data.expectedProgress;
    final status = progressDiff >= 0 ? 'Ahead' : 'Behind';
    final statusColor = progressDiff >= 0 ? Colors.green : Colors.red;

    return Row(
      children: [
        Expanded(
          child: _statCard(
            'Total Estimate',
            _formatHours(data.totalHours),
            Icons.timer,
            theme.colorScheme.primary,
            theme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            'Remaining',
            _formatHours(data.remainingHours),
            Icons.hourglass_bottom,
            Colors.orange,
            theme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            'Status',
            status,
            progressDiff >= 0 ? Icons.trending_up : Icons.trending_down,
            statusColor,
            theme,
          ),
        ),
      ],
    );
  }

  Widget _statCard(
    String label,
    String value,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem(theme.colorScheme.outline, 'Ideal Burndown', theme),
        const SizedBox(width: 24),
        _legendItem(theme.colorScheme.primary, 'Actual Progress', theme),
      ],
    );
  }

  Widget _legendItem(Color color, String label, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 3,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _buildChart(_BurndownData data, ThemeData theme) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: data.totalHours > 0 ? data.totalHours / 5 : 1,
          verticalInterval: data.totalDays > 0 ? data.totalDays / 5 : 1,
          getDrawingHorizontalLine: (value) => FlLine(
            color: theme.dividerColor.withValues(alpha: 0.3),
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (value) => FlLine(
            color: theme.dividerColor.withValues(alpha: 0.3),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            axisNameWidget: Text('Hours', style: theme.textTheme.labelSmall),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: data.totalHours > 0 ? data.totalHours / 5 : 1,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: Text('Days', style: theme.textTheme.labelSmall),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: data.totalDays > 7 ? (data.totalDays / 7).ceil().toDouble() : 1,
              getTitlesWidget: (value, meta) {
                final day = value.toInt();
                if (day > data.totalDays) return const SizedBox();
                final date = data.startDate.add(Duration(days: day));
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${date.day}/${date.month}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            left: BorderSide(color: theme.dividerColor),
            bottom: BorderSide(color: theme.dividerColor),
          ),
        ),
        minX: 0,
        maxX: data.totalDays.toDouble(),
        minY: 0,
        maxY: data.totalHours > 0 ? data.totalHours * 1.1 : 10,
        lineBarsData: [
          // Ideal burndown line (dashed)
          LineChartBarData(
            spots: data.idealPoints,
            isCurved: false,
            color: theme.colorScheme.outline,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            dashArray: [8, 4],
          ),
          // Actual progress line
          LineChartBarData(
            spots: data.actualPoints,
            isCurved: true,
            curveSmoothness: 0.2,
            color: theme.colorScheme.primary,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: theme.colorScheme.primary,
                  strokeWidth: 2,
                  strokeColor: theme.colorScheme.surface,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final isIdeal = spot.barIndex == 0;
                return LineTooltipItem(
                  '${isIdeal ? "Ideal" : "Actual"}: ${spot.y.toStringAsFixed(1)}h',
                  TextStyle(
                    color: isIdeal ? theme.colorScheme.outline : theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSummary(_BurndownData data, int totalSubtasks, ThemeData theme) {
    final completedHours = data.totalHours - data.remainingHours;
    final progressPercent = (data.actualProgress * 100).toInt();
    final expectedPercent = (data.expectedProgress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Completed',
                      style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.outline),
                    ),
                    Text(
                      _formatHours(completedHours),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Progress',
                      style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.outline),
                    ),
                    Text(
                      '$progressPercent%',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Expected',
                      style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.outline),
                    ),
                    Text(
                      '$expectedPercent%',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: data.actualProgress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Day ${data.daysElapsed} of ${data.totalDays}',
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
              ),
              Text(
                '$totalSubtasks subtasks',
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatHours(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    if (m > 0) return '${h}h ${m}m';
    return '${h}h';
  }
}

/// Data class for burndown calculations
class _BurndownData {
  final double totalHours;
  final double remainingHours;
  final List<FlSpot> idealPoints;
  final List<FlSpot> actualPoints;
  final int totalDays;
  final int daysElapsed;
  final DateTime startDate;
  final double expectedProgress;
  final double actualProgress;

  _BurndownData({
    required this.totalHours,
    required this.remainingHours,
    required this.idealPoints,
    required this.actualPoints,
    required this.totalDays,
    required this.daysElapsed,
    required this.startDate,
    required this.expectedProgress,
    required this.actualProgress,
  });
}
