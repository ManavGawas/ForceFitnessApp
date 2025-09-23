import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _uid;
  String? get uid => _uid;
  bool get isSignedIn => _uid != null;
  Object? _lastError;
  Object? get lastError => _lastError;

  AuthProvider() {
    _auth.authStateChanges().listen((u) {
      _uid = u?.uid;
      notifyListeners();
    }, onError: (e) {
      _lastError = e;
      notifyListeners();
    });
  }

}
