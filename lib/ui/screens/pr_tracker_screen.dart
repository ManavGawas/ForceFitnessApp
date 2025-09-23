import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/pr.dart';
import '../../models/exercise.dart';
import '../../services/repositories.dart';
import '../../services/providers/auth_provider.dart' as local_auth;
import '../widgets/common.dart';
import 'package:share_plus/share_plus.dart';

class PRTrackerScreen extends StatelessWidget {
  const PRTrackerScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = context.watch<local_auth.AuthProvider?>()?.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('PR Tracker')),
      body: uid == null
          ? const EmptyState('Sign-in required')
          : StreamBuilder<List<PRRecord>>(
              stream: PRRepository().all(uid),
              builder: (context, snapshot) {
                final items = snapshot.data ?? [];
                if (items.isEmpty) return const EmptyState('No PRs yet');
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final pr = items[i];
                    return ListTile(
                      leading: const Icon(Icons.military_tech_rounded),
                      title: Text(pr.exerciseName),
                      subtitle: Text('${pr.weight.toStringAsFixed(1)} × ${pr.reps}  •  ${pr.date.toLocal().toString().split(' ').first}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.share_rounded),
                        onPressed: () {
                          final msg = 'New PR: ${pr.exerciseName} — ${pr.weight.toStringAsFixed(1)}kg x ${pr.reps} on ${pr.date.toLocal().toString().split(' ').first} #ForceFitness';
                          Share.share(msg);
                        },
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: uid == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showAddDialog(context, uid),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add PR'),
            ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, String uid) async {
    final formKey = GlobalKey<FormState>();
    final weight = TextEditingController();
    final reps = TextEditingController(text: '1');
    DateTime date = DateTime.now();
    Exercise? selected;
    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: const Text('Add PR'),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 420,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(
                  height: 160,
                  child: StreamBuilder<List<Exercise>>(
                    stream: ExerciseRepository().streamAll(uid),
                    builder: (context, snap) {
                      final items = snap.data ?? [];
                      if (items.isEmpty) return const Center(child: Text('Add exercises first'));
                      return ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final e = items[i];
                          final isSel = selected?.id == e.id && selected?.name == e.name;
                          return ListTile(
                            dense: true,
                            selected: isSel,
                            leading: const Icon(Icons.fitness_center_rounded),
                            title: Text(e.name),
                            subtitle: Text(e.muscleGroup),
                            onTap: () => setState(() => selected = e),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: TextFormField(controller: weight, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Weight'), validator: (v) => v==null||v.isEmpty ? 'Required' : null)),
                  const SizedBox(width: 8),
                  Expanded(child: TextFormField(controller: reps, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Reps'))),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Text('Date:  ${date.toLocal().toString().split(' ').first}'),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (picked != null) setState(() => date = picked);
                    },
                    child: const Text('Pick date'),
                  ),
                ])
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (selected == null) return;
                if (!formKey.currentState!.validate()) return;
                final rec = PRRecord(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  exerciseId: selected!.id,
                  exerciseName: selected!.name,
                  date: date,
                  weight: double.tryParse(weight.text) ?? 0,
                  reps: int.tryParse(reps.text) ?? 1,
                );
                await PRRepository().add(uid, rec);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            )
          ],
        );
      }),
    );
  }
}
