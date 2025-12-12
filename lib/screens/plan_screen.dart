import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../widgets/task_card.dart';
import '../widgets/task_dialog.dart';

/// Plan screen - Unified view of all tasks organized by type
class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan'),
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.primary,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          tabs: const [
            Tab(icon: Icon(Icons.block), text: 'Avoid'),
            Tab(icon: Icon(Icons.fitness_center), text: 'Practice'),
            Tab(icon: Icon(Icons.flag), text: 'Goals'),
          ],
        ),
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildTaskList(taskProvider, TaskType.distraction, colorScheme),
              _buildTaskList(taskProvider, TaskType.practice, colorScheme),
              _buildTaskList(taskProvider, TaskType.goal, colorScheme),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateTaskDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }

  Widget _buildTaskList(
    TaskProvider provider,
    TaskType type,
    ColorScheme colorScheme,
  ) {
    final tasks = provider.getTasksByType(type);

    if (tasks.isEmpty) {
      return _buildEmptyState(type, colorScheme);
    }

    // Group tasks: Scheduled vs Unscheduled
    final scheduled = tasks.where((t) => t.isScheduled).toList();
    final unscheduled = tasks.where((t) => !t.isScheduled).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary stats
        _buildStatsCard(tasks, colorScheme),
        const SizedBox(height: 16),

        // Scheduled tasks section
        if (scheduled.isNotEmpty) ...[
          _buildSectionHeader(
            'Scheduled (${scheduled.length})',
            Icons.event,
            colorScheme,
          ),
          const SizedBox(height: 8),
          ...scheduled.asMap().entries.map((entry) {
            final index = entry.key;
            final task = entry.value;
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 300 + (index * 50)),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TaskCard(task: task, showScheduleInfo: true),
              ),
            );
          }),
          const SizedBox(height: 16),
        ],

        // Unscheduled tasks section
        if (unscheduled.isNotEmpty) ...[
          _buildSectionHeader(
            'Unscheduled (${unscheduled.length})',
            Icons.pending_actions,
            colorScheme,
          ),
          const SizedBox(height: 8),
          ...unscheduled.asMap().entries.map((entry) {
            final index = entry.key;
            final task = entry.value;
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 300 + (index * 50)),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TaskCard(task: task, showScheduleInfo: false),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildStatsCard(List<Task> tasks, ColorScheme colorScheme) {
    final completed = tasks.where((t) => t.isCompleted).length;
    final scheduled = tasks.where((t) => t.isScheduled).length;
    final completionRate = tasks.isEmpty ? 0.0 : completed / tasks.length;

    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              '${tasks.length}',
              'Total',
              Icons.task_alt,
              colorScheme.primary,
            ),
            Container(
              width: 1,
              height: 40,
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
            _buildStatItem(
              '$completed',
              'Done',
              Icons.check_circle,
              colorScheme.tertiary,
            ),
            Container(
              width: 1,
              height: 40,
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
            _buildStatItem(
              '$scheduled',
              'Scheduled',
              Icons.event,
              colorScheme.secondary,
            ),
            Container(
              width: 1,
              height: 40,
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
            _buildStatItem(
              '${(completionRate * 100).toInt()}%',
              'Complete',
              Icons.trending_up,
              colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color color) {
    return Semantics(
      label: '$label: $value',
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.scale(
                  scale: value,
                  child: child,
                ),
              );
            },
            child: Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ColorScheme colorScheme) {
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.outline.withValues(alpha: 0.3),
                      colorScheme.outline.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(TaskType type, ColorScheme colorScheme) {
    String message;
    IconData icon;

    switch (type) {
      case TaskType.distraction:
        message = 'No distractions to avoid yet.\nTap + to track habits you want to eliminate.';
        icon = Icons.block;
        break;
      case TaskType.practice:
        message = 'No practices added yet.\nTap + to build positive daily habits.';
        icon = Icons.fitness_center;
        break;
      case TaskType.goal:
        message = 'No goals set yet.\nTap + to define your objectives.';
        icon = Icons.flag;
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: colorScheme.outline.withValues(alpha: 0.5)),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateTaskDialog(BuildContext context) {
    final currentType = TaskType.values[_tabController.index];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskDialog(initialType: currentType),
    );
  }
}
