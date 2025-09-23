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

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});
  @override
  Widget build(BuildContext context) {
  final uid = context.watch<local_auth.AuthProvider?>()?.uid;
    return Scaffold(
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
                  children: [
                    ListTile(
                      leading: const Icon(Icons.badge_rounded),
                      title: const Text('UID'),
                      subtitle: Text(uid),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.settings_rounded),
                      title: const Text('Settings'),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => SettingsScreen(initial: profile)),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.military_tech_rounded),
                      title: const Text('PR Tracker'),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PRTrackerScreen()),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.show_chart_rounded),
                      title: const Text('Progress Charts'),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ProgressChartsScreen()),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.insights_rounded),
                      title: const Text('Progress Hub'),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ProgressHubScreen()),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.calendar_view_week_rounded),
                      title: const Text('Weekly Split Planner'),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SplitPlannerScreen()),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.person_search_rounded),
                      title: const Text('Coaches'),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CoachesScreen()),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.group_rounded),
                      title: const Text('Community & Social'),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SocialScreen()),
                      ),
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
  late TextEditingController calGoal;
  late TextEditingController proteinGoal;

  @override
  void initState() {
    super.initState();
    usesKg = widget.initial.usesKg;
    calGoal = TextEditingController(text: widget.initial.dailyCaloriesGoal.toString());
    proteinGoal = TextEditingController(text: widget.initial.dailyProteinGoal.toString());
  }

  @override
  void dispose() {
    calGoal.dispose();
    proteinGoal.dispose();
    super.dispose();
  }

  Future<void> _save() async {
  final uid = context.read<local_auth.AuthProvider?>()?.uid;
    if (uid == null) return;
    final updated = UserProfile(
      uid: uid,
      dailyCaloriesGoal: int.tryParse(calGoal.text) ?? widget.initial.dailyCaloriesGoal,
      dailyProteinGoal: int.tryParse(proteinGoal.text) ?? widget.initial.dailyProteinGoal,
      usesKg: usesKg,
    );
    await UserProfileRepository().update(uid, updated);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
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
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save_rounded), label: const Text('Save')),
        ],
      ),
    );
  }
}
