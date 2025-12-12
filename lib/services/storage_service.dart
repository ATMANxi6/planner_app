import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';
import '../models/mind_map_node.dart';
import '../models/project.dart';
import '../models/time_block.dart';
import '../models/dashboard_config.dart';
import '../models/theme_settings.dart';
import '../models/planning_node.dart';

class StorageService {
  static const String _tasksBox = 'tasks';
  static const String _mindMapBox = 'mindMap';
  static const String _projectsBox = 'projects';
  static const String _timeBlocksBox = 'timeBlocks';
  static const String _dashboardConfigBox = 'dashboardConfig';
  static const String _themeSettingsBox = 'themeSettings';
  static const String _planningNodesBox = 'planningNodes';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register task-related adapters
    Hive.registerAdapter(TaskTypeAdapter());
    Hive.registerAdapter(PriorityAdapter());
    Hive.registerAdapter(FrequencyAdapter());
    Hive.registerAdapter(CategoryAdapter());
    Hive.registerAdapter(SubtaskAdapter());
    Hive.registerAdapter(MilestoneAdapter());
    Hive.registerAdapter(TaskAdapter());
    Hive.registerAdapter(KanbanStatusAdapter());

    // Register mind map adapters
    Hive.registerAdapter(MindMapNodeAdapter());

    // Register project adapters
    Hive.registerAdapter(ProjectAdapter());

    // Register time blocking adapters
    Hive.registerAdapter(TimeBlockAdapter());
    Hive.registerAdapter(DashboardConfigAdapter());
    Hive.registerAdapter(TimeSlotIntervalAdapter());

    // Register theme settings adapters
    Hive.registerAdapter(ThemeModeAdapter());
    Hive.registerAdapter(FontSizePreferenceAdapter());
    Hive.registerAdapter(ThemeSettingsAdapter());

    // Register planning canvas adapters
    Hive.registerAdapter(PlanningNodeTypeAdapter());
    Hive.registerAdapter(ConnectionTypeAdapter());
    Hive.registerAdapter(NodeConnectionAdapter());
    Hive.registerAdapter(PlanningNodeAdapter());

    // Try to open boxes, delete and recreate if there's a schema mismatch
    try {
      await Hive.openBox<Task>(_tasksBox);
      await Hive.openBox<MindMapNode>(_mindMapBox);
      await Hive.openBox<Project>(_projectsBox);
      await Hive.openBox<TimeBlock>(_timeBlocksBox);
      await Hive.openBox<DashboardConfig>(_dashboardConfigBox);
      await Hive.openBox<ThemeSettings>(_themeSettingsBox);
      await Hive.openBox<PlanningNode>(_planningNodesBox);
    } catch (e) {
      // If there's an error (likely due to schema changes), delete old boxes
      // ignore: avoid_print
      print('Schema migration: Deleting old boxes due to type mismatch');
      await Hive.deleteBoxFromDisk(_tasksBox);
      await Hive.deleteBoxFromDisk(_mindMapBox);
      await Hive.deleteBoxFromDisk(_projectsBox);
      await Hive.deleteBoxFromDisk(_timeBlocksBox);
      await Hive.deleteBoxFromDisk(_dashboardConfigBox);
      await Hive.deleteBoxFromDisk(_themeSettingsBox);
      await Hive.deleteBoxFromDisk(_planningNodesBox);

      // Recreate boxes with new schema
      await Hive.openBox<Task>(_tasksBox);
      await Hive.openBox<MindMapNode>(_mindMapBox);
      await Hive.openBox<Project>(_projectsBox);
      await Hive.openBox<TimeBlock>(_timeBlocksBox);
      await Hive.openBox<DashboardConfig>(_dashboardConfigBox);
      await Hive.openBox<ThemeSettings>(_themeSettingsBox);
      await Hive.openBox<PlanningNode>(_planningNodesBox);
    }
  }

  Box<Task> get tasksBox => Hive.box<Task>(_tasksBox);
  Box<MindMapNode> get mindMapBox => Hive.box<MindMapNode>(_mindMapBox);
  Box<Project> get projectsBox => Hive.box<Project>(_projectsBox);
  Box<TimeBlock> get timeBlocksBox => Hive.box<TimeBlock>(_timeBlocksBox);
  Box<DashboardConfig> get dashboardConfigBox => Hive.box<DashboardConfig>(_dashboardConfigBox);
  Box<ThemeSettings> get themeSettingsBox => Hive.box<ThemeSettings>(_themeSettingsBox);
  Box<PlanningNode> get planningNodesBox => Hive.box<PlanningNode>(_planningNodesBox);

  Future<void> dispose() async {
    await Hive.close();
  }
}
