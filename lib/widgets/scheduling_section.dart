import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import 'task_type_selector.dart';

/// A collapsible section for scheduling task with date, time, duration, and color
class SchedulingSection extends StatefulWidget {
  final bool isScheduled;
  final DateTime? scheduledStart;
  final DateTime? scheduledEnd;
  final int? scheduleColorValue;
  final TaskType taskType;
  final ValueChanged<bool> onScheduleToggled;
  final ValueChanged<SchedulingData?> onSchedulingChanged;

  const SchedulingSection({
    super.key,
    required this.isScheduled,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.scheduleColorValue,
    required this.taskType,
    required this.onScheduleToggled,
    required this.onSchedulingChanged,
  });

  @override
  State<SchedulingSection> createState() => _SchedulingSectionState();
}

class _SchedulingSectionState extends State<SchedulingSection> {
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late int _durationMinutes;
  late Color _selectedColor;

  // Predefined color palette for scheduling
  static const List<Color> colorPalette = [
    Color(0xFFE57373), // Red
    Color(0xFFFF8A65), // Deep Orange
    Color(0xFFFFB74D), // Orange
    Color(0xFFFFF176), // Yellow
    Color(0xFF81C784), // Green
    Color(0xFF64B5F6), // Blue
    Color(0xFF9575CD), // Purple
    Color(0xFF90A4AE), // Blue Grey
  ];

  static const List<int> durationOptions = [15, 30, 45, 60, 90, 120, 180, 240];

  @override
  void initState() {
    super.initState();
    _initializeValues();
  }

  void _initializeValues() {
    if (widget.isScheduled && widget.scheduledStart != null && widget.scheduledEnd != null) {
      _selectedDate = widget.scheduledStart!;
      _startTime = TimeOfDay.fromDateTime(widget.scheduledStart!);
      _durationMinutes = widget.scheduledEnd!.difference(widget.scheduledStart!).inMinutes;
      _selectedColor = Color(widget.scheduleColorValue ?? widget.taskType.colorValue);
    } else {
      _selectedDate = DateTime.now();
      _startTime = TimeOfDay.now();
      _durationMinutes = 60; // Default 1 hour
      _selectedColor = widget.taskType.color;
    }
  }

  void _notifyChanges() {
    if (widget.isScheduled) {
      final start = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );
      final end = start.add(Duration(minutes: _durationMinutes));

      widget.onSchedulingChanged(SchedulingData(
        start: start,
        end: end,
        colorValue: _selectedColor.toARGB32(),
      ));
    } else {
      widget.onSchedulingChanged(null);
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
        _notifyChanges();
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );

    if (time != null) {
      setState(() {
        _startTime = time;
        _notifyChanges();
      });
    }
  }

  void _setDuration(int minutes) {
    setState(() {
      _durationMinutes = minutes;
      _notifyChanges();
    });
  }

  void _setColor(Color color) {
    setState(() {
      _selectedColor = color;
      _notifyChanges();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: 'Scheduling section. ${widget.isScheduled ? 'Scheduled' : 'Not scheduled'}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle switch
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.isScheduled
                  ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.isScheduled
                    ? colorScheme.primary.withValues(alpha: 0.3)
                    : colorScheme.outline.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event,
                  color: widget.isScheduled ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Schedule this task',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: widget.isScheduled ? colorScheme.primary : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.isScheduled
                            ? 'Task will appear in your calendar'
                            : 'Add to your daily schedule',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: widget.isScheduled,
                  onChanged: (value) {
                    widget.onScheduleToggled(value);
                    if (value) {
                      _notifyChanges();
                    }
                  },
                ),
              ],
            ),
          ),

          // Scheduling details (expanded)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            child: widget.isScheduled
                ? Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildSchedulingDetails(theme, colorScheme),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulingDetails(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _selectedColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _selectedColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date picker
          _buildDetailRow(
            icon: Icons.calendar_today,
            label: 'Date',
            value: DateFormat('EEE, MMM d, yyyy').format(_selectedDate),
            onTap: _selectDate,
            theme: theme,
            colorScheme: colorScheme,
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Time picker
          _buildDetailRow(
            icon: Icons.access_time,
            label: 'Start Time',
            value: _startTime.format(context),
            onTap: _selectTime,
            theme: theme,
            colorScheme: colorScheme,
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Duration selector
          Text(
            'Duration',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: durationOptions.map((minutes) {
              final isSelected = _durationMinutes == minutes;
              return ChoiceChip(
                label: Text(_formatDuration(minutes)),
                selected: isSelected,
                onSelected: (_) => _setDuration(minutes),
                selectedColor: _selectedColor.withValues(alpha: 0.3),
                backgroundColor: colorScheme.surfaceContainerHighest,
                labelStyle: TextStyle(
                  color: isSelected ? _selectedColor : colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isSelected ? _selectedColor : colorScheme.outline.withValues(alpha: 0.2),
                  width: isSelected ? 2 : 1,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Color picker
          Text(
            'Color',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: colorPalette.map((color) {
              final isSelected = _selectedColor.toARGB32() == color.toARGB32();
              return Semantics(
                label: 'Color option ${color.toARGB32().toRadixString(16)}',
                selected: isSelected,
                button: true,
                child: InkWell(
                  onTap: () => _setColor(color),
                  borderRadius: BorderRadius.circular(25),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isSelected ? 50 : 44,
                    height: isSelected ? 50 : 44,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? colorScheme.outline : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 24)
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Preview card
          _buildPreviewCard(theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: _selectedColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colorScheme.outline),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard(ThemeData theme, ColorScheme colorScheme) {
    final start = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    final end = start.add(Duration(minutes: _durationMinutes));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _selectedColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _selectedColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.preview, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                'Schedule Preview',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                '${_formatTime(start)} - ${_formatTime(end)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.timer_outlined, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Text(
                _formatDuration(_durationMinutes),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    } else if (minutes % 60 == 0) {
      return '${minutes ~/ 60} hr';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '${hours}h ${mins}m';
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }
}

/// Data class for scheduling information
class SchedulingData {
  final DateTime start;
  final DateTime end;
  final int colorValue;

  const SchedulingData({
    required this.start,
    required this.end,
    required this.colorValue,
  });
}
