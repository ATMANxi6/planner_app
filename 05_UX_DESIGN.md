# Life Planner: Comprehensive Development Report
## Part 5: User Experience Design

**Report Navigation**: [← Part 4](04_PERFORMANCE.md) | **Part 5** | [Part 6 →](06_INTEGRATION.md)

---

## Table of Contents
- [Design System](#design-system)
- [Navigation Structure](#navigation-structure)
- [Gesture Support](#gesture-support)
- [Responsive Layouts](#responsive-layouts)
- [Accessibility Considerations](#accessibility-considerations)
- [UX Patterns](#ux-patterns)

---

## Design System

Life Planner implements Material Design 3 (Material You), Google's latest design language emphasizing personalization, accessibility, and expressive theming.

### Material Design 3 Adoption

**File**: `lib/main.dart:156`

```dart
MaterialApp(
  title: 'Life Planner',
  theme: ThemeData(
    useMaterial3: true,  // Enable Material Design 3
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.light,
    ),
  ),
  darkTheme: ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.dark,
    ),
  ),
  themeMode: ThemeMode.system,  // Follows device setting
)
```

### Color System

**Material 3 Color Roles**:

| Role | Usage | Example |
|------|-------|---------|
| `primary` | Main brand color, FABs, prominent buttons | Deep purple (tasks, actions) |
| `secondary` | Less prominent actions, chips | Teal (categories, tags) |
| `tertiary` | Contrasting accents | Amber (warnings, highlights) |
| `error` | Error states, destructive actions | Red (delete, warnings) |
| `surface` | Card backgrounds, bottom sheets | Light gray / Dark gray |
| `background` | Screen backgrounds | White / Near-black |
| `onPrimary` | Text on primary color | White |
| `onSurface` | Text on surfaces | Black / White |

**Task Type Color Coding**:

```dart
Color _getColorForTaskType(TaskType type) {
  switch (type) {
    case TaskType.distraction:
      return Colors.red[700]!;      // Red: Stop doing this
    case TaskType.practice:
      return Colors.green[700]!;    // Green: Build this habit
    case TaskType.goal:
      return Colors.blue[700]!;     // Blue: Achieve this objective
  }
}
```

**Kanban Status Color Coding**:

```dart
Color _getColorForStatus(KanbanStatus status) {
  switch (status) {
    case KanbanStatus.backlog:
      return Colors.grey[600]!;
    case KanbanStatus.todo:
      return Colors.blue[600]!;
    case KanbanStatus.inProgress:
      return Colors.orange[600]!;
    case KanbanStatus.review:
      return Colors.purple[600]!;
    case KanbanStatus.done:
      return Colors.green[600]!;
  }
}
```

### Typography

**Material 3 Type Scale**:

```dart
TextTheme(
  displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w400),  // Hero text
  displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w400), // Large headlines
  displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w400),  // Section headers

  headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w400),
  headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w400),
  headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w400), // Screen titles

  titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),    // Card titles
  titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),   // List item titles
  titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),    // Subtitles

  bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),     // Main body text
  bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),    // Secondary text
  bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),     // Captions

  labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),    // Button text
  labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),   // Chip text
  labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),    // Small labels
)
```

**Usage in App**:

```dart
// Screen titles
Text('Dashboard', style: Theme.of(context).textTheme.headlineSmall)

// Card titles
Text(task.title, style: Theme.of(context).textTheme.titleMedium)

// Body text
Text(task.description, style: Theme.of(context).textTheme.bodyMedium)

// Captions
Text('Due: ${formatDate(task.deadline)}', style: Theme.of(context).textTheme.bodySmall)
```

### Component Library

**Buttons**:

```dart
// Primary action (e.g., "Create Task")
FilledButton(
  onPressed: _createTask,
  child: Text('Create Task'),
)

// Secondary action (e.g., "Cancel")
OutlinedButton(
  onPressed: () => Navigator.pop(context),
  child: Text('Cancel'),
)

// Tertiary action (e.g., "Learn More")
TextButton(
  onPressed: _showHelp,
  child: Text('Learn More'),
)

// Floating Action Button (e.g., add task)
FloatingActionButton(
  onPressed: _showTaskCreationDialog,
  child: Icon(Icons.add),
)
```

**Cards**:

```dart
Card(
  elevation: 2,  // Material 3 uses subtle elevation
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Task Title', style: Theme.of(context).textTheme.titleMedium),
        SizedBox(height: 8),
        Text('Task description...', style: Theme.of(context).textTheme.bodyMedium),
      ],
    ),
  ),
)
```

**Chips** (for tags, categories):

```dart
Chip(
  label: Text('Work'),
  avatar: Icon(Icons.work, size: 16),
  onDeleted: () => _removeCategory('Work'),
)

InputChip(
  label: Text('High Priority'),
  selected: task.priority == Priority.high,
  onSelected: (selected) => _setPriority(selected ? Priority.high : null),
)
```

---

## Navigation Structure

### Bottom Navigation

**File**: `lib/screens/home_screen.dart:180`

Life Planner uses Material 3's `NavigationBar` for primary navigation, providing 4 main destinations.

```dart
class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    DashboardScreen(),
    PlannerScreen(),
    VisualizerScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Planner',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_graph_outlined),
            selectedIcon: Icon(Icons.auto_graph),
            label: 'Visualizer',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
```

**Navigation Behavior**:
- **Persistent State**: Switching tabs preserves scroll position and state in each screen
- **Material 3 Animations**: Smooth transitions with indicator animation
- **Haptic Feedback**: Light vibration on tab selection (mobile)

### Screen Hierarchy

```
Home Screen (Bottom Nav)
├─ Dashboard
│  ├─ Dashboard Widgets (9 types)
│  └─ Time Block Creation Dialog
│
├─ Planner
│  ├─ Task Type Tabs (Distraction / Practice / Goal)
│  ├─ Task List
│  ├─ Task Detail Screen
│  │  ├─ Edit Task
│  │  ├─ Subtask Management (goals)
│  │  └─ Dependency Management
│  └─ Task Creation Screen
│     ├─ Distraction Form
│     ├─ Practice Form
│     └─ Goal Form
│
├─ Visualizer
│  ├─ Project Selector
│  ├─ Visualization Tabs (Gantt / Kanban / Burndown)
│  ├─ Planning Canvas (Project Mode / Canvas Mode)
│  └─ Project Detail Screen
│
└─ Settings
   ├─ Dashboard Configuration
   ├─ Time Block Preferences
   └─ App Preferences
```

### Deep Linking

Tasks can be opened directly via deep links (future feature):

```dart
// Example implementation
Navigator.pushNamed(
  context,
  '/task/${taskId}',
  arguments: {'task': task},
)
```

---

## Gesture Support

Life Planner implements rich gesture interactions optimized for both mobile (touch) and desktop (mouse) platforms.

### Touch Gestures

#### Single Tap
**Usage**: Primary action (open, select)

```dart
GestureDetector(
  onTap: () {
    // Open task detail
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TaskDetailScreen(task: task)),
    );
  },
  child: TaskListItem(task: task),
)
```

#### Long Press
**Usage**: Context menu, secondary actions

```dart
GestureDetector(
  onLongPress: () {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildContextMenu(task),
    );
  },
  child: TaskListItem(task: task),
)
```

**Context Menu**:
```dart
Widget _buildContextMenu(Task task) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      ListTile(
        leading: Icon(Icons.edit),
        title: Text('Edit'),
        onTap: () => _editTask(task),
      ),
      ListTile(
        leading: Icon(Icons.delete),
        title: Text('Delete'),
        onTap: () => _deleteTask(task),
      ),
      if (task.type == TaskType.goal)
        ListTile(
          leading: Icon(Icons.add),
          title: Text('Add Subtask'),
          onTap: () => _addSubtask(task),
        ),
      ListTile(
        leading: Icon(Icons.link),
        title: Text('Add Dependency'),
        onTap: () => _addDependency(task),
      ),
    ],
  );
}
```

#### Drag
**Usage**: Node positioning, reordering, Kanban workflow

```dart
// Canvas node drag
GestureDetector(
  onPanUpdate: (details) {
    setState(() {
      _dragPositions[node.id] = currentPosition + details.delta;
    });
  },
  onPanEnd: (details) {
    context.read<PlanningProvider>().updateNodePosition(
      node.id,
      _dragPositions[node.id]!,
    );
    setState(() => _dragPositions.remove(node.id));
  },
  child: CanvasNode(node: node),
)

// Kanban drag-and-drop
Draggable<Subtask>(
  data: subtask,
  feedback: Material(
    elevation: 6,
    child: SubtaskCard(subtask: subtask),
  ),
  childWhenDragging: Opacity(
    opacity: 0.5,
    child: SubtaskCard(subtask: subtask),
  ),
  child: SubtaskCard(subtask: subtask),
)

DragTarget<Subtask>(
  onWillAccept: (subtask) => subtask != null,
  onAccept: (subtask) {
    context.read<TaskProvider>().updateSubtaskKanbanStatus(subtask.id, status);
  },
  builder: (context, candidateData, rejectedData) {
    return KanbanColumn(status: status, highlighted: candidateData.isNotEmpty);
  },
)
```

#### Pinch-to-Zoom
**Usage**: Canvas zoom

```dart
GestureDetector(
  onScaleUpdate: (details) {
    setState(() {
      _scale = (_scale * details.scale).clamp(0.5, 3.0);
    });
  },
  child: Transform.scale(
    scale: _scale,
    child: CanvasWidget(),
  ),
)
```

#### Swipe
**Usage**: Dismiss actions, quick actions

```dart
Dismissible(
  key: Key(task.id),
  direction: DismissDirection.endToStart,
  background: Container(
    color: Colors.red,
    alignment: Alignment.centerRight,
    padding: EdgeInsets.only(right: 16),
    child: Icon(Icons.delete, color: Colors.white),
  ),
  confirmDismiss: (direction) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Task?'),
        content: Text('This action cannot be undone.'),
        actions: [
          TextButton(child: Text('Cancel'), onPressed: () => Navigator.pop(context, false)),
          TextButton(child: Text('Delete'), onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );
  },
  onDismissed: (direction) {
    context.read<TaskProvider>().deleteTask(task.id);
  },
  child: TaskListItem(task: task),
)
```

### Mouse Interactions (Desktop)

#### Hover
**Usage**: Visual feedback, tooltips

```dart
MouseRegion(
  onEnter: (_) => setState(() => _isHovered = true),
  onExit: (_) => setState(() => _isHovered = false),
  child: AnimatedContainer(
    duration: Duration(milliseconds: 200),
    decoration: BoxDecoration(
      color: _isHovered ? Colors.grey[100] : Colors.white,
      borderRadius: BorderRadius.circular(8),
    ),
    child: TaskListItem(task: task),
  ),
)
```

#### Scroll Wheel
**Usage**: Canvas pan (with modifier keys)

```dart
Listener(
  onPointerSignal: (event) {
    if (event is PointerScrollEvent) {
      // Shift + scroll: horizontal pan
      if (HardwareKeyboard.instance.isShiftPressed) {
        setState(() {
          _panOffset += Offset(event.scrollDelta.dy, 0);
        });
      }
      // Ctrl + scroll: zoom
      else if (HardwareKeyboard.instance.isControlPressed) {
        setState(() {
          _scale = (_scale - event.scrollDelta.dy * 0.001).clamp(0.5, 3.0);
        });
      }
      // Normal scroll: vertical pan
      else {
        setState(() {
          _panOffset += Offset(0, event.scrollDelta.dy);
        });
      }
    }
  },
  child: CanvasWidget(),
)
```

---

## Responsive Layouts

Life Planner adapts to different screen sizes using Flutter's `LayoutBuilder` and `MediaQuery`.

### Breakpoints

```dart
enum ScreenSize {
  small,   // < 600dp (phones)
  medium,  // 600-840dp (tablets portrait)
  large,   // > 840dp (tablets landscape, desktop)
}

ScreenSize getScreenSize(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width < 600) return ScreenSize.small;
  if (width < 840) return ScreenSize.medium;
  return ScreenSize.large;
}
```

### Adaptive Layouts

#### Dashboard Grid

```dart
class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenSize = getScreenSize(context);

    int crossAxisCount;
    switch (screenSize) {
      case ScreenSize.small:
        crossAxisCount = 1;  // Single column on phones
        break;
      case ScreenSize.medium:
        crossAxisCount = 2;  // 2 columns on tablets
        break;
      case ScreenSize.large:
        crossAxisCount = 3;  // 3 columns on desktop
        break;
    }

    return GridView.count(
      crossAxisCount: crossAxisCount,
      childAspectRatio: 1.5,
      children: _buildDashboardWidgets(),
    );
  }
}
```

#### Gantt Chart Scaling

```dart
class GanttChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final taskNameWidth = screenWidth < 600 ? 120 : 200;  // Adaptive column width

    return Row(
      children: [
        // Task names (fixed width)
        SizedBox(
          width: taskNameWidth,
          child: _buildTaskNames(),
        ),

        // Timeline (flexible)
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _buildTimeline(),
          ),
        ),
      ],
    );
  }
}
```

#### Drawer vs Bottom Sheet

```dart
// Mobile: Bottom sheet for filters
if (screenSize == ScreenSize.small) {
  showModalBottomSheet(
    context: context,
    builder: (context) => FilterOptions(),
  );
}
// Desktop: Side drawer
else {
  setState(() => _showDrawer = true);
}
```

---

## Accessibility Considerations

While not fully WCAG compliant, Life Planner implements some accessibility best practices:

### Color Contrast

All text meets WCAG AA contrast requirements:
- Dark text on light background: 4.5:1 minimum
- Light text on dark background: 4.5:1 minimum
- Interactive elements: 3:1 minimum

```dart
// Good contrast examples
Text(
  'Task Title',
  style: TextStyle(
    color: Colors.grey[900],  // #212121
    backgroundColor: Colors.white,  // #FFFFFF
    // Contrast ratio: 16.1:1 (AAA)
  ),
)

FilledButton(
  style: ButtonStyle(
    backgroundColor: MaterialStateProperty.all(Colors.blue[700]),  // #1976D2
    foregroundColor: MaterialStateProperty.all(Colors.white),      // #FFFFFF
    // Contrast ratio: 4.6:1 (AA)
  ),
  child: Text('Create Task'),
)
```

### Touch Target Size

All interactive elements meet 48dp minimum touch target:

```dart
// Buttons
FilledButton(
  style: ButtonStyle(
    minimumSize: MaterialStateProperty.all(Size(48, 48)),  // 48dp minimum
  ),
  child: Text('Button'),
)

// Checkboxes (Material 3 default: 48dp)
Checkbox(
  value: task.isCompleted,
  onChanged: (value) => _toggleTask(task),
)

// Custom targets
GestureDetector(
  behavior: HitTestBehavior.opaque,  // Expand hit area
  child: Container(
    padding: EdgeInsets.all(12),  // Ensure 48dp total
    child: Icon(Icons.more_vert),
  ),
)
```

### Semantic Labels (Partial)

Some widgets have semantic labels for screen readers:

```dart
Semantics(
  label: 'Mark task as complete',
  child: Checkbox(
    value: task.isCompleted,
    onChanged: (value) => _toggleTask(task),
  ),
)

Semantics(
  button: true,
  enabled: true,
  label: 'Create new task',
  child: FloatingActionButton(
    onPressed: _showTaskCreationDialog,
    child: Icon(Icons.add),
  ),
)
```

**Gap**: Most widgets lack Semantics wrappers (see Part 7 for improvement plan)

### Keyboard Navigation (Desktop)

Basic keyboard shortcuts:

```dart
Focus(
  onKey: (node, event) {
    if (event is RawKeyDownEvent) {
      // Ctrl+N: New task
      if (event.isControlPressed && event.logicalKey == LogicalKeyboardKey.keyN) {
        _showTaskCreationDialog();
        return KeyEventResult.handled;
      }

      // Escape: Close dialog
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        Navigator.pop(context);
        return KeyEventResult.handled;
      }

      // Enter: Submit form
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        _submitForm();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  },
  child: TaskCreationForm(),
)
```

**Gap**: No comprehensive keyboard navigation (tab order, arrow keys, etc.)

---

## UX Patterns

### Empty States

Life Planner provides helpful empty states when no data exists:

```dart
Widget _buildEmptyState(TaskType type) {
  String message;
  IconData icon;

  switch (type) {
    case TaskType.distraction:
      message = 'No distractions tracked yet.\nAdd habits you want to eliminate.';
      icon = Icons.block;
      break;
    case TaskType.practice:
      message = 'No practices yet.\nAdd daily habits you want to build.';
      icon = Icons.fitness_center;
      break;
    case TaskType.goal:
      message = 'No goals yet.\nAdd objectives you want to achieve.';
      icon = Icons.flag;
      break;
  }

  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 80, color: Colors.grey[400]),
        SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
        SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _showTaskCreationDialog,
          icon: Icon(Icons.add),
          label: Text('Add ${_getTypeLabel(type)}'),
        ),
      ],
    ),
  );
}
```

### Loading States

Asynchronous operations show loading indicators:

```dart
class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadDashboardData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error);
        }

        return _buildDashboard(snapshot.data);
      },
    );
  }
}
```

### Success Feedback

Completion actions show celebratory feedback:

```dart
void _completeGoal(Task goal) {
  context.read<TaskProvider>().updateTask(goal.copyWith(isCompleted: true));

  // Show celebration
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.celebration, color: Colors.amber, size: 32),
          SizedBox(width: 8),
          Text('Goal Achieved!'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Congratulations on completing "${goal.title}"!'),
          SizedBox(height: 16),
          Text('You completed ${goal.subtasks.length} subtasks and achieved your goal.'),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Awesome!'),
        ),
      ],
    ),
  );
}
```

### Error Handling

User-friendly error messages:

```dart
void _addDependency(String taskId, String dependsOnId) {
  try {
    context.read<TaskProvider>().addDependency(taskId, dependsOnId);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Dependency added successfully')),
    );
  } on Exception catch (e) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cannot Add Dependency'),
        content: Text(e.toString()),  // "This dependency would create a cycle"
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
```

### Confirmation Dialogs

Destructive actions require confirmation:

```dart
Future<bool> _confirmDelete(Task task) async {
  return await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Delete Task?'),
      content: Text('Are you sure you want to delete "${task.title}"? This action cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.red),
          ),
          child: Text('Delete'),
        ),
      ],
    ),
  ) ?? false;
}
```

---

**Continue to**: [Part 6: Integration & Data Flow →](06_INTEGRATION.md)

**Report Navigation**:
- [Part 1: Executive Overview](01_EXECUTIVE_OVERVIEW.md)
- [Part 2: Architecture & Technical Design](02_ARCHITECTURE.md)
- [Part 3: Feature Catalog](03_FEATURES.md)
- [Part 4: Performance & Optimization](04_PERFORMANCE.md)
- **Part 5: User Experience Design** (Current)
- [Part 6: Integration & Data Flow](06_INTEGRATION.md)
- [Part 7: Code Quality & Roadmap](07_QUALITY_ROADMAP.md)
- [Part 8: Appendices & Reference](08_APPENDICES.md)
