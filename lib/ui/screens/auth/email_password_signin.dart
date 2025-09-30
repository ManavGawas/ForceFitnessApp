import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class EmailPasswordSignIn extends StatefulWidget {
  const EmailPasswordSignIn({super.key});

  @override
  State<EmailPasswordSignIn> createState() => _EmailPasswordSignInState();
}

class _EmailPasswordSignInState extends State<EmailPasswordSignIn> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isLogin = true;
  bool _busy = false;
  String? _error;
  StreamSubscription<User?>? _authSub;
  bool _resetSent = false;

  @override
  void initState() {
    super.initState();
    // Enable edge-to-edge so background extends under system bars
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    // When user signs in successfully, close this screen so AuthGate can show the app
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null && mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() { _busy = true; _error = null; });
    try {
      final auth = FirebaseAuth.instance;
      if (_isLogin) {
        await auth.signInWithEmailAndPassword(email: _email.text.trim(), password: _password.text);
      } else {
        // Clear any previous session to avoid redirecting into the last account
        await auth.signOut();
        final cred = await auth.createUserWithEmailAndPassword(email: _email.text.trim(), password: _password.text);
        // Seed a minimal profile so AuthGate downstream has data
        try {
          // ignore: use_build_context_synchronously
          final uid = cred.user?.uid;
          if (uid != null) {
            await FirebaseFirestore.instance.collection('users').doc(uid).set({
              'onboarded': false,
              'termsAccepted': false,
              'dailyCaloriesGoal': 2000,
              'dailyProteinGoal': 150,
              'dailyCarbsGoal': 300,
              'dailyFatsGoal': 70,
              'dailyStepsTarget': 8000,
              'dailyWaterTargetMl': 2000,
              'dailySleepTargetMin': 480,
              'weeklyWorkoutTarget': 5,
            }, SetOptions(merge: true));
          }
        } catch (_) {}
      }
    } on FirebaseAuthException catch (e) {
      setState(() { _error = e.message ?? e.code; });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _busy = false; });
    }
  }

  Future<void> _sendReset() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() { _error = 'Enter your email to reset password.'; });
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) setState(() { _resetSent = true; _error = null; });
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() { _error = e.message ?? e.code; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
      extendBody: true,
      body: Stack(children: [
        Positioned.fill(child: Image.asset(
          'images/charles-gaudreault-xXofYCc3hqc-unsplash.jpg',
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (ctx, err, st) => Container(color: Colors.black54),
        )),
        Positioned.fill(child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x99000000), Color(0xCC000000)],
            ),
          ),
        )),
        SafeArea(
          top: true,
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 16 - 16,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
              const SizedBox(height: 24),
              Text('Sign in to your\nAccount', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
        Text('Train your mind. Your body will follow.', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70)),
        const SizedBox(height: 8),
        Text('Login with the following methods', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 16),
              Center(
                child: _GoogleButton(onPressed: _busy ? null : _googleSignIn),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: Divider(color: Colors.white24)),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('OR')),
                Expanded(child: Divider(color: Colors.white24)),
              ]),
              const SizedBox(height: 16),
              _FieldContainer(child: TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(prefixIcon: Icon(Icons.email_outlined), hintText: 'Email'))),
              const SizedBox(height: 12),
              _FieldContainer(child: TextField(controller: _password, obscureText: true, decoration: const InputDecoration(prefixIcon: Icon(Icons.lock_outline), hintText: 'Password'))),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _busy ? null : _sendReset,
                  child: const Text('Forgot password?'),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              ],
              if (_resetSent) ...[
                const SizedBox(height: 4),
                const Text('Reset link sent. Check your email.', style: TextStyle(color: Colors.lightGreenAccent)),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: cs.secondary, foregroundColor: Colors.black, shape: const StadiumBorder()),
                  onPressed: _busy ? null : _submit,
                  child: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Text(_isLogin ? 'Login' : 'Create Account'),
                ),
              ),
              TextButton(
                onPressed: _busy ? null : () => setState(() => _isLogin = !_isLogin),
                child: Text(_isLogin ? 'New here? Create account' : 'Have an account? Sign in'),
              ),
              const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ]),
    ));
  }

  Future<void> _googleSignIn() async {
    setState(() => _busy = true);
    try {
      // Ensure no lingering sessions
      await FirebaseAuth.instance.signOut();
      final gs = GoogleSignIn();
      try { await gs.disconnect(); } catch (_) {}
      try { await gs.signOut(); } catch (_) {}
      final googleUser = await gs.signIn();
      if (googleUser == null) return; // canceled
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? e.code);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _FieldContainer extends StatelessWidget {
  final Widget child;
  const _FieldContainer({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: child,
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const _GoogleButton({required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white24),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
        child: Center(
          child: Image.asset(
            'assets/google.png',
            width: 16,
            height: 16,
            fit: BoxFit.contain,
            errorBuilder: (ctx, err, st) => Text('G', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
      label: const Text('Continue with Google'),
    );
  }
}

// Removed legacy _SocialIcon widget; Google button above is clearer and accessible.
