import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../services/providers/auth_provider.dart';
import '../../services/repositories.dart';
import '../../models/run.dart';
import '../../models/pr.dart';

class RunTrackerScreen extends StatefulWidget {
  const RunTrackerScreen({super.key});
  @override
  State<RunTrackerScreen> createState() => _RunTrackerScreenState();
}

class _RunTrackerScreenState extends State<RunTrackerScreen> {
  StreamSubscription<Position>? _sub;
  DateTime? _start;
  int _durationSec = 0;
  double _distance = 0.0;
  Position? _last;
  final List<Map<String, double>> _path = [];
  Timer? _timer;

  Future<void> _startRun() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission perm = await Geolocator.checkPermission();
    if (!enabled || perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission required')));
        return;
      }
    }
    setState(() { _start = DateTime.now(); _durationSec = 0; _distance = 0; _last = null; _path.clear(); });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _durationSec++));
    _sub?.cancel();
    _sub = Geolocator.getPositionStream(locationSettings: const LocationSettings(accuracy: LocationAccuracy.best))
        .listen((pos) {
      if (_last != null) {
        _distance += Geolocator.distanceBetween(_last!.latitude, _last!.longitude, pos.latitude, pos.longitude);
      }
      _last = pos;
      _path.add({'lat': pos.latitude, 'lng': pos.longitude});
      setState(() {});
    });
  }

  Future<void> _stopRun() async {
    _timer?.cancel();
    await _sub?.cancel();
    final uid = context.read<AuthProvider?>()?.uid;
    if (uid != null && _start != null) {
      final run = RunSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        start: _start!,
        end: DateTime.now(),
        distanceMeters: _distance,
        durationSeconds: _durationSec,
        path: _path,
      );
      await RunRepository().save(uid, run);
      // Record PR for Running (by distance in km)
      try {
        final km = _distance / 1000.0;
        final currentBest = await PRRepository().bestForExercise(uid, 'Running Distance');
        final beats = currentBest == null || km > currentBest.weight || (km == currentBest.weight && _durationSec < currentBest.reps);
        if (beats) {
          await PRRepository().add(uid, PRRecord(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            exerciseId: 'running',
            exerciseName: 'Running Distance',
            date: DateTime.now(),
            weight: km,
            reps: _durationSec, // use reps field to store seconds for tie-break
          ));
        }
      } catch (_) {}
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Run saved')));
      setState(() { _start = null; _durationSec = 0; _distance = 0; _last = null; _path.clear(); });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = two(_durationSec ~/ 3600);
    final m = two((_durationSec % 3600) ~/ 60);
    final s = two(_durationSec % 60);
    final km = _distance / 1000.0;
    final pace = _distance > 0 ? Duration(seconds: (_durationSec / km).round()) : Duration.zero;
    final paceStr = _distance > 0 ? '${two(pace.inMinutes)}:${two(pace.inSeconds % 60)} /km' : '--';

    return Scaffold(
      appBar: AppBar(title: const Text('Run Tracker')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
            Expanded(child: Column(children: [
              const Text('Duration'),
              Text('$h:$m:$s', style: Theme.of(context).textTheme.headlineMedium),
            ])),
            Expanded(child: Column(children: [
              const Text('Distance'),
              Text('${km.toStringAsFixed(2)} km', style: Theme.of(context).textTheme.headlineMedium),
            ])),
            Expanded(child: Column(children: [
              const Text('Pace'),
              Text(paceStr, style: Theme.of(context).textTheme.headlineMedium),
            ])),
          ]))),
          const SizedBox(height: 12),
          Expanded(
            child: Card(
              child: Center(
                child: Text(_path.isEmpty ? 'GPS path will appear here' : 'Tracking... (${_path.length} pts)'),
              ),
            ),
          )
        ]),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _start == null ? _startRun : null,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _start != null ? _stopRun : null,
                icon: const Icon(Icons.stop_rounded),
                label: const Text('Stop'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
