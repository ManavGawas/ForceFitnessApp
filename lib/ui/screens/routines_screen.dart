import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/routine.dart';
import '../../services/repositories.dart';
import '../../services/providers/auth_provider.dart';
import '../widgets/branded_scaffold.dart';
import '../../services/providers/pending_workout_provider.dart';
import '../../services/providers/tab_index_provider.dart';
import '../../services/routines_seed_service.dart';
import 'routine_editor_screen.dart';

class RoutinesScreen extends StatelessWidget {
  const RoutinesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider?>()?.uid;
    return BrandedScaffold(
      appBar: AppBar(title: const Text('Routines')),
      floatingActionButton: uid == null ? null : FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RoutineEditorScreen()));
        },
        icon: const Icon(Icons.add),
        label: const Text('New routine'),
      ),
      body: uid == null
          ? const Center(child: Text('Sign in to manage routines'))
          : StreamBuilder<List<Routine>>(
              stream: RoutinesRepository().all(uid),
              builder: (context, snap) {
                final items = snap.data ?? [];
                if (items.isEmpty) {
                  return Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('No routines yet'),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: () async {
                          await RoutinesSeedService.seedCurated(uid);
                        },
                        child: const Text('Import curated routines'),
                      )
                    ]),
                  );
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final r = items[i];
                    return ListTile(
                      title: Text(r.name),
                      subtitle: Text('${r.exercises.length} exercises'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'duplicate') {
                            final copy = Routine(id: '${r.id}_copy', name: '${r.name} (copy)', exercises: r.exercises);
                            await RoutinesRepository().upsert(uid, copy);
                          } else if (v == 'edit') {
                            // Navigate to editor with existing routine
                            // ignore: use_build_context_synchronously
                            await Navigator.of(context).push(MaterialPageRoute(builder: (_) => RoutineEditorScreen(existing: r)));
                          } else if (v == 'delete') {
                            await RoutinesRepository().delete(uid, r.id);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                      onTap: () {
                        // Start in Logger via pending specs
                        final specs = r.exercises.map((e) => PendingExerciseSpec(
                          name: e.name,
                          sets: e.sets.map((s) => PendingSetSpec(kg: (s['kg'] as num?)?.toDouble(), reps: (s['reps'] as num?)?.toInt() ?? 0)).toList(),
                        )).toList();
                        context.read<PendingWorkoutProvider>().setPending(specs);
                        context.read<TabIndexProvider>().setIndex(1);
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}