import 'package:flutter/material.dart';

class SessionLoggerScreen extends StatelessWidget {
  const SessionLoggerScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Session Logger')),
      body: const Center(child: Text('Log sets, reps, weight.')),
    );
  }
}
