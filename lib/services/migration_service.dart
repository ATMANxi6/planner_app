import 'package:flutter/foundation.dart' hide Category;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../models/time_block.dart';
import 'storage_service.dart';

/// Service to migrate data from old architecture to new unified Task system
class MigrationService {
  final StorageService _storage;
  final _uuid = const Uuid();

  static const String _migrationKey = 'migration_v2_completed';

  MigrationService(this._storage);

  /// Check if migration has already been completed
  Future<bool> get isMigrationCompleted async {
    try {
      final box = await Hive.openBox('settings');
      return box.get(_migrationKey, defaultValue: false);
    } catch (e) {
      return false;
    }
  }

  /// Mark migration as completed
  Future<void> _markMigrationCompleted() async {
    try {
      final box = await Hive.openBox('settings');
      await box.put(_migrationKey, true);
    } catch (e) {
      debugPrint('Error marking migration as completed: $e');
    }
  }

  /// Perform complete migration from TimeBlocks + MindMap to unified Task system
  Future<MigrationResult> migrate() async {
    if (await isMigrationCompleted) {
      return MigrationResult(
        success: true,
        message: 'Migration already completed',
        tasksUpdated: 0,
        tasksCreated: 0,
        timeBlocksProcessed: 0,
        mindMapNodesRemoved: 0,
      );
    }

    int tasksUpdated = 0;
    int tasksCreated = 0;
    int timeBlocksProcessed = 0;
    int mindMapNodesRemoved = 0;

    try {
      debugPrint('🔄 Starting migration to unified Task system...');

      // Step 1: Migrate TimeBlocks to Task scheduling
      final timeBlocks = _storage.timeBlocksBox.values.toList();
      debugPrint('📦 Found ${timeBlocks.length} time blocks to migrate');

      for (final block in timeBlocks) {
        timeBlocksProcessed++;

        if (block.linkedTaskId != null) {
          // Update existing linked task with scheduling info
          final task = _storage.tasksBox.get(block.linkedTaskId);
          if (task != null) {
            task.scheduledStart = block.startTime;
            task.scheduledEnd = block.endTime;
            task.scheduleColorValue = block.colorValue;
            await task.save();
            tasksUpdated++;
            debugPrint('✅ Updated task "${task.name}" with schedule');
          } else {
            debugPrint('⚠️  Linked task not found for timeblock "${block.title}"');
            // Create new task for orphaned timeblock
            await _createTaskFromTimeBlock(block);
            tasksCreated++;
          }
        } else {
          // Create new Goal task for unlinked timeblock
          await _createTaskFromTimeBlock(block);
          tasksCreated++;
          debugPrint('✅ Created new task from timeblock "${block.title}"');
        }
      }

      // Step 2: Remove MindMap data (feature being removed)
      final mindMapNodes = _storage.mindMapBox.values.toList();
      mindMapNodesRemoved = mindMapNodes.length;
      if (mindMapNodesRemoved > 0) {
        await _storage.mindMapBox.clear();
        debugPrint('🗑️  Removed $mindMapNodesRemoved mind map nodes');
      }

      // Step 3: Clear old TimeBlocks box
      await _storage.timeBlocksBox.clear();
      debugPrint('🗑️  Cleared time blocks box');

      // Mark migration as completed
      await _markMigrationCompleted();

      debugPrint('✨ Migration completed successfully!');
      debugPrint('   - Tasks updated: $tasksUpdated');
      debugPrint('   - Tasks created: $tasksCreated');
      debugPrint('   - Time blocks processed: $timeBlocksProcessed');
      debugPrint('   - Mind map nodes removed: $mindMapNodesRemoved');

      return MigrationResult(
        success: true,
        message: 'Migration completed successfully',
        tasksUpdated: tasksUpdated,
        tasksCreated: tasksCreated,
        timeBlocksProcessed: timeBlocksProcessed,
        mindMapNodesRemoved: mindMapNodesRemoved,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Migration failed: $e');
      debugPrint(stackTrace.toString());
      return MigrationResult(
        success: false,
        message: 'Migration failed: $e',
        tasksUpdated: tasksUpdated,
        tasksCreated: tasksCreated,
        timeBlocksProcessed: timeBlocksProcessed,
        mindMapNodesRemoved: mindMapNodesRemoved,
      );
    }
  }

  /// Create a new Task from a TimeBlock
  Future<Task> _createTaskFromTimeBlock(TimeBlock block) async {
    final task = Task(
      id: _uuid.v4(),
      name: block.title,
      description: block.description ?? 'Migrated from schedule',
      type: TaskType.goal, // Convert all unlinked timeblocks to goals
      category: block.category != null
          ? _parseCategory(block.category!)
          : Category.personal,
      timeEstimate: block.durationMinutes,
      scheduledStart: block.startTime,
      scheduledEnd: block.endTime,
      scheduleColorValue: block.colorValue,
      isCompleted: block.isCompleted,
    );

    await _storage.tasksBox.put(task.id, task);
    return task;
  }

  /// Parse category string to Category enum
  Category _parseCategory(String categoryStr) {
    try {
      return Category.values.firstWhere(
        (c) => c.name.toLowerCase() == categoryStr.toLowerCase(),
        orElse: () => Category.personal,
      );
    } catch (e) {
      return Category.personal;
    }
  }
}

/// Result of migration operation
class MigrationResult {
  final bool success;
  final String message;
  final int tasksUpdated;
  final int tasksCreated;
  final int timeBlocksProcessed;
  final int mindMapNodesRemoved;

  MigrationResult({
    required this.success,
    required this.message,
    required this.tasksUpdated,
    required this.tasksCreated,
    required this.timeBlocksProcessed,
    required this.mindMapNodesRemoved,
  });

  @override
  String toString() {
    return 'MigrationResult('
        'success: $success, '
        'message: $message, '
        'tasksUpdated: $tasksUpdated, '
        'tasksCreated: $tasksCreated, '
        'timeBlocksProcessed: $timeBlocksProcessed, '
        'mindMapNodesRemoved: $mindMapNodesRemoved'
        ')';
  }
}
