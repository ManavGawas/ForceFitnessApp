import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/branded_scaffold.dart';
import '../widgets/workout_card.dart';
import '../../services/providers/tab_index_provider.dart';

class WorkoutsCatalogScreen extends StatefulWidget {
  const WorkoutsCatalogScreen({super.key});
  @override
  State<WorkoutsCatalogScreen> createState() => _WorkoutsCatalogScreenState();
}

class _WorkoutsCatalogScreenState extends State<WorkoutsCatalogScreen> {
  String level = 'All';
  String category = 'All';
  String q = '';

  // no-op: items are defined inline in build for now

  @override
  Widget build(BuildContext context) {
    // Extract the items by creating a temporary carousel and accessing its list would be messy.
    // For simplicity, redefine the same items here (keep in sync with dashboard).
    final items = [
      WorkoutPreset('Shoulder Flex Stability','images/1.jpeg','Intermediate',45, 'Shoulders', steps: const ['Warm-up: band external rotations 2x15','Overhead press 4x8','Lateral raises 3x12','Face pulls 3x15']),
      WorkoutPreset('Leg Poses','images/4.jpeg','Beginner',50, 'Legs', steps: const ['Bodyweight squats 3x12','Lunges 3x10/leg','Calf raises 3x15']),
      WorkoutPreset('Core Blast','images/5.jpeg','Intermediate',30, 'Core', steps: const ['Plank 3x45s','Hanging knee raises 3x12','Cable crunch 3x15']),
      WorkoutPreset('Chest Power','images/10.jpeg','Advanced',55, 'Chest', steps: const ['Bench press 5x5','Incline dumbbell press 3x10','Cable fly 3x12']),
      WorkoutPreset('Back Strength','images/7.jpeg','Intermediate',60, 'Back', steps: const ['Deadlift 5x3','Lat pulldown 4x10','Seated row 3x12']),
      WorkoutPreset('Arm Finisher','images/6.jpeg','Intermediate',25, 'Arms', steps: const ['Barbell curls 4x10','Rope pushdowns 4x12','Hammer curls 3x12']),
      WorkoutPreset('Full Body Ignite','images/2.jpeg','Beginner',40, 'Full Body', steps: const ['Goblet squat 3x12','Push-ups 3x12','Row machine 10 min']),
      WorkoutPreset('Pull Day','images/edgar-chaparro-sHfo3WOgGTU-unsplash.jpg','Intermediate',50, 'Back', steps: const ['Pull-ups 4xAMRAP','Barbell row 4x8','Rear delt fly 3x15']),
      WorkoutPreset('Push Day','images/brett-jordan-U2q73PfHFpM-unsplash.jpg','Intermediate',50, 'Chest', steps: const ['Bench press 4x8','OHP 4x8','Tricep dips 3x12']),
      WorkoutPreset('Arms & Abs','images/aaron-brogden-miCR9VIQ5PE-unsplash.jpg','Beginner',35, 'Arms', steps: const ['EZ curls 3x12','Overhead tricep ext 3x12','Planks 3x60s']),
    ];

    final filtered = items.where((e) {
      final levelOk = level == 'All' || e.tag == level;
      final catOk = category == 'All' || e.category == category;
      final qOk = q.isEmpty || e.title.toLowerCase().contains(q) || e.category.toLowerCase().contains(q);
      return levelOk && catOk && qOk;
    }).toList();

    return BrandedScaffold(
      appBar: AppBar(title: const Text('All Workouts')),
      body: Column(children: [
        TextField(
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search workouts'),
          onChanged: (v) => setState(() => q = v.trim().toLowerCase()),
        ),
        const SizedBox(height: 8),
        Row(children: [
          DropdownButton<String>(
            value: level,
            items: const [DropdownMenuItem(value: 'All', child: Text('All Levels')), DropdownMenuItem(value: 'Beginner', child: Text('Beginner')), DropdownMenuItem(value: 'Intermediate', child: Text('Intermediate')), DropdownMenuItem(value: 'Advanced', child: Text('Advanced'))],
            onChanged: (v) => setState(() => level = v ?? 'All'),
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: category,
            items: const [
              DropdownMenuItem(value: 'All', child: Text('All Categories')),
              DropdownMenuItem(value: 'Chest', child: Text('Chest')),
              DropdownMenuItem(value: 'Back', child: Text('Back')),
              DropdownMenuItem(value: 'Arms', child: Text('Arms')),
              DropdownMenuItem(value: 'Core', child: Text('Core')),
              DropdownMenuItem(value: 'Legs', child: Text('Legs')),
              DropdownMenuItem(value: 'Shoulders', child: Text('Shoulders')),
              DropdownMenuItem(value: 'Full Body', child: Text('Full Body')),
            ],
            onChanged: (v) => setState(() => category = v ?? 'All'),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => context.read<TabIndexProvider>().setIndex(1),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Open Logger'),
          ),
        ]),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 280/210),
            itemCount: filtered.length,
            itemBuilder: (_, i) => WorkoutCard(item: filtered[i], onTap: () {
              // Open details by reusing dashboard card flow
              showModalBottomSheet(
                context: context,
                showDragHandle: true,
                builder: (_) => _WorkoutPreview(item: filtered[i]),
              );
            }),
          ),
        )
      ]),
    );
  }
}

// Lightweight preview when opening from catalog grid
class _WorkoutPreview extends StatelessWidget {
  final WorkoutPreset item;
  const _WorkoutPreview({required this.item});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item.title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text('${item.tag} • ${item.category} • ${item.minutes} min'),
        const SizedBox(height: 8),
        ...item.steps.take(4).map((s) => ListTile(leading: const Icon(Icons.check), title: Text(s))),
        const SizedBox(height: 8),
        FilledButton.icon(onPressed: () {
          Navigator.of(context).pop();
          // Navigate back to dashboard or logger as desired
          context.read<TabIndexProvider>().setIndex(1);
        }, icon: const Icon(Icons.play_arrow_rounded), label: const Text('Start in Logger'))
      ]),
    );
  }
}
