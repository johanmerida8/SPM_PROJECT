import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationProvider with ChangeNotifier {
  bool _notificationsEnabled = true;

  NotificationProvider() {
    loadPreference();
  }

  bool get notificationsEnabled => _notificationsEnabled;

  void openNotificationSettings() async {
    await savePreference();
    notifyListeners();
  }

  void toggleNotifications() async{
    _notificationsEnabled = !_notificationsEnabled;
    await savePreference();
    notifyListeners();

    openNotificationSettings();
  }

  Future<void> loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
  }

  Future<void> savePreference() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('notificationsEnabled', _notificationsEnabled);
  }
}