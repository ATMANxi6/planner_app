# Life Planner: Comprehensive Development Report
## Part 6: Integration & Data Flow

**Report Navigation**: [← Part 5](05_UX_DESIGN.md) | **Part 6** | [Part 7 →](07_QUALITY_ROADMAP.md)

---

## Table of Contents
- [Cross-Feature Integration](#cross-feature-integration)
- [Data Flow Patterns](#data-flow-patterns)
- [Provider Dependencies](#provider-dependencies)
- [Integration Examples](#integration-examples)

---

## Cross-Feature Integration

Life Planner's true power comes from how features integrate seamlessly. This section documents the integration points that create a unified user experience.

### Integration Matrix

| Feature A | Feature B | Integration Point | Data Flow |
|-----------|-----------|------------------|-----------|
| **Task Management** | **Planning Canvas** | PlanningNode.taskId → Task | Canvas nodes wrap tasks with visual metadata |
| **Task Management** | **Mind Map** | MindMapNode.linkedTaskId → Task | Mind map nodes link to tasks for execution |
| **Tasks** | **Projects** | Task.projectId → Project | Tasks belong to projects for visualization |
| **Tasks** | **Time Blocks** | TimeBlock.linkedTaskId → Task | Schedule tasks in calendar |
| **Subtasks** | **Time Blocks** | TimeBlock.linkedSubtaskId → Subtask | Schedule subtasks independently |
| **Projects** | **Gantt Chart** | Project → Tasks → Subtasks | Timeline visualization of project tasks |
| **Projects** | **Kanban Board** | Project → Tasks → Subtasks | Workflow visualization |
| **Projects** | **Burndown Chart** | Project → Subtask time estimates | Progress tracking |
| **Planning Canvas** | **Projects** | PlanningNode.projectId → Project | Canvas scoped to project |
| **Dashboard** | **Everything** | Multi-provider consumption | Central hub aggregates all data |

### Integration Depth

**Level 1: Reference Integration** (Foreign Keys)
- Task → Project via `task.projectId`
- PlanningNode → Task via `planningNode.taskId`
- TimeBlock → Task via `timeBlock.linkedTaskId`

**Level 2: Reactive Integration** (Automatic Updates)
- Complete all subtasks → Goal auto-completes
- Move subtask to "Done" in Kanban → Subtask marked complete
- Delete task → Remove from planning canvas, mind map links cleared

**Level 3: Bidirectional Integration** (Two-way Sync)
- Task dependencies ↔ Planning canvas connections (can sync on user action)
- Task start/deadline ↔ Gantt chart bars (drag bar updates task dates)

---

## Data Flow Patterns

### Pattern 1: Create Task → Multi-Feature Propagation

**User Action**: Create new goal task with 3 subtasks

**Data Flow**:

```
1. User fills task creation form
   ↓
2. TaskProvider.addTask(task)
   ├─ Save to Hive: tasksBox.put(task.id, task)
   ├─ notifyListeners() → Triggers rebuild in:
   │  ├─ PlannerScreen (shows new task in goal tab)
   │  ├─ DashboardScreen (updates stats widget)
   │  └─ VisualizerScreen (if task has projectId)
   └─ Return to previous screen

3. PlanningProvider auto-creates PlanningNode
   ├─ Detects new task (via TaskProvider listener)
   ├─ Creates PlanningNode(taskId: task.id, isPositioned: false)
   ├─ Save to planningNodesBox
   └─ notifyListeners() → Canvas shows node in drawer

4. Dashboard widgets update
   ├─ DailyTasksWidget: Shows task if no startDate (today)
   ├─ StatsWidget: Increments total task count
   ├─ DeadlinesWidget: Shows task if deadline within 7 days
   └─ ProjectsWidget: Highlights project if task.projectId set
```

**Files Touched**:
- `lib/providers/task_provider.dart:605` (addTask method)
- `lib/providers/planning_provider.dart:605` (auto-create node)
- `lib/screens/planner_screen.dart:380` (rebuild task list)
- `lib/screens/dashboard_screen.dart:450` (rebuild widgets)

### Pattern 2: Complete Subtask → Cascading Updates

**User Action**: Check off subtask in Kanban board

**Data Flow**:

```
1. User drags subtask to "Done" column
   ↓
2. TaskProvider.updateSubtaskKanbanStatus(subtaskId, KanbanStatus.done)
   ├─ Find parent task
   ├─ Update subtask.kanbanStatus = done
   ├─ Check if all subtasks done → Auto-complete parent goal
   ├─ task.save() → Hive write
   └─ notifyListeners()

3. Reactive updates across features:
   ├─ Kanban Board: Subtask moves to "Done" column
   ├─ Gantt Chart: Subtask bar turns green
   ├─ Burndown Chart: Remaining hours decrease
   ├─ Task Detail Screen: Progress bar updates (2/3 subtasks done)
   ├─ Planner Screen: Goal shows completion badge if all subtasks done
   ├─ Dashboard Stats: Completion percentage increases
   └─ Dashboard Streaks: Updates if goal was a practice with frequency
```

**Cascade Logic** (in TaskProvider):

```dart
void updateSubtaskKanbanStatus(String taskId, String subtaskId, KanbanStatus status) {
  final task = _storage.tasksBox.get(taskId);
  final subtask = task?.subtasks.firstWhere((s) => s.id == subtaskId);

  if (subtask != null) {
    // 1. Update status
    subtask.kanbanStatus = status;

    // 2. Auto-complete if moved to "Done"
    if (status == KanbanStatus.done && !subtask.isCompleted) {
      subtask.isCompleted = true;
      subtask.completedAt = DateTime.now();
    }

    // 3. Check parent goal completion
    _checkGoalCompletion(task!);

    // 4. Persist
    task.save();

    // 5. Notify all listeners
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

      // Update streak if practice with frequency
      if (task.frequency != null) {
        task.streakCount++;
      }

      task.save();

      // Show celebration (via global event bus or callback)
      _eventBus.fire(GoalCompletedEvent(task));
    }
  }
}
```

### Pattern 3: Dashboard → Deep Links

**User Action**: Tap "3 tasks due today" in Dashboard

**Data Flow**:

```
1. User taps DeadlinesWidget
   ↓
2. Navigate to PlannerScreen with filter
   Navigator.push(
     context,
     MaterialPageRoute(
       builder: (context) => PlannerScreen(
         initialFilter: TaskFilter.dueToday(),
       ),
     ),
   )
   ↓
3. PlannerScreen builds with filter
   ├─ TaskProvider.getTasksByFilter(filter)
   ├─ Returns tasks where deadline == today
   ├─ ListView shows filtered tasks
   └─ AppBar shows "Tasks Due Today" title
```

**Filter Types**:

```dart
class TaskFilter {
  final TaskType? type;
  final DateTime? dueDate;
  final Priority? priority;
  final String? projectId;
  final String? category;

  // Preset filters
  factory TaskFilter.dueToday() => TaskFilter(dueDate: DateTime.now());
  factory TaskFilter.highPriority() => TaskFilter(priority: Priority.high);
  factory TaskFilter.project(String id) => TaskFilter(projectId: id);
}
```

---

## Provider Dependencies

### Dependency Graph

```
                StorageService (singleton)
                        ↓
        ┌───────────────┴───────────────┐
        ↓                               ↓
  TaskProvider                    ProjectProvider
  (Core domain)                   (Organizational)
        ↓                               ↓
        ├───────────────┬───────────────┤
        ↓               ↓               ↓
  PlanningProvider  MindMapProvider  TimeBlockProvider
  (Visual planning) (Brainstorming)  (Scheduling)
        ↓               ↓               ↓
        └───────────────┴───────────────┘
                        ↓
              DashboardConfigProvider
              (User preferences)
```

### Cross-Provider Access

**Reading from Another Provider**:

```dart
// In PlanningProvider
class PlanningProvider extends ChangeNotifier {
  final StorageService _storage;
  BuildContext? _context;  // Stored during initialization

  TaskProvider get _taskProvider => _context!.read<TaskProvider>();
  ProjectProvider get _projectProvider => _context!.read<ProjectProvider>();

  List<PlanningNodeWithTask> _buildAllNodes() {
    final nodes = _storage.planningNodesBox.values.toList();

    return nodes.map((node) {
      // Cross-provider read: Get task data
      final task = node.taskId != null
          ? _taskProvider.getTask(node.taskId!)
          : null;

      return PlanningNodeWithTask(node: node, task: task);
    }).toList();
  }
}
```

**Reacting to Another Provider's Changes**:

```dart
// In DashboardScreen
class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    // Watch multiple providers
    final tasks = context.watch<TaskProvider>().tasks;
    final projects = context.watch<ProjectProvider>().projects;
    final timeBlocks = context.watch<TimeBlockProvider>().getTodayBlocks();

    return Column(
      children: [
        StatsWidget(tasks: tasks, projects: projects),
        TimeBlocksWidget(timeBlocks: timeBlocks, tasks: tasks),
        // ... more widgets
      ],
    );
  }
}
```

### Provider Lifecycle

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize storage (opens Hive boxes)
  await StorageService.init();

  // 2. Create provider instances
  runApp(
    MultiProvider(
      providers: [
        // Level 0: Storage
        Provider<StorageService>(
          create: (_) => StorageService(),
        ),

        // Level 1: Core providers (depend on storage)
        ChangeNotifierProvider<TaskProvider>(
          create: (context) => TaskProvider(context.read<StorageService>()),
        ),
        ChangeNotifierProvider<ProjectProvider>(
          create: (context) => ProjectProvider(context.read<StorageService>()),
        ),

        // Level 2: Feature providers (depend on Level 1)
        ChangeNotifierProvider<PlanningProvider>(
          create: (context) => PlanningProvider(
            context.read<StorageService>(),
            context,  // For cross-provider access
          ),
        ),
        ChangeNotifierProvider<MindMapProvider>(
          create: (context) => MindMapProvider(context.read<StorageService>()),
        ),
        ChangeNotifierProvider<TimeBlockProvider>(
          create: (context) => TimeBlockProvider(context.read<StorageService>()),
        ),

        // Level 3: Config provider (depends on everything)
        ChangeNotifierProvider<DashboardConfigProvider>(
          create: (context) => DashboardConfigProvider(context.read<StorageService>()),
        ),
      ],
      child: MyApp(),
    ),
  );

  // 3. Post-initialization tasks
  final taskProvider = Provider.of<TaskProvider>(context, listen: false);
  taskProvider.resetRecurringTasks();  // Reset daily/weekly/monthly tasks
}
```

---

## Integration Examples

### Example 1: Mind Map → Task → Time Block → Dashboard

**User Journey**:

```
1. User brainstorms "Launch Marketing Campaign" in Mind Map
   ↓
2. User creates mind map node
   MindMapProvider.addNode(MindMapNode(
     title: 'Launch Marketing Campaign',
   ))
   ↓
3. User links node to new task
   TaskProvider.addTask(Task(
     title: 'Launch Marketing Campaign',
     type: TaskType.goal,
   ))
   MindMapProvider.updateNode(node.copyWith(
     linkedTaskId: task.id,
   ))
   ↓
4. User adds 3 subtasks to goal
   TaskProvider.addSubtask(task.id, Subtask(title: 'Create landing page'))
   TaskProvider.addSubtask(task.id, Subtask(title: 'Set up ads'))
   TaskProvider.addSubtask(task.id, Subtask(title: 'Launch campaign'))
   ↓
5. User schedules first subtask in time block
   TimeBlockProvider.addTimeBlock(TimeBlock(
     title: 'Work on landing page',
     startTime: DateTime(2025, 12, 15, 9, 0),
     endTime: DateTime(2025, 12, 15, 11, 0),
     linkedSubtaskId: subtask1.id,
   ))
   ↓
6. Dashboard automatically shows:
   - DailyTasksWidget: "Launch Marketing Campaign (0/3 subtasks)"
   - TimeBlocksWidget: "9:00-11:00 Work on landing page"
   - ProjectsWidget: Project containing this goal (if assigned)
   - DeadlinesWidget: Campaign deadline (if set)
```

**Data Connections**:

```
MindMapNode
  └─ linkedTaskId ──→ Task (Goal)
                        ├─ subtasks[0] ←─── TimeBlock.linkedSubtaskId
                        ├─ subtasks[1]
                        └─ subtasks[2]
                        ├─ projectId ──→ Project
                        └─ deadline ──→ Shown in DeadlinesWidget
```

### Example 2: Planning Canvas → Gantt Chart → Kanban Board

**User Journey**:

```
1. User organizes project in Planning Canvas (Canvas mode)
   - Places nodes on canvas
   - Draws dependency connections
   PlanningProvider.updateNodePosition(nodeId, position)
   PlanningProvider.addConnection(fromId, toId)
   ↓
2. User switches to Visualizer → Gantt Chart
   - Tasks with canvas connections shown with arrows
   - Timeline calculated from task.startDate and task.deadline
   VisualizerScreen shows GanttChart(projectId: selectedProject.id)
   ↓
3. User drags Gantt bar to reschedule task
   GanttChart._handleDrag(taskId, newStartDate, newEndDate)
   TaskProvider.updateTask(task.copyWith(
     startDate: newStartDate,
     deadline: newEndDate,
   ))
   ↓
4. User switches to Kanban Board
   - Same subtasks appear in Kanban columns
   - Positions determined by subtask.kanbanStatus
   VisualizerScreen shows KanbanBoard(projectId: selectedProject.id)
   ↓
5. User moves subtask from "To Do" to "In Progress"
   KanbanBoard.onDragAccept(subtask, KanbanStatus.inProgress)
   TaskProvider.updateSubtaskKanbanStatus(subtask.id, status)
   ↓
6. All views update reactively:
   - Canvas: Node color changes (visual feedback)
   - Gantt: Bar color changes (in progress = orange)
   - Burndown: No change (not yet complete)
   - Dashboard: Stats update (1 task in progress)
```

**Shared Data Model**:

```
Project
  └─ projectId ──→ Task.projectId
                    ├─ Task data (title, dates, etc.)
                    ├─ Subtasks
                    │   └─ Subtask.kanbanStatus ──→ Kanban column
                    └─ PlanningNode (visual metadata)
                        ├─ x, y (canvas position)
                        └─ dependencies (canvas connections)
```

All three visualizations (Gantt, Kanban, Burndown) read from the same `Task` and `Subtask` objects, ensuring consistency.

### Example 3: Recurring Task Reset Flow

**Triggered On**: App startup (main.dart)

**Data Flow**:

```
1. App launches
   main() → StorageService.init() → Provider setup
   ↓
2. Post-initialization: Reset recurring tasks
   TaskProvider.resetRecurringTasks()
   ↓
3. Check each task with frequency set
   for (final task in tasks.where((t) => t.frequency != null && t.isCompleted)) {
     final lastReset = task.lastResetDate ?? task.completedAt ?? task.createdAt;
     final shouldReset = _shouldResetTask(task.frequency!, lastReset, DateTime.now());

     if (shouldReset) {
       // Reset task
       task.isCompleted = false;
       task.completedAt = null;
       task.lastResetDate = DateTime.now();

       // Reset subtasks (for goals)
       if (task.type == TaskType.goal) {
         for (final subtask in task.subtasks) {
           subtask.isCompleted = false;
         }
       }

       task.save();
     }
   }
   ↓
4. notifyListeners() → All UI updates
   - PlannerScreen shows unchecked tasks
   - Dashboard stats reset
   - Streak counters reset (if task was practice/distraction)
```

**Reset Logic**:

```dart
bool _shouldResetTask(Frequency frequency, DateTime lastReset, DateTime now) {
  switch (frequency) {
    case Frequency.daily:
      return now.day != lastReset.day || now.month != lastReset.month;

    case Frequency.weekly:
      return now.difference(lastReset).inDays >= 7;

    case Frequency.monthly:
      return now.month != lastReset.month || now.year != lastReset.year;
  }
}
```

**Example Scenarios**:

| Task | Frequency | Last Reset | Current Date | Should Reset? |
|------|-----------|------------|-------------|---------------|
| Morning exercise | Daily | 2025-12-11 | 2025-12-12 | ✅ Yes (new day) |
| Weekly review | Weekly | 2025-12-05 | 2025-12-12 | ✅ Yes (7+ days) |
| Monthly report | Monthly | 2025-11-15 | 2025-12-12 | ✅ Yes (new month) |
| Morning exercise | Daily | 2025-12-12 | 2025-12-12 | ❌ No (same day) |

---

**Continue to**: [Part 7: Code Quality & Roadmap →](07_QUALITY_ROADMAP.md)

**Report Navigation**:
- [Part 1: Executive Overview](01_EXECUTIVE_OVERVIEW.md)
- [Part 2: Architecture & Technical Design](02_ARCHITECTURE.md)
- [Part 3: Feature Catalog](03_FEATURES.md)
- [Part 4: Performance & Optimization](04_PERFORMANCE.md)
- [Part 5: User Experience Design](05_UX_DESIGN.md)
- **Part 6: Integration & Data Flow** (Current)
- [Part 7: Code Quality & Roadmap](07_QUALITY_ROADMAP.md)
- [Part 8: Appendices & Reference](08_APPENDICES.md)
