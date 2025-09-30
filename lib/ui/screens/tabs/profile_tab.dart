import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../services/providers/auth_provider.dart' as local_auth;
import '../../../services/repositories.dart';
import '../../../models/user_profile.dart';
import '../pr_tracker_screen.dart';
import '../progress_charts_screen.dart';
import '../split_planner_screen.dart';
import '../coaches.dart';
import '../progress_hub_screen.dart';
import '../social_screen.dart';
import '../../widgets/branded_scaffold.dart';
import '../user_goals_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});
  @override
  Widget build(BuildContext context) {
  final uid = context.watch<local_auth.AuthProvider?>()?.uid;
    return BrandedScaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          )
        ],
      ),
      body: uid == null
          ? const Center(child: Text('Not signed in'))
          : StreamBuilder<UserProfile>(
              stream: UserProfileRepository().stream(uid),
              builder: (context, snapshot) {
                final profile = snapshot.data ?? UserProfile(uid: uid);
                return ListView(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                  children: [
                    // Header card with avatar, display, quick stats
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                          CircleAvatar(
                            radius: 28,
                            child: Text(
                              (() {
                                final dn = (profile.displayName ?? '').trim();
                                if (dn.isEmpty) return 'U';
                                return dn.characters.first.toUpperCase();
                              })(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Builder(builder: (context) {
                                final fbName = FirebaseAuth.instance.currentUser?.displayName;
                                final name = (profile.displayName ?? fbName ?? '').trim().isEmpty
                                    ? 'Athlete'
                                    : (profile.displayName ?? fbName!) .trim();
                                return Text(name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700));
                              }),
                              const SizedBox(height: 4),
                              Text('Let’s make today count.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
                            ]),
                          ),
                          FilledButton.tonal(
                            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SettingsScreen(initial: profile))),
                            child: const Text('Edit'),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Quick links grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.7,
                      children: [
                        _QuickTile(icon: Icons.military_tech_rounded, title: 'PR Tracker', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PRTrackerScreen()))),
                        _QuickTile(icon: Icons.show_chart_rounded, title: 'Progress Charts', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProgressChartsScreen()))),
                        _QuickTile(icon: Icons.insights_rounded, title: 'Progress Hub', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProgressHubScreen()))),
                        _QuickTile(icon: Icons.calendar_view_week_rounded, title: 'Split Planner', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SplitPlannerScreen()))),
                        _QuickTile(icon: Icons.flag_rounded, title: 'Goals', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UserGoalsScreen()))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Community section
                    Card(
                      child: Column(children: [
                        const ListTile(leading: Icon(Icons.people_alt_rounded), title: Text('Community & Coaching')), const Divider(height: 1),
                        ListTile(leading: const Icon(Icons.person_search_rounded), title: const Text('Coaches'), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CoachesScreen()))),
                        ListTile(leading: const Icon(Icons.group_rounded), title: const Text('Community & Social'), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SocialScreen()))),
                      ]),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  final UserProfile initial;
  const SettingsScreen({super.key, required this.initial});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool usesKg;
  late TextEditingController displayName;
  late TextEditingController calGoal;
  late TextEditingController proteinGoal;
  late TextEditingController carbsGoal;
  late TextEditingController fatsGoal;
  late TextEditingController stepsTarget;
  late TextEditingController waterTarget;

  @override
  void initState() {
    super.initState();
    usesKg = widget.initial.usesKg;
    final fbName = FirebaseAuth.instance.currentUser?.displayName;
    displayName = TextEditingController(text: widget.initial.displayName ?? fbName ?? '');
    calGoal = TextEditingController(text: widget.initial.dailyCaloriesGoal.toString());
    proteinGoal = TextEditingController(text: widget.initial.dailyProteinGoal.toString());
    carbsGoal = TextEditingController(text: widget.initial.dailyCarbsGoal.toString());
    fatsGoal = TextEditingController(text: widget.initial.dailyFatsGoal.toString());
    stepsTarget = TextEditingController(text: widget.initial.dailyStepsTarget.toString());
    waterTarget = TextEditingController(text: widget.initial.dailyWaterTargetMl.toString());
  }

  @override
  void dispose() {
    displayName.dispose();
    calGoal.dispose();
    proteinGoal.dispose();
    carbsGoal.dispose();
    fatsGoal.dispose();
    stepsTarget.dispose();
    waterTarget.dispose();
    super.dispose();
  }

  Future<void> _save() async {
  final uid = context.read<local_auth.AuthProvider?>()?.uid;
    if (uid == null) return;
    final updated = UserProfile(
      uid: uid,
      displayName: displayName.text.trim().isEmpty ? widget.initial.displayName : displayName.text.trim(),
      dailyCaloriesGoal: int.tryParse(calGoal.text) ?? widget.initial.dailyCaloriesGoal,
      dailyProteinGoal: int.tryParse(proteinGoal.text) ?? widget.initial.dailyProteinGoal,
      dailyCarbsGoal: int.tryParse(carbsGoal.text) ?? widget.initial.dailyCarbsGoal,
      dailyFatsGoal: int.tryParse(fatsGoal.text) ?? widget.initial.dailyFatsGoal,
      dailyStepsTarget: int.tryParse(stepsTarget.text) ?? widget.initial.dailyStepsTarget,
      dailyWaterTargetMl: int.tryParse(waterTarget.text) ?? widget.initial.dailyWaterTargetMl,
      usesKg: usesKg,
    );
    await UserProfileRepository().update(uid, updated);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return BrandedScaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: displayName,
              decoration: const InputDecoration(labelText: 'Display name'),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: usesKg,
            onChanged: (v) => setState(() => usesKg = v),
            title: const Text('Use kilograms (kg)'),
            subtitle: const Text('Off = pounds (lb)'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: calGoal,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Daily calories goal'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: proteinGoal,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Daily protein goal (g)'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: carbsGoal,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Daily carbs goal (g)'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: fatsGoal,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Daily fats goal (g)'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: stepsTarget,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Daily steps target'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: waterTarget,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Daily water target (ml)'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save_rounded), label: const Text('Save')),
        ],
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  final IconData icon; final String title; final VoidCallback onTap;
  const _QuickTile({required this.icon, required this.title, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            CircleAvatar(child: Icon(icon)), const SizedBox(width: 10),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14)
          ]),
        ),
      ),
    );
  }
}
