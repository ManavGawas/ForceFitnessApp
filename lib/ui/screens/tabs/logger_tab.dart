import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/workout.dart';
import '../../../services/repositories.dart';
import '../../../models/exercise.dart';
import '../../../models/pr.dart';
import '../../../services/providers/auth_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../widgets/branded_scaffold.dart';
import '../../../services/providers/pending_workout_provider.dart';

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
    // Merge with any already added exercises and keep user's custom ones
    setState(() {
      final existingNames = _exercises.map((e) => e.name.toLowerCase()).toSet();
      for (final n in names) {
        if (!existingNames.contains(n.toLowerCase())) {
          _exercises.add(_ExerciseModel(name: n));
        }
      }
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
      // Persist PRs: for each exercise, take max (weight,reps) pair and upsert if it beats previous
      for (final e in entries) {
        final bestSet = e.sets.fold<SetEntry?>(null, (b, s) {
          if (b == null) return s;
          if (s.weight > b.weight) return s;
          if (s.weight == b.weight && s.reps > b.reps) return s;
          return b;
        });
        if (bestSet == null) continue;
        final currentBest = await PRRepository().bestForExercise(uid, e.exerciseName);
        final beats = currentBest == null ||
            bestSet.weight > currentBest.weight ||
            (bestSet.weight == currentBest.weight && bestSet.reps > currentBest.reps);
        if (beats) {
          final rec = PRRecord(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            exerciseId: e.exerciseId,
            exerciseName: e.exerciseName,
            date: DateTime.now(),
            weight: bestSet.weight.toDouble(),
            reps: bestSet.reps,
          );
          await PRRepository().add(uid, rec);
        }
      }
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
    // Preload pending workout (if any)
    final pending = context.watch<PendingWorkoutProvider>().takePending();
    if (pending != null && pending.isNotEmpty && _exercises.isEmpty) {
      for (final p in pending) {
        final m = _ExerciseModel(name: p.name);
        if (p.sets.isNotEmpty) {
          for (final s in p.sets) {
            m.addSet();
            final last = m.sets.last;
            last.reps = s.reps;
            last.kg = s.kg;
            last.type = s.type ?? 'normal';
          }
        }
        _exercises.add(m);
      }
    }
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
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
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
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 1,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Gradient header
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.primary.withOpacity(0.08), Colors.transparent],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(children: [
            const Icon(Icons.flash_on_rounded),
            const SizedBox(width: 8),
            Expanded(child: Text(widget.model.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
            IconButton(
              tooltip: 'Weight plate calc',
              onPressed: () => _openPlateCalculator(context),
              icon: const Icon(Icons.calculate_rounded),
            ),
            IconButton(onPressed: widget.onRemove, icon: const Icon(Icons.delete_outline)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (_previous != null) ...[
            const SizedBox(height: 6),
            Text('Previous: '
                '${_previous!.sets.map((s) => '${s.weight}x${s.reps}${s.rpe != null ? ' RPE${s.rpe}' : ''}').join(', ')}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
          ],
          const Divider(height: 16, color: Colors.white12),
          TextField(
            decoration: const InputDecoration(labelText: 'Exercise note (optional)'),
            onChanged: (v) => widget.model.note = v,
          ),
          const SizedBox(height: 8),
          // Header row for clarity (hidden on narrow layouts)
          LayoutBuilder(builder: (context, c) {
            final isNarrow = c.maxWidth < 380;
            if (isNarrow) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: const [
                SizedBox(width: 62, child: Text('Set', style: TextStyle(fontWeight: FontWeight.w700))),
                Expanded(child: Text('Weight (kg)', style: TextStyle(fontWeight: FontWeight.w700))),
                SizedBox(width: 8),
                Expanded(child: Text('Reps', style: TextStyle(fontWeight: FontWeight.w700))),
                SizedBox(width: 8),
                Expanded(child: Text('RPE', style: TextStyle(fontWeight: FontWeight.w700))),
                SizedBox(width: 8),
                SizedBox(width: 140, child: Text('Type', style: TextStyle(fontWeight: FontWeight.w700))),
                SizedBox(width: 8),
                SizedBox(width: 40),
              ]),
            );
          }),
          ...widget.model.sets.map((s) => _SetRow(
                model: s,
                onDelete: () => setState(() => widget.model.removeSet(s)),
                onChanged: () {
                  // Notify only when user crosses previous PR (consider reps on tie weight)
                  final prevBest = _previous?.sets.fold<SetEntry?>(null, (b, e) {
                        if (b == null) return e;
                        if (e.weight > b.weight) return e;
                        if (e.weight == b.weight && e.reps > b.reps) return e;
                        return b;
                      });
                  final currBest = widget.model.sets.fold<_SetModel?>(null, (b, e) {
                        if (b == null) return e;
                        final bw = b.kg ?? 0; final br = b.reps ?? 0;
                        final ew = e.kg ?? 0; final er = e.reps ?? 0;
                        if (ew > bw) return e;
                        if (ew == bw && er > br) return e;
                        return b;
                      });
                  final hit = prevBest != null && currBest != null &&
                      (((currBest.kg ?? 0) > prevBest.weight) ||
                       ((currBest.kg ?? 0) == prevBest.weight && (currBest.reps ?? 0) > prevBest.reps));
                  if (hit) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New PR! 🎉')));
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
      ]),
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
          SizedBox(width: 62, child: Text('Set ${model.number}')), const SizedBox(width: 4),
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
        // On narrow screens, don't repeat the header; present inputs stacked cleanly
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Set ${model.number}', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(prefixText: 'kg ', labelText: 'Weight'),
              onChanged: (v) { model.kg = double.tryParse(v); onChanged?.call(); },
            ),
            const SizedBox(height: 8),
            Row(children: [
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
            ]),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
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
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline)),
            )
          ],
        );
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
    // Logical warm-up progression at 40/60/75/90% with descending reps
    final steps = [
      {'p': 0.4, 'r': 8},
      {'p': 0.6, 'r': 5},
      {'p': 0.75, 'r': 3},
      {'p': 0.9, 'r': 1},
    ];
    final insertAt = sets.isEmpty ? 0 : sets.length - 1; // before the last top set
    var idx = insertAt;
    for (final s in steps) {
      final kg = (target * (s['p'] as double)).roundToDouble();
      sets.insert(idx, _SetModel(number: 0)
        ..kg = kg
        ..reps = s['r'] as int
        ..type = 'warmup');
      idx++;
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
