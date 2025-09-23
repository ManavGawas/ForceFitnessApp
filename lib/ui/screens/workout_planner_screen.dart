import 'package:flutter/material.dart';

class WorkoutPlannerScreen extends StatelessWidget {
  const WorkoutPlannerScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workout Planner')),
      body: const Center(child: Text('Plan your workouts here.')),
    );
  }
}
