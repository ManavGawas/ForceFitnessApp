import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../services/repositories.dart';
import '../../models/workout.dart';
import '../../models/body_measurement.dart';
import '../../models/progress_photo.dart';
import '../../services/providers/auth_provider.dart';
import '../widgets/common.dart';
import '../widgets/branded_scaffold.dart';

class ProgressHubScreen extends StatelessWidget {
  const ProgressHubScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider?>()?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('Sign-in required')));
    final monthStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
    return BrandedScaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: ListView(
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
                    final weight = TextEditingController();
                    final chest = TextEditingController();
                    final waist = TextEditingController();
                    final hips = TextEditingController();
                    final arm = TextEditingController();
                    final thigh = TextEditingController();
                    final m = await showDialog<BodyMeasurement?>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Add Measurements'),
                        content: SizedBox(
                          width: 380,
                          child: SingleChildScrollView(
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              TextField(controller: weight, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Weight (kg)')),
                              Row(children: [
                                Expanded(child: TextField(controller: chest, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Chest (cm)'))),
                                const SizedBox(width: 8),
                                Expanded(child: TextField(controller: waist, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Waist (cm)'))),
                              ]),
                              Row(children: [
                                Expanded(child: TextField(controller: hips, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Hips (cm)'))),
                                const SizedBox(width: 8),
                                Expanded(child: TextField(controller: arm, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Arm (cm)'))),
                              ]),
                              TextField(controller: thigh, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Thigh (cm)')),
                            ]),
                          ),
                        ),
                        actions: [
                          TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text('Cancel')),
                          FilledButton(onPressed: ()=>Navigator.pop(ctx, BodyMeasurement(
                            id: '',
                            date: DateTime.now(),
                            weightKg: double.tryParse(weight.text) ?? 0,
                            chest: double.tryParse(chest.text),
                            waist: double.tryParse(waist.text),
                            hips: double.tryParse(hips.text),
                            arm: double.tryParse(arm.text),
                            thigh: double.tryParse(thigh.text),
                          )), child: const Text('Save'))
                        ],
                      ),
                    );
                    if (m != null) {
                      await BodyMeasurementsRepository().add(uid, m);
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
                      child: Image.network(list[i].storagePath, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported)),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              icon: const Icon(Icons.add_a_photo_rounded),
              label: const Text('Add Photo'),
              onPressed: () async {
                final picker = ImagePicker();
                final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1600);
                if (picked == null) return;
                final name = 'photos/${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
                final ref = FirebaseStorage.instance.ref().child('users').child(uid).child(name);
                await ref.putData(await picked.readAsBytes());
                final url = await ref.getDownloadURL();
                await ProgressPhotosRepository().add(uid, ProgressPhoto(id: '', date: DateTime.now(), storagePath: url));
              },
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
