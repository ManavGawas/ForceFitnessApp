import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/providers/auth_provider.dart';
import '../root_shell.dart';
import '../onboarding_screen.dart';
import '../onboarding_preferences.dart';
import '../../../services/repositories.dart';
import '../../../models/user_profile.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider?>()?.uid;
    if (uid == null) return const OnboardingScreen();
    return StreamBuilder<UserProfile>(
      stream: UserProfileRepository().stream(uid),
      builder: (context, snap) {
        final p = snap.data;
        if (p == null) return const SizedBox.shrink();
        if (!p.onboarded) return const OnboardingPreferencesScreen();
        return const RootShell();
      },
    );
  }
}
