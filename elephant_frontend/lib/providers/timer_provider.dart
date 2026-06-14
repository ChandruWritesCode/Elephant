import 'dart:async';

import 'package:flutter/material.dart';

class OtpProvider extends ChangeNotifier {
  int _secondsRemaining = 60;
  String _otp = '';
  Timer? _timer;

  int get secondsRemaining => _secondsRemaining;
  bool get canResend => _secondsRemaining == 0;
  String get otp => _otp;
  bool get isOtpComplete => _otp.length == 6;

  void updateOtp(String value) {
    _otp = value;
    notifyListeners();
  }

  void startTimer() {
    _timer?.cancel();

    _secondsRemaining = 60;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        _secondsRemaining--;
        notifyListeners();
      } else {
        timer.cancel();
      }
    });
  }

  void resetTimer() {
    startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
