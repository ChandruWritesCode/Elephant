import 'package:flutter/material.dart';

class BasicProviders extends ChangeNotifier {
  String _phoneNumber = '';
  String _conCode = '';
  bool _isNumberValid = false;

  void setNumberValid(bool val) {
    _isNumberValid = val;
    notifyListeners();
  }

  bool get isNumberValid => _isNumberValid;
  String get getCompleteNumber => '$_conCode $_phoneNumber';

  void updateNumber(String num) {
    _phoneNumber = num;
    notifyListeners();
  }

  void updateConCode(String val) {
    _conCode = val;
    notifyListeners();
  }
}
