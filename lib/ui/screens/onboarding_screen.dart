import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth/email_password_signin.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  final _slides = const [
    'images/mob-alizadeh-93or5BgHobk-unsplash.jpg',
    'images/edgar-chaparro-sHfo3WOgGTU-unsplash.jpg',
    'images/anastase-maragos-7kEpUPB8vNk-unsplash.jpg',
    'images/sushil-ghimire-5UbIqV58CW8-unsplash.jpg',
  ];
  final _titles = const [
    'Fitness, Just the\nWay You Like It.',
    'Train Smarter, Not Harder.',
    'Fuel Your Progress.',
    'Own Your Routine.'
  ];
  final _subtitles = const [
    'Tailored routines and tools to crush your goals.',
    'Guided plans and trackers keep you on target.',
    'Log meals fast with barcodes, grams, and goals.',
    'Build splits, track PRs, and see results.'
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Stack(children: [
        PageView.builder(
          controller: _controller,
          itemCount: _slides.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (ctx, i) {
            return Stack(children: [
              Positioned.fill(
                child: Image.asset(_slides[i], fit: BoxFit.cover),
              ),
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87],
                    ),
                  ),
                ),
              ),
              // Place title/subtitle just above the footer dots/CTA
              Positioned(
                left: 20,
                right: 20,
                bottom: 140, // keep comfortably above the dots & buttons
                child: SafeArea(
                  top: false,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      _titles[i],
                      style: GoogleFonts.bebasNeue(
                        textStyle: const TextStyle(fontSize: 46, height: 1.0),
                      ).copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _subtitles[i],
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                    ),
                  ]),
                ),
              ),
            ]);
          },
        ),
        // Pinned footer: dots + arrow/CTA + terms
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    for (int d = 0; d < _slides.length; d++) ...[
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(right: 6),
                        height: 6,
                        width: _index == d ? 28 : 8,
                        decoration: BoxDecoration(
                          color: _index == d ? cs.secondary : Colors.white30,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      )
                    ]
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    // Skip for now (left)
                    if (_index < _slides.length - 1)
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const EmailPasswordSignIn()),
                        ),
                        child: const Text('Skip for now'),
                      )
                    else
                      const SizedBox.shrink(),
                    const Spacer(),
                    Expanded(
                      child: _index == _slides.length - 1
                          ? ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: cs.secondary,
                                foregroundColor: Colors.black,
                                shape: const StadiumBorder(),
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const EmailPasswordSignIn()),
                                );
                              },
                              icon: const Icon(Icons.double_arrow_rounded),
                              label: const Text('Get Started'),
                            )
                          : Align(
                              alignment: Alignment.centerRight,
                              child: IconButton.filledTonal(
                                onPressed: () => _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
                                icon: const Icon(Icons.arrow_forward_rounded),
                              ),
                            ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Icon(Icons.check_box_rounded, size: 18, color: cs.secondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'I have read and agree to the terms and conditions.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                      ),
                    )
                  ])
                ],
              ),
            ),
          ),
        )
      ]),
    );
  }
}
