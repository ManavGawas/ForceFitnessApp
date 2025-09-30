import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/exercise.dart';
import '../../../services/providers/auth_provider.dart';
import '../../../services/repositories.dart';
import '../../widgets/common.dart';
import '../../../services/exercise_seed_service.dart';
import '../../widgets/branded_scaffold.dart';
import '../tutorial_viewer_screen.dart';
import '../../../models/tutorial.dart';

class ExercisesTab extends StatefulWidget {
  const ExercisesTab({super.key});
  @override
  State<ExercisesTab> createState() => _ExercisesTabState();
}

class _ExercisesTabState extends State<ExercisesTab> {
  String _query = '';
  String _filter = 'All';

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
    return BrandedScaffold(
      appBar: AppBar(title: const Text('Exercises')),
      body: Column(children: [
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
                    final all = snapshot.data ?? [];
                    if (all.isEmpty) {
                      return Center(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const EmptyState('No exercises yet'),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            onPressed: () async {
                              await ExerciseSeedService.seedIfEmpty(uid);
                            },
                            icon: const Icon(Icons.cloud_download_rounded),
                            label: const Text('Import default exercises'),
                          )
                        ]),
                      );
                    }
                    final cats = <String>{
                      for (final e in all) (e.category ?? e.muscleGroup).trim(),
                    }..removeWhere((s) => s.isEmpty);
                    final catList = ['All', ...cats.toList()..sort()];
                    final filtered = all
                        .where((e) => _query.isEmpty || e.name.toLowerCase().contains(_query) || (e.category ?? '').toLowerCase().contains(_query))
                        .where((e) => _filter == 'All' || (e.category ?? e.muscleGroup) == _filter)
                        .toList();
                    if (filtered.isEmpty) {
                      return Column(children: [
                        _ChipsRow(categories: catList, selected: _filter, onSelected: (c) => setState(() => _filter = c)),
                        const SizedBox(height: 24),
                        const Expanded(child: EmptyState('No exercises match your filters')),
                      ]);
                    }
                    return Column(children: [
                      _ChipsRow(categories: catList, selected: _filter, onSelected: (c) => setState(() => _filter = c)),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          padding: const EdgeInsets.only(bottom: 80),
                          itemBuilder: (context, index) {
                            final e = filtered[index];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                                  child: const Icon(Icons.fitness_center_rounded),
                                ),
                                title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                subtitle: Text([
                                  e.category,
                                  e.primaryMuscle,
                                ].whereType<String>().where((s) => s.isNotEmpty).join(' • ')),
                                trailing: Wrap(spacing: 6, children: [
                                  IconButton(
                                    tooltip: 'Open tutorial',
                                    icon: const Icon(Icons.school_rounded),
                                    onPressed: () {
                                      final t = Tutorial(
                                        id: e.name.toLowerCase().replaceAll(' ', '_'),
                                        title: '${e.name} Tutorial',
                                        imageUrls: const [
                                          'images/edgar-chaparro-sHfo3WOgGTU-unsplash.jpg',
                                          'images/brett-jordan-U2q73PfHFpM-unsplash.jpg',
                                        ],
                                      );
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => TutorialViewerScreen(tutorial: t)),
                                      );
                                    },
                                  ),
                                  if (e.isCustom == true)
                                    IconButton(
                                      tooltip: 'Edit Custom Exercise',
                                      icon: const Icon(Icons.edit, size: 18),
                                      onPressed: () async {
                                        await _editCustomExercise(context, uid, e);
                                      },
                                    ),
                                ]),
                              ),
                            );
                          },
                        ),
                      )
                    ]);
                  },
                ),
        ),
      ]),
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

extension on _ExercisesTabState {
  Future<void> _editCustomExercise(BuildContext context, String uid, Exercise e) async {
    final nameCtrl = TextEditingController(text: e.name);
    final catCtrl = TextEditingController(text: e.category ?? '');
    final primCtrl = TextEditingController(text: e.primaryMuscle ?? '');
    final secCtrl = TextEditingController(text: (e.secondaryMuscles ?? []).join(', '));
    final formKey = GlobalKey<FormState>();
    final repo = ExerciseRepository();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Exercise'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
              TextFormField(controller: catCtrl, decoration: const InputDecoration(labelText: 'Category')),
              TextFormField(controller: primCtrl, decoration: const InputDecoration(labelText: 'Primary muscle')),
              TextFormField(controller: secCtrl, decoration: const InputDecoration(labelText: 'Secondary muscles (comma separated)')),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final updated = Exercise(
                id: e.id,
                name: nameCtrl.text.trim(),
                muscleGroup: primCtrl.text.trim().isNotEmpty ? primCtrl.text.trim() : (catCtrl.text.trim().isNotEmpty ? catCtrl.text.trim() : 'general'),
                category: catCtrl.text.trim().isEmpty ? null : catCtrl.text.trim(),
                primaryMuscle: primCtrl.text.trim().isEmpty ? null : primCtrl.text.trim(),
                secondaryMuscles: secCtrl.text.trim().isEmpty ? null : secCtrl.text.split(',').map((s)=>s.trim()).where((s)=>s.isNotEmpty).toList(),
                isCustom: true,
              );
              await repo.upsert(uid, updated);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }
}

class _ChipsRow extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;
  const _ChipsRow({required this.categories, required this.selected, required this.onSelected});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(children: [
        for (final c in categories)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(c),
              selected: selected == c,
              onSelected: (_) => onSelected(c),
            ),
          )
      ]),
    );
  }
}
