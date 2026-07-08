import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:mobile/models/user.dart';
import '../services/auth.dart';

class AuthState extends ChangeNotifier {
  final AuthService _authService = AuthService();

  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? _currentUser;

  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  UserModel? get currentUser => _currentUser;

  static VoidCallback? onGlobalUnauthorized;

  AuthState() {
    onGlobalUnauthorized = logoutSilently;
  }

  Future<void> loadUserProfile() async {
    if (_token == null) return;

    try {
      final res = await _authService.getCurrentUser(_token!);
      final data = res.data;

      final userData = data['data'] ?? data['user'] ?? data;

      _currentUser = UserModel.fromJson(userData);
      notifyListeners();
    } catch (e) {
      debugPrint("Failed to load user profile: $e");
    }
  }

  Future<String?> checkAutoLogin() async {
    _token = await _authService.getToken();

    if (_token != null) {
      await loadUserProfile();
    }

    notifyListeners();
    return _token;
  }

  Future<bool> handleLogin(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _authService.login(username, password);
      dynamic dataMap = res.data;

      if (dataMap is String) {
        try {
          dataMap = jsonDecode(dataMap);
        } catch (_) {}
      }

      if (dataMap is Map && dataMap['success'] == true) {
        Map<String, dynamic>? tokens = dataMap['data']?['tokens'];
        if (tokens != null &&
            tokens['access_token'] != null &&
            tokens['refresh_token'] != null) {
          _token = tokens['access_token'];
          await _authService.saveTokens(
            tokens['access_token'],
            tokens['refresh_token'],
          );

          await loadUserProfile();

          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
      _errorMessage =
          dataMap['error'] ?? dataMap['message'] ?? "Authentication failed";
    } on DioException catch (e) {
      _errorMessage = e.response?.data?['error'] ?? "Server validation failed.";
    } catch (e) {
      _errorMessage = "Connection parsing error occurred";
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> handleRegister(
    String username,
    String displayName,
    String password,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _authService.register(username, displayName, password);
      dynamic dataMap = res.data;

      if (dataMap is String) {
        try {
          dataMap = jsonDecode(dataMap);
        } catch (_) {}
      }

      if (dataMap is Map && dataMap['success'] == true) {
        Map<String, dynamic>? tokens = dataMap['data']?['tokens'];
        if (tokens != null &&
            tokens['access_token'] != null &&
            tokens['refresh_token'] != null) {
          _token = tokens['access_token'];
          await _authService.saveTokens(
            tokens['access_token'],
            tokens['refresh_token'],
          );

          await loadUserProfile();

          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
      _errorMessage = dataMap['error'] ?? "Registration failed";
    } on DioException catch (e) {
      _errorMessage = e.response?.data?['error'] ?? "Registration rejected.";
    } catch (e) {
      _errorMessage = "Server error occurred during sign up";
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    await _authService.logout();
    notifyListeners();
  }

  void logoutSilently() {
    if (_token != null) {
      _token = null;
      _currentUser = null;
      _authService.logout();
      notifyListeners();
    }
  }
}
