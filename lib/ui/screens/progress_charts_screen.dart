import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/pr.dart';
import '../../models/exercise.dart';
import '../../services/repositories.dart';
import '../../services/providers/auth_provider.dart' as local_auth;
import '../widgets/common.dart';
import '../widgets/branded_scaffold.dart';

class ProgressChartsScreen extends StatefulWidget {
  const ProgressChartsScreen({super.key});
  @override
  State<ProgressChartsScreen> createState() => _ProgressChartsScreenState();
}

class _ProgressChartsScreenState extends State<ProgressChartsScreen> {
  Exercise? selected;
  @override
  Widget build(BuildContext context) {
    final uid = context.watch<local_auth.AuthProvider?>()?.uid;
    return BrandedScaffold(
      appBar: AppBar(title: const Text('Progress Charts')),
      body: uid == null
            ? const EmptyState('Sign-in required')
            : Column(children: [
                SizedBox(
                  height: 56,
                  child: StreamBuilder<List<Exercise>>(
                    stream: ExerciseRepository().streamAll(uid),
                    builder: (context, snap) {
                      final items = snap.data ?? [];
                      if (items.isEmpty) return const Center(child: Text('Add exercises first'));
                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final e = items[i];
                          final isSel = selected?.id == e.id && selected?.name == e.name;
                          return ChoiceChip(
                            label: Text(e.name),
                            selected: isSel,
                            onSelected: (_) => setState(() => selected = e),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: selected == null
                      ? const EmptyState('Pick an exercise')
                      : StreamBuilder<List<PRRecord>>(
                          stream: PRRepository().all(uid),
                          builder: (context, snap) {
                            final all = (snap.data ?? []).where((p) => p.exerciseId == selected!.id || p.exerciseName == selected!.name).toList()
                              ..sort((a, b) => a.date.compareTo(b.date));
                            if (all.isEmpty) return const EmptyState('No PRs for this exercise');
                            final points = <FlSpot>[];
                            for (var i = 0; i < all.length; i++) {
                              points.add(FlSpot(i.toDouble(), all[i].weight));
                            }
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: LineChart(
                                  LineChartData(
                                    titlesData: const FlTitlesData(show: false),
                                    gridData: const FlGridData(show: false),
                                    borderData: FlBorderData(show: true, border: const Border.fromBorderSide(BorderSide(color: Colors.white12))),
                                    lineBarsData: [
                                      LineChartBarData(
                                        isCurved: true,
                                        color: Theme.of(context).colorScheme.primary,
                                        barWidth: 3,
                                        dotData: FlDotData(show: true),
                                        spots: points,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ]),
    );
  }
}
