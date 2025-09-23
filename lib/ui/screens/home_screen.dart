import 'package:flutter/material.dart';
import '../app_routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _Nav('Calendar', Icons.calendar_today, AppRoutes.calendar),
      _Nav('Planner', Icons.edit_calendar, AppRoutes.workoutPlanner),
      _Nav('Logger', Icons.fitness_center, AppRoutes.sessionLogger),
      _Nav('Exercises', Icons.library_books, AppRoutes.exerciseLibrary),
      _Nav('PRs', Icons.military_tech, AppRoutes.prTracker),
      _Nav('Nutrition', Icons.restaurant, AppRoutes.nutritionLog),
      _Nav('Progress', Icons.show_chart, AppRoutes.progressCharts),
      _Nav('Progress Hub', Icons.insights, AppRoutes.progressHub),
      _Nav('Social', Icons.group, '/social'),
      _Nav('Settings', Icons.settings, AppRoutes.settings),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('GymMate')),
      body: Stack(children: [
        Positioned.fill(child: Opacity(opacity: 0.15, child: Image.asset('images/3.webp', fit: BoxFit.cover))),
        GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(12),
        children: [
          for (final c in cards)
            Card(
              child: InkWell(
                onTap: () => Navigator.pushNamed(context, c.route),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(c.icon, size: 36),
                      const SizedBox(height: 8),
                      Text(c.label),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      ]),
    );
  }
}

class _Nav {
  final String label;
  final IconData icon;
  final String route;
  _Nav(this.label, this.icon, this.route);
}
