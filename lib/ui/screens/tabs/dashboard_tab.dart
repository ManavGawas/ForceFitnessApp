import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/providers/selected_date_provider.dart';
import '../../../services/providers/auth_provider.dart';
import '../../../services/repositories.dart';
import '../../../models/nutrition.dart';
import '../../../models/workout.dart';
import '../../../services/providers/tab_index_provider.dart';
import '../../../models/user_profile.dart';
import '../../../models/steps.dart';
import 'package:gymmate/ui/screens/run_tracker_screen.dart';
import 'package:gymmate/models/run.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('images/logo.png', height: 24),
                  const SizedBox(width: 8),
                  const Text('Force Fitness'),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.directions_run_rounded),
                  tooltip: 'Start Run',
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RunTrackerScreen())),
                )
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _HeroBanner(),
                    SizedBox(height: 12),
                    _DaySelector(),
                    SizedBox(height: 12),
                    _CircularSummary(),
                    SizedBox(height: 12),
                    _CategoriesRow(),
                    SizedBox(height: 8),
                    _PopularCarousel(),
                    SizedBox(height: 12),
                    _RunSummaryCard(),
                    SizedBox(height: 12),
                    _QuickActions(),
                  ],
                ),
              ),
            )
          ],
        ),
        // Floating rounded '+' action with glow
        Positioned(
          right: 20,
          bottom: 30,
          child: _GlowingActionButton(
            onTap: () => context.read<TabIndexProvider>().setIndex(1),
          ),
        )
      ],
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [cs.primary.withValues(alpha: 0.25), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        image: const DecorationImage(
          image: AssetImage('images/3.webp'),
          fit: BoxFit.cover,
          opacity: 0.2,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Fitness, Just the Way You Like It.', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('Tailored routines and tools to crush your goals.'),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RunTrackerScreen())),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start Run'),
            )
          ]),
        ),
      ]),
    );
  }
}

class _CircularSummary extends StatelessWidget {
  const _CircularSummary();
  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider?>()?.uid;
    final day = context.watch<SelectedDateProvider>().day;
    if (uid == null) {
      return Row(children: const [
        Expanded(child: _CircularStat(title: 'Calories', value: 0, goal: 1, unit: 'kcal')),
        Expanded(child: _CircularStat(title: 'Protein', value: 0, goal: 1, unit: 'g')),
        Expanded(child: _CircularStat(title: 'Carbs', value: 0, goal: 1, unit: 'g')),
      ]);
    }
    return StreamBuilder<UserProfile>(
      stream: UserProfileRepository().stream(uid),
      builder: (context, profSnap) {
        final profile = profSnap.data ?? UserProfile(uid: uid);
        return StreamBuilder<List<NutritionEntry>>(
          stream: NutritionRepository().byDay(uid, day),
          builder: (context, nutriSnap) {
            final entries = nutriSnap.data ?? [];
            final kcal = entries.fold<int>(0, (s, e) => s + e.calories);
            final protein = entries.fold<int>(0, (s, e) => s + e.protein);
            final carbs = entries.fold<int>(0, (s, e) => s + e.carbs);
            return Row(children: [
              Expanded(child: _CircularStat(title: 'Calories', value: kcal, goal: profile.dailyCaloriesGoal, unit: 'kcal')),
              Expanded(child: _CircularStat(title: 'Protein', value: protein, goal: profile.dailyProteinGoal, unit: 'g')),
              Expanded(child: _CircularStat(title: 'Carbs', value: carbs, goal: 300, unit: 'g')),
            ]);
          },
        );
      },
    );
  }
}

class _CircularStat extends StatelessWidget {
  final String title; final int value; final int goal; final String unit;
  const _CircularStat({required this.title, required this.value, required this.goal, required this.unit});
  @override
  Widget build(BuildContext context) {
    final ratio = goal == 0 ? 0.0 : (value / goal).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(builder: (context, c) {
          final circle = c.maxWidth < 160 ? 48.0 : 64.0;
          return Row(children: [
            SizedBox(
              width: circle, height: circle,
              child: Stack(alignment: Alignment.center, children: [
                CircularProgressIndicator(value: ratio, strokeWidth: 6),
                Text('${(ratio*100).round()}%'),
              ]),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('$value / $goal $unit', maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            )
          ]);
        }),
      ),
    );
  }
}

class _CategoriesRow extends StatefulWidget {
  const _CategoriesRow();
  @override
  State<_CategoriesRow> createState() => _CategoriesRowState();
}

class _CategoriesRowState extends State<_CategoriesRow> {
  int _index = 0;
  static const cats = ['All','Chest','Back','Arms'];
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (int i=0;i<cats.length;i++) Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(cats[i]),
                selected: _index==i,
                onSelected: (_) => setState(() => _index = i),
              ),
            )
          ]),
        ),
      ),
      TextButton(onPressed: (){}, child: const Text('See All'))
    ]);
  }
}

class _PopularCarousel extends StatelessWidget {
  const _PopularCarousel();
  @override
  Widget build(BuildContext context) {
    final items = [
      _PopularItem('Shoulder Flex Stability','images/1.jpeg','Intermediate',45),
      _PopularItem('Leg Poses','images/4.jpeg','Beginner',50),
      _PopularItem('Core Blast','images/5.jpeg','Intermediate',30),
    ];
    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) => _PopularCard(item: items[i]),
      ),
    );
  }
}

class _PopularItem {
  final String title; final String image; final String tag; final int minutes;
  _PopularItem(this.title,this.image,this.tag,this.minutes);
}

class _PopularCard extends StatelessWidget {
  final _PopularItem item;
  const _PopularCard({required this.item});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
          Positioned.fill(child: Image.asset(item.image, fit: BoxFit.cover)),
          Positioned(
            left: 8, top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
              child: Text(item.tag),
            ),
          ),
          Positioned(
            left: 8, right: 8, bottom: 8,
            child: Row(children: [
              Expanded(child: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))),
              const SizedBox(width: 8),
              Row(children: [const Icon(Icons.timer, size: 16), Text(' ${item.minutes} min')])
            ]),
          )
        ]),
      ),
    );
  }
}

class _RunSummaryCard extends StatelessWidget {
  const _RunSummaryCard();
  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider?>()?.uid;
    if (uid == null) return const SizedBox.shrink();
    return StreamBuilder(
      stream: RunRepository().all(uid),
      builder: (context, snapshot) {
        final runs = (snapshot.data as List?)?.cast<RunSession>() ?? const <RunSession>[];
        // last 7 days distances
        final now = DateTime.now();
        final last7 = List<double>.generate(7, (i) {
          final d = DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i));
          final total = runs.where((r) => r.start.year==d.year && r.start.month==d.month && r.start.day==d.day)
              .fold<double>(0.0, (s, r) => s + r.distanceMeters/1000.0);
          return total;
        });
        final weekTotal = last7.fold<double>(0.0, (s,e)=>s+e);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('Running (7d)'),
                const Spacer(),
                Text('${weekTotal.toStringAsFixed(1)} km')
              ]),
              const SizedBox(height: 8),
              SizedBox(height: 120, child: LineChart(LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: Theme.of(context).colorScheme.primary,
                    dotData: FlDotData(show: false),
                    spots: [for (int i=0;i<last7.length;i++) FlSpot(i.toDouble(), last7[i])],
                  )
                ],
              )))
            ]),
          ),
        );
      },
    );
  }
}

class _GlowingActionButton extends StatefulWidget {
  final VoidCallback onTap;
  const _GlowingActionButton({required this.onTap});
  @override
  State<_GlowingActionButton> createState() => _GlowingActionButtonState();
}

class _GlowingActionButtonState extends State<_GlowingActionButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return ScaleTransition(
      scale: Tween<double>(begin: 0.95, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 24, spreadRadius: 4),
          ],
        ),
        child: FloatingActionButton(
          onPressed: widget.onTap,
          child: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }
}

class _DaySelector extends StatelessWidget {
  const _DaySelector();
  @override
  Widget build(BuildContext context) {
    final selected = context.watch<SelectedDateProvider>().day;
    return Row(children: [
      IconButton(
        onPressed: () => context.read<SelectedDateProvider>().setDay(selected.subtract(const Duration(days: 1))),
        icon: const Icon(Icons.chevron_left_rounded),
      ),
      Expanded(
        child: Center(
          child: Text(
            '${selected.year}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
      IconButton(
        onPressed: () => context.read<SelectedDateProvider>().setDay(selected.add(const Duration(days: 1))),
        icon: const Icon(Icons.chevron_right_rounded),
      ),
    ]);
  }
}

class _QuickSummary extends StatelessWidget {
  const _QuickSummary();
  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider?>()?.uid;
    final day = context.watch<SelectedDateProvider>().day;
    if (uid == null) {
      return Row(children: const [
        Expanded(child: _SummaryCard(title: 'Calories', value: '--')),
        Expanded(child: _SummaryCard(title: 'Protein', value: '--')),
        Expanded(child: _SummaryCard(title: 'Workout', value: '--')),
      ]);
    }
    return StreamBuilder<UserProfile>(
      stream: UserProfileRepository().stream(uid),
      builder: (context, profSnap) {
        final profile = profSnap.data ?? UserProfile(uid: uid);
        return StreamBuilder<List<NutritionEntry>>(
          stream: NutritionRepository().byDay(uid, day),
          builder: (context, nutriSnap) {
            final entries = nutriSnap.data ?? [];
            final kcal = entries.fold<int>(0, (s, e) => s + e.calories);
            final protein = entries.fold<int>(0, (s, e) => s + e.protein);
            return StreamBuilder<List<StepsEntry>>(
              stream: StepsRepository().byDay(uid, day),
              builder: (context, stepSnap) {
                final steps = (stepSnap.data ?? []).fold<int>(0, (s, e) => s + e.steps);
                return StreamBuilder<List<WorkoutSession>>(
              stream: WorkoutRepository().byDay(uid, day),
              builder: (context, workSnap) {
                final hasWorkout = (workSnap.data ?? []).isNotEmpty;
                return Row(children: [
                  Expanded(child: _SummaryCard(title: 'Calories', value: '$kcal / ${profile.dailyCaloriesGoal}')),
                  Expanded(child: _SummaryCard(title: 'Protein', value: '${protein}g / ${profile.dailyProteinGoal}g')),
                  Expanded(child: _SummaryCard(title: 'Steps', value: steps.toString())),
                  Expanded(child: _SummaryCard(title: 'Workout', value: hasWorkout ? 'Logged' : '—')),
                ]);
              },
            );
              },
            );
          },
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title; final String value;
  const _SummaryCard({required this.title, required this.value});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
        ]),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();
  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider?>()?.uid;
    return Row(children: [
      Expanded(child: _ActionButton(icon: Icons.play_arrow_rounded, label: 'Start Workout', onTap: () => context.read<TabIndexProvider>().setIndex(1))),
      Expanded(child: _ActionButton(icon: Icons.add, label: 'Add Set', onTap: () => context.read<TabIndexProvider>().setIndex(1))),
      Expanded(child: _ActionButton(icon: Icons.restaurant_rounded, label: 'Add Food', onTap: () => context.read<TabIndexProvider>().setIndex(3))),
      Expanded(child: _ActionButton(icon: Icons.directions_walk_rounded, label: 'Add Steps', onTap: () async {
        if (uid == null) return;
        final controller = TextEditingController();
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Add steps for today'),
            content: TextField(controller: controller, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Steps')),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
            ],
          ),
        );
        if (ok == true) {
          final n = int.tryParse(controller.text) ?? 0;
          await StepsRepository().add(uid, StepsEntry(id: '', date: DateTime.now(), steps: n));
        }
      })),
    ]);
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 28), const SizedBox(height: 6), Text(label)
          ]),
        ),
      ),
    );
  }
}
