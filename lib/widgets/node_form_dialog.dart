import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/mind_map_provider.dart';
import '../providers/task_provider.dart';

class NodeFormDialog extends StatefulWidget {
  const NodeFormDialog({super.key});

  @override
  State<NodeFormDialog> createState() => _NodeFormDialogState();
}

class _NodeFormDialogState extends State<NodeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  Color _selectedColor = Colors.deepPurple;
  Task? _linkedGoal;

  final List<Color> _colors = [
    Colors.deepPurple,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.red,
    Colors.pink,
    Colors.teal,
    Colors.amber,
  ];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Text(
        'Add Node',
        style: theme.textTheme.headlineSmall,
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter a title' : null,
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Color',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _colors.map((color) {
                final isSelected = color == _selectedColor;
                return InkWell(
                  onTap: () => setState(() => _selectedColor = color),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? colorScheme.primary : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: colorScheme.primary.withValues(alpha: 0.4),
                                blurRadius: 8,
                                spreadRadius: 2,
                              )
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 28,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Consumer<TaskProvider>(
              builder: (context, taskProvider, _) {
                final goals = taskProvider.goals;
                return DropdownButtonFormField<Task>(
                  initialValue: _linkedGoal,
                  decoration: InputDecoration(
                    labelText: 'Link to Goal (Optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                  ),
                  hint: const Text('Select a goal task'),
                  items: [
                    const DropdownMenuItem<Task>(
                      value: null,
                      child: Text('None'),
                    ),
                    ...goals.map((goal) {
                      return DropdownMenuItem(
                        value: goal,
                        child: Text(goal.name),
                      );
                    }),
                  ],
                  onChanged: (value) => setState(() => _linkedGoal = value),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final mindMapProvider = context.read<MindMapProvider>();

      // If linked to a goal with subtasks, create goal node with subtask nodes
      if (_linkedGoal != null && _linkedGoal!.subtasks.isNotEmpty) {
        final subtasks = _linkedGoal!.subtasks.map((s) {
          return {'id': s.id, 'title': s.title};
        }).toList();

        mindMapProvider.createGoalNodeWithSubtasks(
          title: _titleController.text,
          taskId: _linkedGoal!.id,
          subtasks: subtasks,
          x: 100,
          y: 100,
          color: _selectedColor.toARGB32(),
        );
      } else {
        // Create a regular node
        mindMapProvider.createNode(
          title: _titleController.text,
          x: 100,
          y: 100,
          color: _selectedColor.toARGB32(),
          linkedTaskId: _linkedGoal?.id,
        );
      }

      Navigator.pop(context);
    }
  }
}
