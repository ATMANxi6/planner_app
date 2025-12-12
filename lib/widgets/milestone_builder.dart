import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';

/// A builder widget for creating and managing goal milestones
/// Allows adding, editing, removing milestones with target dates
class MilestoneBuilder extends StatefulWidget {
  final List<Milestone> initialMilestones;
  final ValueChanged<List<Milestone>> onChanged;

  const MilestoneBuilder({
    super.key,
    required this.initialMilestones,
    required this.onChanged,
  });

  @override
  State<MilestoneBuilder> createState() => _MilestoneBuilderState();
}

class _MilestoneBuilderState extends State<MilestoneBuilder> {
  late List<Milestone> _milestones;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _milestones = List.from(widget.initialMilestones);
  }

  void _addMilestone() {
    showDialog(
      context: context,
      builder: (context) => _MilestoneDialog(
        onSave: (title, description, targetDate) {
          setState(() {
            _milestones.add(
              Milestone(
                id: _uuid.v4(),
                title: title,
                description: description,
                targetDate: targetDate,
              ),
            );
            widget.onChanged(_milestones);
          });
        },
      ),
    );
  }

  void _editMilestone(int index) {
    final milestone = _milestones[index];
    showDialog(
      context: context,
      builder: (context) => _MilestoneDialog(
        initialTitle: milestone.title,
        initialDescription: milestone.description,
        initialDate: milestone.targetDate,
        onSave: (title, description, targetDate) {
          setState(() {
            _milestones[index] = Milestone(
              id: milestone.id,
              title: title,
              description: description,
              targetDate: targetDate,
              isCompleted: milestone.isCompleted,
              completedAt: milestone.completedAt,
            );
            widget.onChanged(_milestones);
          });
        },
      ),
    );
  }

  void _removeMilestone(int index) {
    setState(() {
      _milestones.removeAt(index);
      widget.onChanged(_milestones);
    });
  }

  void _reorderMilestones(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _milestones.removeAt(oldIndex);
      _milestones.insert(newIndex, item);
      widget.onChanged(_milestones);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: 'Milestones section with ${_milestones.length} milestones',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Milestones',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: _addMilestone,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (_milestones.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      size: 40,
                      color: colorScheme.outline.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No milestones yet',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Break down your goal into key checkpoints',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _milestones.length,
              onReorder: _reorderMilestones,
              itemBuilder: (context, index) {
                final milestone = _milestones[index];
                return _MilestoneCard(
                  key: ValueKey(milestone.id),
                  milestone: milestone,
                  index: index,
                  onEdit: () => _editMilestone(index),
                  onDelete: () => _removeMilestone(index),
                );
              },
            ),

          if (_milestones.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8),
              child: Text(
                '${_milestones.length} ${_milestones.length == 1 ? 'milestone' : 'milestones'}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  final Milestone milestone;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MilestoneCard({
    super.key,
    required this.milestone,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Semantics(
          label: 'Milestone ${index + 1}',
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          milestone.title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (milestone.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                milestone.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (milestone.targetDate != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: colorScheme.tertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${milestone.targetDate!.day}/${milestone.targetDate!.month}/${milestone.targetDate!.year}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.tertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: onEdit,
              tooltip: 'Edit milestone',
              color: colorScheme.primary,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: onDelete,
              tooltip: 'Delete milestone',
              color: colorScheme.error,
            ),
            Icon(
              Icons.drag_handle,
              color: colorScheme.outline,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _MilestoneDialog extends StatefulWidget {
  final String? initialTitle;
  final String? initialDescription;
  final DateTime? initialDate;
  final void Function(String title, String description, DateTime? targetDate) onSave;

  const _MilestoneDialog({
    this.initialTitle,
    this.initialDescription,
    this.initialDate,
    required this.onSave,
  });

  @override
  State<_MilestoneDialog> createState() => _MilestoneDialogState();
}

class _MilestoneDialogState extends State<_MilestoneDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  DateTime? _targetDate;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _descriptionController = TextEditingController(text: widget.initialDescription ?? '');
    _targetDate = widget.initialDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)), // 10 years
    );

    if (date != null) {
      setState(() {
        _targetDate = date;
      });
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      widget.onSave(
        _titleController.text.trim(),
        _descriptionController.text.trim(),
        _targetDate,
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Text(widget.initialTitle == null ? 'Add Milestone' : 'Edit Milestone'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g., Complete research phase',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Add details about this milestone',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.calendar_today, color: colorScheme.primary),
              title: Text(
                _targetDate == null
                    ? 'No target date'
                    : '${_targetDate!.day}/${_targetDate!.month}/${_targetDate!.year}',
                style: theme.textTheme.bodyMedium,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_targetDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _targetDate = null),
                      tooltip: 'Clear date',
                    ),
                  FilledButton.tonal(
                    onPressed: _selectDate,
                    child: const Text('Pick Date'),
                  ),
                ],
              ),
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
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
