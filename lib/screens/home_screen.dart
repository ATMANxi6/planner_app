import 'package:flutter/material.dart';
import 'plan_screen.dart';
import 'schedule_screen.dart';
import 'dashboard_screen.dart';
import 'settings_screen.dart';
import 'planning_canvas_screen.dart';

/// Main app screen with 5-tab navigation: Tasks, Canvas, Schedule, Dashboard, Settings
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    PlanScreen(),              // Tab 1: Task list by type
    PlanningCanvasScreen(),    // Tab 2: Visual flow planning
    ScheduleScreen(),          // Tab 3: Schedule calendar
    DashboardScreen(),         // Tab 4: Dashboard with customizable widgets
    SettingsScreen(),          // Tab 5: Settings & preferences
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.task_outlined),
            selectedIcon: Icon(Icons.task),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_tree_outlined),
            selectedIcon: Icon(Icons.account_tree),
            label: 'Canvas',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
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
