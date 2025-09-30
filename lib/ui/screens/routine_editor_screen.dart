import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/routine.dart';
import '../../services/repositories.dart';
import '../../services/providers/auth_provider.dart';
import '../../models/exercise.dart';

class RoutineEditorScreen extends StatefulWidget {
  final Routine? existing;
  const RoutineEditorScreen({super.key, this.existing});

  @override
  State<RoutineEditorScreen> createState() => _RoutineEditorScreenState();
}

class _RoutineEditorScreenState extends State<RoutineEditorScreen> {
  final _nameCtrl = TextEditingController();
  final List<RoutineExercise> _items = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameCtrl.text = widget.existing!.name;
      _items.addAll(widget.existing!.exercises.map((e) => RoutineExercise(exerciseId: e.exerciseId, name: e.name, sets: List<Map<String, dynamic>>.from(e.sets))));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _addExercisePicker() async {
    final uid = context.read<AuthProvider?>()?.uid;
    if (uid == null) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          expand: false,
          builder: (_, ctl) {
            return Column(
              children: [
                const SizedBox(height: 8),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 8),
                const Text('Pick exercise', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Expanded(
                  child: StreamBuilder<List<Exercise>>(
                    stream: ExerciseRepository().streamAll(uid),
                    builder: (context, snap) {
                      final items = snap.data ?? [];
                      if (items.isEmpty) return const Center(child: Text('No exercises. Import or add some first.'));
                      return ListView.builder(
                        controller: ctl,
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final ex = items[i];
                          return ListTile(
                            title: Text(ex.name),
                            subtitle: ex.muscleGroup.isNotEmpty ? Text(ex.muscleGroup) : null,
                            onTap: () {
                              setState(() {
                                _items.add(RoutineExercise(
                                  exerciseId: ex.id,
                                  name: ex.name,
                                  sets: const [
                                    {'reps': 10, 'kg': null},
                                    {'reps': 10, 'kg': null},
                                    {'reps': 10, 'kg': null},
                                  ],
                                ));
                              });
                              Navigator.pop(context);
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _save() async {
    final uid = context.read<AuthProvider?>()?.uid;
    if (uid == null) return;
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a routine name')));
      return;
    }
    setState(() => _saving = true);
    try {
      final id = widget.existing?.id ?? _slugify(_nameCtrl.text.trim()) + '_${DateTime.now().millisecondsSinceEpoch}';
      final r = Routine(id: id, name: _nameCtrl.text.trim(), exercises: _items);
      await RoutinesRepository().upsert(uid, r);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save routine: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'New Routine' : 'Edit Routine'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addExercisePicker,
        icon: const Icon(Icons.add),
        label: const Text('Add exercise'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Routine name',
              hintText: 'e.g., Push Day',
              prefixIcon: Icon(Icons.edit_outlined),
            ),
          ),
          const SizedBox(height: 16),
          if (_items.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: Text('No exercises yet. Tap "Add exercise" to include some.')),
            ),
          ..._items.asMap().entries.map((entry) {
            final i = entry.key;
            final e = entry.value;
            return _EditableExerciseCard(
              key: ValueKey('ex_${i}_${e.exerciseId}'),
              e: e,
              onChanged: (updated) => setState(() => _items[i] = updated),
              onRemove: () => setState(() => _items.removeAt(i)),
              onMoveUp: i == 0 ? null : () => setState(() => _swap(i, i - 1)),
              onMoveDown: i == _items.length - 1 ? null : () => setState(() => _swap(i, i + 1)),
            );
          }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _swap(int a, int b) {
    final tmp = _items[a];
    _items[a] = _items[b];
    _items[b] = tmp;
  }

  String _slugify(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r"[^a-z0-9]+"), '_')
      .replaceAll(RegExp(r"_+"), '_')
      .replaceAll(RegExp(r"^_|_$"), '');
}

class _EditableExerciseCard extends StatelessWidget {
  final RoutineExercise e;
  final ValueChanged<RoutineExercise> onChanged;
  final VoidCallback onRemove;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  const _EditableExerciseCard({super.key, required this.e, required this.onChanged, required this.onRemove, this.onMoveUp, this.onMoveDown});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Expanded(child: Text(e.name, style: const TextStyle(fontWeight: FontWeight.w600))),
              IconButton(onPressed: onMoveUp, icon: const Icon(Icons.arrow_upward)),
              IconButton(onPressed: onMoveDown, icon: const Icon(Icons.arrow_downward)),
              IconButton(onPressed: onRemove, icon: const Icon(Icons.delete_outline)),
            ],
          ),
          const SizedBox(height: 8),
          ...e.sets.asMap().entries.map((entry) {
            final i = entry.key;
            final s = Map<String, dynamic>.from(entry.value);
            final reps = (s['reps'] as num?)?.toInt() ?? 10;
            final kg = (s['kg'] as num?)?.toDouble();
            return Row(
              children: [
                Text('Set ${i + 1}'),
                const SizedBox(width: 8),
                SizedBox(
                  width: 90,
                  child: TextFormField(
                    initialValue: reps.toString(),
                    decoration: const InputDecoration(labelText: 'Reps'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      final nv = int.tryParse(v);
                      if (nv != null) {
                        s['reps'] = nv;
                        _commit(context, i, s);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 110,
                  child: TextFormField(
                    initialValue: kg?.toString() ?? '',
                    decoration: const InputDecoration(labelText: 'Kg (optional)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) {
                      final nv = double.tryParse(v);
                      s['kg'] = nv;
                      _commit(context, i, s);
                    },
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    final sets = List<Map<String, dynamic>>.from(e.sets);
                    sets.removeAt(i);
                    onChanged(RoutineExercise(exerciseId: e.exerciseId, name: e.name, sets: sets));
                  },
                  icon: const Icon(Icons.remove_circle_outline),
                ),
              ],
            );
          }),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                final sets = List<Map<String, dynamic>>.from(e.sets);
                sets.add({'reps': 10, 'kg': null});
                onChanged(RoutineExercise(exerciseId: e.exerciseId, name: e.name, sets: sets));
              },
              icon: const Icon(Icons.add),
              label: const Text('Add set'),
            ),
          )
        ]),
      ),
    );
  }

  void _commit(BuildContext context, int i, Map<String, dynamic> s) {
    final sets = List<Map<String, dynamic>>.from(e.sets);
    sets[i] = s;
    onChanged(RoutineExercise(exerciseId: e.exerciseId, name: e.name, sets: sets));
  }
}
