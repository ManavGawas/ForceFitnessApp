import 'package:flutter/material.dart';

class NutritionLogScreen extends StatelessWidget {
  const NutritionLogScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nutrition Log')),
      body: const Center(child: Text('Track calories and macros.')),
    );
  }
}
