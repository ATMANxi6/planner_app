import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../providers/theme_provider.dart';
import '../services/storage_service.dart';
import '../models/dashboard_config.dart';
import '../models/theme_settings.dart' as model;

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: false,
        backgroundColor: colorScheme.surface,
      ),
      body: ListView(
        children: [
          // App Information Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Life Planner',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),

          // Appearance Section
          _buildAppearanceSection(context),

          const Divider(),

          // Time Blocking Section
          _buildTimeBlockingSection(context, theme, colorScheme),

          const Divider(),

          // Dashboard Widgets Section
          _buildDashboardWidgetsSection(context, theme, colorScheme),

          const Divider(),

          // Data Management Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Data Management',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: colorScheme.error),
            title: Text('Clear All Data', style: TextStyle(color: colorScheme.error)),
            subtitle: const Text('Delete all tasks'),
            onTap: () => _confirmClearAllData(context),
          ),

          const Divider(),

          // About Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'About',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.info_outlined, color: colorScheme.primary),
            title: const Text('About Life Planner'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAboutDialog(context),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _confirmClearAllData(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all your tasks, practices, and goals. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              final taskProvider = context.read<TaskProvider>();

              // Clear all tasks
              final allTasks = taskProvider.allTasks.toList();
              for (var task in allTasks) {
                taskProvider.deleteTask(task.id);
              }

              Navigator.pop(ctx);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All data cleared'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('About Life Planner'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Life Planner',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              SizedBox(height: 8),
              Text('Version 1.0.0'),
              SizedBox(height: 16),
              Text(
                'A comprehensive planning app that helps you:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              Text('• Avoid distractions'),
              Text('• Build daily practices'),
              Text('• Achieve your goals'),
              Text('• Schedule and block time'),
              Text('• Track progress with visualizations'),
              SizedBox(height: 16),
              Text(
                'Built with Flutter',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTimeSlotIntervalDialog(BuildContext context, DashboardConfig config) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Time Slot Interval'),
        content: RadioGroup<TimeSlotInterval>(
          groupValue: config.timeSlotInterval,
          onChanged: (value) {
            if (value != null) {
              config.update(timeSlotInterval: value);
              Navigator.pop(ctx);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: TimeSlotInterval.values.map((interval) {
              return RadioListTile<TimeSlotInterval>(
                title: Text(interval.displayName),
                value: interval,
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showWorkingHoursDialog(BuildContext context, DashboardConfig config) {
    int startHour = config.dayStartHour;
    int endHour = config.dayEndHour;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Working Hours'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Start Hour'),
                subtitle: Text(_formatHour(startHour)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: startHour > 0
                          ? () => setState(() => startHour--)
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: startHour < endHour - 1
                          ? () => setState(() => startHour++)
                          : null,
                    ),
                  ],
                ),
              ),
              ListTile(
                title: const Text('End Hour'),
                subtitle: Text(_formatHour(endHour)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: endHour > startHour + 1
                          ? () => setState(() => endHour--)
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: endHour < 24
                          ? () => setState(() => endHour++)
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                config.update(
                  dayStartHour: startHour,
                  dayEndHour: endHour,
                );
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }

  Widget _buildDashboardWidgetsSection(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    final storage = Provider.of<StorageService>(context, listen: false);

    // Get or create dashboard config
    DashboardConfig config;
    if (storage.dashboardConfigBox.isEmpty) {
      config = DashboardConfig.defaultConfig();
      storage.dashboardConfigBox.put('config', config);
    } else {
      config = storage.dashboardConfigBox.get('config') ?? DashboardConfig.defaultConfig();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Dashboard Widgets',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SwitchListTile(
          secondary: Icon(Icons.center_focus_strong, color: colorScheme.primary),
          title: const Text('Focus Mode Widget'),
          subtitle: const Text('Show current/next time block'),
          value: config.showFocusModeWidget,
          onChanged: (value) {
            config.update(showFocusModeWidget: value);
          },
        ),
        SwitchListTile(
          secondary: Icon(Icons.bolt, color: Colors.amber[700]),
          title: const Text('Quick Wins Widget'),
          subtitle: const Text('Show easiest tasks for momentum'),
          value: config.showQuickWinsWidget,
          onChanged: (value) {
            config.update(showQuickWinsWidget: value);
          },
        ),
        SwitchListTile(
          secondary: Icon(Icons.task_alt, color: colorScheme.primary),
          title: const Text('Daily Tasks Widget'),
          subtitle: const Text('Show tasks for today'),
          value: config.showDailyTasksWidget,
          onChanged: (value) {
            config.update(showDailyTasksWidget: value);
          },
        ),
        SwitchListTile(
          secondary: Icon(Icons.track_changes, color: colorScheme.primary),
          title: const Text('Goal Progress Widget'),
          subtitle: const Text('Show goals with supporting practices'),
          value: config.showGoalProgressWidget,
          onChanged: (value) {
            config.update(showGoalProgressWidget: value);
          },
        ),
        SwitchListTile(
          secondary: Icon(Icons.bar_chart, color: colorScheme.primary),
          title: const Text('Stats Widget'),
          subtitle: const Text('Show completion statistics'),
          value: config.showStatsWidget,
          onChanged: (value) {
            config.update(showStatsWidget: value);
          },
        ),
        SwitchListTile(
          secondary: Icon(Icons.local_fire_department, color: colorScheme.primary),
          title: const Text('Streaks Widget'),
          subtitle: const Text('Show active habit streaks'),
          value: config.showStreaksWidget,
          onChanged: (value) {
            config.update(showStreaksWidget: value);
          },
        ),
        SwitchListTile(
          secondary: Icon(Icons.folder, color: colorScheme.primary),
          title: const Text('Projects Widget'),
          subtitle: const Text('Show project summaries'),
          value: config.showProjectsWidget,
          onChanged: (value) {
            config.update(showProjectsWidget: value);
          },
        ),
        SwitchListTile(
          secondary: Icon(Icons.event, color: colorScheme.primary),
          title: const Text('Deadlines Widget'),
          subtitle: const Text('Show upcoming task deadlines'),
          value: config.showDeadlinesWidget,
          onChanged: (value) {
            config.update(showDeadlinesWidget: value);
          },
        ),
      ],
    );
  }

  Widget _buildTimeBlockingSection(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    final storage = Provider.of<StorageService>(context, listen: false);

    // Get or create dashboard config
    DashboardConfig config;
    if (storage.dashboardConfigBox.isEmpty) {
      config = DashboardConfig.defaultConfig();
      storage.dashboardConfigBox.put('config', config);
    } else {
      config = storage.dashboardConfigBox.get('config') ?? DashboardConfig.defaultConfig();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Time Blocking',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListTile(
          leading: Icon(Icons.schedule, color: colorScheme.primary),
          title: const Text('Time Slot Interval'),
          subtitle: Text(config.timeSlotInterval.displayName),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showTimeSlotIntervalDialog(context, config),
        ),
        ListTile(
          leading: Icon(Icons.access_time, color: colorScheme.primary),
          title: const Text('Working Hours'),
          subtitle: Text('${_formatHour(config.dayStartHour)} - ${_formatHour(config.dayEndHour)}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showWorkingHoursDialog(context, config),
        ),
      ],
    );
  }

  Widget _buildAppearanceSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Appearance',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Theme Mode Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.brightness_6, color: colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Theme Mode',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<model.ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: model.ThemeMode.light,
                            label: Text('Light'),
                            icon: Icon(Icons.light_mode, size: 16),
                          ),
                          ButtonSegment(
                            value: model.ThemeMode.dark,
                            label: Text('Dark'),
                            icon: Icon(Icons.dark_mode, size: 16),
                          ),
                          ButtonSegment(
                            value: model.ThemeMode.system,
                            label: Text('Auto'),
                            icon: Icon(Icons.settings_brightness, size: 16),
                          ),
                        ],
                        selected: {themeProvider.settings.themeMode},
                        onSelectionChanged: (Set<model.ThemeMode> newSelection) {
                          themeProvider.setThemeMode(newSelection.first);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Accent Color Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.palette, color: colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Accent Color',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: ThemeProvider.colorOptions.map((option) {
                          final isSelected = themeProvider.seedColor.toARGB32() == option.color.toARGB32();
                          return _buildColorChip(
                            context,
                            option,
                            isSelected,
                            () => themeProvider.setSeedColor(option.color),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Font Size Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.text_fields, color: colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Font Size',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<model.FontSizePreference>(
                        segments: const [
                          ButtonSegment(
                            value: model.FontSizePreference.small,
                            label: Text('Small'),
                          ),
                          ButtonSegment(
                            value: model.FontSizePreference.medium,
                            label: Text('Medium'),
                          ),
                          ButtonSegment(
                            value: model.FontSizePreference.large,
                            label: Text('Large'),
                          ),
                        ],
                        selected: {themeProvider.fontSizePreference},
                        onSelectionChanged: (Set<model.FontSizePreference> newSelection) {
                          themeProvider.setFontSizePreference(newSelection.first);
                        },
                      ),
                      const SizedBox(height: 12),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: 14 * themeProvider.textScaleFactor,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        child: const Text('Preview: This is how text will appear'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildColorChip(
    BuildContext context,
    ColorOption option,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Semantics(
      label: '${option.name} color',
      selected: isSelected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: option.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.transparent,
              width: 3,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: option.color.withValues(alpha: 0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: isSelected
              ? const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 28,
                )
              : null,
        ),
      ),
    );
  }
}
