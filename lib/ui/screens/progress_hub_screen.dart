import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/repositories.dart';
import '../../models/workout.dart';
import '../../models/body_measurement.dart';
import '../../models/progress_photo.dart';
import '../../services/providers/auth_provider.dart';
import '../widgets/common.dart';

class ProgressHubScreen extends StatelessWidget {
  const ProgressHubScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider?>()?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('Sign-in required')));
    final monthStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          SectionCard(
            title: 'Monthly Report',
            child: StreamBuilder<List<WorkoutSession>>(
              stream: WorkoutRepository().byMonth(uid, monthStart),
              builder: (context, snap) {
                final sessions = snap.data ?? const [];
                final days = <int,int>{};
                for (final s in sessions) {
                  days[s.date.day] = (days[s.date.day] ?? 0) + 1;
                }
                final totalSets = sessions.fold<int>(0, (t, s) => t + s.entries.fold<int>(0, (tt, e) => tt + e.sets.length));
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Workouts: ${sessions.length}  ·  Sets: $totalSets'),
                  const SizedBox(height: 8),
                  SizedBox(height: 120, child: BarChart(BarChartData(
                    titlesData: const FlTitlesData(show: false),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: [
                      for (int i = 1; i <= DateTime.now().day; i++)
                        BarChartGroupData(x: i, barRods: [BarChartRodData(toY: (days[i] ?? 0).toDouble())])
                    ],
                  )))
                ]);
              },
            ),
          ),
          const SizedBox(height: 8),
          SectionCard(
            title: 'Workout Streak',
            child: FutureBuilder<int>(
              future: WorkoutRepository().currentStreak(uid),
              builder: (context, snap) => Text('Current streak: ${snap.data ?? 0} days'),
            ),
          ),
          const SizedBox(height: 8),
          SectionCard(
            title: 'Body Measurements',
            child: Column(children: [
              SizedBox(
                height: 160,
                child: StreamBuilder<List<BodyMeasurement>>(
                  stream: BodyMeasurementsRepository().all(uid),
                  builder: (context, snap) {
                    final list = snap.data ?? const [];
                    if (list.isEmpty) return const EmptyState('No measurements yet');
                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => Container(
                        width: 180,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF202020),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(list[i].date.toIso8601String().substring(0,10)),
                          const SizedBox(height: 8),
                          Text('Weight: ${list[i].weightKg.toStringAsFixed(1)} kg'),
                          if (list[i].waist != null) Text('Waist: ${list[i].waist} cm'),
                          if (list[i].chest != null) Text('Chest: ${list[i].chest} cm'),
                        ]),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () async {
                    final c = TextEditingController();
                    final d = await showDialog<double?>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Add weight (kg)'),
                        content: TextField(controller: c, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                        actions: [TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text('Cancel')), FilledButton(onPressed: ()=>Navigator.pop(ctx, double.tryParse(c.text)), child: const Text('Save'))],
                      ),
                    );
                    if (d != null) {
                      await BodyMeasurementsRepository().add(uid, BodyMeasurement(id: '', date: DateTime.now(), weightKg: d));
                    }
                  },
                  icon: const Icon(Icons.add), label: const Text('Add Measurement'),
                ),
              )
            ]),
          ),
          const SizedBox(height: 8),
          SectionCard(
            title: 'Progress Photos',
            child: SizedBox(
              height: 160,
              child: StreamBuilder<List<ProgressPhoto>>(
                stream: ProgressPhotosRepository().all(uid),
                builder: (context, snap) {
                  final list = snap.data ?? const [];
                  if (list.isEmpty) return const EmptyState('No photos yet');
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset('images/1.jpeg', fit: BoxFit.cover), // placeholder thumbnail
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          SectionCard(
            title: 'Muscle Distribution (WIP)',
            child: SizedBox(
              height: 140,
              child: PieChart(PieChartData(sections: [
                PieChartSectionData(value: 30, color: Colors.orange, title: 'Chest'),
                PieChartSectionData(value: 25, color: Colors.blueGrey, title: 'Back'),
                PieChartSectionData(value: 20, color: Colors.green, title: 'Legs'),
                PieChartSectionData(value: 15, color: Colors.purple, title: 'Arms'),
                PieChartSectionData(value: 10, color: Colors.teal, title: 'Other'),
              ], sectionsSpace: 0, centerSpaceRadius: 30)),
            ),
          ),
        ],
      ),
    );
  }
}
