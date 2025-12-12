# Quick Start Guide: Drag-and-Drop Schedule

## Overview
Your Schedule screen now has a Google Calendar-style interactive view with drag-and-drop functionality!

## What's New

### Files Created
1. **lib/widgets/time_slot_grid.dart** - Time slot grid with hour labels
2. **lib/widgets/draggable_timeblock.dart** - Draggable/resizable task blocks
3. **lib/widgets/unscheduled_tasks_panel.dart** - Bottom drawer with unscheduled tasks
4. **lib/widgets/interactive_calendar_view.dart** - Main interactive calendar

### Files Modified
1. **lib/screens/schedule_screen.dart** - Added interactive view toggle
2. **lib/providers/task_provider.dart** - Added conflict detection helpers

## How to Use

### Switching Views
- **Interactive Calendar** (default): Tap the list icon to switch to list view
- **List View**: Tap the calendar icon to return to interactive view

### Scheduling Tasks
1. Open Schedule screen
2. Bottom panel shows all unscheduled tasks
3. **Drag** a task from the panel onto any time slot
4. Task is scheduled at that time
5. If there's a conflict, you'll see a warning dialog

### Repositioning Tasks
1. **Long-press** on any scheduled task block
2. **Drag** it to a new time slot
3. Release to drop
4. Task snaps to the nearest time slot

### Resizing Tasks
1. Find the resize handles (small horizontal bars) at the top and bottom of task blocks
2. **Drag** the top edge to change start time
3. **Drag** the bottom edge to change end time
4. Minimum duration is one time slot interval

### Unscheduling Tasks
1. **Tap** on any scheduled task block
2. In the bottom sheet, tap **"Unschedule"**
3. Task moves back to unscheduled panel

### Filtering Unscheduled Tasks
1. Open the unscheduled tasks panel (drag it up)
2. Use filter chips at the top:
   - **All** - Show all task types
   - **Avoid** - Red tasks (distractions)
   - **Practice** - Blue tasks (habits)
   - **Goals** - Green tasks (objectives)

## Configuration

### Time Slot Settings
Edit `DashboardConfig` via Settings screen:
- **Time Slot Interval**: 15, 30, or 60 minutes
- **Day Start Hour**: Default 6 AM
- **Day End Hour**: Default 11 PM

### Task Colors
Tasks use default colors based on type:
- Red: Avoid tasks
- Blue: Practice tasks
- Green: Goal tasks

You can customize via `task.scheduleColorValue`

## Features

### Visual Feedback
- Drop zones highlight when dragging over them
- Current time shown with red line (when viewing today)
- Haptic feedback on drag/drop/resize
- Opacity changes during drag operations

### Smart Conflict Detection
- Automatically detects scheduling conflicts
- Shows warning dialog with conflicting tasks
- Option to schedule anyway or cancel

### Auto-Sync
- Changes immediately reflect in Plan screen
- Scheduled tasks show in "Scheduled" section
- Unscheduled tasks show in "Unscheduled" section

### Auto-Scroll
- When viewing today, automatically scrolls to current time
- Helps you quickly see your current schedule

## Tips

1. **Default Duration**: If a task has no time estimate, it uses the time slot interval (default 30 min)
2. **Snapping**: All scheduling snaps to the grid based on your time slot interval
3. **Working Hours**: You can only schedule within configured working hours
4. **Minimum Duration**: Tasks must be at least one time slot interval long
5. **Panel Control**: Drag the unscheduled panel handle up/down to expand/collapse

## Testing Checklist

- [ ] Drag unscheduled task to calendar
- [ ] Long-press and reposition existing task
- [ ] Resize task by dragging edges
- [ ] Filter unscheduled tasks by type
- [ ] View task details by tapping
- [ ] Unschedule a task
- [ ] Complete/uncomplete a task
- [ ] Check Plan screen shows correct status
- [ ] Test conflict detection
- [ ] Switch between interactive and list views

## Next Steps

1. **Run the app**: `flutter run`
2. **Navigate to Schedule screen**: Use bottom navigation
3. **Create some tasks**: Use Plan screen or Schedule list view
4. **Try drag-and-drop**: Schedule your tasks!

## Troubleshooting

### Tasks not showing in unscheduled panel
- Check that tasks exist in Plan screen
- Verify tasks don't have scheduledStart/scheduledEnd set
- Pull down panel to ensure it's expanded

### Can't drag tasks
- Ensure you're in interactive calendar view (not list view)
- For repositioning, make sure to long-press (not tap)
- For new tasks, drag directly from unscheduled panel

### Time slots wrong
- Check DashboardConfig settings
- Verify dayStartHour and dayEndHour are correct
- Time slot interval should be 15, 30, or 60 minutes

### Conflicts not detected
- Ensure tasks have valid scheduledStart and scheduledEnd times
- Check that dates match (conflicts only detected same-day)

## Advanced Usage

### Programmatic Scheduling
```dart
await taskProvider.scheduleTask(
  taskId: task.id,
  start: DateTime(2024, 1, 15, 9, 0),  // 9:00 AM
  end: DateTime(2024, 1, 15, 10, 30),   // 10:30 AM
);
```

### Finding Available Slots
```dart
final nextSlot = taskProvider.findNextAvailableSlot(
  startingFrom: DateTime.now(),
  durationMinutes: 60,
);
```

### Checking Conflicts
```dart
final hasConflict = taskProvider.hasTimeSlotConflict(
  start: startTime,
  end: endTime,
  excludeTaskId: currentTask.id,
);
```

## Support

For issues or feature requests, refer to:
- `DRAG_DROP_IMPLEMENTATION.md` - Detailed technical documentation
- `CLAUDE.md` - Project architecture and patterns
- Task model definition in `lib/models/task.dart`
