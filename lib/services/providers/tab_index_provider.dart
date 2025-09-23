import 'package:flutter/foundation.dart';

class TabIndexProvider extends ChangeNotifier {
  int _index = 0;
  int get index => _index;
  void setIndex(int i) {
    if (i == _index) return;
    _index = i;
    notifyListeners();
  }
}
