# Practical Example: Building a Task Manager Feature

## Feature Requirements
Create a task management feature where users can:
- View their tasks
- Add new tasks
- Mark tasks as complete
- Delete tasks
- Filter by status (all, active, completed)

---

## 🧠 LOGIC AGENT: Architecture & Business Rules

### Use Cases Defined

```dart
// domain/use_cases/get_tasks_use_case.dart
class GetTasksUseCase {
  final TaskRepository repository;
  
  GetTasksUseCase(this.repository);
  
  Future<Result<List<Task>>> call({TaskFilter filter = TaskFilter.all}) async {
    final result = await repository.getTasks();
    
    return result.map((tasks) {
      switch (filter) {
        case TaskFilter.active:
          return tasks.where((t) => !t.isCompleted).toList();
        case TaskFilter.completed:
          return tasks.where((t) => t.isCompleted).toList();
        case TaskFilter.all:
          return tasks;
      }
    });
  }
}

// domain/use_cases/create_task_use_case.dart
class CreateTaskUseCase {
  final TaskRepository repository;
  final TaskValidator validator;
  
  CreateTaskUseCase(this.repository, this.validator);
  
  Future<Result<Task>> call(CreateTaskParams params) async {
    // Business Rule: Validate title
    final validationResult = validator.validateTitle(params.title);
    if (!validationResult.isValid) {
      return Failure(ValidationException(validationResult.errorMessage!));
    }
    
    // Business Rule: Title must be unique
    final existing = await repository.getTaskByTitle(params.title);
    if (existing.isSuccess) {
      return Failure(DuplicateTaskException('Task with this title exists'));
    }
    
    return await repository.createTask(params.title, params.description);
  }
}
```

### State Management (BLoC)

```dart
// application/bloc/task_bloc.dart
class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final GetTasksUseCase getTasksUseCase;
  final CreateTaskUseCase createTaskUseCase;
  final CompleteTaskUseCase completeTaskUseCase;
  final DeleteTaskUseCase deleteTaskUseCase;
  
  TaskBloc({
    required this.getTasksUseCase,
    required this.createTaskUseCase,
    required this.completeTaskUseCase,
    required this.deleteTaskUseCase,
  }) : super(TaskInitial()) {
    on<LoadTasks>(_onLoadTasks);
    on<CreateTask>(_onCreateTask);
    on<CompleteTask>(_onCompleteTask);
    on<DeleteTask>(_onDeleteTask);
    on<FilterTasks>(_onFilterTasks);
  }
  
  Future<void> _onLoadTasks(LoadTasks event, Emitter<TaskState> emit) async {
    emit(TaskLoading());
    
    final result = await getTasksUseCase(filter: event.filter);
    
    result.when(
      success: (tasks) => emit(TaskLoaded(
        tasks: tasks,
        filter: event.filter,
      )),
      failure: (error) => emit(TaskError(error.message)),
    );
  }
  
  Future<void> _onCreateTask(CreateTask event, Emitter<TaskState> emit) async {
    final currentState = state;
    if (currentState is! TaskLoaded) return;
    
    emit(TaskCreating());
    
    final result = await createTaskUseCase(
      CreateTaskParams(
        title: event.title,
        description: event.description,
      ),
    );
    
    result.when(
      success: (task) {
        // Reload tasks after successful creation
        add(LoadTasks(filter: currentState.filter));
      },
      failure: (error) => emit(TaskError(error.message)),
    );
  }
}
```

### Business Rules Documentation

```dart
// domain/validators/task_validator.dart
class TaskValidator {
  ValidationResult validateTitle(String title) {
    // Business Rule 1: Title cannot be empty
    if (title.trim().isEmpty) {
      return ValidationResult.error('Task title cannot be empty');
    }
    
    // Business Rule 2: Title must be between 3 and 100 characters
    if (title.length < 3) {
      return ValidationResult.error('Task title must be at least 3 characters');
    }
    
    if (title.length > 100) {
      return ValidationResult.error('Task title cannot exceed 100 characters');
    }
    
    // Business Rule 3: Title cannot contain special characters
    final hasSpecialChars = RegExp(r'[<>{}[\]\\]').hasMatch(title);
    if (hasSpecialChars) {
      return ValidationResult.error('Task title cannot contain special characters');
    }
    
    return ValidationResult.valid();
  }
}
```

**Communication to Backend Agent:**
- Need `TaskRepository` with methods: `getTasks()`, `createTask()`, `getTaskByTitle()`, `updateTask()`, `deleteTask()`
- Need `Task` model with fields: `id`, `title`, `description`, `isCompleted`, `createdAt`
- Errors to handle: `NetworkException`, `CacheException`, `NotFoundException`

**Communication to Frontend Agent:**
- Use `TaskBloc` for state management
- States available: `TaskInitial`, `TaskLoading`, `TaskCreating`, `TaskLoaded`, `TaskError`
- Events to dispatch: `LoadTasks`, `CreateTask`, `CompleteTask`, `DeleteTask`, `FilterTasks`
- Validation errors will be in `TaskError.message`

---

## 🔌 BACKEND AGENT: Data Layer Implementation

### Data Models

```dart
// data/models/task_model.dart
class TaskModel {
  final String id;
  final String title;
  final String? description;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;

  TaskModel({
    required this.id,
    required this.title,
    this.description,
    required this.isCompleted,
    required this.createdAt,
    this.completedAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      isCompleted: json['is_completed'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'is_completed': isCompleted,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  Task toDomain() {
    return Task(
      id: id,
      title: title,
      description: description,
      isCompleted: isCompleted,
      createdAt: createdAt,
      completedAt: completedAt,
    );
  }
}
```

### API Service

```dart
// data/services/api/task_api_service.dart
class TaskApiService {
  final Dio _dio;
  
  TaskApiService(this._dio);
  
  Future<List<TaskModel>> getTasks() async {
    try {
      final response = await _dio.get('/tasks');
      final List<dynamic> data = response.data['tasks'];
      return data.map((json) => TaskModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<TaskModel> createTask(String title, String? description) async {
    try {
      final response = await _dio.post(
        '/tasks',
        data: {
          'title': title,
          'description': description,
        },
      );
      return TaskModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<TaskModel> updateTask(String id, {bool? isCompleted}) async {
    try {
      final response = await _dio.patch(
        '/tasks/$id',
        data: {
          if (isCompleted != null) 'is_completed': isCompleted,
        },
      );
      return TaskModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<void> deleteTask(String id) async {
    try {
      await _dio.delete('/tasks/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  AppException _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException('Connection timeout');
      case DioExceptionType.connectionError:
        return NetworkException('No internet connection');
      default:
        if (e.response?.statusCode == 404) {
          return NotFoundException('Task not found');
        }
        return ServerException('Server error: ${e.message}');
    }
  }
}
```

### Local Storage

```dart
// data/services/local_storage/task_local_storage.dart
class TaskLocalStorage {
  final Hive _hive;
  static const String _boxName = 'tasks';
  
  TaskLocalStorage(this._hive);
  
  Future<void> saveTasks(List<TaskModel> tasks) async {
    final box = await _hive.openBox<Map>(_boxName);
    await box.clear();
    
    for (var task in tasks) {
      await box.put(task.id, task.toJson());
    }
  }
  
  Future<List<TaskModel>> getTasks() async {
    final box = await _hive.openBox<Map>(_boxName);
    return box.values
        .map((json) => TaskModel.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }
  
  Future<void> saveTask(TaskModel task) async {
    final box = await _hive.openBox<Map>(_boxName);
    await box.put(task.id, task.toJson());
  }
  
  Future<void> deleteTask(String id) async {
    final box = await _hive.openBox<Map>(_boxName);
    await box.delete(id);
  }
}
```

### Repository Implementation

```dart
// data/repositories/task_repository_impl.dart
class TaskRepositoryImpl implements TaskRepository {
  final TaskApiService _apiService;
  final TaskLocalStorage _localStorage;
  final NetworkInfo _networkInfo;
  
  TaskRepositoryImpl(
    this._apiService,
    this._localStorage,
    this._networkInfo,
  );
  
  @override
  Future<Result<List<Task>>> getTasks() async {
    try {
      // Check network connectivity
      if (await _networkInfo.isConnected) {
        // Fetch from API
        final tasks = await _apiService.getTasks();
        
        // Cache locally
        await _localStorage.saveTasks(tasks);
        
        return Success(tasks.map((t) => t.toDomain()).toList());
      } else {
        // Use cached data when offline
        final cached = await _localStorage.getTasks();
        return Success(cached.map((t) => t.toDomain()).toList());
      }
    } on AppException catch (e) {
      // Try local cache on error
      try {
        final cached = await _localStorage.getTasks();
        return Success(cached.map((t) => t.toDomain()).toList());
      } catch (_) {
        return Failure(e);
      }
    } catch (e) {
      return Failure(CacheException('Failed to load tasks'));
    }
  }
  
  @override
  Future<Result<Task>> createTask(String title, String? description) async {
    try {
      if (!await _networkInfo.isConnected) {
        return Failure(NetworkException('No internet connection'));
      }
      
      final task = await _apiService.createTask(title, description);
      await _localStorage.saveTask(task);
      
      return Success(task.toDomain());
    } on AppException catch (e) {
      return Failure(e);
    }
  }
  
  @override
  Future<Result<Task>> getTaskByTitle(String title) async {
    try {
      final tasks = await _localStorage.getTasks();
      final task = tasks.firstWhere(
        (t) => t.title.toLowerCase() == title.toLowerCase(),
      );
      return Success(task.toDomain());
    } catch (e) {
      return Failure(NotFoundException('Task not found'));
    }
  }
}
```

**Communication to Logic Agent:**
- `TaskRepository` implemented with all requested methods
- Offline-first strategy: tries API first, falls back to cache
- Error types returned: `NetworkException`, `CacheException`, `NotFoundException`, `ServerException`
- Models use domain entities defined by Logic Agent

**Communication to Frontend Agent:**
- `TaskModel` structure available for type safety
- Repository handles loading states internally
- Errors are wrapped in `Result` type for easy handling

---

## 🎨 FRONTEND AGENT: UI Implementation

### Task List Screen

```dart
// presentation/screens/task_list_screen.dart
class TaskListScreen extends StatelessWidget {
  const TaskListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          _FilterMenu(),
        ],
      ),
      body: BlocBuilder<TaskBloc, TaskState>(
        builder: (context, state) {
          if (state is TaskInitial || state is TaskLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state is TaskError) {
            return _ErrorView(message: state.message);
          }
          
          if (state is TaskLoaded) {
            if (state.tasks.isEmpty) {
              return _EmptyState(filter: state.filter);
            }
            
            return _TaskList(tasks: state.tasks);
          }
          
          return const SizedBox();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateTaskDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateTaskDialog(),
    );
  }
}
```

### Task List Widget

```dart
// presentation/widgets/task_list.dart
class _TaskList extends StatelessWidget {
  final List<Task> tasks;
  
  const _TaskList({required this.tasks});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: tasks.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskListItem(
          task: task,
          onTap: () => _onTaskTap(context, task),
          onComplete: () => _onTaskComplete(context, task),
          onDelete: () => _onTaskDelete(context, task),
        );
      },
    );
  }
  
  void _onTaskTap(BuildContext context, Task task) {
    // Navigate to task detail or show bottom sheet
    showModalBottomSheet(
      context: context,
      builder: (context) => TaskDetailSheet(task: task),
    );
  }
  
  void _onTaskComplete(BuildContext context, Task task) {
    context.read<TaskBloc>().add(CompleteTask(taskId: task.id));
  }
  
  void _onTaskDelete(BuildContext context, Task task) {
    // Show confirmation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<TaskBloc>().add(DeleteTask(taskId: task.id));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
```

### Task List Item

```dart
// presentation/widgets/task_list_item.dart
class TaskListItem extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onDelete;

  const TaskListItem({
    Key? key,
    required this.task,
    this.onTap,
    this.onComplete,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (_) => onComplete?.call(),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: task.description != null
            ? Text(
                task.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
```

### Create Task Dialog

```dart
// presentation/widgets/create_task_dialog.dart
class CreateTaskDialog extends StatefulWidget {
  const CreateTaskDialog({Key? key}) : super(key: key);

  @override
  State<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<CreateTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocListener<TaskBloc, TaskState>(
      listener: (context, state) {
        if (state is TaskLoaded) {
          // Task created successfully
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task created successfully')),
          );
        }
        
        if (state is TaskError) {
          // Show error message from Logic Agent's validation
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: AlertDialog(
        title: const Text('Create New Task'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter task title',
                ),
                autofocus: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Enter task description',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          BlocBuilder<TaskBloc, TaskState>(
            builder: (context, state) {
              final isCreating = state is TaskCreating;
              
              return ElevatedButton(
                onPressed: isCreating ? null : _createTask,
                child: isCreating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create'),
              );
            },
          ),
        ],
      ),
    );
  }

  void _createTask() {
    if (_formKey.currentState!.validate()) {
      context.read<TaskBloc>().add(
            CreateTask(
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
            ),
          );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
```

### Filter Menu

```dart
// presentation/widgets/filter_menu.dart
class _FilterMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        final currentFilter = state is TaskLoaded 
            ? state.filter 
            : TaskFilter.all;
            
        return PopupMenuButton<TaskFilter>(
          icon: const Icon(Icons.filter_list),
          onSelected: (filter) {
            context.read<TaskBloc>().add(LoadTasks(filter: filter));
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: TaskFilter.all,
              child: Row(
                children: [
                  if (currentFilter == TaskFilter.all)
                    const Icon(Icons.check, size: 18),
                  const SizedBox(width: 8),
                  const Text('All Tasks'),
                ],
              ),
            ),
            PopupMenuItem(
              value: TaskFilter.active,
              child: Row(
                children: [
                  if (currentFilter == TaskFilter.active)
                    const Icon(Icons.check, size: 18),
                  const SizedBox(width: 8),
                  const Text('Active'),
                ],
              ),
            ),
            PopupMenuItem(
              value: TaskFilter.completed,
              child: Row(
                children: [
                  if (currentFilter == TaskFilter.completed)
                    const Icon(Icons.check, size: 18),
                  const SizedBox(width: 8),
                  const Text('Completed'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
```

**Communication back to Logic Agent:**
- UI triggers events: `CreateTask`, `CompleteTask`, `DeleteTask`, `LoadTasks`, `FilterTasks`
- Responds to states from `TaskBloc`
- Displays validation errors from business logic
- Loading states shown during operations

---

## Integration Summary

### Data Flow Diagram
```
User Interaction (Frontend)
    ↓
Event Dispatched to BLoC (Logic)
    ↓
Use Case Executed with Validation (Logic)
    ↓
Repository Called (Backend)
    ↓
API Service / Local Storage (Backend)
    ↓
Data Returned through Repository (Backend)
    ↓
State Updated in BLoC (Logic)
    ↓
UI Rebuilds with New State (Frontend)
```

### Key Integration Points

1. **Frontend → Logic**: Events dispatched via `context.read<TaskBloc>().add()`
2. **Logic → Backend**: Use cases call repository methods
3. **Backend → Logic**: Returns `Result<T>` with success or failure
4. **Logic → Frontend**: Emits states that trigger UI rebuilds

### Testing Strategy

**Logic Agent Tests:**
- Unit test each use case
- Test business validation rules
- Test BLoC state transitions

**Backend Agent Tests:**
- Integration tests for API service
- Test offline/online scenarios
- Test caching behavior

**Frontend Agent Tests:**
- Widget tests for each component
- Test user interactions
- Test state-based rendering

This example demonstrates how all three agents work together cohesively while maintaining clear boundaries and responsibilities!
