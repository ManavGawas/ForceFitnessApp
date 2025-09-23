import 'package:flutter/material.dart';
import '../theme.dart';
import 'package:provider/provider.dart';
import '../../services/providers/tab_index_provider.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/logger_tab.dart';
import 'tabs/exercises_tab.dart';
import 'tabs/nutrition_tab.dart';
import 'tabs/profile_tab.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});
  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  final _pages = const [
    DashboardTab(),
    LoggerTab(),
    ExercisesTab(),
    NutritionTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final index = context.watch<TabIndexProvider>().index;
    return Theme(
      data: AppTheme.light(),
      child: Scaffold(
        body: IndexedStack(index: index, children: _pages),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: index,
          onTap: (i) => context.read<TabIndexProvider>().setIndex(i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.fitness_center_rounded), label: 'Log'),
            BottomNavigationBarItem(icon: Icon(Icons.library_books_rounded), label: 'Exercises'),
            BottomNavigationBarItem(icon: Icon(Icons.restaurant_rounded), label: 'Nutrition'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
