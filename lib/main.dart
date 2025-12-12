import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/storage_service.dart';
import 'services/migration_service.dart';
import 'services/notification_service.dart';
import 'providers/task_provider.dart';
import 'providers/project_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/planning_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();

  final storage = StorageService();
  final notificationService = NotificationService();

  // Initialize notification service
  await notificationService.initialize();
  // Request notification permissions
  await notificationService.requestPermissions();

  // Run migration from old TimeBlock/MindMap system to unified Task system
  final migrationService = MigrationService(storage);
  final migrationResult = await migrationService.migrate();

  if (migrationResult.success) {
    debugPrint('✅ Migration completed: ${migrationResult.message}');
  } else {
    debugPrint('⚠️ Migration warning: ${migrationResult.message}');
  }

  // Reset recurring tasks on app start
  final taskProvider = TaskProvider(storage, notificationService);
  await taskProvider.resetRecurringTasks();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = StorageService();
    final notificationService = NotificationService();

    return MultiProvider(
      providers: [
        Provider<StorageService>(create: (_) => storage),
        Provider<NotificationService>(create: (_) => notificationService),
        ChangeNotifierProvider(create: (_) => TaskProvider(storage, notificationService)),
        ChangeNotifierProvider(create: (_) => ProjectProvider(storage)),
        ChangeNotifierProvider(create: (_) => ThemeProvider(storage)),
        ChangeNotifierProvider(create: (_) => PlanningProvider(storage)),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Life Planner',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: themeProvider.seedColor,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: themeProvider.seedColor,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            themeMode: themeProvider.themeMode,
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(themeProvider.textScaleFactor),
                ),
                child: child!,
              );
            },
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
