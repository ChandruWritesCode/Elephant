import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BasicProviders extends ChangeNotifier {
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

}
