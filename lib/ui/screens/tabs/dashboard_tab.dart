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
import 'package:gymmate/ui/screens/workouts_catalog_screen.dart';
import '../../widgets/workout_card.dart';
import '../../../services/providers/pending_workout_provider.dart';
import '../../../models/tutorial.dart';
import '../tutorial_viewer_screen.dart';
import '../../screens/routines_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/water.dart';
import '../../../models/sleep.dart';
import '../user_goals_screen.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});
  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  int _categoryIndex = 0; // 0=All,1=Chest,2=Back,3=Arms
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: const _BrandTitle(),
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
                padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 96),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _WelcomeCard(),
                    const SizedBox(height: 12),
                    const _HeroBanner(),
                    const SizedBox(height: 12),
                    const _DaySelector(),
                    const SizedBox(height: 12),
                    const _CircularSummary(),
                    const SizedBox(height: 12),
                    const _WeeklyGoalCircles(),
                    const SizedBox(height: 12),
                    _CategoriesRow(
                      selectedIndex: _categoryIndex,
                      onChanged: (i) => setState(() => _categoryIndex = i),
                    ),
                    const SizedBox(height: 8),
                    _PopularCarousel(categoryIndex: _categoryIndex),
                    const SizedBox(height: 12),
                    const _RunSummaryCard(),
                    const SizedBox(height: 12),
                    const _QuickActions(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            )
          ],
        ),
        // Floating rounded '+' action with glow
        Positioned(
          right: 20,
          bottom: 76,
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

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();
  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider?>()?.uid;
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    if (uid == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            const Icon(Icons.waving_hand_rounded, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Welcome!', style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text("Ready to crush today's workout?", style: text.bodyMedium),
            ])),
            FilledButton(
              onPressed: () => context.read<TabIndexProvider>().setIndex(4),
              child: const Text('Sign in'),
            ),
          ]),
        ),
      );
    }
    return StreamBuilder<UserProfile>(
      stream: UserProfileRepository().stream(uid),
      builder: (context, snap) {
        final profile = snap.data ?? UserProfile(uid: uid);
        final name = (profile.displayName ?? '').trim().isEmpty ? 'Athlete' : profile.displayName!.trim();
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [cs.secondary.withValues(alpha: 0.20), cs.primary.withValues(alpha: 0.10)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: cs.secondaryContainer,
              child: Text(name.characters.first.toUpperCase(), style: text.titleLarge?.copyWith(color: cs.onSecondaryContainer, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Welcome back', maxLines: 1, overflow: TextOverflow.ellipsis, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text("Ready to crush today's workout?", maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodyMedium?.copyWith(color: Colors.white70)),
              ]),
            ),
            FilledButton.tonalIcon(
              onPressed: () => context.read<TabIndexProvider>().setIndex(1),
              icon: const Icon(Icons.fitness_center_rounded),
              label: const Text('Start'),
            ),
          ]),
        );
      },
    );
  }
}

class _BrandTitle extends StatelessWidget {
  const _BrandTitle();
  @override
  Widget build(BuildContext context) {
    // Use GoogleFonts if available; fall back gracefully
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    TextStyle base = theme.textTheme.titleLarge ?? const TextStyle(fontSize: 20);
    // Split-colored brand: "Force" in white (Bebas Neue), "Fitness" in orange (Oswald)
    final white = cs.onSurface;
    final orange = cs.secondary;
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(children: [
        TextSpan(
          text: 'Force ',
          style: GoogleFonts.bebasNeue(textStyle: base).copyWith(
            letterSpacing: 0.8,
            fontWeight: FontWeight.w800,
            color: white,
          ),
        ),
        TextSpan(
          text: 'Fitness',
          style: GoogleFonts.oswald(textStyle: base).copyWith(
            letterSpacing: 0.6,
            fontWeight: FontWeight.w700,
            color: orange,
          ),
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
      return _NutriRowOrWrap(children: const [
        _NutriCard(kind: _NutriKind.calories, value: 0, goal: 230),
        _NutriCard(kind: _NutriKind.protein, value: 0, goal: 392),
        _NutriCard(kind: _NutriKind.carbs, value: 0, goal: 480),
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
            return _NutriRowOrWrap(children: [
              _NutriCard(kind: _NutriKind.calories, value: kcal, goal: profile.dailyCaloriesGoal),
              _NutriCard(kind: _NutriKind.protein, value: protein, goal: profile.dailyProteinGoal),
              _NutriCard(kind: _NutriKind.carbs, value: carbs, goal: profile.dailyCarbsGoal),
            ]);
          },
        );
      },
    );
  }
}

enum _NutriKind { calories, protein, carbs }

class _NutriCard extends StatelessWidget {
  final _NutriKind kind;
  final int value;
  final int goal;
  const _NutriCard({required this.kind, required this.value, required this.goal});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final titles = {
      _NutriKind.calories: 'Calories',
      _NutriKind.protein: 'Proteins',
      _NutriKind.carbs: 'Carbs',
    };
    final unit = {
      _NutriKind.calories: 'Kcal',
      _NutriKind.protein: 'g',
      _NutriKind.carbs: 'g',
    };
    final icon = {
      _NutriKind.calories: Icons.local_fire_department_rounded,
      _NutriKind.protein: Icons.auto_awesome_rounded,
      _NutriKind.carbs: Icons.grain_rounded,
    };
    final bg = cs.surfaceContainerHighest;
    final primary = kind == _NutriKind.calories ? cs.error : (kind == _NutriKind.protein ? cs.primary : cs.tertiary);
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(radius: 14, backgroundColor: primary.withOpacity(0.2), child: Icon(icon[kind], color: primary, size: 18)),
          const SizedBox(width: 8),
          Flexible(child: Text(titles[kind]!, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.titleMedium)),
        ]),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('$value', style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(width: 4),
            Text(unit[kind]!, style: text.titleMedium?.copyWith(color: Colors.white70)),
          ]),
        ),
        const SizedBox(height: 6),
        Text('/ $goal ${unit[kind]}', style: text.bodySmall?.copyWith(color: Colors.white70)),
      ]),
    );
  }
}

class _NutriRowOrWrap extends StatelessWidget {
  final List<Widget> children;
  const _NutriRowOrWrap({required this.children});
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      // Use Wrap (2 columns) on narrow widths to prevent overflow, else 3 in a row
      if (c.maxWidth < 380) {
        final tileWidth = (c.maxWidth - 8) / 2; // two columns with 8px gap
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final w in children) SizedBox(width: tileWidth, child: w)],
        );
      }
      return Row(children: [
        Expanded(child: children[0]),
        const SizedBox(width: 8),
        Expanded(child: children[1]),
        const SizedBox(width: 8),
        Expanded(child: children[2]),
      ]);
    });
  }
}

class _CategoriesRow extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  const _CategoriesRow({required this.selectedIndex, required this.onChanged});
  static const cats = ['All','Chest','Back','Arms','Legs','Shoulders','Core','Full Body'];
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
                selected: selectedIndex==i,
                onSelected: (_) => onChanged(i),
              ),
            )
          ]),
        ),
      ),
      TextButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const WorkoutsCatalogScreen()),
        ),
        child: const Text('See All'),
      )
    ]);
  }
}

class _PopularCarousel extends StatelessWidget {
  final int categoryIndex; // index in cats above
  const _PopularCarousel({required this.categoryIndex});
  @override
  Widget build(BuildContext context) {
    final all = [
      WorkoutPreset('Shoulder Flex Stability','images/1.jpeg','Intermediate',45, 'Shoulders', steps: const [
        'Warm-up: band external rotations 2x15',
        'Overhead press 4x8',
        'Lateral raises 3x12',
        'Face pulls 3x15',
      ]),
      WorkoutPreset('Leg Poses','images/4.jpeg','Beginner',50, 'Legs', steps: const [
        'Bodyweight squats 3x12',
        'Lunges 3x10/leg',
        'Calf raises 3x15',
      ]),
      WorkoutPreset('Core Blast','images/5.jpeg','Intermediate',30, 'Core', steps: const [
        'Plank 3x45s',
        'Hanging knee raises 3x12',
        'Cable crunch 3x15',
      ]),
      WorkoutPreset('Chest Power','images/10.jpeg','Advanced',55, 'Chest', steps: const [
        'Bench press 5x5', 'Incline dumbbell press 3x10', 'Cable fly 3x12'
      ]),
      WorkoutPreset('Back Strength','images/7.jpeg','Intermediate',60, 'Back', steps: const [
        'Deadlift 5x3', 'Lat pulldown 4x10', 'Seated row 3x12'
      ]),
      WorkoutPreset('Arm Finisher','images/6.jpeg','Intermediate',25, 'Arms', steps: const [
        'Barbell curls 4x10', 'Rope pushdowns 4x12', 'Hammer curls 3x12'
      ]),
      WorkoutPreset('Full Body Ignite','images/2.jpeg','Beginner',40, 'Full Body', steps: const [
        'Goblet squat 3x12', 'Push-ups 3x12', 'Row machine 10 min'
      ]),
      WorkoutPreset('Pull Day','images/edgar-chaparro-sHfo3WOgGTU-unsplash.jpg','Intermediate',50, 'Back', steps: const [
        'Pull-ups 4xAMRAP', 'Barbell row 4x8', 'Rear delt fly 3x15'
      ]),
      WorkoutPreset('Push Day','images/brett-jordan-U2q73PfHFpM-unsplash.jpg','Intermediate',50, 'Chest', steps: const [
        'Bench press 4x8', 'OHP 4x8', 'Tricep dips 3x12'
      ]),
      WorkoutPreset('Arms & Abs','images/aaron-brogden-miCR9VIQ5PE-unsplash.jpg','Beginner',35, 'Arms', steps: const [
        'EZ curls 3x12', 'Overhead tricep ext 3x12', 'Planks 3x60s'
      ]),
    ];
  final filter = _CategoriesRow.cats[categoryIndex];
    final items = filter == 'All' ? all : all.where((e) => e.category == filter).toList();
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

// _PopularItem replaced by WorkoutPreset

class _PopularCard extends StatelessWidget {
  final WorkoutPreset item;
  const _PopularCard({required this.item});
  @override
  Widget build(BuildContext context) {
    return WorkoutCard(
      item: item,
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => _WorkoutDetailScreen(item: item),
      )),
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


class _WeeklyGoalCircles extends StatelessWidget {
  const _WeeklyGoalCircles();
  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider?>()?.uid;
    if (uid == null) return const SizedBox.shrink();
    final selected = context.watch<SelectedDateProvider>().day;
    final monday = DateTime(selected.year, selected.month, selected.day).subtract(Duration(days: (selected.weekday + 6) % 7));
    final nextMonday = monday.add(const Duration(days: 7));
    return StreamBuilder<UserProfile>(
      stream: UserProfileRepository().stream(uid),
      builder: (context, profSnap) {
        final profile = profSnap.data;
        if (profile == null) return const SizedBox.shrink();
        return StreamBuilder<List<StepsEntry>>(
          stream: StepsRepository().byRange(uid, monday, nextMonday),
          builder: (context, stepsSnap) {
            final stepsList = stepsSnap.data ?? const [];
            final weekSteps = stepsList.fold<int>(0, (s, e) => s + e.steps);
            return StreamBuilder<List<WorkoutSession>>(
              stream: WorkoutRepository().byRange(uid, monday, nextMonday),
              builder: (context, wSnap) {
                final workouts = wSnap.data ?? const [];
                final daysWithWorkout = workouts.map((w) => DateTime(w.date.year, w.date.month, w.date.day)).toSet().length;
                return StreamBuilder<List<WaterEntry>>(
                  stream: WaterRepository().byRange(uid, monday, nextMonday),
                  builder: (context, waterSnap) {
                    final waterList = waterSnap.data ?? const [];
                    final weekWater = waterList.fold<int>(0, (s, e) => s + e.ml);
                    return StreamBuilder<List<SleepEntry>>(
                      stream: SleepRepository().byRange(uid, monday, nextMonday),
                      builder: (context, sleepSnap) {
                        final sleepList = sleepSnap.data ?? const [];
                        final weekSleepMin = sleepList.fold<int>(0, (s, e) => s + e.minutes);
                        final stepsTarget = profile.dailyStepsTarget * 7;
                        final waterTarget = profile.dailyWaterTargetMl * 7;
                        final workoutTarget = profile.weeklyWorkoutTarget;
                        final sleepTarget = profile.dailySleepTargetMin * 7;
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Weekly Goals', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 12),
                              LayoutBuilder(builder: (context, c) {
                                final isNarrow = c.maxWidth < 380;
                                final size = isNarrow ? 90.0 : 110.0;
                                return Wrap(
                                  alignment: WrapAlignment.spaceEvenly,
                                  runSpacing: 12,
                                  spacing: 12,
                                  children: [
                                    _CircleGoal(label: 'Workouts', value: daysWithWorkout.toDouble(), target: workoutTarget.toDouble(), color: Theme.of(context).colorScheme.secondary, size: size, unit: 'days'),
                                    _CircleGoal(label: 'Steps', value: weekSteps.toDouble(), target: stepsTarget.toDouble(), color: Theme.of(context).colorScheme.primary, size: size, unit: 'steps', formatter: (v,t){
                                      final pct = (v/t).clamp(0.0, 1.0);
                                      final ks = (v/1000).toStringAsFixed(1);
                                      final kt = (t/1000).toStringAsFixed(1);
                                      return '${(pct*100).toStringAsFixed(0)}%\n${ks}k/${kt}k';
                                    }),
                                    _CircleGoal(label: 'Water', value: weekWater.toDouble(), target: waterTarget.toDouble(), color: Theme.of(context).colorScheme.tertiary, size: size, unit: 'ml', formatter: (v,t){
                                      final pct = (v/t).clamp(0.0, 1.0);
                                      final cups = (v/250).floor();
                                      final cupsT = (t/250).floor();
                                      return '${(pct*100).toStringAsFixed(0)}%\n$cups/$cupsT cups';
                                    }),
                                    _CircleGoal(label: 'Sleep', value: weekSleepMin.toDouble(), target: sleepTarget.toDouble(), color: Theme.of(context).colorScheme.inversePrimary, size: size, unit: 'min', formatter: (v,t){
                                      final pct = (v/t).clamp(0.0, 1.0);
                                      final h = (v/60).toStringAsFixed(1);
                                      final ht = (t/60).toStringAsFixed(1);
                                      return '${(pct*100).toStringAsFixed(0)}%\n$h/$ht h';
                                    }),
                                  ],
                                );
                              }),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.tonal(
                                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UserGoalsScreen())),
                                  child: const Text('Edit goals'),
                                ),
                              )
                            ]),
                          ),
                        );
                      },
                    );
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

class _CircleGoal extends StatefulWidget {
  final String label; final double value; final double target; final Color color; final double size; final String unit; final String Function(double,double)? formatter;
  const _CircleGoal({required this.label, required this.value, required this.target, required this.color, required this.size, required this.unit, this.formatter});
  @override
  State<_CircleGoal> createState() => _CircleGoalState();
}

class _CircleGoalState extends State<_CircleGoal> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }
  @override
  void didUpdateWidget(covariant _CircleGoal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.value/widget.target) != (oldWidget.value/oldWidget.target)) {
      _ctrl
        ..reset()
        ..forward();
    }
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final pct = widget.target <= 0 ? 0.0 : (widget.value / widget.target).clamp(0.0, 1.0);
    return Column(children: [
      SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _anim,
          builder: (_, __) {
            final prog = pct * _anim.value;
            return CustomPaint(
              painter: _RingPainter(progress: prog, color: widget.color, bg: Theme.of(context).colorScheme.surfaceContainerHighest),
              child: Center(
                child: Text(
                  widget.formatter != null ? widget.formatter!(widget.value, widget.target) : '${(prog*100).toStringAsFixed(0)}%\n${widget.value.toStringAsFixed(0)}/${widget.target.toStringAsFixed(0)}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 8),
      Text(widget.label, style: Theme.of(context).textTheme.bodyMedium),
    ]);
  }
}

class _RingPainter extends CustomPainter {
  final double progress; // 0..1
  final Color color; final Color bg;
  _RingPainter({required this.progress, required this.color, required this.bg});
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 10.0;
    final center = Offset(size.width/2, size.height/2);
    final radius = (size.width/2) - stroke/2;
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = bg;
    final fgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke
      ..color = color;
    canvas.drawCircle(center, radius, bgPaint);
    final sweep = 2 * 3.1415926535 * progress;
    final start = -3.1415926535/2;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, sweep, false, fgPaint);
  }
  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.color != color || oldDelegate.bg != bg;
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



class _QuickActions extends StatelessWidget {
  const _QuickActions();
  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider?>()?.uid;
    final selectedDay = context.watch<SelectedDateProvider>().day;
    final cards = <_ActionButton>[
      _ActionButton(icon: Icons.play_arrow_rounded, label: 'Start Workout', onTap: () => context.read<TabIndexProvider>().setIndex(1)),
      _ActionButton(icon: Icons.add, label: 'Add Set', onTap: () => context.read<TabIndexProvider>().setIndex(1)),
      _ActionButton(icon: Icons.restaurant_rounded, label: 'Add Food', onTap: () => context.read<TabIndexProvider>().setIndex(3)),
      _ActionButton(icon: Icons.list_alt_rounded, label: 'Routines', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RoutinesScreen()))),
  _ActionButton(icon: Icons.flag_rounded, label: 'Goals', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UserGoalsScreen()))),
      _ActionButton(icon: Icons.directions_walk_rounded, label: 'Add Steps', onTap: () async {
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
          // Persist for the currently selected day
          final d = DateTime(selectedDay.year, selectedDay.month, selectedDay.day, 12);
          await StepsRepository().add(uid, StepsEntry(id: '', date: d, steps: n));
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Steps added')));
        }
      }),
      _ActionButton(icon: Icons.opacity_rounded, label: 'Add Water', onTap: () async {
        if (uid == null) return;
        final controller = TextEditingController(text: '250');
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Add water (ml)'),
            content: TextField(controller: controller, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Milliliters')),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
            ],
          ),
        );
        if (ok == true) {
          final ml = int.tryParse(controller.text) ?? 250;
          final d = DateTime(selectedDay.year, selectedDay.month, selectedDay.day, 12);
          await WaterRepository().add(uid, WaterEntry(id: '', date: d, ml: ml));
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Water added')));
        }
      }),
      _ActionButton(icon: Icons.night_shelter_rounded, label: 'Log Sleep', onTap: () async {
        if (uid == null) return;
        final controller = TextEditingController(text: '420');
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Log sleep (minutes)'),
            content: TextField(controller: controller, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Minutes')),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
            ],
          ),
        );
        if (ok == true) {
          final mins = int.tryParse(controller.text) ?? 420;
          final d = DateTime(selectedDay.year, selectedDay.month, selectedDay.day, 12);
          await SleepRepository().add(uid, SleepEntry(id: '', date: d, minutes: mins));
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sleep logged')));
        }
      }),
    ];
    // Responsive grid for perfect alignment across devices
    return LayoutBuilder(builder: (context, c) {
      final width = c.maxWidth;
      // Fewer columns on smaller widths to avoid vertical overflow
      final columns = width >= 480 ? 5 : (width >= 400 ? 4 : 3);
      // More height on narrow screens so label fits
      final childAspect = width <= 380 ? 0.8 : (width < 440 ? 0.95 : 1.1); // width / height
      final bottomSafe = MediaQuery.of(context).viewPadding.bottom;
      return GridView.builder(
        itemCount: cards.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: 28 + bottomSafe),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: childAspect,
        ),
        itemBuilder: (context, i) => cards[i],
      );
    });
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
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 24),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
          ]),
        ),
      ),
    );
  }
}

class _WorkoutDetailScreen extends StatelessWidget {
  final WorkoutPreset item;
  const _WorkoutDetailScreen({required this.item});
  @override
  Widget build(BuildContext context) {
    final sampleTutorialImages = [
      'images/edgar-chaparro-sHfo3WOgGTU-unsplash.jpg',
      'images/brett-jordan-U2q73PfHFpM-unsplash.jpg',
      'images/aaron-brogden-miCR9VIQ5PE-unsplash.jpg',
    ];
    return Scaffold(
      appBar: AppBar(title: Text(item.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(item.image, height: 180, fit: BoxFit.cover),
          ),
          const SizedBox(height: 12),
          Text('${item.tag} • ${item.category} • ${item.minutes} min', style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 12),
          Text('How to do it', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...item.steps.map((s) => ListTile(
                leading: const Icon(Icons.check_circle_outline_rounded),
                title: Text(s),
              )),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TutorialViewerScreen(
                    tutorial: Tutorial(
                      id: item.title.replaceAll(' ', '_').toLowerCase(),
                      title: '${item.title} Tutorial',
                      description: 'Visual guide for ${item.title}',
                      imageUrls: sampleTutorialImages,
                    ),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.school_rounded),
            label: const Text('Open Tutorial Viewer'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {
              final specs = _presetToExercises(item);
              context.read<PendingWorkoutProvider>().setPending(specs);
              context.read<TabIndexProvider>().setIndex(1);
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Start in Logger'),
          )
        ],
      ),
    );
  }
}

// Maps curated presets to canonical exercise names with suggested set/rep schemes
List<PendingExerciseSpec> _presetToExercises(WorkoutPreset p) {
  List<PendingExerciseSpec> ex(String name, List<List<num>> sr) => [
        PendingExerciseSpec(
          name: name,
          sets: sr
              .map((e) => PendingSetSpec(kg: e.length > 1 ? (e[1] as num?)?.toDouble() : null, reps: e.first.toInt()))
              .toList(),
        )
      ];
  switch (p.title) {
    case 'Chest Power':
      return [
        ...ex('Bench Press', [[5, 0], [5, 0], [5, 0], [5, 0], [5, 0]]),
        ...ex('Incline Dumbbell Press', [[10], [10], [10]]),
        ...ex('Cable Fly', [[12], [12], [12]]),
      ];
    case 'Back Strength':
      return [
        ...ex('Deadlift', [[3], [3], [3], [3], [3]]),
        ...ex('Lat Pulldown', [[10], [10], [10], [10]]),
        ...ex('Seated Row', [[12], [12], [12]]),
      ];
    case 'Arm Finisher':
      return [
        ...ex('Barbell Curl', [[10], [10], [10], [10]]),
        ...ex('Triceps Pushdown', [[12], [12], [12], [12]]),
        ...ex('Hammer Curl', [[12], [12], [12]]),
      ];
    case 'Pull Day':
      return [
        ...ex('Pull-up', [[8], [8], [8], [8]]),
        ...ex('Barbell Row', [[8], [8], [8], [8]]),
        ...ex('Rear Delt Fly', [[15], [15], [15]]),
      ];
    case 'Push Day':
      return [
        ...ex('Bench Press', [[8], [8], [8], [8]]),
        ...ex('Overhead Press', [[8], [8], [8], [8]]),
        ...ex('Dip', [[12], [12], [12]]),
      ];
    case 'Full Body Ignite':
      return [
        ...ex('Goblet Squat', [[12], [12], [12]]),
        ...ex('Push-up', [[12], [12], [12]]),
        ...ex('Row Machine', [[600]]), // seconds
      ];
    case 'Shoulder Flex Stability':
      return [
        ...ex('Overhead Press', [[8], [8], [8], [8]]),
        ...ex('Lateral Raise', [[12], [12], [12]]),
        ...ex('Face Pull', [[15], [15], [15]]),
      ];
    case 'Core Blast':
      return [
        ...ex('Plank', [[45], [45], [45]]),
        ...ex('Hanging Knee Raise', [[12], [12], [12]]),
        ...ex('Cable Crunch', [[15], [15], [15]]),
      ];
    case 'Leg Poses':
      return [
        ...ex('Bodyweight Squat', [[12], [12], [12]]),
        ...ex('Lunge', [[10], [10], [10]]),
        ...ex('Calf Raise', [[15], [15], [15]]),
      ];
    case 'Arms & Abs':
      return [
        ...ex('EZ Bar Curl', [[12], [12], [12]]),
        ...ex('Overhead Tricep Extension', [[12], [12], [12]]),
        ...ex('Plank', [[60], [60], [60]]),
      ];
  }
  // Fallback: use title as single exercise
  return [PendingExerciseSpec(name: p.title)];
}
