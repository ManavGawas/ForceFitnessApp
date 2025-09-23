import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/repositories.dart';
import '../../models/split.dart';
import '../../models/exercise.dart';
import '../../services/providers/auth_provider.dart';

class SplitPlannerScreen extends StatelessWidget {
  const SplitPlannerScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider?>()?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('Not signed in')));
    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Split Planner')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final nameController = TextEditingController();
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('New Split'),
              content: TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
              ],
            ),
          );
          if (ok == true) {
            final plan = SplitPlan(id: 'new', name: nameController.text.trim().isEmpty ? 'Split' : nameController.text.trim(), days: {});
            await SplitRepository().create(uid, plan);
          }
        },
        icon: const Icon(Icons.add_rounded), label: const Text('New Split'),
      ),
      body: StreamBuilder<List<SplitPlan>>(
        stream: SplitRepository().all(uid),
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No splits yet. Tap New Split to create one.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemBuilder: (ctx, i) => _SplitTile(plan: items[i], uid: uid),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: items.length,
          );
        },
      ),
    );
  }
}

class _SplitTile extends StatelessWidget {
  final SplitPlan plan;
  final String uid;
  const _SplitTile({required this.plan, required this.uid});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(plan.name),
        subtitle: Text(plan.active ? 'Active' : 'Inactive'),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => _EditSplitScreen(uid: uid, plan: plan))),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            icon: Icon(plan.active ? Icons.check_circle : Icons.radio_button_unchecked),
            onPressed: () => SplitRepository().setActive(uid, plan.id, active: true),
            tooltip: 'Set active',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => SplitRepository().delete(uid, plan.id),
          ),
        ]),
      ),
    );
  }
}

class _EditSplitScreen extends StatefulWidget {
  final String uid;
  final SplitPlan plan;
  const _EditSplitScreen({required this.uid, required this.plan});
  @override
  State<_EditSplitScreen> createState() => _EditSplitScreenState();
}

class _EditSplitScreenState extends State<_EditSplitScreen> {
  late SplitPlan plan;
  @override
  void initState() {
    super.initState();
    plan = widget.plan;
  }

  Future<void> _pickExercisesForDay(int weekday) async {
    final picked = await showDialog<List<String>>(
      context: context,
      builder: (ctx) => _ExerciseMultiPicker(uid: widget.uid, initial: plan.days[weekday] ?? const []),
    );
    if (picked != null) {
      final updated = Map<int, List<String>>.from(plan.days);
      updated[weekday] = picked;
      setState(() => plan = SplitPlan(id: plan.id, name: plan.name, days: updated, active: plan.active));
      await SplitRepository().update(widget.uid, plan);
    }
  }

  @override
  Widget build(BuildContext context) {
    const weekdays = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return Scaffold(
      appBar: AppBar(title: Text('Edit: ${plan.name}')),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemBuilder: (_, i) {
          final dayIdx = i + 1; // 1..7
          final list = plan.days[dayIdx] ?? const [];
          return Card(
            child: ListTile(
              title: Text(weekdays[i]),
              subtitle: Text(list.isEmpty ? 'No exercises' : list.join(', ')),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => _pickExercisesForDay(dayIdx),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemCount: 7,
      ),
    );
  }
}

class _ExerciseMultiPicker extends StatefulWidget {
  final String uid;
  final List<String> initial; // exercise names for simplicity
  const _ExerciseMultiPicker({required this.uid, required this.initial});
  @override
  State<_ExerciseMultiPicker> createState() => _ExerciseMultiPickerState();
}

class _ExerciseMultiPickerState extends State<_ExerciseMultiPicker> {
  String _query = '';
  late Set<String> _selected;
  @override
  void initState() {
    super.initState();
    _selected = widget.initial.toSet();
  }
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pick exercises'),
      content: SizedBox(
        width: 500,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search'),
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: StreamBuilder<List<Exercise>>(
              stream: ExerciseRepository().streamAll(widget.uid),
              builder: (context, snapshot) {
                final items = (snapshot.data ?? [])
                    .where((e) => _query.isEmpty || e.name.toLowerCase().contains(_query))
                    .toList();
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final e = items[i];
                    final checked = _selected.contains(e.name);
                    return CheckboxListTile(
                      value: checked,
                      onChanged: (v) => setState(() {
                        if (v == true) { _selected.add(e.name); } else { _selected.remove(e.name); }
                      }),
                      title: Text(e.name),
                      subtitle: Text(e.muscleGroup),
                    );
                  },
                );
              },
            ),
          )
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, _selected.toList()), child: const Text('Save')),
      ],
    );
  }
}
