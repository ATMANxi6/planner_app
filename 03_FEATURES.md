# Life Planner: Comprehensive Development Report
## Part 3: Feature Catalog

**Report Navigation**: [← Part 2](02_ARCHITECTURE.md) | **Part 3** | [Part 4 →](04_PERFORMANCE.md)

---

## Table of Contents
- [Task Management System](#task-management-system)
- [Planning Canvas (Dual-Mode)](#planning-canvas-dual-mode)
- [Project Visualization Suite](#project-visualization-suite)
- [Time Blocking System](#time-blocking-system)
- [Mind Mapping](#mind-mapping)
- [Dashboard System](#dashboard-system)
- [Feature Integration Matrix](#feature-integration-matrix)

---

## Task Management System

The task management system is the foundation of Life Planner, built around three behavioral task types that reflect different psychological approaches to productivity.

### Three Task Types

#### 1. Distraction Tasks (Habits to Eliminate)

**Purpose**: Help users identify and eliminate counterproductive behaviors

**Behavioral Psychology Basis**:
- Based on habit loop research (Cue → Routine → Reward)
- Focuses on trigger awareness and replacement behaviors
- Cost-benefit analysis to reinforce motivation

**Unique Fields**:

| Field | Type | Purpose | Example |
|-------|------|---------|---------|
| `replacementBehavior` | String | What to do instead | "When I want to scroll social media, I'll read a book chapter" |
| `commonTriggers` | List\<String\> | Situations that trigger habit | ["boredom", "after meals", "waiting in line"] |
| `costImpact` | String | Time/money/health cost | "2 hours/day, poor sleep quality, reduced focus" |
| `streakCount` | int | Days avoided consecutively | 15 (displayed as "15-day streak!") |

**User Workflow**:
```
1. User creates distraction: "Checking phone during work"
2. Fills out:
   - Replacement: "5-minute walk or water break"
   - Triggers: "notification sound", "work frustration", "boredom"
   - Cost: "30 minutes per interruption, reduced productivity"
3. Daily check-in: Mark as avoided today
4. Streak increments: 1 day → 7 days → 30 days
5. If broken: Streak resets to 0, user reflects on trigger
```

**UI Components**:
- `DistactionForm` (widgets/task_forms/distraction_form.dart:320 lines)
- Trigger tag chips (add/remove triggers dynamically)
- Cost calculator (estimates daily/weekly/yearly impact)
- Streak display with flame icon and milestone markers (7, 14, 30, 90 days)

**Real-World Example**:
```dart
Task(
  id: 'dist-001',
  title: 'Excessive Social Media Scrolling',
  type: TaskType.distraction,
  description: 'Mindless scrolling on Instagram/Twitter during work hours',
  replacementBehavior: 'Take 5-minute walk, drink water, or do 10 pushups',
  commonTriggers: ['notification buzz', 'boredom', 'avoiding difficult task', 'lunch break'],
  costImpact: '''
    Time: ~2 hours/day = 14 hours/week = 728 hours/year
    Productivity: 20-30% reduction in deep work
    Mental health: Increased anxiety, comparison fatigue
  ''',
  streakCount: 12,  // 12 days avoided
  createdAt: DateTime(2025, 11, 1),
)
```

#### 2. Practice Tasks (Habits to Build)

**Purpose**: Help users establish consistent positive habits

**Behavioral Psychology Basis**:
- Based on habit stacking and tiny habits methodology
- Focus on consistency over intensity
- Daily reflection for metacognition

**Unique Fields**:

| Field | Type | Purpose | Example |
|-------|------|---------|---------|
| `progressMetric` | String | How to measure success | "Write 500 words" or "Exercise 20 minutes" |
| `resourcesNeeded` | List\<String\> | Tools/materials required | ["notebook", "running shoes", "timer"] |
| `reflectionPrompt` | String | Daily reflection question | "What did I learn today? What went well?" |
| `streakCount` | int | Days completed consecutively | 42 (displayed as "42-day streak!") |

**User Workflow**:
```
1. User creates practice: "Morning journaling"
2. Fills out:
   - Metric: "Write 3 pages (750 words)"
   - Resources: "notebook, pen, coffee"
   - Reflection: "What am I grateful for today?"
3. Daily completion: Check off task
4. Streak increments: User sees progress
5. Reflection prompt appears: User writes notes
6. Frequency: Daily (auto-resets next day)
```

**UI Components**:
- `PracticeForm` (widgets/task_forms/practice_form.dart:340 lines)
- Resource checklist (user can check off items before starting)
- Progress metric tracker (numerical or time-based)
- Reflection journal (text area appears after completion)
- Streak calendar view (visual representation of completion history)

**Real-World Example**:
```dart
Task(
  id: 'prac-001',
  title: 'Morning Exercise Routine',
  type: TaskType.practice,
  description: 'Consistent morning workout to build strength and energy',
  progressMetric: '30 minutes: 10 min cardio + 20 min strength',
  resourcesNeeded: ['yoga mat', 'dumbbells', 'water bottle', 'workout app'],
  reflectionPrompt: 'How did my body feel today? What exercise was hardest?',
  streakCount: 28,  // 28 days completed
  frequency: Frequency.daily,
  reminderTime: DateTime(2025, 12, 12, 6, 30),  // 6:30 AM daily
  timeEstimate: 30,  // 30 minutes
  createdAt: DateTime(2025, 11, 14),
)
```

#### 3. Goal Tasks (Objectives to Achieve)

**Purpose**: Help users plan and achieve long-term objectives

**Behavioral Psychology Basis**:
- Based on SMART goals framework (Specific, Measurable, Achievable, Relevant, Time-bound)
- Milestone decomposition for sustained motivation
- "Why" analysis for intrinsic motivation

**Unique Fields**:

| Field | Type | Purpose | Example |
|-------|------|---------|---------|
| `whyPurpose` | String | Motivation and meaning | "To advance my career and achieve financial independence" |
| `successCriteria` | String | Definition of done | "Product launched with 100 users and $1000 MRR" |
| `relatedHabits` | List\<String\> | Practices supporting goal | ["Daily coding practice", "Weekly user interviews"] |
| `milestones` | List\<Milestone\> | Progress checkpoints | [Milestone("MVP complete", dueDate: Mar 1), ...] |
| `subtasks` | List\<Subtask\> | Actionable breakdown | [Subtask("Design database schema"), ...] |

**User Workflow**:
```
1. User creates goal: "Launch side project SaaS"
2. Fills out:
   - Why: "Financial freedom, skill growth, help others"
   - Success: "100 paying users, $1000 MRR, 4.5★ rating"
   - Related habits: ["Daily coding", "Marketing experiments"]
3. Adds milestones:
   - Milestone 1: "MVP complete" (due: March 1)
   - Milestone 2: "Beta launch" (due: April 1)
   - Milestone 3: "Public launch" (due: May 1)
4. Breaks into subtasks:
   - "Design database schema"
   - "Build authentication"
   - "Implement core feature"
   - "Write documentation"
   - "Set up payment processing"
5. Tracks in Kanban: Subtasks move through workflow
6. Auto-completion: Goal completes when all subtasks done
```

**UI Components**:
- `GoalForm` (widgets/task_forms/goal_form.dart:420 lines)
- Milestone timeline widget (horizontal progress bar)
- Subtask tree (hierarchical checklist with indentation)
- Why/purpose prominently displayed (motivational reminder)
- Related habits link list (tap to navigate to practice tasks)
- Success criteria checklist (break into measurable items)

**Real-World Example**:
```dart
Task(
  id: 'goal-001',
  title: 'Launch Personal Finance SaaS',
  type: TaskType.goal,
  description: 'Build and launch a subscription-based budgeting app',
  whyPurpose: '''
    Why: Achieve financial independence, help others manage money better
    Personal: Prove I can build a business, gain technical skills
    Impact: Help 1000s of people improve their financial health
  ''',
  successCriteria: '''
    1. Product live at myfinanceapp.com
    2. 100 paying subscribers ($10/month)
    3. $1000 MRR sustained for 2 months
    4. 4.5+ star rating from users
    5. 10% month-over-month growth
  ''',
  relatedHabits: ['Daily coding practice', 'Weekly marketing experiments', 'Daily user interviews'],
  milestones: [
    Milestone(
      id: 'ms-001',
      title: 'MVP Complete',
      description: 'Core features: auth, budgets, expense tracking',
      dueDate: DateTime(2025, 3, 1),
    ),
    Milestone(
      id: 'ms-002',
      title: 'Beta Launch',
      description: '20 beta users, collect feedback',
      dueDate: DateTime(2025, 4, 1),
    ),
    Milestone(
      id: 'ms-003',
      title: 'Public Launch',
      description: 'Public release, marketing campaign',
      dueDate: DateTime(2025, 5, 1),
    ),
  ],
  subtasks: [
    Subtask(id: 'st-001', title: 'Design database schema', isCompleted: true),
    Subtask(id: 'st-002', title: 'Build authentication system', isCompleted: true),
    Subtask(id: 'st-003', title: 'Implement budget creation', isCompleted: false, kanbanStatus: KanbanStatus.inProgress),
    Subtask(id: 'st-004', title: 'Build expense tracking', isCompleted: false, kanbanStatus: KanbanStatus.todo),
    Subtask(id: 'st-005', title: 'Set up payment processing (Stripe)', isCompleted: false),
    Subtask(id: 'st-006', title: 'Write user documentation', isCompleted: false),
  ],
  startDate: DateTime(2025, 1, 1),
  deadline: DateTime(2025, 5, 31),
  timeEstimate: 300,  // 300 hours estimated
  priority: Priority.high,
  createdAt: DateTime(2024, 12, 15),
)
```

### Common Fields (All Task Types)

All three task types share these fields:

**Core Identity**:
- `id`: UUID string
- `title`: Display name (max 100 chars)
- `description`: Optional long-form details (markdown supported)
- `type`: TaskType enum (distraction/practice/goal)
- `isCompleted`: Boolean completion status
- `createdAt`: Timestamp
- `completedAt`: Timestamp (set when marked complete)

**Scheduling**:
- `startDate`: When to begin task
- `deadline`: Due date (triggers deadline warnings)
- `frequency`: Daily/weekly/monthly for recurring tasks
- `reminderTime`: Local notification time
- `timeEstimate`: Expected duration in minutes (used for burndown charts)
- `lastResetDate`: Last recurrence reset (auto-managed)

**Organization**:
- `priority`: 1-5 scale or enum (low/medium/high/urgent)
- `category`: User-defined tag (e.g., "work", "personal", "health")
- `projectId`: Foreign key to Project model
- `kanbanStatus`: Workflow stage (backlog/todo/inProgress/review/done)
- `dependencies`: List of task IDs this depends on (DAG with cycle detection)

### Task CRUD Operations

**Creating Tasks**:

File: `lib/screens/task_creation_screen.dart` (650 lines)

```dart
// User flow:
1. Navigate to Planner screen
2. Select task type tab (Distraction / Practice / Goal)
3. Tap FAB (+) button
4. Fill out form:
   - Common fields (title, description, deadline, etc.)
   - Type-specific fields (dynamically shown)
5. Tap "Create Task"
6. TaskProvider.addTask() called
7. Task saved to Hive
8. UI updates reactively

// Code example:
void _createTask() {
  final newTask = Task(
    id: Uuid().v4(),
    title: _titleController.text,
    description: _descriptionController.text,
    type: _selectedType,
    isCompleted: false,
    createdAt: DateTime.now(),
    // ... type-specific fields
  );

  context.read<TaskProvider>().addTask(newTask);
  Navigator.pop(context);
}
```

**Viewing Tasks**:

File: `lib/screens/planner_screen.dart` (380 lines)

```dart
// Planner screen with tabs
DefaultTabController(
  length: 3,
  child: Scaffold(
    appBar: AppBar(
      title: Text('Planner'),
      bottom: TabBar(
        tabs: [
          Tab(text: 'Distractions', icon: Icon(Icons.block)),
          Tab(text: 'Practices', icon: Icon(Icons.fitness_center)),
          Tab(text: 'Goals', icon: Icon(Icons.flag)),
        ],
      ),
    ),
    body: TabBarView(
      children: [
        _buildTaskList(TaskType.distraction),
        _buildTaskList(TaskType.practice),
        _buildTaskList(TaskType.goal),
      ],
    ),
  ),
)

Widget _buildTaskList(TaskType type) {
  return Consumer<TaskProvider>(
    builder: (context, taskProvider, _) {
      final tasks = taskProvider.getTasksByType(type);

      if (tasks.isEmpty) {
        return _buildEmptyState(type);
      }

      return ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          return TaskListItem(task: tasks[index]);
        },
      );
    },
  );
}
```

**Editing Tasks**:

File: `lib/screens/task_detail_screen.dart` (420 lines)

```dart
// Tap task → Navigate to detail screen
// Shows:
// - Title and description (editable)
// - Type-specific fields (editable)
// - Subtasks (for goals) with checkboxes
// - Milestones (for goals) with progress bar
// - Streak count (for distractions/practices)
// - Dependencies (visual graph)
// - Action buttons: Edit, Delete, Mark Complete

void _updateTask() {
  final updatedTask = task.copyWith(
    title: _titleController.text,
    description: _descriptionController.text,
    // ... updated fields
  );

  context.read<TaskProvider>().updateTask(updatedTask);
  Navigator.pop(context);
}
```

**Completing Tasks**:

```dart
// Simple completion
void _toggleCompletion(Task task) {
  task.isCompleted = !task.isCompleted;
  task.completedAt = task.isCompleted ? DateTime.now() : null;

  context.read<TaskProvider>().updateTask(task);
}

// Auto-completion for goals (when all subtasks done)
void _checkGoalCompletion(Task goal) {
  if (goal.type == TaskType.goal) {
    final allSubtasksComplete = goal.subtasks.every((s) => s.isCompleted);

    if (allSubtasksComplete && !goal.isCompleted) {
      goal.isCompleted = true;
      goal.completedAt = DateTime.now();
      // Show celebration animation 🎉
    }
  }
}
```

**Deleting Tasks**:

```dart
void _deleteTask(String taskId) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Delete Task?'),
      content: Text('This action cannot be undone. Dependencies will be removed.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            context.read<TaskProvider>().deleteTask(taskId);
            Navigator.pop(context);  // Close dialog
            Navigator.pop(context);  // Close detail screen
          },
          child: Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}
```

### Subtasks (Goals Only)

**Purpose**: Break goals into actionable steps

**Features**:
- Hierarchical display (indented under parent goal)
- Individual completion checkboxes
- Kanban status (can be moved through workflow independently)
- Time estimates (contribute to burndown chart)
- Dependencies (subtasks can depend on other subtasks)

**UI**:

File: `lib/widgets/shared/subtask_list.dart` (180 lines)

```dart
Widget build(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Subtasks (${completedCount}/${totalCount})', style: Theme.of(context).textTheme.titleMedium),
      SizedBox(height: 8),
      ...subtasks.map((subtask) => CheckboxListTile(
        title: Text(subtask.title, style: subtask.isCompleted ? TextStyle(decoration: TextDecoration.lineThrough) : null),
        value: subtask.isCompleted,
        onChanged: (value) => _toggleSubtask(subtask),
        secondary: _buildSubtaskActions(subtask),  // Edit, delete, dependencies
      )),
      SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: _showAddSubtaskDialog,
        icon: Icon(Icons.add),
        label: Text('Add Subtask'),
      ),
    ],
  );
}
```

**Auto-Completion Logic**:

```dart
// In TaskProvider
void toggleSubtask(String taskId, String subtaskId) {
  final task = _storage.tasksBox.get(taskId);
  final subtask = task?.subtasks.firstWhere((s) => s.id == subtaskId);

  if (subtask != null) {
    subtask.isCompleted = !subtask.isCompleted;
    task!.save();

    // Check if all subtasks are now complete
    _checkGoalCompletion(task);

    notifyListeners();
  }
}

void _checkGoalCompletion(Task task) {
  if (task.type == TaskType.goal) {
    final allComplete = task.subtasks.every((s) => s.isCompleted);

    if (allComplete && !task.isCompleted) {
      // Auto-complete goal
      task.isCompleted = true;
      task.completedAt = DateTime.now();
      task.save();

      // Show celebration 🎉
      _showCompletionCelebration(task);
    } else if (!allComplete && task.isCompleted) {
      // Auto-uncomplete goal (user unchecked a subtask)
      task.isCompleted = false;
      task.completedAt = null;
      task.save();
    }
  }
}
```

### Milestones (Goals Only)

**Purpose**: Mark progress checkpoints for long-term goals

**Features**:
- Title and description
- Optional due date
- Completion checkbox (independent of subtasks)
- Progress visualization (timeline or progress bar)

**UI**:

File: `lib/widgets/shared/milestone_timeline.dart` (240 lines)

```dart
// Horizontal timeline showing milestone progress
Widget build(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Milestones', style: Theme.of(context).textTheme.titleMedium),
      SizedBox(height: 16),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: milestones.asMap().entries.map((entry) {
            final index = entry.key;
            final milestone = entry.value;
            final isLast = index == milestones.length - 1;

            return Row(
              children: [
                _buildMilestoneNode(milestone),
                if (!isLast) _buildConnector(milestone.isCompleted),
              ],
            );
          }).toList(),
        ),
      ),
      SizedBox(height: 8),
      LinearProgressIndicator(
        value: completedCount / totalCount,
        backgroundColor: Colors.grey[300],
        valueColor: AlwaysStoppedAnimation(Colors.green),
      ),
      SizedBox(height: 4),
      Text('${completedCount}/${totalCount} milestones complete', style: TextStyle(fontSize: 12)),
    ],
  );
}

Widget _buildMilestoneNode(Milestone milestone) {
  return Column(
    children: [
      Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: milestone.isCompleted ? Colors.green : Colors.grey[300],
          border: Border.all(color: Colors.grey[600]!, width: 2),
        ),
        child: milestone.isCompleted
            ? Icon(Icons.check, color: Colors.white, size: 40)
            : Icon(Icons.circle, color: Colors.grey[600], size: 20),
      ),
      SizedBox(height: 8),
      SizedBox(
        width: 100,
        child: Text(
          milestone.title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12),
        ),
      ),
      if (milestone.dueDate != null)
        Text(
          DateFormat('MMM dd').format(milestone.dueDate!),
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),
    ],
  );
}

Widget _buildConnector(bool isCompleted) {
  return Container(
    width: 40,
    height: 4,
    color: isCompleted ? Colors.green : Colors.grey[300],
  );
}
```

### Dependencies

**Purpose**: Define task relationships and enforce order

**Implementation**: Directed Acyclic Graph (DAG) with cycle detection

**User Workflow**:
```
1. Open task detail screen
2. Tap "Add Dependency" button
3. Select task this depends on from list
4. System checks for cycles using BFS
5. If valid: Dependency added, visual graph updated
6. If cycle: Error shown ("Cannot create circular dependency")
```

**Cycle Detection Algorithm**:

File: `lib/providers/task_provider.dart` (605 lines)

```dart
void addDependency(String taskId, String dependsOnId) {
  final task = _storage.tasksBox.get(taskId);

  if (task != null) {
    // Prevent self-dependency
    if (taskId == dependsOnId) {
      throw Exception('Task cannot depend on itself');
    }

    // Prevent duplicate
    if (task.dependencies.contains(dependsOnId)) {
      return;  // Already exists
    }

    // Cycle detection (BFS)
    if (_wouldCreateCycle(taskId, dependsOnId)) {
      throw Exception('This dependency would create a circular reference');
    }

    // Safe to add
    task.dependencies.add(dependsOnId);
    task.save();
    notifyListeners();
  }
}

bool _wouldCreateCycle(String fromId, String toId) {
  // BFS: Can we reach fromId by traversing dependencies from toId?
  final queue = <String>[toId];
  final visited = <String>{};

  while (queue.isNotEmpty) {
    final currentId = queue.removeAt(0);

    // Found cycle!
    if (currentId == fromId) {
      return true;
    }

    // Skip already visited
    if (visited.contains(currentId)) {
      continue;
    }
    visited.add(currentId);

    // Add dependencies to queue
    final currentTask = _storage.tasksBox.get(currentId);
    if (currentTask != null) {
      queue.addAll(currentTask.dependencies);
    }
  }

  return false;  // No cycle found
}

List<Task> getDependencies(String taskId) {
  final task = _storage.tasksBox.get(taskId);
  if (task == null) return [];

  return task.dependencies
      .map((id) => _storage.tasksBox.get(id))
      .whereType<Task>()
      .toList();
}

bool areDependenciesComplete(String taskId) {
  final dependencies = getDependencies(taskId);
  return dependencies.every((task) => task.isCompleted);
}
```

**Visual Dependency Graph**:

File: `lib/widgets/shared/dependency_graph_widget.dart` (280 lines)

```dart
// Interactive graph showing task dependencies
// Uses force-directed layout algorithm
// Nodes: Tasks (color-coded by type)
// Edges: Arrows showing dependency direction
// Interactions:
//   - Tap node: Navigate to task detail
//   - Tap edge: Remove dependency
//   - Drag node: Reposition (visual only, no persistence)

class DependencyGraphWidget extends StatelessWidget {
  final Task task;
  final List<Task> dependencies;
  final List<Task> dependents;  // Tasks that depend on this task

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DependencyGraphPainter(
        centerTask: task,
        dependencies: dependencies,
        dependents: dependents,
      ),
      child: GestureDetector(
        onTapUp: (details) => _handleTap(details.localPosition),
      ),
    );
  }
}
```

---

## Planning Canvas (Dual-Mode)

The Planning Canvas is a unique feature that bridges visual and structured planning. It supports two modes that share the same underlying data.

### Mode Overview

| Mode | View Style | Use Case | Persistence |
|------|----------|----------|-------------|
| **Project Mode** | Hierarchical tree | Structured task breakdown | Hive (tasks, subtasks) |
| **Canvas Mode** | Spatial 2D canvas | Visual brainstorming | Hive (planning nodes with x, y) |

**Key Insight**: Both modes operate on the same `Task` objects. Canvas mode adds `PlanningNode` wrappers that store visual metadata (x, y coordinates, canvas-specific dependencies).

### Project Mode

**File**: `lib/widgets/planning/planning_canvas_view.dart` (680 lines)

**Layout**: Traditional hierarchical view

```
Project: Launch SaaS Product
├── Goal: Build MVP
│   ├── Subtask: Design database
│   ├── Subtask: Build auth system
│   └── Subtask: Implement core feature
├── Goal: Marketing Campaign
│   ├── Subtask: Create landing page
│   ├── Subtask: Set up analytics
│   └── Subtask: Launch ads
└── Goal: Beta Testing
    ├── Subtask: Recruit testers
    ├── Subtask: Collect feedback
    └── Subtask: Fix bugs
```

**Interactions**:
- Expand/collapse task groups
- Drag to reorder (within same parent)
- Tap to view task details
- Long-press for context menu (edit, delete, add subtask)

**UI Structure**:
```dart
Widget _buildProjectMode() {
  return ListView(
    children: [
      ...projects.map((project) => ExpansionTile(
        title: Text(project.name),
        children: _buildTaskTree(project.id),
      )),
    ],
  );
}

List<Widget> _buildTaskTree(String projectId) {
  final tasks = context.read<TaskProvider>().getTasksByProject(projectId);

  return tasks.map((task) {
    return ExpansionTile(
      leading: Checkbox(
        value: task.isCompleted,
        onChanged: (value) => _toggleTask(task),
      ),
      title: Text(task.title),
      children: [
        ...task.subtasks.map((subtask) => ListTile(
          leading: Checkbox(
            value: subtask.isCompleted,
            onChanged: (value) => _toggleSubtask(task.id, subtask.id),
          ),
          title: Text(subtask.title),
        )),
      ],
    );
  }).toList();
}
```

### Canvas Mode

**File**: Same as above (mode toggle switches views)

**Layout**: Infinite 2D canvas with spatial positioning

```
┌─────────────────────────────────────────────────┐
│                 Canvas (2000x2000px)            │
│                                                 │
│   [Design DB]                                   │
│        │                                        │
│        ↓                                        │
│   [Build Auth] ──→ [Implement Feature]         │
│        │                       │                │
│        ↓                       ↓                │
│   [Create Landing] ──→ [Launch MVP]            │
│                                                 │
│   [Unplaced: Recruit Testers] ← Drawer         │
│   [Unplaced: Fix Bugs]                          │
└─────────────────────────────────────────────────┘
```

**Interactions**:
- **Pan**: Drag background to navigate canvas
- **Zoom**: Pinch gesture (mobile) or scroll (desktop)
- **Place Node**: Drag from "Unplaced Items" drawer onto canvas
- **Move Node**: Drag positioned node to new location
- **Connect Nodes**: Long-press node → "Add Connection" → tap target node
- **Delete Node**: Long-press node → "Remove from Canvas" (moves back to drawer)

**Data Model**:

```dart
@HiveType(typeId: 13)
class PlanningNode extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String? taskId;          // FK to Task
  @HiveField(2) double? x;               // Canvas X position
  @HiveField(3) double? y;               // Canvas Y position
  @HiveField(4) bool isPositioned;       // True if placed on canvas
  @HiveField(5) DateTime createdAt;
  @HiveField(6) List<String> dependencies; // Node IDs (visual connections)
  @HiveField(7) String? projectId;
}

// Relationship:
// PlanningNode wraps Task with visual metadata
// isPositioned = false → Node in drawer (unplaced)
// isPositioned = true → Node on canvas at (x, y)
```

**Canvas Rendering**:

File: `lib/widgets/planning/planning_canvas_connection_painter.dart` (220 lines)

```dart
class PlanningCanvasConnectionPainter extends CustomPainter {
  final List<PlanningNode> nodes;
  final String? selectedNodeId;
  final Map<String, Offset> dragPositions;  // Transient drag state

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw connections between nodes
    for (final node in nodes) {
      if (!node.isPositioned) continue;

      // Use transient drag position if dragging, else persisted position
      final fromPos = dragPositions[node.id] ?? Offset(node.x!, node.y!);
      final fromCenter = Offset(fromPos.dx + 60, fromPos.dy + 40);  // Node center

      for (final depId in node.dependencies) {
        final toNode = nodes.firstWhere((n) => n.id == depId);
        if (!toNode.isPositioned) continue;

        final toPos = dragPositions[toNode.id] ?? Offset(toNode.x!, toNode.y!);
        final toCenter = Offset(toPos.dx + 60, toPos.dy + 40);

        // Draw arrow
        _drawArrow(canvas, paint, fromCenter, toCenter);
      }
    }
  }

  void _drawArrow(Canvas canvas, Paint paint, Offset from, Offset to) {
    // Draw line
    canvas.drawLine(from, to, paint);

    // Draw arrowhead (trigonometry)
    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    final arrowSize = 10.0;

    final path = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(
        to.dx - arrowSize * math.cos(angle - math.pi / 6),
        to.dy - arrowSize * math.sin(angle - math.pi / 6),
      )
      ..moveTo(to.dx, to.dy)
      ..lineTo(
        to.dx - arrowSize * math.cos(angle + math.pi / 6),
        to.dy - arrowSize * math.sin(angle + math.pi / 6),
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(PlanningCanvasConnectionPainter oldDelegate) {
    // Smart repaint: Only redraw if nodes or drag positions changed
    return oldDelegate.nodes != nodes ||
           oldDelegate.selectedNodeId != selectedNodeId ||
           oldDelegate.dragPositions != dragPositions;
  }
}
```

**Node Widget**:

File: `lib/widgets/planning/planning_canvas_node.dart` (180 lines)

```dart
class PlanningCanvasNode extends StatelessWidget {
  final PlanningNode node;
  final Task? task;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: node.x,
      top: node.y,
      child: GestureDetector(
        onTap: () => _handleTap(context),
        onLongPress: () => _showContextMenu(context),
        onPanUpdate: (details) => _handleDrag(context, details),
        onPanEnd: (details) => _handleDragEnd(context),
        child: Container(
          width: 120,
          height: 80,
          decoration: BoxDecoration(
            color: _getColorForTaskType(task?.type),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[700]!, width: 2),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))],
          ),
          child: Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task?.title ?? 'Untitled',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                Row(
                  children: [
                    if (task?.isCompleted == true)
                      Icon(Icons.check_circle, size: 16, color: Colors.green),
                    if (task?.dependencies.isNotEmpty == true)
                      Icon(Icons.link, size: 16, color: Colors.blue),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleDrag(BuildContext context, DragUpdateDetails details) {
    // Update transient position (in-memory only)
    context.read<PlanningProvider>().updateNodePosition(
      node.id,
      Offset(node.x! + details.delta.dx, node.y! + details.delta.dy),
    );
  }

  void _handleDragEnd(BuildContext context) {
    // Debounced persistence happens in provider (300ms after last drag)
  }
}
```

**Unplaced Items Drawer**:

File: `lib/widgets/planning/unplaced_items_drawer.dart` (150 lines)

```dart
// Bottom drawer showing nodes not yet positioned on canvas
class UnplacedItemsDrawer extends StatelessWidget {
  final List<PlanningNode> unplacedNodes;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.2,  // 20% of screen height
      minChildSize: 0.1,
      maxChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              _buildHandle(),
              Text('Unplaced Items (${unplacedNodes.length})', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: unplacedNodes.length,
                  itemBuilder: (context, index) {
                    final node = unplacedNodes[index];
                    return Draggable<PlanningNode>(
                      data: node,
                      feedback: Material(
                        child: _buildNodePreview(node),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.5,
                        child: _buildNodePreview(node),
                      ),
                      child: _buildNodePreview(node),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNodePreview(PlanningNode node) {
    return Container(
      margin: EdgeInsets.all(8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(node.task?.title ?? 'Untitled'),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[600],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
```

### Mode Switching

```dart
// In PlanningProvider
bool _isCanvasMode = false;

void toggleMode() {
  _isCanvasMode = !_isCanvasMode;
  notifyListeners();
}

// In UI
IconButton(
  icon: Icon(_isCanvasMode ? Icons.list : Icons.grid_view),
  onPressed: () {
    context.read<PlanningProvider>().toggleMode();
  },
  tooltip: _isCanvasMode ? 'Switch to Project Mode' : 'Switch to Canvas Mode',
)
```

**Data Persistence Across Modes**:

- **Project → Canvas**: Existing tasks automatically get `PlanningNode` wrappers (created on-demand if not exists)
- **Canvas → Project**: Node positions persist in Hive, but Project mode ignores x/y coordinates
- **Shared Data**: Task title, description, completion status, dependencies (from Task model) are always in sync
- **Mode-Specific Data**: Canvas connections (PlanningNode.dependencies) are separate from task dependencies (Task.dependencies) but can be synced via UI action

---

## Project Visualization Suite

The visualizer provides three professional views for project tracking: Gantt chart (timeline), Kanban board (workflow), and Burndown chart (progress).

### Project Selector

**File**: `lib/widgets/visualizer/project_selector.dart` (120 lines)

```dart
// Dropdown at top of Visualizer screen
class ProjectSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, projectProvider, _) {
        final projects = projectProvider.projects;
        final selected = projectProvider.selectedProject;

        return DropdownButton<String>(
          value: selected?.id,
          hint: Text('Select Project'),
          items: projects.map((project) {
            return DropdownMenuItem(
              value: project.id,
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(int.parse(project.color ?? 'FF0000', radix: 16)),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(project.name),
                ],
              ),
            );
          }).toList(),
          onChanged: (projectId) {
            projectProvider.setSelectedProject(projectId);
          },
        );
      },
    );
  }
}
```

### Gantt Chart

**File**: `lib/widgets/visualizer/gantt_chart.dart` (520 lines)

**Purpose**: Timeline visualization showing task start/end dates and dependencies

**Layout**:

```
Tasks          Jan 2025        Feb 2025        Mar 2025
─────────────────────────────────────────────────────────
Design DB      [████]
Build Auth         [█████] ──→
Core Feature              [██████████]
Landing Page                  [████]
Launch MVP                          [███] ──→
Beta Testing                              [████████]
```

**Features**:
- Horizontal bars representing task duration
- Start date: `task.startDate ?? task.createdAt`
- End date: `task.deadline ?? task.startDate + 1 day`
- Dependency arrows connecting related tasks
- Color-coded by project or priority
- Drag bar to reschedule (updates start/end dates)
- Click task to view details

**Implementation**:

```dart
class GanttChart extends StatelessWidget {
  final String projectId;

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskProvider>().getTasksByProject(projectId);
    final subtasks = _getAllSubtasks(tasks);  // Flatten subtasks

    // Calculate timeline bounds
    final earliestStart = _getEarliestDate(tasks);
    final latestEnd = _getLatestDate(tasks);
    final totalDays = latestEnd.difference(earliestStart).inDays;

    return Column(
      children: [
        _buildTimelineHeader(earliestStart, latestEnd),
        Expanded(
          child: ListView.builder(
            itemCount: subtasks.length,
            itemBuilder: (context, index) {
              final subtask = subtasks[index];
              return _buildGanttRow(subtask, earliestStart, totalDays);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGanttRow(Subtask subtask, DateTime startBound, int totalDays) {
    final taskStart = subtask.startDate ?? DateTime.now();
    final taskEnd = subtask.deadline ?? taskStart.add(Duration(days: 1));

    // Calculate bar position and width
    final startOffset = taskStart.difference(startBound).inDays;
    final duration = taskEnd.difference(taskStart).inDays;
    final barLeft = (startOffset / totalDays) * 100;  // Percentage
    final barWidth = (duration / totalDays) * 100;     // Percentage

    return Container(
      height: 50,
      child: Row(
        children: [
          // Task name (fixed width)
          SizedBox(
            width: 150,
            child: Text(subtask.title, overflow: TextOverflow.ellipsis),
          ),

          // Timeline area
          Expanded(
            child: Stack(
              children: [
                // Grid lines
                _buildGridLines(totalDays),

                // Task bar
                Positioned(
                  left: barLeft,
                  top: 10,
                  child: GestureDetector(
                    onPanUpdate: (details) => _handleDrag(subtask, details),
                    child: Container(
                      width: barWidth,
                      height: 30,
                      decoration: BoxDecoration(
                        color: _getColorForStatus(subtask.kanbanStatus),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          '${duration}d',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                ),

                // Dependency arrows (drawn via CustomPainter)
                CustomPaint(
                  painter: GanttArrowPainter(subtask, subtasks, startBound, totalDays),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleDrag(Subtask subtask, DragUpdateDetails details) {
    // Calculate new dates based on drag delta
    // Update subtask.startDate and subtask.deadline
    // TaskProvider.updateSubtask() → save() → notifyListeners()
  }
}
```

### Kanban Board

**File**: `lib/widgets/visualizer/kanban_board.dart` (480 lines)

**Purpose**: Drag-and-drop workflow management

**Layout**: 5-column board

```
┌─────────────┬─────────────┬─────────────┬─────────────┬─────────────┐
│  BACKLOG    │   TO DO     │ IN PROGRESS │   REVIEW    │    DONE     │
├─────────────┼─────────────┼─────────────┼─────────────┼─────────────┤
│ [Design DB] │ [Build Auth]│ [Core Feat] │ [Landing]   │ [Setup Env] │
│ [Fix Bug #3]│ [Write Docs]│             │             │ [Domain Reg]│
│ [Add Tests] │             │             │             │             │
└─────────────┴─────────────┴─────────────┴─────────────┴─────────────┘
```

**Workflow**:
```
Backlog → To Do → In Progress → Review → Done
           ↑                              │
           └──────── (if incomplete) ─────┘
```

**Auto-completion**: Moving subtask to "Done" column auto-completes the subtask and checks if parent goal should be completed

**Implementation**:

```dart
class KanbanBoard extends StatelessWidget {
  final String projectId;

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskProvider>().getTasksByProject(projectId);
    final subtasks = _getAllSubtasks(tasks);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: KanbanStatus.values.map((status) {
        return Expanded(
          child: _buildColumn(status, subtasks, context),
        );
      }).toList(),
    );
  }

  Widget _buildColumn(KanbanStatus status, List<Subtask> allSubtasks, BuildContext context) {
    final columnSubtasks = allSubtasks.where((s) => s.kanbanStatus == status).toList();

    return DragTarget<Subtask>(
      onWillAccept: (subtask) => subtask != null,
      onAccept: (subtask) {
        // Update subtask status
        context.read<TaskProvider>().updateSubtaskKanbanStatus(subtask.id, status);

        // Auto-complete if moved to Done
        if (status == KanbanStatus.done && !subtask.isCompleted) {
          context.read<TaskProvider>().toggleSubtask(subtask.parentTaskId, subtask.id);
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          margin: EdgeInsets.all(8),
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
            border: candidateData.isNotEmpty
                ? Border.all(color: Colors.blue, width: 2)  // Highlight on hover
                : null,
          ),
          child: Column(
            children: [
              // Column header
              Text(
                _getStatusLabel(status),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                '${columnSubtasks.length} items',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Divider(),

              // Subtask cards
              Expanded(
                child: ListView.builder(
                  itemCount: columnSubtasks.length,
                  itemBuilder: (context, index) {
                    return _buildSubtaskCard(columnSubtasks[index]);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubtaskCard(Subtask subtask) {
    return Draggable<Subtask>(
      data: subtask,
      feedback: Material(
        elevation: 4,
        child: _buildCardContent(subtask),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: _buildCardContent(subtask),
      ),
      child: _buildCardContent(subtask),
    );
  }

  Widget _buildCardContent(Subtask subtask) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtask.title,
            style: TextStyle(fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 8),
          Row(
            children: [
              if (subtask.timeEstimate != null)
                Chip(
                  label: Text('${subtask.timeEstimate}min'),
                  avatar: Icon(Icons.timer, size: 16),
                ),
              if (subtask.dependencies.isNotEmpty)
                Chip(
                  label: Text('${subtask.dependencies.length} deps'),
                  avatar: Icon(Icons.link, size: 16),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
```

### Burndown Chart

**File**: `lib/widgets/visualizer/burndown_chart.dart` (380 lines)

**Purpose**: Track remaining work over time

**Data**: Calculates total `timeEstimate` for incomplete subtasks

**Layout**:

```
Remaining Hours
    ↑
 100│ ●
    │   ●
 80 │     ●
    │       ●
 60 │         ●
    │           ● (actual)
 40 │           ╲
    │            ╲ (ideal)
 20 │             ╲
    │              ●
  0 └───────────────────→ Time
     Start    Week 1    Week 2    Deadline
```

**Features**:
- **Ideal line**: Linear decrease from total hours to zero by deadline
- **Actual line**: Real progress based on completed subtasks
- **Projection**: Dotted line showing estimated completion date based on current velocity

**Implementation**:

```dart
class BurndownChart extends StatelessWidget {
  final String projectId;

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskProvider>().getTasksByProject(projectId);
    final subtasks = _getAllSubtasks(tasks);

    // Calculate data points
    final totalHours = _calculateTotalHours(subtasks);
    final dataPoints = _calculateBurndown(subtasks);

    return LineChart(
      LineChartData(
        lineBarsData: [
          // Ideal line
          LineChartBarData(
            spots: _calculateIdealLine(totalHours, startDate, deadline),
            isCurved: false,
            color: Colors.grey,
            dashArray: [5, 5],
            dotData: FlDotData(show: false),
          ),

          // Actual line
          LineChartBarData(
            spots: dataPoints,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: FlDotData(show: true),
          ),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            axisNameWidget: Text('Remaining Hours'),
            sideTitles: SideTitles(showTitles: true),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: Text('Date'),
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final date = startDate.add(Duration(days: value.toInt()));
                return Text(DateFormat('MMM dd').format(date));
              },
            ),
          ),
        ),
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: true),
      ),
    );
  }

  double _calculateTotalHours(List<Subtask> subtasks) {
    return subtasks
        .where((s) => s.timeEstimate != null)
        .fold(0.0, (sum, s) => sum + (s.timeEstimate! / 60));  // Convert minutes to hours
  }

  List<FlSpot> _calculateBurndown(List<Subtask> subtasks) {
    final points = <FlSpot>[];
    final sortedSubtasks = subtasks
        .where((s) => s.completedAt != null)
        .toList()
      ..sort((a, b) => a.completedAt!.compareTo(b.completedAt!));

    var remainingHours = _calculateTotalHours(subtasks);
    points.add(FlSpot(0, remainingHours));  // Start point

    for (final subtask in sortedSubtasks) {
      remainingHours -= (subtask.timeEstimate ?? 0) / 60;
      final daysSinceStart = subtask.completedAt!.difference(startDate).inDays;
      points.add(FlSpot(daysSinceStart.toDouble(), remainingHours));
    }

    return points;
  }

  List<FlSpot> _calculateIdealLine(double totalHours, DateTime start, DateTime end) {
    final totalDays = end.difference(start).inDays;
    return [
      FlSpot(0, totalHours),
      FlSpot(totalDays.toDouble(), 0),
    ];
  }
}
```

---

(Continuing in next message due to length...)

**Continue to**: [Part 4: Performance & Optimization →](04_PERFORMANCE.md)
