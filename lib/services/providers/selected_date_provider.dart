import 'package:flutter/foundation.dart';

class SelectedDateProvider extends ChangeNotifier {
  DateTime _day = DateTime.now();
  DateTime get day => DateTime(_day.year, _day.month, _day.day);
  void setDay(DateTime d) {
    _day = d;
    notifyListeners();
  }
}
