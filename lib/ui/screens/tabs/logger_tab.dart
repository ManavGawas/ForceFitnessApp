import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/workout.dart';
import '../../../services/repositories.dart';
import '../../../models/exercise.dart';
import '../../../services/providers/auth_provider.dart';
import '../../../models/split.dart';
import 'package:share_plus/share_plus.dart';
import '../../widgets/branded_scaffold.dart';

class LoggerTab extends StatefulWidget {
  const LoggerTab({super.key});
  @override
  State<LoggerTab> createState() => _LoggerTabState();
}

class _LoggerTabState extends State<LoggerTab> {
  final List<_ExerciseModel> _exercises = [];
  DateTime? _restStart;

  void _addExercise() async {
    final uid = context.read<AuthProvider?>()?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign-in required')));
      return;
    }
    final selected = await showDialog<Exercise>(
      context: context,
      builder: (ctx) {
        return _ExercisePickerDialog(uid: uid);
      },
    );
    if (selected != null) {
      setState(() {
        _exercises.add(_ExerciseModel(name: selected.name));
      });
    }
  }

  Future<void> _loadSplitForToday() async {
    final uid = context.read<AuthProvider?>()?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign-in required')));
      return;
    }
    final split = await SplitRepository().active(uid).first;
    if (split == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No active split set')));
      return;
    }
    final weekday = DateTime.now().weekday; // 1..7
    final names = split.days[weekday] ?? const [];
    if (names.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No exercises for today in split')));
      return;
    }
    setState(() {
      _exercises.clear();
      _exercises.addAll(names.map((n) => _ExerciseModel(name: n)));
    });
  }

  Future<void> _saveSession() async {
    final uid = context.read<AuthProvider>().uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not signed in')));
      return;
    }
    final entries = _exercises
        .map((e) => WorkoutEntry(
              exerciseId: e.name.toLowerCase().replaceAll(' ', '_'),
              exerciseName: e.name,
              sets: e.sets
                  .map((s) => SetEntry(setNumber: s.number, weight: s.kg ?? 0, reps: s.reps ?? 0, rpe: s.rpe))
                  .toList(),
            ))
        .toList();
    final session = WorkoutSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      entries: entries,
    );
    try {
      await WorkoutRepository().saveSession(uid, session);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session saved')));
      // Offer to share
      final totalSets = entries.fold<int>(0, (s, e) => s + e.sets.length);
      final lines = entries.map((e) => '${e.exerciseName} (${e.sets.length} sets)').join(', ');
      final shareMsg = 'Crushed today\'s workout: $totalSets sets — $lines  #ForceFitness';
      final share = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Share your workout?'),
          content: const Text('Let friends know what you\'ve accomplished.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No thanks')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Share')),
          ],
        ),
      );
      if (share == true) {
        Share.share(shareMsg);
      }
      setState(() => _exercises.clear());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BrandedScaffold(
      appBar: AppBar(
        title: const Text('Session Logger'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _restStart = DateTime.now();
              });
            },
            icon: const Icon(Icons.timer_rounded),
            tooltip: 'Start rest timer',
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveSession,
        icon: const Icon(Icons.save_rounded),
        label: const Text('Save Session'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.fitness_center_rounded),
              title: const Text('Add Exercise'),
              trailing: const Icon(Icons.add_rounded),
              onTap: _addExercise,
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today_rounded),
              title: const Text('Load today\'s split'),
              onTap: _loadSplitForToday,
            ),
          ),
          const SizedBox(height: 8),
          if (_exercises.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No exercises yet. Tap "Add Exercise" to start.'),
            )
          else
            ..._exercises.map((m) => _ExerciseCard(
                  model: m,
                  onRemove: () => setState(() => _exercises.remove(m)),
                )),
          if (_restStart != null) ...[
            const SizedBox(height: 8),
            _RestTimerWidget(
              start: _restStart!,
              onStop: () => setState(() => _restStart = null),
            )
          ]
        ],
      ),
    );
  }

}

class _ExerciseCard extends StatefulWidget {
  final _ExerciseModel model;
  final VoidCallback onRemove;
  const _ExerciseCard({required this.model, required this.onRemove});
  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  WorkoutEntry? _previous;

  @override
  void initState() {
    super.initState();
    _loadPrev();
  }

  Future<void> _loadPrev() async {
    final uid = context.mounted ? context.read<AuthProvider?>()?.uid : null;
    if (uid == null) return;
    final prev = await WorkoutRepository().previousForExercise(uid, widget.model.name);
    if (!mounted) return;
    setState(() => _previous = prev);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.flash_on_rounded),
            const SizedBox(width: 8),
            Expanded(child: Text(widget.model.name, style: Theme.of(context).textTheme.titleMedium)),
            const Spacer(),
            IconButton(
              tooltip: 'Weight plate calc',
              onPressed: () => _openPlateCalculator(context),
              icon: const Icon(Icons.calculate_rounded),
            ),
            IconButton(onPressed: widget.onRemove, icon: const Icon(Icons.delete_outline)),
          ]),
          if (_previous != null) ...[
            const SizedBox(height: 6),
            Text('Previous: '
                '${_previous!.sets.map((s) => '${s.weight}x${s.reps}${s.rpe != null ? ' RPE${s.rpe}' : ''}').join(', ')}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
          ],
          const Divider(),
          TextField(
            decoration: const InputDecoration(labelText: 'Exercise note (optional)'),
            onChanged: (v) => widget.model.note = v,
          ),
          const SizedBox(height: 8),
          ...widget.model.sets.map((s) => _SetRow(
                model: s,
                onDelete: () => setState(() => widget.model.removeSet(s)),
                onChanged: () {
                  // naive PR check: if any weight exceeds previous max weight
                  final prevMax = _previous?.sets.fold<double>(0, (p, e) => e.weight > p ? e.weight : p) ?? 0;
                  final currentMax = widget.model.sets.fold<double>(0, (p, e) => (e.kg ?? 0) > p ? (e.kg ?? 0) : p);
                  if (currentMax > 0 && currentMax > prevMax) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('New PR potential! Keep it up 💪')),
                    );
                  }
                },
              )),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              OutlinedButton.icon(
                onPressed: () => setState(() => widget.model.addWarmups()),
                icon: const Icon(Icons.local_fire_department_rounded),
                label: const Text('Warm-up calc'),
              ),
              TextButton.icon(
                onPressed: () => setState(() => widget.model.addSet()),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add set'),
              ),
            ]),
          )
        ]),
      ),
    );
  }

  void _openPlateCalculator(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        final target = widget.model.sets.isNotEmpty ? (widget.model.sets.last.kg ?? 0) : 0;
        final bar = 20.0; // 20kg barbell
  final perSide = ((target - bar) / 2).clamp(0.0, double.infinity);
        final plates = _calcPlates(perSide);
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Plate calculator', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Target weight: ${target.toStringAsFixed(1)} kg  (bar 20kg)'),
            const SizedBox(height: 12),
            if (plates.isEmpty) const Text('Add weight to see plate breakdown')
            else Text('Per side: ${plates.map((e) => '${e.toStringAsFixed(1)}kg').join(' + ')}'),
            const SizedBox(height: 8),
          ]),
        );
      },
    );
  }

  List<double> _calcPlates(double perSide) {
    final sizes = [25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25];
    final result = <double>[];
    var remaining = perSide;
    for (final s in sizes) {
      while (remaining + 1e-6 >= s) { // floating tolerance
        result.add(s);
        remaining -= s;
      }
    }
    return result;
  }
}

class _SetRow extends StatelessWidget {
  final _SetModel model;
  final VoidCallback onDelete;
  final VoidCallback? onChanged;
  const _SetRow({required this.model, required this.onDelete, this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: LayoutBuilder(builder: (context, c) {
        final isNarrow = c.maxWidth < 380;
        final row = Row(children: [
          Text('Set ${model.number}'), const SizedBox(width: 12),
          Expanded(child: TextField(
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(prefixText: 'kg ', labelText: 'Weight'),
            onChanged: (v) { model.kg = double.tryParse(v); onChanged?.call(); },
          )),
          const SizedBox(width: 8),
          Expanded(child: TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Reps'),
            onChanged: (v) { model.reps = int.tryParse(v); onChanged?.call(); },
          )),
          const SizedBox(width: 8),
          Expanded(child: TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'RPE'),
            onChanged: (v) { model.rpe = int.tryParse(v); onChanged?.call(); },
          )),
          const SizedBox(width: 8),
          SizedBox(
            width: 140,
            child: DropdownButtonFormField<String>(
              value: model.type,
              items: const [
                DropdownMenuItem(value: 'normal', child: Text('Normal')),
                DropdownMenuItem(value: 'warmup', child: Text('Warm-up')),
                DropdownMenuItem(value: 'drop', child: Text('Drop')),
                DropdownMenuItem(value: 'failure', child: Text('Failure')),
              ],
              onChanged: (v) { model.type = v; onChanged?.call(); },
              decoration: const InputDecoration(labelText: 'Type'),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline))
        ]);
        if (!isNarrow) return row;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Text('Set ${model.number}')]),
          const SizedBox(height: 6),
          Row(children: [Expanded(child: row)]),
        ]);
      }),
    );
  }
}

class _ExerciseModel {
  final String name;
  final List<_SetModel> sets = [];
  String? note;
  _ExerciseModel({required this.name}) { addSet(); }
  void addSet() => sets.add(_SetModel(number: sets.length + 1));
  void addWarmups() {
    final target = sets.isNotEmpty ? (sets.last.kg ?? 0) : 0;
    if (target <= 0) return;
    final plan = [0.5, 0.7, 0.85];
    for (final p in plan) {
      sets.insert(sets.isNotEmpty ? sets.length - 0 : 0, _SetModel(number: 0)..kg = (target * p).roundToDouble()..reps = 5..type = 'warmup');
    }
    for (var i = 0; i < sets.length; i++) { sets[i] = sets[i].copyWith(number: i+1); }
  }
  void removeSet(_SetModel s) {
    sets.remove(s);
    for (var i = 0; i < sets.length; i++) { sets[i] = sets[i].copyWith(number: i+1); }
  }
}

class _SetModel {
  final int number;
  double? kg;
  int? reps;
  int? rpe;
  String? type = 'normal';
  _SetModel({required this.number});
  _SetModel copyWith({int? number}) => _SetModel(number: number ?? this.number)..kg = kg..reps = reps..rpe = rpe..type = type;
}

class _RestTimerWidget extends StatefulWidget {
  final DateTime start;
  final VoidCallback onStop;
  const _RestTimerWidget({required this.start, required this.onStop});
  @override
  State<_RestTimerWidget> createState() => _RestTimerWidgetState();
}

class _RestTimerWidgetState extends State<_RestTimerWidget> {
  late DateTime _start;
  Duration _elapsed = Duration.zero;
  @override
  void initState() {
    super.initState();
    _start = widget.start;
    _tick();
  }
  void _tick() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 1));
      setState(() { _elapsed = DateTime.now().difference(_start); });
    }
  }
  @override
  Widget build(BuildContext context) {
    String two(int n) => n.toString().padLeft(2, '0');
    final m = two(_elapsed.inMinutes.remainder(60));
    final s = two(_elapsed.inSeconds.remainder(60));
    return Card(child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
      const Icon(Icons.timer_rounded), const SizedBox(width: 8), Text('Rest: $m:$s'), const Spacer(),
      TextButton(onPressed: () => setState(() { _start = DateTime.now(); _elapsed = Duration.zero; }), child: const Text('Reset')),
      const SizedBox(width: 8),
      TextButton(onPressed: widget.onStop, child: const Text('Done'))
    ])));
  }
}

class _ExercisePickerDialog extends StatefulWidget {
  final String uid;
  const _ExercisePickerDialog({required this.uid});
  @override
  State<_ExercisePickerDialog> createState() => _ExercisePickerDialogState();
}

class _ExercisePickerDialogState extends State<_ExercisePickerDialog> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pick Exercise'),
      content: SizedBox(
        width: 400,
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
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = (snapshot.data ?? [])
                    .where((e) => _query.isEmpty || e.name.toLowerCase().contains(_query) || e.muscleGroup.toLowerCase().contains(_query))
                    .toList();
                if (items.isEmpty) return const Center(child: Text('No exercises'));
                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final e = items[i];
                    return ListTile(
                      leading: const Icon(Icons.fitness_center),
                      title: Text(e.name),
                      subtitle: Text(e.muscleGroup),
                      onTap: () => Navigator.pop(context, e),
                    );
                  },
                );
              },
            ),
          )
        ]),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
    );
  }
}
