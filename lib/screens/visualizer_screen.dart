import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../models/project.dart';
import '../providers/task_provider.dart';
import '../providers/project_provider.dart';
import '../widgets/gantt_chart.dart';
import '../widgets/kanban_board.dart';
import '../widgets/burndown_chart.dart';

/// Main Visualizer screen with project management and visualization tabs
class VisualizerScreen extends StatefulWidget {
  const VisualizerScreen({super.key});

  @override
  State<VisualizerScreen> createState() => _VisualizerScreenState();
}

class _VisualizerScreenState extends State<VisualizerScreen>
    with SingleTickerProviderStateMixin {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Visualizer'),
        centerTitle: false,
        backgroundColor: theme.colorScheme.surface,
        actions: [
          // Only show "Create Project" button when projects exist
          // (empty state has its own create button)
          Consumer<ProjectProvider>(
            builder: (context, projectProvider, _) {
              if (projectProvider.allProjects.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.add_box_outlined),
                  onPressed: () => _showCreateProjectDialog(context),
                  tooltip: 'Create Project',
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(context),
            tooltip: 'Help',
          ),
        ],
      ),
      body: Consumer2<ProjectProvider, TaskProvider>(
        builder: (context, projectProvider, taskProvider, _) {
          final projects = projectProvider.allProjects;
          final selectedProject = projectProvider.selectedProject;

          if (projects.isEmpty) {
            return _buildEmptyState(theme);
          }

          return Column(
            children: [
              // Project selector
              _buildProjectSelector(
                context,
                projects,
                selectedProject,
                projectProvider,
                theme,
              ),
              if (selectedProject != null) ...[
                // Tabs
                Container(
                  color: theme.colorScheme.surfaceContainerLow,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.colorScheme.outline,
                    indicatorColor: theme.colorScheme.primary,
                    tabs: const [
                      Tab(icon: Icon(Icons.timeline), text: 'Gantt'),
                      Tab(icon: Icon(Icons.view_kanban), text: 'Kanban'),
                      Tab(icon: Icon(Icons.show_chart), text: 'Burndown'),
                    ],
                  ),
                ),
                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      GanttChart(
                        project: selectedProject,
                        tasks: taskProvider.getTasksByProject(selectedProject.id),
                      ),
                      KanbanBoard(
                        project: selectedProject,
                        tasks: taskProvider.getTasksByProject(selectedProject.id),
                      ),
                      BurndownChart(
                        project: selectedProject,
                        tasks: taskProvider.getTasksByProject(selectedProject.id),
                      ),
                    ],
                  ),
                ),
              ] else
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open_outlined,
                          size: 64,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Select a project to view',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<ProjectProvider>(
        builder: (context, projectProvider, _) {
          if (projectProvider.selectedProject == null) return const SizedBox();
          return FloatingActionButton.extended(
            onPressed: () => _showAddTaskDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Task'),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_outlined,
            size: 80,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 24),
          Text(
            'No projects yet',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a project to start planning and tracking',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showCreateProjectDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Project'),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectSelector(
    BuildContext context,
    List<Project> projects,
    Project? selected,
    ProjectProvider provider,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
            theme.colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.folder_special,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: selected?.id,
              decoration: InputDecoration(
                labelText: 'Select Project',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              items: projects.map((project) {
                return DropdownMenuItem<String>(
                  value: project.id,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Color(project.colorValue),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(project.name),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (projectId) {
                provider.selectProject(projectId);
              },
            ),
          ),
          if (selected != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _showEditProjectDialog(context, selected),
              tooltip: 'Edit Project',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _showDeleteProjectDialog(context, selected),
              tooltip: 'Delete Project',
            ),
          ],
        ],
      ),
    );
  }

  void _showCreateProjectDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 30));
    Color selectedColor = Colors.blue;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Create Project'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Project Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                // Color picker
                Row(
                  children: [
                    const Text('Color: '),
                    const SizedBox(width: 8),
                    ...Colors.primaries.take(8).map((color) => GestureDetector(
                          onTap: () => setState(() => selectedColor = color),
                          child: Container(
                            width: 28,
                            height: 28,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: selectedColor == color
                                  ? Border.all(color: Colors.black, width: 2)
                                  : null,
                            ),
                          ),
                        )),
                  ],
                ),
                const SizedBox(height: 16),
                // Date pickers
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.play_arrow),
                  title: const Text('Start Date'),
                  subtitle: Text(_formatDate(startDate)),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: ctx,
                      initialDate: startDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) setState(() => startDate = date);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.stop),
                  title: const Text('End Date'),
                  subtitle: Text(_formatDate(endDate)),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: ctx,
                      initialDate: endDate,
                      firstDate: startDate,
                      lastDate: DateTime(2030),
                    );
                    if (date != null) setState(() => endDate = date);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
                context.read<ProjectProvider>().createProject(
                      name: nameController.text.trim(),
                      description: descController.text.trim(),
                      colorValue: selectedColor.toARGB32(),
                      startDate: startDate,
                      endDate: endDate,
                    );
                Navigator.pop(ctx);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProjectDialog(BuildContext context, Project project) {
    final nameController = TextEditingController(text: project.name);
    final descController = TextEditingController(text: project.description);
    DateTime startDate = project.startDate;
    DateTime endDate = project.endDate;
    Color selectedColor = Color(project.colorValue);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Edit Project'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Project Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Color: '),
                    const SizedBox(width: 8),
                    ...Colors.primaries.take(8).map((color) => GestureDetector(
                          onTap: () => setState(() => selectedColor = color),
                          child: Container(
                            width: 28,
                            height: 28,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: selectedColor == color
                                  ? Border.all(color: Colors.black, width: 2)
                                  : null,
                            ),
                          ),
                        )),
                  ],
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.play_arrow),
                  title: const Text('Start Date'),
                  subtitle: Text(_formatDate(startDate)),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: ctx,
                      initialDate: startDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) setState(() => startDate = date);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.stop),
                  title: const Text('End Date'),
                  subtitle: Text(_formatDate(endDate)),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: ctx,
                      initialDate: endDate,
                      firstDate: startDate,
                      lastDate: DateTime(2030),
                    );
                    if (date != null) setState(() => endDate = date);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
                project.name = nameController.text.trim();
                project.description = descController.text.trim();
                project.colorValue = selectedColor.toARGB32();
                project.startDate = startDate;
                project.endDate = endDate;
                context.read<ProjectProvider>().updateProject(project);
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteProjectDialog(BuildContext context, Project project) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text(
          'Are you sure you want to delete "${project.name}"?\n\n'
          'Tasks in this project will NOT be deleted, but will be unassigned.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              // Unassign all tasks from this project
              final taskProvider = context.read<TaskProvider>();
              for (final task in taskProvider.getTasksByProject(project.id)) {
                taskProvider.assignTaskToProject(task.id, null);
              }
              context.read<ProjectProvider>().deleteProject(project.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final projectProvider = context.read<ProjectProvider>();
    final taskProvider = context.read<TaskProvider>();
    final selectedProject = projectProvider.selectedProject;

    if (selectedProject == null) return;

    // Get project tasks and unassigned tasks
    final projectTasks = taskProvider.getTasksByProject(selectedProject.id);
    final unassignedTasks = taskProvider.unassignedTasks;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.add_task),
                  const SizedBox(width: 8),
                  Text(
                    'Manage ${selectedProject.name}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  // Create new parent task
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(Icons.folder_outlined, color: Theme.of(context).colorScheme.primary),
                      ),
                      title: const Text('Create Parent Task'),
                      subtitle: const Text('Add a new task category for subtasks'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(ctx);
                        _showCreateNewTaskDialog(context, selectedProject);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Add subtasks to existing project tasks
                  if (projectTasks.isNotEmpty) ...[
                    Text(
                      'Add Subtasks to Existing Tasks',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Subtasks are the actionable items shown in Gantt, Kanban, and Burndown views',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...projectTasks.map((task) => Card(
                      child: ExpansionTile(
                        leading: Icon(Icons.folder, color: Theme.of(context).colorScheme.primary),
                        title: Text(task.name),
                        subtitle: Text('${task.subtasks.length} subtasks'),
                        children: [
                          ...task.subtasks.map((subtask) => ListTile(
                            dense: true,
                            leading: Icon(
                              subtask.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                              size: 18,
                              color: subtask.isCompleted ? Colors.green : Colors.grey,
                            ),
                            title: Text(subtask.title),
                            subtitle: subtask.timeEstimate != null
                                ? Text('${subtask.timeEstimate! ~/ 60}h ${subtask.timeEstimate! % 60}m')
                                : null,
                          )),
                          ListTile(
                            leading: const Icon(Icons.add_circle_outline, color: Colors.green),
                            title: const Text('Add Subtask'),
                            onTap: () {
                              Navigator.pop(ctx);
                              _showCreateSubtaskDialog(context, task, selectedProject);
                            },
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 16),
                  ],

                  // Add existing unassigned tasks
                  if (unassignedTasks.isNotEmpty) ...[
                    Text(
                      'Add Existing Tasks',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...unassignedTasks.map((task) => _TaskAssignmentCard(
                      task: task,
                      projectId: selectedProject.id,
                    )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateSubtaskDialog(BuildContext context, Task parentTask, Project project) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final timeController = TextEditingController();
    Priority selectedPriority = Priority.medium;
    DateTime? startDate;
    DateTime? deadline;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Add Subtask to ${parentTask.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Subtask Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: timeController,
                  decoration: const InputDecoration(
                    labelText: 'Time Estimate (minutes)',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., 120 for 2 hours',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Priority>(
                  initialValue: selectedPriority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: Priority.values.map((p) {
                    return DropdownMenuItem(value: p, child: Text(p.name.toUpperCase()));
                  }).toList(),
                  onChanged: (p) {
                    if (p != null) setState(() => selectedPriority = p);
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.play_arrow),
                  title: const Text('Start Date'),
                  subtitle: Text(startDate != null ? _formatDate(startDate!) : 'Not set'),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: ctx,
                      initialDate: startDate ?? project.startDate,
                      firstDate: project.startDate,
                      lastDate: project.endDate,
                    );
                    if (date != null) setState(() => startDate = date);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.flag),
                  title: const Text('Deadline'),
                  subtitle: Text(deadline != null ? _formatDate(deadline!) : 'Not set'),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: ctx,
                      initialDate: deadline ?? (startDate ?? project.startDate),
                      firstDate: startDate ?? project.startDate,
                      lastDate: project.endDate,
                    );
                    if (date != null) setState(() => deadline = date);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty) return;

                context.read<TaskProvider>().createSubtaskWithDetails(
                  parentTask.id,
                  title: titleController.text.trim(),
                  description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                  startDate: startDate,
                  deadline: deadline,
                  timeEstimate: int.tryParse(timeController.text),
                  priority: selectedPriority,
                  kanbanStatus: KanbanStatus.backlog,
                );

                Navigator.pop(ctx);
              },
              child: const Text('Add Subtask'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateNewTaskDialog(BuildContext context, Project project) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final timeController = TextEditingController();
    TaskType selectedType = TaskType.goal;
    Priority selectedPriority = Priority.medium;
    DateTime? startDate;
    DateTime? deadline;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Create Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Task Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TaskType>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Task Type',
                    border: OutlineInputBorder(),
                  ),
                  items: TaskType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (type) {
                    if (type != null) setState(() => selectedType = type);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Priority>(
                  initialValue: selectedPriority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: Priority.values.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Text(p.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (p) {
                    if (p != null) setState(() => selectedPriority = p);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: timeController,
                  decoration: const InputDecoration(
                    labelText: 'Time Estimate (minutes)',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., 120',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.play_arrow),
                  title: const Text('Start Date'),
                  subtitle: Text(startDate != null
                      ? _formatDate(startDate!)
                      : 'Not set'),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: ctx,
                      initialDate: startDate ?? project.startDate,
                      firstDate: project.startDate,
                      lastDate: project.endDate,
                    );
                    if (date != null) setState(() => startDate = date);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.flag),
                  title: const Text('Deadline'),
                  subtitle: Text(deadline != null
                      ? _formatDate(deadline!)
                      : 'Not set'),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: ctx,
                      initialDate: deadline ?? (startDate ?? project.startDate),
                      firstDate: startDate ?? project.startDate,
                      lastDate: project.endDate,
                    );
                    if (date != null) setState(() => deadline = date);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;

                final taskProvider = context.read<TaskProvider>();
                final task = await taskProvider.createTask(
                  name: nameController.text.trim(),
                  description: descController.text.trim(),
                  type: selectedType,
                  priority: selectedPriority,
                  timeEstimate: int.tryParse(timeController.text),
                  deadline: deadline,
                );

                // Assign to project and set visualization fields
                taskProvider.assignTaskToProject(task.id, project.id);
                if (startDate != null) {
                  taskProvider.updateTaskStartDate(task.id, startDate!);
                }
                taskProvider.updateKanbanStatus(task.id, KanbanStatus.backlog);

                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline),
            SizedBox(width: 8),
            Text('Project Visualizer Help'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📊 Gantt Chart', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('• View task timelines horizontally'),
              Text('• See task dependencies as arrows'),
              Text('• Track progress visually'),
              SizedBox(height: 12),
              Text('📋 Kanban Board', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('• Drag tasks between columns'),
              Text('• Columns: Backlog → To Do → In Progress → Review → Done'),
              Text('• Tap a card to view details'),
              SizedBox(height: 12),
              Text('📉 Burndown Chart', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('• Track remaining work vs time'),
              Text('• Dashed line = ideal progress'),
              Text('• Solid line = actual progress'),
              SizedBox(height: 12),
              Text('💡 Tips', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('• Set time estimates on tasks for accurate burndown'),
              Text('• Use start dates and deadlines for Gantt view'),
              Text('• Long-press to drag cards in Kanban'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Card for assigning a task to a project
class _TaskAssignmentCard extends StatelessWidget {
  final Task task;
  final String projectId;

  const _TaskAssignmentCard({
    required this.task,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _getTypeIcon(),
        title: Text(
          task.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          task.type.name.toUpperCase(),
          style: theme.textTheme.labelSmall,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.add_circle_outline),
          color: theme.colorScheme.primary,
          onPressed: () {
            final taskProvider = context.read<TaskProvider>();
            taskProvider.assignTaskToProject(task.id, projectId);
            taskProvider.updateKanbanStatus(task.id, KanbanStatus.backlog);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Widget _getTypeIcon() {
    final (icon, color) = switch (task.type) {
      TaskType.distraction => (Icons.block, Colors.red),
      TaskType.practice => (Icons.repeat, Colors.blue),
      TaskType.goal => (Icons.flag, Colors.green),
    };
    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.2),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
