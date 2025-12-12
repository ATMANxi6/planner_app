import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import 'task_type_selector.dart';
import 'chip_input_field.dart';
import 'milestone_builder.dart';
import 'scheduling_section.dart';

/// Unified task creation and editing dialog
/// Supports all three task types with type-specific fields
/// Optional scheduling with date, time, duration, and color selection
class TaskDialog extends StatefulWidget {
  final Task? task; // null for creation, non-null for editing
  final TaskType? initialType; // For creation from specific tab
  final DateTime? initialScheduledDate; // For creation from schedule screen
  final String? initialTitle; // Pre-fill title (e.g., from Planning Canvas)
  final String? initialDescription; // Pre-fill description

  const TaskDialog({
    super.key,
    this.task,
    this.initialType,
    this.initialScheduledDate,
    this.initialTitle,
    this.initialDescription,
  });

  @override
  State<TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<TaskDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late FocusNode _nameFocusNode;

  // Basic fields
  late TaskType _selectedType;
  late Priority _selectedPriority;

  // Scheduling
  bool _isScheduled = false;
  DateTime? _scheduledStart;
  DateTime? _scheduledEnd;
  int? _scheduleColorValue;

  // Type-specific fields
  // Distraction
  late TextEditingController _replacementBehaviorController;
  List<String> _commonTriggers = [];
  late TextEditingController _costImpactController;

  // Practice
  late TextEditingController _progressMetricController;
  List<String> _resourcesNeeded = [];
  late TextEditingController _reflectionPromptController;

  // Goal
  late TextEditingController _whyPurposeController;
  late TextEditingController _successCriteriaController;
  List<Milestone> _milestones = [];
  List<Subtask> _subtasks = [];
  List<String> _linkedPracticeIds = []; // Supporting practices for this goal

  // Additional options
  bool _showAdditionalOptions = false;
  DateTime? _deadline;
  Frequency? _frequency;
  int? _timeEstimate;
  DateTime? _reminderTime;
  Category? _category;

  // Animation
  late AnimationController _animationController;

  // Track if form has been modified
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeValues();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();

    // Auto-focus name field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.task == null) {
        _nameFocusNode.requestFocus();
      }
    });
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _nameFocusNode = FocusNode();
    _replacementBehaviorController = TextEditingController();
    _costImpactController = TextEditingController();
    _progressMetricController = TextEditingController();
    _reflectionPromptController = TextEditingController();
    _whyPurposeController = TextEditingController();
    _successCriteriaController = TextEditingController();
  }

  void _initializeValues() {
    if (widget.task != null) {
      // Editing existing task
      final task = widget.task!;
      _nameController.text = task.name;
      _descriptionController.text = task.description;
      _selectedType = task.type;
      _selectedPriority = task.priority;

      // Scheduling
      _isScheduled = task.isScheduled;
      _scheduledStart = task.scheduledStart;
      _scheduledEnd = task.scheduledEnd;
      _scheduleColorValue = task.scheduleColorValue;

      // Type-specific
      _replacementBehaviorController.text = task.replacementBehavior ?? '';
      _commonTriggers = List.from(task.commonTriggers);
      _costImpactController.text = task.costImpact ?? '';

      _progressMetricController.text = task.progressMetric ?? '';
      _resourcesNeeded = List.from(task.resourcesNeeded);
      _reflectionPromptController.text = task.reflectionPrompt ?? '';

      _whyPurposeController.text = task.whyPurpose ?? '';
      _successCriteriaController.text = task.successCriteria ?? '';
      _milestones = List.from(task.milestones);
      _subtasks = List.from(task.subtasks);
      _linkedPracticeIds = List.from(task.supportingPractices);

      // Additional options
      _deadline = task.deadline;
      _frequency = task.frequency;
      _timeEstimate = task.timeEstimate;
      _reminderTime = task.reminderTime;
      _category = task.category;
      _showAdditionalOptions = _deadline != null || _frequency != null ||
          _timeEstimate != null || _reminderTime != null || _category != null;
    } else {
      // Creating new task
      _selectedType = widget.initialType ?? TaskType.practice;
      _selectedPriority = Priority.medium;

      // Pre-fill title and description if provided (e.g., from Planning Canvas)
      if (widget.initialTitle != null) {
        _nameController.text = widget.initialTitle!;
      }
      if (widget.initialDescription != null) {
        _descriptionController.text = widget.initialDescription!;
      }

      // If scheduled date is provided, auto-enable scheduling
      if (widget.initialScheduledDate != null) {
        _isScheduled = true;
        _scheduledStart = widget.initialScheduledDate;
        _scheduledEnd = widget.initialScheduledDate!.add(const Duration(hours: 1));
        _scheduleColorValue = _selectedType.colorValue;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _nameFocusNode.dispose();
    _replacementBehaviorController.dispose();
    _costImpactController.dispose();
    _progressMetricController.dispose();
    _reflectionPromptController.dispose();
    _whyPurposeController.dispose();
    _successCriteriaController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _markAsModified() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = context.read<TaskProvider>();

    if (widget.task == null) {
      // Create new task
      final newTask = await provider.createTask(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        priority: _selectedPriority,
        scheduledStart: _isScheduled ? _scheduledStart : null,
        scheduledEnd: _isScheduled ? _scheduledEnd : null,
        scheduleColorValue: _isScheduled ? _scheduleColorValue : null,
        // Distraction fields
        replacementBehavior: _selectedType == TaskType.distraction
            ? _replacementBehaviorController.text.trim().nullIfEmpty()
            : null,
        commonTriggers: _selectedType == TaskType.distraction ? _commonTriggers : null,
        costImpact: _selectedType == TaskType.distraction
            ? _costImpactController.text.trim().nullIfEmpty()
            : null,
        // Practice fields
        progressMetric: _selectedType == TaskType.practice
            ? _progressMetricController.text.trim().nullIfEmpty()
            : null,
        resourcesNeeded: _selectedType == TaskType.practice ? _resourcesNeeded : null,
        reflectionPrompt: _selectedType == TaskType.practice
            ? _reflectionPromptController.text.trim().nullIfEmpty()
            : null,
        // Goal fields
        whyPurpose: _selectedType == TaskType.goal
            ? _whyPurposeController.text.trim().nullIfEmpty()
            : null,
        successCriteria: _selectedType == TaskType.goal
            ? _successCriteriaController.text.trim().nullIfEmpty()
            : null,
        milestones: _selectedType == TaskType.goal ? _milestones : null,
        subtasks: _selectedType == TaskType.goal ? _subtasks : null,
        // Additional options
        deadline: _deadline,
        frequency: _frequency,
        timeEstimate: _timeEstimate,
        reminderTime: _reminderTime,
        category: _category,
      );

      // Link practices to goal if this is a goal task
      if (_selectedType == TaskType.goal && _linkedPracticeIds.isNotEmpty) {
        for (final practiceId in _linkedPracticeIds) {
          await provider.linkPracticeToGoal(practiceId, newTask.id);
        }
      }

      // Return the created task for integration with other features
      if (mounted) {
        Navigator.pop(context, newTask);
        return;
      }
    } else {
      // Update existing task
      final task = widget.task!;
      task.name = _nameController.text.trim();
      task.description = _descriptionController.text.trim();
      task.type = _selectedType;
      task.priority = _selectedPriority;

      task.scheduledStart = _isScheduled ? _scheduledStart : null;
      task.scheduledEnd = _isScheduled ? _scheduledEnd : null;
      task.scheduleColorValue = _isScheduled ? _scheduleColorValue : null;

      // Type-specific fields
      if (_selectedType == TaskType.distraction) {
        task.replacementBehavior = _replacementBehaviorController.text.trim().nullIfEmpty();
        task.commonTriggers = _commonTriggers;
        task.costImpact = _costImpactController.text.trim().nullIfEmpty();
      }

      if (_selectedType == TaskType.practice) {
        task.progressMetric = _progressMetricController.text.trim().nullIfEmpty();
        task.resourcesNeeded = _resourcesNeeded;
        task.reflectionPrompt = _reflectionPromptController.text.trim().nullIfEmpty();
      }

      if (_selectedType == TaskType.goal) {
        task.whyPurpose = _whyPurposeController.text.trim().nullIfEmpty();
        task.successCriteria = _successCriteriaController.text.trim().nullIfEmpty();
        task.milestones = _milestones;
        task.subtasks = _subtasks;
      }

      task.deadline = _deadline;
      task.frequency = _frequency;
      task.timeEstimate = _timeEstimate;
      task.reminderTime = _reminderTime;
      task.category = _category;

      await provider.updateTask(task);

      // Sync practice links if this is a goal task
      if (_selectedType == TaskType.goal) {
        final oldLinkedPractices = task.supportingPractices.toSet();
        final newLinkedPractices = _linkedPracticeIds.toSet();

        // Remove unlinked practices
        for (final practiceId in oldLinkedPractices.difference(newLinkedPractices)) {
          await provider.unlinkPracticeFromGoal(practiceId, task.id);
        }

        // Add new linked practices
        for (final practiceId in newLinkedPractices.difference(oldLinkedPractices)) {
          await provider.linkPracticeToGoal(practiceId, task.id);
        }
      }
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          navigator.pop();
        }
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return FadeTransition(
            opacity: _animationController,
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outline.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 16, 16),
                    child: Row(
                      children: [
                        Icon(
                          widget.task == null ? Icons.add_task : Icons.edit,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.task == null ? 'Create Task' : 'Edit Task',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () async {
                            final navigator = Navigator.of(context);
                            final shouldPop = await _onWillPop();
                            if (shouldPop && mounted) {
                              navigator.pop();
                            }
                          },
                          tooltip: 'Close',
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Content
                  Expanded(
                    child: Form(
                      key: _formKey,
                      onChanged: _markAsModified,
                      child: ListView(
                        controller: scrollController,
                        padding: EdgeInsets.fromLTRB(24, 24, 24, mediaQuery.viewInsets.bottom + 24),
                        children: [
                          // Task name
                          TextFormField(
                            controller: _nameController,
                            focusNode: _nameFocusNode,
                            decoration: InputDecoration(
                              labelText: 'Task Name',
                              hintText: 'What do you want to accomplish?',
                              prefixIcon: const Icon(Icons.task_alt),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                              counterText: '',
                            ),
                            maxLength: 100,
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a task name';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 24),

                          // Task type selector
                          TaskTypeSelector(
                            selectedType: _selectedType,
                            onChanged: (type) {
                              setState(() {
                                _selectedType = type;
                                _markAsModified();
                              });
                            },
                            enabled: widget.task == null, // Can't change type when editing
                          ),

                          const SizedBox(height: 24),

                          // Description
                          TextFormField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              labelText: 'Description (optional)',
                              hintText: 'Add more details about this task',
                              prefixIcon: const Icon(Icons.description_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            ),
                            maxLines: 3,
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.newline,
                          ),

                          const SizedBox(height: 24),

                          // Priority selector
                          _buildPrioritySelector(theme, colorScheme),

                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 24),

                          // Type-specific fields
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.1, 0.0),
                                    end: Offset.zero,
                                  ).animate(CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic,
                                  )),
                                  child: child,
                                ),
                              );
                            },
                            child: _buildTypeSpecificFields(theme, colorScheme),
                          ),

                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 24),

                          // Scheduling section
                          SchedulingSection(
                            isScheduled: _isScheduled,
                            scheduledStart: _scheduledStart,
                            scheduledEnd: _scheduledEnd,
                            scheduleColorValue: _scheduleColorValue,
                            taskType: _selectedType,
                            onScheduleToggled: (value) {
                              setState(() {
                                _isScheduled = value;
                                _markAsModified();
                              });
                            },
                            onSchedulingChanged: (data) {
                              setState(() {
                                if (data != null) {
                                  _scheduledStart = data.start;
                                  _scheduledEnd = data.end;
                                  _scheduleColorValue = data.colorValue;
                                } else {
                                  _scheduledStart = null;
                                  _scheduledEnd = null;
                                  _scheduleColorValue = null;
                                }
                                _markAsModified();
                              });
                            },
                          ),

                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 24),

                          // Additional options (collapsible)
                          _buildAdditionalOptions(theme, colorScheme),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),

                  // Footer with actions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      border: Border(
                        top: BorderSide(
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    child: SafeArea(
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final navigator = Navigator.of(context);
                                final shouldPop = await _onWillPop();
                                if (shouldPop && mounted) {
                                  navigator.pop();
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: FilledButton(
                              onPressed: _save,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: Text(widget.task == null ? 'Create Task' : 'Save Changes'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPrioritySelector(ThemeData theme, ColorScheme colorScheme) {
    return Semantics(
      label: 'Priority selector. Currently: ${_selectedPriority.name}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Priority',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<Priority>(
            segments: const [
              ButtonSegment(
                value: Priority.high,
                label: Text('High'),
                icon: Icon(Icons.priority_high, size: 18),
              ),
              ButtonSegment(
                value: Priority.medium,
                label: Text('Medium'),
                icon: Icon(Icons.remove, size: 18),
              ),
              ButtonSegment(
                value: Priority.low,
                label: Text('Low'),
                icon: Icon(Icons.low_priority, size: 18),
              ),
            ],
            selected: {_selectedPriority},
            onSelectionChanged: (selection) {
              setState(() {
                _selectedPriority = selection.first;
                _markAsModified();
              });
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return switch (_selectedPriority) {
                    Priority.high => colorScheme.error.withValues(alpha: 0.2),
                    Priority.medium => colorScheme.primary.withValues(alpha: 0.2),
                    Priority.low => colorScheme.secondary.withValues(alpha: 0.2),
                  };
                }
                return null;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return switch (_selectedPriority) {
                    Priority.high => colorScheme.error,
                    Priority.medium => colorScheme.primary,
                    Priority.low => colorScheme.secondary,
                  };
                }
                return null;
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSpecificFields(ThemeData theme, ColorScheme colorScheme) {
    return switch (_selectedType) {
      TaskType.distraction => _buildDistractionFields(theme, colorScheme),
      TaskType.practice => _buildPracticeFields(theme, colorScheme),
      TaskType.goal => _buildGoalFields(theme, colorScheme),
    };
  }

  Widget _buildDistractionFields(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      key: const ValueKey('distraction'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Distraction Details',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFFE57373),
          ),
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _replacementBehaviorController,
          decoration: InputDecoration(
            labelText: 'Replacement Behavior',
            hintText: 'What will you do instead?',
            prefixIcon: const Icon(Icons.swap_horiz),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          ),
          textCapitalization: TextCapitalization.sentences,
        ),

        const SizedBox(height: 16),

        ChipInputField(
          label: 'Common Triggers',
          hint: 'What triggers this distraction?',
          initialItems: _commonTriggers,
          icon: Icons.warning_amber,
          onChanged: (items) {
            _commonTriggers = items;
            _markAsModified();
          },
        ),

        const SizedBox(height: 16),

        TextFormField(
          controller: _costImpactController,
          decoration: InputDecoration(
            labelText: 'Cost/Impact',
            hintText: 'What does this distraction cost you?',
            prefixIcon: const Icon(Icons.trending_down),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          ),
          textCapitalization: TextCapitalization.sentences,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildPracticeFields(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      key: const ValueKey('practice'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Practice Details',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF64B5F6),
          ),
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _progressMetricController,
          decoration: InputDecoration(
            labelText: 'Progress Metric',
            hintText: 'How will you measure progress?',
            prefixIcon: const Icon(Icons.trending_up),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          ),
          textCapitalization: TextCapitalization.sentences,
        ),

        const SizedBox(height: 16),

        ChipInputField(
          label: 'Resources Needed',
          hint: 'What do you need to succeed?',
          initialItems: _resourcesNeeded,
          icon: Icons.inventory_2_outlined,
          onChanged: (items) {
            _resourcesNeeded = items;
            _markAsModified();
          },
        ),

        const SizedBox(height: 16),

        TextFormField(
          controller: _reflectionPromptController,
          decoration: InputDecoration(
            labelText: 'Reflection Prompt',
            hintText: 'A question to reflect on after completing',
            prefixIcon: const Icon(Icons.lightbulb_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          ),
          textCapitalization: TextCapitalization.sentences,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildGoalFields(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      key: const ValueKey('goal'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Goal Details',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF81C784),
          ),
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _whyPurposeController,
          decoration: InputDecoration(
            labelText: 'Why / Purpose',
            hintText: 'Why is this goal important to you?',
            prefixIcon: const Icon(Icons.favorite_border),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          ),
          textCapitalization: TextCapitalization.sentences,
          maxLines: 2,
        ),

        const SizedBox(height: 16),

        TextFormField(
          controller: _successCriteriaController,
          decoration: InputDecoration(
            labelText: 'Success Criteria',
            hintText: 'How will you know you achieved it?',
            prefixIcon: const Icon(Icons.check_circle_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          ),
          textCapitalization: TextCapitalization.sentences,
          maxLines: 2,
        ),

        const SizedBox(height: 24),

        // Supporting Practices Section
        Text(
          'Supporting Practices',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Link daily practices that help you achieve this goal',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),

        // Linked practices display
        if (_linkedPracticeIds.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _linkedPracticeIds.map((practiceId) {
              final practice = context.read<TaskProvider>().getTask(practiceId);
              if (practice == null) return const SizedBox.shrink();

              return Chip(
                label: Text(practice.name),
                avatar: const Icon(Icons.fitness_center, size: 18),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () {
                  setState(() {
                    _linkedPracticeIds.remove(practiceId);
                    _markAsModified();
                  });
                },
              );
            }).toList(),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No practices linked yet. Add practices to support this goal.',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 12),

        // Add practice button
        FilledButton.tonalIcon(
          onPressed: () => _showPracticeLinkingDialog(theme, colorScheme),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Link Practice'),
          style: FilledButton.styleFrom(
            visualDensity: VisualDensity.compact,
          ),
        ),

        const SizedBox(height: 24),

        MilestoneBuilder(
          initialMilestones: _milestones,
          onChanged: (milestones) {
            _milestones = milestones;
            _markAsModified();
          },
        ),

        const SizedBox(height: 24),

        _buildSubtasksBuilder(theme, colorScheme),
      ],
    );
  }

  Widget _buildSubtasksBuilder(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Subtasks',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: () => _addSubtask(theme, colorScheme),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        if (_subtasks.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.checklist,
                    size: 40,
                    color: colorScheme.outline.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No subtasks yet',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...List.generate(_subtasks.length, (index) {
            final subtask = _subtasks[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
              child: ListTile(
                leading: Text(
                  '${index + 1}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                title: Text(subtask.title),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    setState(() {
                      _subtasks.removeAt(index);
                      _markAsModified();
                    });
                  },
                  color: colorScheme.error,
                ),
              ),
            );
          }),
      ],
    );
  }

  void _addSubtask(ThemeData theme, ColorScheme colorScheme) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Subtask'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Subtask title',
            hintText: 'What needs to be done?',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _subtasks.add(Subtask(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: controller.text.trim(),
                  ));
                  _markAsModified();
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPracticeLinkingDialog(ThemeData theme, ColorScheme colorScheme) async {
    final taskProvider = context.read<TaskProvider>();
    final practices = taskProvider.practices
        .where((p) => !_linkedPracticeIds.contains(p.id))
        .toList();

    // Show bottom sheet with practice list
    await showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Link a Practice',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (practices.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.fitness_center,
                        size: 48,
                        color: colorScheme.outline.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No practices available',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create a practice first, then link it here',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: practices.length,
                  itemBuilder: (context, index) {
                    final practice = practices[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF64B5F6).withValues(alpha: 0.2),
                        child: const Icon(
                          Icons.fitness_center,
                          color: Color(0xFF64B5F6),
                          size: 20,
                        ),
                      ),
                      title: Text(practice.name),
                      subtitle: practice.description.isNotEmpty
                          ? Text(
                              practice.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      trailing: Icon(
                        Icons.add_circle_outline,
                        color: colorScheme.primary,
                      ),
                      onTap: () {
                        setState(() {
                          _linkedPracticeIds.add(practice.id);
                          _markAsModified();
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalOptions(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _showAdditionalOptions = !_showAdditionalOptions;
            });
          },
          child: Row(
            children: [
              Icon(
                _showAdditionalOptions ? Icons.expand_less : Icons.expand_more,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Additional Options',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),

        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          child: _showAdditionalOptions
              ? Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildDeadlinePicker(theme, colorScheme),
                    const SizedBox(height: 16),
                    _buildFrequencySelector(theme, colorScheme),
                    const SizedBox(height: 16),
                    _buildTimeEstimateField(theme, colorScheme),
                    const SizedBox(height: 16),
                    _buildCategorySelector(theme, colorScheme),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildDeadlinePicker(ThemeData theme, ColorScheme colorScheme) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.calendar_today, color: colorScheme.error),
      title: Text(
        _deadline == null ? 'No deadline' : 'Deadline: ${_deadline!.day}/${_deadline!.month}/${_deadline!.year}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_deadline != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _deadline = null;
                  _markAsModified();
                });
              },
            ),
          FilledButton.tonal(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _deadline ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 3650)),
              );
              if (date != null) {
                setState(() {
                  _deadline = date;
                  _markAsModified();
                });
              }
            },
            child: const Text('Pick Date'),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencySelector(ThemeData theme, ColorScheme colorScheme) {
    return DropdownButtonFormField<Frequency?>(
      initialValue: _frequency,
      decoration: InputDecoration(
        labelText: 'Recurrence',
        prefixIcon: const Icon(Icons.repeat),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      ),
      items: const [
        DropdownMenuItem(value: null, child: Text('None')),
        DropdownMenuItem(value: Frequency.daily, child: Text('Daily')),
        DropdownMenuItem(value: Frequency.weekly, child: Text('Weekly')),
        DropdownMenuItem(value: Frequency.monthly, child: Text('Monthly')),
      ],
      onChanged: (value) {
        setState(() {
          _frequency = value;
          _markAsModified();
        });
      },
    );
  }

  Widget _buildTimeEstimateField(ThemeData theme, ColorScheme colorScheme) {
    final controller = TextEditingController(
      text: _timeEstimate?.toString() ?? '',
    );

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Time Estimate (minutes)',
        hintText: 'How long will this take?',
        prefixIcon: const Icon(Icons.timer_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (value) {
        _timeEstimate = int.tryParse(value);
        _markAsModified();
      },
    );
  }

  Widget _buildCategorySelector(ThemeData theme, ColorScheme colorScheme) {
    return DropdownButtonFormField<Category?>(
      initialValue: _category,
      decoration: InputDecoration(
        labelText: 'Category',
        prefixIcon: const Icon(Icons.category),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      ),
      items: const [
        DropdownMenuItem(value: null, child: Text('None')),
        DropdownMenuItem(value: Category.work, child: Text('Work')),
        DropdownMenuItem(value: Category.health, child: Text('Health')),
        DropdownMenuItem(value: Category.relationships, child: Text('Relationships')),
        DropdownMenuItem(value: Category.learning, child: Text('Learning')),
        DropdownMenuItem(value: Category.personal, child: Text('Personal')),
      ],
      onChanged: (value) {
        setState(() {
          _category = value;
          _markAsModified();
        });
      },
    );
  }
}

/// Extension to convert empty string to null
extension _StringExtension on String {
  String? nullIfEmpty() => isEmpty ? null : this;
}
