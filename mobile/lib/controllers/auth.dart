import 'package:flutter/material.dart';
import '../services/auth.dart';

class AuthState extends ChangeNotifier {
  final AuthService _authService = AuthService();
  bool isLoading = false;
  String? errorMessage;

  Future<String?> checkAutoLogin() async {
    return await _authService.getToken();
  }

  Future<bool> handleLogin(String username, String password) async {
    errorMessage = null;
    _setLoading(true);
    try {
      final response = await _authService.login(username, password);
      if (response.data['success'] == true) {
        final token = response.data['data']['tokens']['access_token'];
        if (token != null) {
          await _authService.saveToken(token);
          _setLoading(false);
          return true;
        }
      }
      errorMessage = response.data['error'] ?? "Authentication failed";
    } catch (e) {
      errorMessage = "Connection parsing error occurred";
    }
    _setLoading(false);
    return false;
  }

 
  Future<String?> handleRegister(String username, String displayName, String password) async {
    errorMessage = null;
    _setLoading(true);
    try {
      final response = await _authService.register(username, displayName, password);
      if (response.data['success'] == true) {
        final token = response.data['data']['tokens']['access_token'];
        final String? assignedUsername = response.data['data']['user']['username'];
        
        if (token != null && assignedUsername != null) {
          await _authService.saveToken(token);
          _setLoading(false);
          return assignedUsername;
        }
      }
      errorMessage = response.data['error'] ?? "Registration failed";
    } catch (e) {
      errorMessage = "Server error occurred during sign up";
    }
    _setLoading(false);
    return null;
  }

  Future<void> handleLogout() async {
    await _authService.logout();
    notifyListeners();
  }

  void _setLoading(bool val) {
    isLoading = val;
    notifyListeners();
  }
}