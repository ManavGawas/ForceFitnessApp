import 'package:flutter/widgets.dart';
import 'screens/screens.dart';
import 'screens/progress_hub_screen.dart';

class AppRoutes {
  static const welcome = '/';
  static const home = '/home';
  static const calendar = '/calendar';
  static const workoutPlanner = '/planner';
  static const sessionLogger = '/logger';
  static const exerciseLibrary = '/exercises';
  static const prTracker = '/prs';
  static const nutritionLog = '/nutrition';
  static const progressCharts = '/progress';
  static const progressHub = '/progress-hub';
  static const settings = '/settings';
}

Map<String, WidgetBuilder> buildRoutes() => {
      AppRoutes.welcome: (_) => const WelcomeScreen(),
      AppRoutes.home: (_) => const HomeScreen(),
      AppRoutes.calendar: (_) => const CalendarScreen(),
      AppRoutes.workoutPlanner: (_) => const WorkoutPlannerScreen(),
      AppRoutes.sessionLogger: (_) => const SessionLoggerScreen(),
      AppRoutes.exerciseLibrary: (_) => const ExerciseLibraryScreen(),
  AppRoutes.prTracker: (_) => const PRTrackerScreen(),
      AppRoutes.nutritionLog: (_) => const NutritionLogScreen(),
      AppRoutes.progressCharts: (_) => const ProgressChartsScreen(),
      AppRoutes.progressHub: (_) => const ProgressHubScreen(),
      AppRoutes.settings: (_) => const SettingsScreen(),
    };
