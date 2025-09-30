import 'package:flutter/material.dart';
import '../app_routes.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool agreed = true;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Stack(children: [
        Positioned.fill(child: Image.asset('images/3.webp', fit: BoxFit.cover)),
  Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0.55))),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Spacer(),
              Text('Fitness, Just the\nWay You Like It.',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 40, height: 1.05)),
              const SizedBox(height: 8),
              const Text('Tailored routines, exciting moves, and the tools to crush your goals—every step of the way.'),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: agreed ? () => Navigator.pushReplacementNamed(context, AppRoutes.home) : null,
                    icon: const Icon(Icons.double_arrow_rounded),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text('Get Started'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Checkbox(value: agreed, onChanged: (v) => setState(() => agreed = v ?? false)),
                const SizedBox(width: 6),
                const Expanded(child: Text('I have read and agree to the terms and conditions.'))
              ])
            ]),
          ),
        ),
      ]),
    );
  }
}
