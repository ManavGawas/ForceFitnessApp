import 'package:flutter/foundation.dart';

class PendingSetSpec {
  final double? kg;
  final int reps;
  final String? type; // normal/warmup/etc.
  const PendingSetSpec({this.kg, required this.reps, this.type});
}

class PendingExerciseSpec {
  final String name;
  final List<PendingSetSpec> sets;
  const PendingExerciseSpec({required this.name, this.sets = const []});
}

class PendingWorkoutProvider extends ChangeNotifier {
  List<PendingExerciseSpec>? _pending;

  void setPending(List<PendingExerciseSpec> items) {
    _pending = List<PendingExerciseSpec>.from(items);
    notifyListeners();
  }

  List<PendingExerciseSpec>? takePending() {
    final tmp = _pending;
    _pending = null;
    if (tmp != null) notifyListeners();
    return tmp;
  }
}
