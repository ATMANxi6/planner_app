import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';

/// Dialog for selecting or creating a project for a Canvas
/// Used when creating the first task from a Canvas node
class CanvasProjectSelectorDialog extends StatefulWidget {
  final String suggestedProjectName;
  final Color suggestedColor;

  const CanvasProjectSelectorDialog({
    super.key,
    required this.suggestedProjectName,
    this.suggestedColor = const Color(0xFF6200EE),
  });

  @override
  State<CanvasProjectSelectorDialog> createState() =>
      _CanvasProjectSelectorDialogState();
}

class _CanvasProjectSelectorDialogState
    extends State<CanvasProjectSelectorDialog> {
  bool _isCreatingNew = true;
  String? _selectedProjectId;

  // For new project creation
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  Color _selectedColor = const Color(0xFF6200EE);
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.suggestedProjectName;
    _selectedColor = widget.suggestedColor;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectProvider = context.watch<ProjectProvider>();
    final existingProjects = projectProvider.allProjects;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.account_tree,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Link Canvas to Project',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info text
                    Text(
                      'All tasks created from this canvas will be automatically assigned to this project.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                    ),
                    const SizedBox(height: 20),

                    // Toggle between create new / select existing
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: true,
                          label: Text('Create New'),
                          icon: Icon(Icons.add),
                        ),
                        ButtonSegment(
                          value: false,
                          label: Text('Select Existing'),
                          icon: Icon(Icons.list),
                        ),
                      ],
                      selected: {_isCreatingNew},
                      onSelectionChanged: (Set<bool> newSelection) {
                        setState(() {
                          _isCreatingNew = newSelection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // Content based on selection
                    if (_isCreatingNew) ...[
                      _buildNewProjectForm(context),
                    ] else ...[
                      _buildExistingProjectsList(context, existingProjects),
                    ],
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _canSubmit(existingProjects)
                        ? () => _submit(context, projectProvider)
                        : null,
                    child: Text(_isCreatingNew ? 'Create Project' : 'Link Project'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewProjectForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Project name
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Project Name',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.label),
          ),
          autofocus: true,
        ),
        const SizedBox(height: 16),

        // Description
        TextField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description (optional)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),

        // Color picker
        Text(
          'Project Color',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            const Color(0xFF6200EE), // Purple
            const Color(0xFF4CAF50), // Green
            const Color(0xFF2196F3), // Blue
            const Color(0xFFFF9800), // Orange
            const Color(0xFFF44336), // Red
            const Color(0xFF9C27B0), // Purple
            const Color(0xFF00BCD4), // Cyan
            const Color(0xFFFFEB3B), // Yellow
          ].map((color) {
            final isSelected = _selectedColor == color;
            return InkWell(
              onTap: () => setState(() => _selectedColor = color),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Date range
        Row(
          children: [
            Expanded(
              child: _buildDateButton(
                context,
                'Start Date',
                _startDate,
                (date) => setState(() => _startDate = date),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDateButton(
                context,
                'End Date',
                _endDate,
                (date) => setState(() => _endDate = date),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateButton(
    BuildContext context,
    String label,
    DateTime date,
    Function(DateTime) onDateSelected,
  ) {
    return OutlinedButton.icon(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          onDateSelected(picked);
        }
      },
      icon: const Icon(Icons.calendar_today, size: 16),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          Text(
            '${date.day}/${date.month}/${date.year}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.all(12),
      ),
    );
  }

  Widget _buildExistingProjectsList(
      BuildContext context, List<Project> projects) {
    if (projects.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.inbox,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'No projects yet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create your first project to get started',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        final isSelected = _selectedProjectId == project.id;

        return Card(
          elevation: isSelected ? 2 : 0,
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Color(project.colorValue),
                shape: BoxShape.circle,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white)
                  : null,
            ),
            title: Text(project.name),
            subtitle: project.description.isEmpty
                ? null
                : Text(
                    project.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${project.durationDays} days',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (project.isOverdue)
                  Text(
                    'Overdue',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
              ],
            ),
            onTap: () {
              setState(() {
                _selectedProjectId = isSelected ? null : project.id;
              });
            },
          ),
        );
      },
    );
  }

  bool _canSubmit(List<Project> existingProjects) {
    if (_isCreatingNew) {
      return _nameController.text.trim().isNotEmpty;
    } else {
      return _selectedProjectId != null;
    }
  }

  Future<void> _submit(
      BuildContext context, ProjectProvider projectProvider) async {
    String? projectId;

    if (_isCreatingNew) {
      // Create new project
      final project = await projectProvider.createProject(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        colorValue: _selectedColor.toARGB32(),
        startDate: _startDate,
        endDate: _endDate,
      );
      projectId = project.id;
    } else {
      // Use selected project
      projectId = _selectedProjectId;
    }

    if (context.mounted && projectId != null) {
      Navigator.of(context).pop(projectId);
    }
  }
}
