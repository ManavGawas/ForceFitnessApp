import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  Future<void> _submit() async {
    setState(() { _busy = true; _error = null; });
    try {
      final auth = FirebaseAuth.instance;
      if (_isLogin) {
        await auth.signInWithEmailAndPassword(email: _email.text.trim(), password: _password.text);
      } else {
        await auth.createUserWithEmailAndPassword(email: _email.text.trim(), password: _password.text);
      }
    } on FirebaseAuthException catch (e) {
      setState(() { _error = e.message ?? e.code; });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _busy = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Text('GymMate', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 12),
                  // Google Sign-In
                  OutlinedButton.icon(
                    icon: Image.asset('assets/google.png', width: 18, height: 18, filterQuality: FilterQuality.medium),
                    label: const Text('Continue with Google'),
                    onPressed: _busy ? null : () async {
                      setState(() => _busy = true);
                      try {
                        final googleUser = await GoogleSignIn().signIn();
                        if (googleUser == null) return; // canceled
                        final googleAuth = await googleUser.authentication;
                        final credential = GoogleAuthProvider.credential(
                          accessToken: googleAuth.accessToken,
                          idToken: googleAuth.idToken,
                        );
                        await FirebaseAuth.instance.signInWithCredential(credential);
                      } catch (e) {
                        setState(() => _error = e.toString());
                      } finally {
                        if (mounted) setState(() => _busy = false);
                      }
                    },
                  ),
                  const SizedBox(height: 6),
                  TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
                  const SizedBox(height: 8),
                  TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Text(_isLogin ? 'Sign In' : 'Create Account'),
                    ),
                  ),
                  TextButton(
                    onPressed: _busy ? null : () => setState(() => _isLogin = !_isLogin),
                    child: Text(_isLogin ? 'New here? Create account' : 'Have an account? Sign in'),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
