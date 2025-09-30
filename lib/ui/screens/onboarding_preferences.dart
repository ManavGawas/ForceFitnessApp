import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/providers/auth_provider.dart' as local_auth;
import '../../services/repositories.dart';
import '../../models/user_profile.dart';
import '../../models/split.dart';

class OnboardingPreferencesScreen extends StatefulWidget {
  const OnboardingPreferencesScreen({super.key});
  @override
  State<OnboardingPreferencesScreen> createState() => _OnboardingPreferencesScreenState();
}

class _OnboardingPreferencesScreenState extends State<OnboardingPreferencesScreen> {
  int _step = 0; // 0=name,1=goal,2=activities,3=frequency
  final _nameCtrl = TextEditingController();
  String? _goal;
  final Set<String> _activities = {};
  int _freq = 3; // days/week

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferences'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.black26,
              boxShadow: [BoxShadow(color: cs.secondary.withOpacity(0.2), blurRadius: 8, spreadRadius: 1)],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              child: LinearProgressIndicator(
                value: (_step + 1) / 4,
                color: cs.secondary,
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (_step == 0) ..._buildNameStep(context)
          else if (_step == 1) ..._buildGoalStep(context)
          else if (_step == 2) ..._buildActivitiesStep(context)
          else ..._buildFrequencyStep(context),
          const Spacer(),
          Row(children: [
            TextButton(onPressed: _step == 0 ? null : () => setState(() => _step -= 1), child: const Text('Back')),
            const Spacer(),
            FilledButton(
              onPressed: () async {
                if (_step < 3) {
                  setState(() => _step += 1);
                } else {
                  await _finalize(context);
                }
              },
              child: Text(_step < 3 ? 'Next' : 'Finish'),
            )
          ])
        ]),
      ),
    );
  }

  List<Widget> _buildNameStep(BuildContext context) {
    return [
      Text("What should we call you?", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      TextField(
        controller: _nameCtrl,
        autofocus: true,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(hintText: 'Enter your name or nickname'),
      ),
      const SizedBox(height: 8),
      const Text('We will use this name across your dashboard and profile.'),
    ];
  }

  List<Widget> _buildGoalStep(BuildContext context) {
    final options = ['Weight Loss', 'Build Muscle', 'Improve Endurance', 'Enhance Flexibility', 'General Fitness'];
    return [
      Text('What are your fitness goals?', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      Text('Select one option.'),
      const SizedBox(height: 12),
      ...options.map((o) => _SelectTile(title: o, selected: _goal == o, onTap: () => setState(() => _goal = o))),
    ];
  }

  List<Widget> _buildActivitiesStep(BuildContext context) {
    final chips = ['Running', 'Weightlifting', 'HIIT', 'Boot Camp', 'Walking', 'Cycling', 'Yoga', 'Pilates', 'Swimming', 'Home Workouts', 'Dance', 'Community Workouts', 'Other'];
    return [
      Text('What types of activities do you enjoy?', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      Text('Select all that apply.'),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final c in chips)
          ChoiceChip(
            label: Text(c),
            selected: _activities.contains(c),
            onSelected: (v) => setState(() => v ? _activities.add(c) : _activities.remove(c)),
          )
      ])
    ];
  }

  List<Widget> _buildFrequencyStep(BuildContext context) {
    final opts = [1, 2, 3, 4, 5, 6, 7];
    return [
      Text('How often do you want to workout?', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      Text('Select one option.'),
      const SizedBox(height: 12),
      ...opts.map((n) => _SelectTile(title: n == 1 ? '1 Day' : '$n Days', subtitle: n <= 2 ? 'Ease into your routine.' : (n <= 4 ? 'Steady progress.' : 'Advanced training.'), selected: _freq == n, onTap: () => setState(() => _freq = n)))
    ];
  }

  Future<void> _finalize(BuildContext context) async {
    // Save to user profile and seed split/nutrition suggestions
  final uid = context.read<local_auth.AuthProvider?>()?.uid;
    if (uid != null) {
      final displayName = _nameCtrl.text.trim();
      final baseline = _goal == 'Weight Loss'
          ? 1800
          : _goal == 'Build Muscle'
              ? 2600
              : 2200;
      final protein = _goal == 'Build Muscle' ? 170 : 140;
      await UserProfileRepository().update(uid, UserProfile(
        uid: uid,
        displayName: displayName.isEmpty ? null : displayName,
        dailyCaloriesGoal: baseline,
        dailyProteinGoal: protein,
        onboarded: true,
        termsAccepted: true,
      ));
      // Try to reflect name in FirebaseAuth profile too (best-effort)
      try {
        if (displayName.isNotEmpty) {
          await FirebaseAuth.instance.currentUser?.updateDisplayName(displayName);
        }
      } catch (_) {}

      // Seed split based on goal
      final map = <int, List<String>>{};
      if ((_goal ?? '').contains('Muscle')) {
        map[1] = ['Bench Press', 'Incline Dumbbell Press', 'Cable Fly'];
        map[3] = ['Deadlift', 'Lat Pulldown', 'Seated Row'];
        map[5] = ['Squat', 'Leg Press', 'Leg Curl'];
      } else if ((_goal ?? '').contains('Endurance')) {
        map[2] = ['Row Machine', 'Push-up', 'Goblet Squat'];
        map[4] = ['Run 30 min', 'Plank', 'Lunge'];
        map[6] = ['Cycling 30 min', 'Hanging Knee Raise', 'Face Pull'];
      } else {
        map[1] = ['Full Body Circuit'];
        map[3] = ['Full Body Circuit'];
        map[5] = ['Full Body Circuit'];
      }
      await SplitRepository().create(uid, SplitPlan(id: '', name: 'Suggested Plan', days: map, active: true));
    }
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}

class _SelectTile extends StatelessWidget {
  final String title; final String? subtitle; final bool selected; final VoidCallback onTap;
  const _SelectTile({required this.title, this.subtitle, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: selected ? cs.secondary : Colors.white12, width: selected ? 1.4 : 1),
        boxShadow: [if (selected) BoxShadow(color: cs.secondary.withOpacity(0.15), blurRadius: 12, spreadRadius: 1)],
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: selected ? cs.secondary : null)),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? cs.secondary : Colors.white54),
      ),
    );
  }
}
