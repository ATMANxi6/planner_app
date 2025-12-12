import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../providers/project_provider.dart';
import '../screens/visualizer_screen.dart';
import '../widgets/project_dialog.dart';

/// Track screen - Stats, streaks, and project progress
class TrackScreen extends StatefulWidget {
  const TrackScreen({super.key});

  @override
  State<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends State<TrackScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Rebuild when tab changes to show/hide FAB
    _tabController.addListener(() {
      setState(() {});
    });
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
        title: const Text('Track'),
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.primary,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          tabs: const [
            Tab(icon: Icon(Icons.analytics), text: 'Stats'),
            Tab(icon: Icon(Icons.account_tree), text: 'Projects'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatsTab(),
          _buildProjectsTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 1
          ? Consumer<ProjectProvider>(
              builder: (context, projectProvider, child) {
                // Only show FAB if there are projects (empty state has its own button)
                if (projectProvider.allProjects.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Semantics(
                  label: 'Create new project',
                  button: true,
                  child: FloatingActionButton.extended(
                    onPressed: () => _showCreateProjectDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('New Project'),
                  ),
                );
              },
            )
          : null,
    );
  }

  void _showCreateProjectDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ProjectDialog(),
    );
  }

  Widget _buildStatsTab() {
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        final colorScheme = Theme.of(context).colorScheme;
        final today = DateTime.now();

        // Calculate stats
        final allTasks = provider.allTasks;
        final todayTasks = provider.getScheduledTasksForDate(today);
        final completedToday = todayTasks.where((t) => t.isCompleted).length;
        final totalScheduledToday = provider.getTotalScheduledTime(today);
        final completedScheduledToday = provider.getCompletedScheduledTime(today);

        final distractions = provider.distractions;
        final practices = provider.practices;
        final goals = provider.goals;

        final completedTasks = allTasks.where((t) => t.isCompleted).length;
        final completionRate = allTasks.isEmpty ? 0.0 : completedTasks / allTasks.length;

        // Calculate streaks
        final maxDistractionsStreak = distractions.isEmpty ? 0 :
            distractions.map((t) => t.streakCount).reduce((a, b) => a > b ? a : b);
        final maxPracticeStreak = practices.isEmpty ? 0 :
            practices.map((t) => t.streakCount).reduce((a, b) => a > b ? a : b);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Today's Summary
            _buildSectionHeader('Today\'s Summary', Icons.today, colorScheme),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              color: colorScheme.primaryContainer.withValues(alpha: 0.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildStatRow(
                      'Tasks Scheduled',
                      '${todayTasks.length}',
                      Icons.event,
                      colorScheme.primary,
                    ),
                    const Divider(height: 24),
                    _buildStatRow(
                      'Tasks Completed',
                      '$completedToday',
                      Icons.check_circle,
                      colorScheme.tertiary,
                    ),
                    const Divider(height: 24),
                    _buildStatRow(
                      'Time Scheduled',
                      '${(totalScheduledToday / 60).toStringAsFixed(1)} hrs',
                      Icons.schedule,
                      colorScheme.secondary,
                    ),
                    const Divider(height: 24),
                    _buildStatRow(
                      'Time Completed',
                      '${(completedScheduledToday / 60).toStringAsFixed(1)} hrs',
                      Icons.done_all,
                      Colors.green,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Overall Stats
            _buildSectionHeader('Overall Statistics', Icons.bar_chart, colorScheme),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '${allTasks.length}',
                    'Total Tasks',
                    Icons.task_alt,
                    colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '$completedTasks',
                    'Completed',
                    Icons.check_circle,
                    colorScheme.tertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '${(completionRate * 100).toInt()}%',
                    'Completion Rate',
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '${provider.scheduledTasks.length}',
                    'Scheduled',
                    Icons.event,
                    colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Streaks
            _buildSectionHeader('🔥 Streaks', Icons.local_fire_department, colorScheme),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStreakCard(
                    '$maxDistractionsStreak',
                    'Days Avoided',
                    Icons.block,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStreakCard(
                    '$maxPracticeStreak',
                    'Practice Streak',
                    Icons.fitness_center,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Task Types Breakdown
            _buildSectionHeader('Task Types', Icons.pie_chart, colorScheme),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildTaskTypeRow(
                      'Distractions',
                      distractions.length,
                      distractions.where((t) => t.isCompleted).length,
                      Icons.block,
                      Colors.red,
                    ),
                    const Divider(height: 24),
                    _buildTaskTypeRow(
                      'Practices',
                      practices.length,
                      practices.where((t) => t.isCompleted).length,
                      Icons.fitness_center,
                      Colors.blue,
                    ),
                    const Divider(height: 24),
                    _buildTaskTypeRow(
                      'Goals',
                      goals.length,
                      goals.where((t) => t.isCompleted).length,
                      Icons.flag,
                      Colors.green,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProjectsTab() {
    return Consumer2<ProjectProvider, TaskProvider>(
      builder: (context, projectProvider, taskProvider, child) {
        final projects = projectProvider.allProjects;
        final colorScheme = Theme.of(context).colorScheme;

        if (projects.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_tree,
                      size: 64,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'No Projects Yet',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Projects help you organize related tasks and\ntrack progress with Gantt charts, Kanban\nboards, and burndown charts.',
                    style: TextStyle(
                      fontSize: 15,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () => _showCreateProjectDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Your First Project'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: projects.length,
          itemBuilder: (context, index) {
            final project = projects[index];
            final projectTasks = taskProvider.getTasksByProject(project.id);
            final completion = taskProvider.getProjectSubtaskCompletion(project.id);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  // Set the selected project before navigating
                  projectProvider.selectProject(project.id);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VisualizerScreen(),
                    ),
                  );
                },
                onLongPress: () => _showProjectOptions(context, project, projectProvider),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.folder,
                            color: Color(project.colorValue),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              project.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.more_vert),
                            iconSize: 20,
                            onPressed: () => _showProjectOptions(context, project, projectProvider),
                            tooltip: 'Project options',
                            constraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                          ),
                        ],
                      ),
                      if (project.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          project.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Progress',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: completion,
                                  backgroundColor: colorScheme.surfaceContainerHighest,
                                  color: Color(project.colorValue),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '${(completion * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(project.colorValue),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.task_alt,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${projectTasks.length} tasks',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.timer,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${(taskProvider.getProjectSubtaskTotalTime(project.id) / 60).toStringAsFixed(1)}h',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showProjectOptions(BuildContext context, project, ProjectProvider projectProvider) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Project name
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.folder,
                    color: Color(project.colorValue),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      project.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // View details
            Semantics(
              label: 'View project details',
              button: true,
              child: ListTile(
                leading: Icon(Icons.visibility, color: colorScheme.primary),
                title: const Text('View Details'),
                onTap: () {
                  Navigator.pop(context);
                  projectProvider.selectProject(project.id);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VisualizerScreen(),
                    ),
                  );
                },
              ),
            ),

            // Edit project
            Semantics(
              label: 'Edit project',
              button: true,
              child: ListTile(
                leading: Icon(Icons.edit, color: colorScheme.secondary),
                title: const Text('Edit Project'),
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => ProjectDialog(project: project),
                  );
                },
              ),
            ),

            // Delete project
            Semantics(
              label: 'Delete project',
              button: true,
              child: ListTile(
                leading: Icon(Icons.delete, color: colorScheme.error),
                title: const Text('Delete Project'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context, project, projectProvider);
                },
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, project, ProjectProvider projectProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project?'),
        content: RichText(
          text: TextSpan(
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
            ),
            children: [
              const TextSpan(text: 'Are you sure you want to delete '),
              TextSpan(
                text: project.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '?\n\nTasks will remain but lose their project association.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await projectProvider.deleteProject(project.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${project.name} deleted'),
                    behavior: SnackBarBehavior.floating,
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () {
                        // Note: Undo would require more complex state management
                        // For now, just showing the action pattern
                      },
                    ),
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ColorScheme colorScheme) {
    return Semantics(
      header: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOutCubic,
              builder: (context, animValue, child) {
                return Opacity(
                  opacity: animValue,
                  child: Transform.scale(
                    scale: animValue,
                    child: child,
                  ),
                );
              },
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: color.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard(String value, String label, IconData icon, Color color) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: color.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 36),
            ),
            const SizedBox(height: 12),
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.elasticOut,
              builder: (context, animValue, child) {
                return Transform.scale(
                  scale: 0.5 + (animValue * 0.5),
                  child: Opacity(
                    opacity: animValue.clamp(0.0, 1.0),
                    child: child,
                  ),
                );
              },
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: -1,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskTypeRow(
    String label,
    int total,
    int completed,
    IconData icon,
    Color color,
  ) {
    final percentage = total == 0 ? 0.0 : completed / total;

    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: percentage,
                backgroundColor: Colors.grey[200],
                color: color,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$completed/$total',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
