import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/exercise.dart';
import '../../../services/providers/auth_provider.dart';
import '../../../services/repositories.dart';
import '../../widgets/common.dart';
import '../../../services/exercise_seed_service.dart';

class ExercisesTab extends StatefulWidget {
  const ExercisesTab({super.key});
  @override
  State<ExercisesTab> createState() => _ExercisesTabState();
}

class _ExercisesTabState extends State<ExercisesTab> {
  String _query = '';

  Future<void> _addCustomExercise(BuildContext context, String uid) async {
    final nameCtrl = TextEditingController();
    final catCtrl = TextEditingController();
    final primCtrl = TextEditingController();
    final secCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final repo = ExerciseRepository();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Exercise'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
                TextFormField(controller: catCtrl, decoration: const InputDecoration(labelText: 'Category')),
                TextFormField(controller: primCtrl, decoration: const InputDecoration(labelText: 'Primary muscle')),
                TextFormField(controller: secCtrl, decoration: const InputDecoration(labelText: 'Secondary muscles (comma separated)')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final primary = primCtrl.text.trim();
              final category = catCtrl.text.trim();
              final ex = Exercise(
                id: '',
                name: nameCtrl.text.trim(),
                muscleGroup: primary.isNotEmpty ? primary : (category.isNotEmpty ? category : 'general'),
                category: category.isEmpty ? null : category,
                primaryMuscle: primary.isEmpty ? null : primary,
                secondaryMuscles: secCtrl.text.trim().isEmpty ? null : secCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                isCustom: true,
              );
              await repo.add(uid, ex);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider?>()?.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Exercises')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search exercises',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: uid == null
                ? const EmptyState('Sign-in required to load exercises')
                : StreamBuilder<List<Exercise>>(
                    stream: ExerciseRepository().streamAll(uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if ((snapshot.data ?? []).isEmpty) {
                        // Offer one-click import
                        return Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            const EmptyState('No exercises yet'),
                            const SizedBox(height: 8),
                            FilledButton.icon(
                              onPressed: () async {
                                if (uid == null) return;
                                await ExerciseSeedService.seedIfEmpty(uid);
                              },
                              icon: const Icon(Icons.cloud_download_rounded),
                              label: const Text('Import default exercises'),
                            )
                          ]),
                        );
                      }
                      final items = (snapshot.data ?? [])
                          .where((e) => _query.isEmpty || e.name.toLowerCase().contains(_query) || (e.category ?? '').toLowerCase().contains(_query))
                          .toList();
                      if (items.isEmpty) return const EmptyState('No exercises found');
                      return ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final e = items[index];
                          return ListTile(
                            leading: const Icon(Icons.fitness_center),
                            title: Text(e.name),
                            subtitle: Text([e.category, e.primaryMuscle].whereType<String>().where((s) => s.isNotEmpty).join(' • ')),
                            trailing: e.isCustom == true ? const Icon(Icons.edit, size: 18) : null,
                          );
                        },
                      );
                    },
                  ),
          ),
        ]),
      ),
      floatingActionButton: uid == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _addCustomExercise(context, uid),
              label: const Text('Add Custom'),
              icon: const Icon(Icons.add),
            ),
    );
  }
}
