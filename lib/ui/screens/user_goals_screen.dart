import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_profile.dart';
import '../../services/providers/auth_provider.dart';
import '../../services/repositories.dart';

class UserGoalsScreen extends StatefulWidget {
  const UserGoalsScreen({super.key});
  @override
  State<UserGoalsScreen> createState() => _UserGoalsScreenState();
}

class _UserGoalsScreenState extends State<UserGoalsScreen> {
  late TextEditingController cal;
  late TextEditingController protein;
  late TextEditingController carbs;
  late TextEditingController fats;
  late TextEditingController steps;
  late TextEditingController water;
  late TextEditingController sleep;
  late TextEditingController weeklyWorkouts;

  @override
  void dispose() {
    cal.dispose(); protein.dispose(); carbs.dispose(); fats.dispose(); steps.dispose(); water.dispose(); sleep.dispose(); weeklyWorkouts.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider?>()?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('Sign in to manage goals')));
    return StreamBuilder<UserProfile>(
      stream: UserProfileRepository().stream(uid),
      builder: (context, snap) {
        final p = snap.data;
        if (p == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        cal = TextEditingController(text: p.dailyCaloriesGoal.toString());
        protein = TextEditingController(text: p.dailyProteinGoal.toString());
        carbs = TextEditingController(text: p.dailyCarbsGoal.toString());
        fats = TextEditingController(text: p.dailyFatsGoal.toString());
        steps = TextEditingController(text: p.dailyStepsTarget.toString());
        water = TextEditingController(text: p.dailyWaterTargetMl.toString());
        sleep = TextEditingController(text: p.dailySleepTargetMin.toString());
        weeklyWorkouts = TextEditingController(text: p.weeklyWorkoutTarget.toString());
        return Scaffold(
          appBar: AppBar(title: const Text('Goals')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _goalField('Daily calories', cal, 'kcal'),
              _goalField('Daily protein', protein, 'g'),
              _goalField('Daily carbs', carbs, 'g'),
              _goalField('Daily fats', fats, 'g'),
              _goalField('Daily steps', steps, 'steps'),
              _goalField('Daily water', water, 'ml'),
              _goalField('Daily sleep', sleep, 'min'),
              _goalField('Weekly workouts', weeklyWorkouts, 'days'),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () async {
                  final updated = UserProfile(
                    uid: p.uid,
                    displayName: p.displayName,
                    bodyWeightKg: p.bodyWeightKg,
                    dailyCaloriesGoal: int.tryParse(cal.text) ?? p.dailyCaloriesGoal,
                    dailyProteinGoal: int.tryParse(protein.text) ?? p.dailyProteinGoal,
                    dailyCarbsGoal: int.tryParse(carbs.text) ?? p.dailyCarbsGoal,
                    dailyFatsGoal: int.tryParse(fats.text) ?? p.dailyFatsGoal,
                    dailyStepsTarget: int.tryParse(steps.text) ?? p.dailyStepsTarget,
                    dailyWaterTargetMl: int.tryParse(water.text) ?? p.dailyWaterTargetMl,
                    dailySleepTargetMin: int.tryParse(sleep.text) ?? p.dailySleepTargetMin,
                    weeklyWorkoutTarget: int.tryParse(weeklyWorkouts.text) ?? p.weeklyWorkoutTarget,
                    usesKg: p.usesKg,
                    onboarded: p.onboarded,
                    termsAccepted: p.termsAccepted,
                  );
                  final repo = UserProfileRepository();
                  await repo.update(p.uid, updated);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Goals updated')));
                },
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save'),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _goalField(String label, TextEditingController c, String unit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label, suffixText: unit),
      ),
    );
  }
}
