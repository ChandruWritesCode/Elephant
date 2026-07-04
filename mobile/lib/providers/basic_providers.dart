import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BasicProviders extends ChangeNotifier {
  String _phoneNumber = '';
  String _conCode = '';
  bool _isNumberValid = false;
  bool _hasLoggedIn = false;
  bool _isInitialized = false;

  bool _notificationsSwitch = false;

  bool get notificationsSwitch => _notificationsSwitch;

  void initNotificationsSwitch() async {
    final pref = await SharedPreferences.getInstance();
    _notificationsSwitch = pref.getBool('notificationToggle') ?? false;
    notifyListeners();
  }

  void toggleNotifications() async {
    _notificationsSwitch = !_notificationsSwitch;
    notifyListeners();

    final pref = await SharedPreferences.getInstance();
    pref.setBool('notificationToggle', _notificationsSwitch);
  }

  bool get isInitialized => _isInitialized;

  bool get hasLoggedIn => _hasLoggedIn;
  bool get isNumberValid => _isNumberValid;
  String get getCompleteNumber => '$_conCode $_phoneNumber';

  BasicProviders() {
    _loadLoginState();
  }

  Future<void> _loadLoginState() async {
    final pref = await SharedPreferences.getInstance();
    _hasLoggedIn = pref.getBool('hasLoggedIn') ?? false;
    _isInitialized = true;

    notifyListeners();
  }

  Future<void> logInSave() async {
    _hasLoggedIn = true;
    notifyListeners();

    final pref = await SharedPreferences.getInstance();
    await pref.setBool('hasLoggedIn', true);
  }

  Future<void> logOutSave() async {
    _hasLoggedIn = false;
    notifyListeners();

    final pref = await SharedPreferences.getInstance();
    await pref.setBool('hasLoggedIn', false);
  }

  void setNumberValid(bool val) {
    _isNumberValid = val;
    notifyListeners();
  }

  void updateNumber(String num) {
    _phoneNumber = num;
    notifyListeners();
  }

  void updateConCode(String val) {
    _conCode = val;
    notifyListeners();
  }
}
