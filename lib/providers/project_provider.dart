import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../services/storage_service.dart';

/// Provider for managing projects and their associated tasks
class ProjectProvider extends ChangeNotifier {
  final StorageService _storage;
  final _uuid = const Uuid();

  /// Currently selected project for visualization
  String? _selectedProjectId;

  ProjectProvider(this._storage);

  // ========== Getters ==========

  /// Get all projects
  List<Project> get allProjects => _storage.projectsBox.values.toList();

  /// Get projects sorted by start date
  List<Project> get projectsByStartDate {
    final projects = allProjects;
    projects.sort((a, b) => a.startDate.compareTo(b.startDate));
    return projects;
  }

  /// Get the currently selected project
  Project? get selectedProject {
    if (_selectedProjectId == null) return null;
    return _storage.projectsBox.get(_selectedProjectId);
  }

  /// Get selected project ID
  String? get selectedProjectId => _selectedProjectId;

  /// Get a project by ID
  Project? getProjectById(String id) => _storage.projectsBox.get(id);

  // ========== Project CRUD Operations ==========

  /// Create a new project
  Future<Project> createProject({
    required String name,
    String description = '',
    required int colorValue,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final project = Project(
      id: _uuid.v4(),
      name: name,
      description: description,
      colorValue: colorValue,
      startDate: startDate,
      endDate: endDate,
    );
    await _storage.projectsBox.put(project.id, project);
    notifyListeners();
    return project;
  }

  /// Update an existing project
  Future<void> updateProject(Project project) async {
    project.updatedAt = DateTime.now();
    await project.save();
    notifyListeners();
  }

  /// Delete a project (tasks remain but lose their project association)
  Future<void> deleteProject(String projectId) async {
    await _storage.projectsBox.delete(projectId);
    if (_selectedProjectId == projectId) {
      _selectedProjectId = null;
    }
    notifyListeners();
  }

  // ========== Selection Management ==========

  /// Select a project for visualization
  void selectProject(String? projectId) {
    _selectedProjectId = projectId;
    notifyListeners();
  }

  /// Clear project selection
  void clearSelection() {
    _selectedProjectId = null;
    notifyListeners();
  }

  // ========== Task Relationship Helpers ==========

  /// Get tasks that belong to a specific project
  List<Task> getTasksForProject(String projectId, List<Task> allTasks) {
    return allTasks.where((task) => task.projectId == projectId).toList();
  }

  /// Get tasks for the selected project
  List<Task> getSelectedProjectTasks(List<Task> allTasks) {
    if (_selectedProjectId == null) return [];
    return getTasksForProject(_selectedProjectId!, allTasks);
  }

  /// Calculate project completion percentage based on completed tasks
  double getProjectCompletion(String projectId, List<Task> allTasks) {
    final projectTasks = getTasksForProject(projectId, allTasks);
    if (projectTasks.isEmpty) return 0.0;

    final completedCount = projectTasks.where((t) => t.isCompleted).length;
    return completedCount / projectTasks.length;
  }

  /// Calculate total time estimate for a project
  int getTotalTimeEstimate(String projectId, List<Task> allTasks) {
    final projectTasks = getTasksForProject(projectId, allTasks);
    return projectTasks.fold<int>(
      0,
      (sum, task) => sum + (task.timeEstimate ?? 0),
    );
  }

  /// Calculate remaining time estimate for a project
  int getRemainingTimeEstimate(String projectId, List<Task> allTasks) {
    final projectTasks = getTasksForProject(projectId, allTasks);
    return projectTasks.fold<int>(
      0,
      (sum, task) => sum + task.remainingTimeEstimate,
    );
  }

  /// Get tasks grouped by Kanban status
  Map<KanbanStatus, List<Task>> getTasksByKanbanStatus(
    String projectId,
    List<Task> allTasks,
  ) {
    final projectTasks = getTasksForProject(projectId, allTasks);
    final Map<KanbanStatus, List<Task>> grouped = {
      for (var status in KanbanStatus.values) status: [],
    };

    for (final task in projectTasks) {
      final status = task.kanbanStatus ?? KanbanStatus.backlog;
      grouped[status]!.add(task);
    }

    return grouped;
  }

  /// Get tasks sorted for Gantt chart (by start date)
  List<Task> getTasksForGantt(String projectId, List<Task> allTasks) {
    final projectTasks = getTasksForProject(projectId, allTasks);
    projectTasks.sort(
      (a, b) => a.effectiveStartDate.compareTo(b.effectiveStartDate),
    );
    return projectTasks;
  }

  /// Get date range for project Gantt chart
  ({DateTime start, DateTime end}) getProjectDateRange(
    String projectId,
    List<Task> allTasks,
  ) {
    final project = getProjectById(projectId);
    if (project == null) {
      final now = DateTime.now();
      return (start: now, end: now.add(const Duration(days: 30)));
    }
    return (start: project.startDate, end: project.endDate);
  }
}
