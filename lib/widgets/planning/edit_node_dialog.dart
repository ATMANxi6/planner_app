import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/planning_node.dart';
import '../../providers/planning_provider.dart';

/// Dialog for editing an existing planning node
class EditNodeDialog extends StatefulWidget {
  final PlanningNode node;

  const EditNodeDialog({super.key, required this.node});

  @override
  State<EditNodeDialog> createState() => _EditNodeDialogState();
}

class _EditNodeDialogState extends State<EditNodeDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  late PlanningNodeType _selectedType;
  DateTime? _selectedDeadline;
  int? _timeEstimateMinutes;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.node.title);
    _descriptionController = TextEditingController(text: widget.node.description ?? '');
    _selectedType = widget.node.type;
    _selectedDeadline = widget.node.deadline;
    _timeEstimateMinutes = widget.node.timeEstimateMinutes;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.edit,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Edit Node',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Node Type Selector
              Text(
                'Node Type',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: PlanningNodeType.values.map((type) {
                  final isSelected = _selectedType == type;
                  final color = Color(PlanningNode.getDefaultColorForType(type));

                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          PlanningNode.getIconForType(type),
                          size: 16,
                          color: isSelected ? Colors.white : color,
                        ),
                        const SizedBox(width: 4),
                        Text(type.name),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedType = type);
                      }
                    },
                    selectedColor: color,
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.sentences,
              ),

              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),

              const SizedBox(height: 16),

              // Optional Fields
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDeadline(context),
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _selectedDeadline != null
                            ? '${_selectedDeadline!.month}/${_selectedDeadline!.day}/${_selectedDeadline!.year}'
                            : 'Deadline',
                      ),
                    ),
                  ),
                  if (_selectedDeadline != null) ...[
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _selectedDeadline = null),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickTimeEstimate(context),
                      icon: const Icon(Icons.timer),
                      label: Text(
                        _timeEstimateMinutes != null
                            ? _formatDuration(_timeEstimateMinutes!)
                            : 'Time Est.',
                      ),
                    ),
                  ),
                  if (_timeEstimateMinutes != null) ...[
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _timeEstimateMinutes = null),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _saveChanges,
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                  ),
                ],
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDeadline(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() => _selectedDeadline = date);
    }
  }

  Future<void> _pickTimeEstimate(BuildContext context) async {
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => _TimeEstimateDialog(
        initialMinutes: _timeEstimateMinutes,
      ),
    );

    if (result != null) {
      setState(() => _timeEstimateMinutes = result);
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<PlanningProvider>();

    await provider.updateNode(
      widget.node.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      type: _selectedType,
      deadline: _selectedDeadline,
      timeEstimateMinutes: _timeEstimateMinutes,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Node updated'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
  }
}

// Time Estimate Picker Dialog
class _TimeEstimateDialog extends StatefulWidget {
  final int? initialMinutes;

  const _TimeEstimateDialog({this.initialMinutes});

  @override
  State<_TimeEstimateDialog> createState() => _TimeEstimateDialogState();
}

class _TimeEstimateDialogState extends State<_TimeEstimateDialog> {
  late int _hours;
  late int _minutes;

  @override
  void initState() {
    super.initState();
    _hours = (widget.initialMinutes ?? 0) ~/ 60;
    _minutes = (widget.initialMinutes ?? 0) % 60;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Time Estimate'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text('Hours'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: _hours > 0
                              ? () => setState(() => _hours--)
                              : null,
                        ),
                        Text(
                          '$_hours',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => setState(() => _hours++),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    const Text('Minutes'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: _minutes >= 15
                              ? () => setState(() => _minutes -= 15)
                              : null,
                        ),
                        Text(
                          '$_minutes',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: _minutes < 45
                              ? () => setState(() => _minutes += 15)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final totalMinutes = _hours * 60 + _minutes;
            Navigator.pop(context, totalMinutes > 0 ? totalMinutes : null);
          },
          child: const Text('Set'),
        ),
      ],
    );
  }
}
