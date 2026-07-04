import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../services/auth.dart';

class AuthState extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  static VoidCallback? onGlobalUnauthorized;

  AuthState() {
    onGlobalUnauthorized = logoutSilently;
  }

  Future<String?> checkAutoLogin() async {
    _token = await _storage.read(key: "access_token");
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
    await _authService.logout();
    notifyListeners();
  }

  void logoutSilently() {
    if (_token != null) {
      _token = null;
      _authService.logout();
      notifyListeners();
    }
  }
}
