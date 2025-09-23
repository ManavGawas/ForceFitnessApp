import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/providers/auth_provider.dart';
import '../root_shell.dart';
import 'email_password_signin.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider?>()?.uid;
    if (uid == null) return const EmailPasswordSignIn();
    return const RootShell();
  }
}
