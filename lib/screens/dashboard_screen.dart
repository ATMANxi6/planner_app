import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../models/dashboard_config.dart';
import '../widgets/dashboard_widgets/daily_tasks_widget.dart';
import '../widgets/dashboard_widgets/goal_progress_widget.dart';
import '../widgets/dashboard_widgets/stats_widget.dart';
import '../widgets/dashboard_widgets/streaks_widget.dart';
import '../widgets/dashboard_widgets/projects_widget.dart';
import '../widgets/dashboard_widgets/deadlines_widget.dart';
import '../widgets/dashboard_widgets/focus_mode_widget.dart';
import '../widgets/dashboard_widgets/quick_wins_widget.dart';
import '../widgets/dashboard_widgets/canvas_progress_widget.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final storage = Provider.of<StorageService>(context, listen: false);

    // Get or create dashboard config
    DashboardConfig config;
    if (storage.dashboardConfigBox.isEmpty) {
      config = DashboardConfig.defaultConfig();
      storage.dashboardConfigBox.put('config', config);
    } else {
      config = storage.dashboardConfigBox.get('config') ?? DashboardConfig.defaultConfig();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: false,
        backgroundColor: colorScheme.surface,
      ),
      body: Builder(
        builder: (context) {
          final visibleWidgets = _getVisibleWidgets(config);

          if (visibleWidgets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.widgets_outlined,
                    size: 64,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No widgets enabled',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enable widgets in Settings',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            );
          }

          return ReorderableListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: visibleWidgets.length,
            itemBuilder: (context, index) {
              final widgetId = visibleWidgets[index];
              return Padding(
                key: ValueKey(widgetId),
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildWidget(widgetId),
              );
            },
            onReorder: (oldIndex, newIndex) {
              // Update config with new order
              final updatedOrder = List<String>.from(config.widgetOrder);
              final visibleOldIndex = config.widgetOrder.indexOf(visibleWidgets[oldIndex]);
              final visibleNewIndex = newIndex < visibleWidgets.length
                  ? config.widgetOrder.indexOf(visibleWidgets[newIndex])
                  : config.widgetOrder.length - 1;

              if (visibleOldIndex < visibleNewIndex) {
                final item = updatedOrder.removeAt(visibleOldIndex);
                updatedOrder.insert(visibleNewIndex, item);
              } else {
                final item = updatedOrder.removeAt(visibleOldIndex);
                updatedOrder.insert(visibleNewIndex, item);
              }

              config.update(widgetOrder: updatedOrder);
            },
          );
        },
      ),
    );
  }

  List<String> _getVisibleWidgets(DashboardConfig config) {
    return config.widgetOrder.where((widgetId) {
      switch (widgetId) {
        case 'focus_mode':
          return config.showFocusModeWidget;
        case 'quick_wins':
          return config.showQuickWinsWidget;
        case 'canvas_progress':
          return config.showCanvasProgressWidget;
        case 'daily_tasks':
          return config.showDailyTasksWidget;
        case 'goal_progress':
          return config.showGoalProgressWidget;
        case 'stats':
          return config.showStatsWidget;
        case 'streaks':
          return config.showStreaksWidget;
        case 'projects':
          return config.showProjectsWidget;
        case 'deadlines':
          return config.showDeadlinesWidget;
        default:
          return false;
      }
    }).toList();
  }

  Widget _buildWidget(String widgetId) {
    switch (widgetId) {
      case 'focus_mode':
        return const FocusModeWidget();
      case 'quick_wins':
        return const QuickWinsWidget();
      case 'canvas_progress':
        return const CanvasProgressWidget();
      case 'daily_tasks':
        return const DailyTasksWidget();
      case 'goal_progress':
        return const GoalProgressWidget();
      case 'stats':
        return const StatsWidget();
      case 'streaks':
        return const StreaksWidget();
      case 'projects':
        return const ProjectsWidget();
      case 'deadlines':
        return const DeadlinesWidget();
      default:
        return const SizedBox.shrink();
    }
  }
}
