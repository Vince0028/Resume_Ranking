import 'package:flutter/material.dart';
import '../models/models.dart';

class AppProvider with ChangeNotifier {
  // User Profile State
  UserProfile _userProfile = UserProfile.empty();

  UserProfile get userProfile => _userProfile;

  void updateUserProfile(UserProfile newProfile) {
    _userProfile = newProfile;
    notifyListeners();
  }

  // Theme State
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  // Friends List State
  final List<Friend> _friends = [];

  List<Friend> get friends => List.unmodifiable(_friends);

  void addFriend(Friend friend) {
    _friends.add(friend);
    notifyListeners();
  }

  void updateFriend(String id, Friend updatedFriend) {
    final index = _friends.indexWhere((f) => f.id == id);
    if (index != -1) {
      _friends[index] = updatedFriend;
      notifyListeners();
    }
  }

  void deleteFriend(String id) {
    _friends.removeWhere((f) => f.id == id);
    notifyListeners();
  }
}
