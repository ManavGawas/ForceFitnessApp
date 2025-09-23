import 'package:flutter/material.dart';

class ExerciseLibraryScreen extends StatelessWidget {
  const ExerciseLibraryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exercise Library')),
      body: const Center(child: Text('Browse and add exercises.')),
    );
  }
}
