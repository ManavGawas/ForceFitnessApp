import 'package:flutter/material.dart';
import 'services/firebase_service.dart';
import 'package:provider/provider.dart';
import 'services/providers/auth_provider.dart';
import 'services/providers/selected_date_provider.dart';
import 'services/providers/tab_index_provider.dart';
import 'ui/screens/auth/auth_gate.dart';
import 'ui/theme.dart';
import 'services/providers/pending_workout_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await FirebaseService.init();
  } catch (e) {
    // Allows the app to launch even if Firebase isn't configured yet.
    // Run `flutterfire configure` to generate firebase_options.dart then restart.
    debugPrint('Firebase initialization skipped: $e');
  }
  runApp(const GymMateApp());
}

class GymMateApp extends StatelessWidget {
  const GymMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SelectedDateProvider()),
        ChangeNotifierProvider(create: (_) => TabIndexProvider()),
        ChangeNotifierProvider(create: (_) => PendingWorkoutProvider()),
      ],
      child: MaterialApp(
        title: 'GymMate',
        theme: AppTheme.light(),
        debugShowCheckedModeBanner: false,
        home: const AuthGate(),
      ),
    );
  }
}
