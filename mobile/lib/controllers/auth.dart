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

      if (dataMap is Map) {
        if (dataMap['success'] == true) {
          String? extractedToken;

          if (dataMap['data'] != null && dataMap['data'] is Map) {
            final dataEnv = dataMap['data'];
            if (dataEnv['tokens'] != null && dataEnv['tokens'] is Map) {
              extractedToken = dataEnv['tokens']['access_token'];
            }
          }

          if (extractedToken != null) {
            _token = extractedToken;
            await _storage.write(key: "access_token", value: _token);
            _isLoading = false;
            notifyListeners();
            return true;
          }
        }
        _errorMessage =
            dataMap['error'] ?? dataMap['message'] ?? "Authentication failed";
      } else {
        _errorMessage = "Unexpected server payload architecture structure.";
      }
    } on DioException catch (e) {
      dynamic responseData = e.response?.data;
      if (responseData is String) {
        try {
          responseData = jsonDecode(responseData);
        } catch (_) {}
      }

      if (responseData is Map) {
        _errorMessage =
            responseData['error'] ??
            responseData['message'] ??
            "Server validation failed.";
      } else {
        _errorMessage =
            "Server error code: ${e.response?.statusCode ?? 'unknown'}.";
      }
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

    String? finalUsername;
    bool registerSuccess = false;

    try {
      final res = await _authService.register(username, displayName, password);

      dynamic dataMap = res.data;
      if (dataMap is String) {
        try {
          dataMap = jsonDecode(dataMap);
        } catch (_) {}
      }

      if (dataMap is Map) {
        if (dataMap['success'] == true) {
          String? extractedToken;

          if (dataMap['data'] != null && dataMap['data'] is Map) {
            final dataEnv = dataMap['data'];
            if (dataEnv['tokens'] != null && dataEnv['tokens'] is Map) {
              extractedToken = dataEnv['tokens']['access_token'];
            }
            if (dataEnv['user'] != null && dataEnv['user'] is Map) {
              finalUsername = dataEnv['user']['username'];
            }
          }

          if (extractedToken != null) {
            _token = extractedToken;
            await _storage.write(key: "access_token", value: _token);
            _isLoading = false;
            notifyListeners();
            return true;
          }

          registerSuccess = true;
        } else {
          _errorMessage =
              dataMap['error'] ?? dataMap['message'] ?? "Registration failed";
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }
    } on DioException catch (e) {
      dynamic responseData = e.response?.data;
      if (responseData is String) {
        try {
          responseData = jsonDecode(responseData);
        } catch (_) {}
      }
      if (responseData is Map) {
        _errorMessage =
            responseData['error'] ??
            responseData['message'] ??
            "Registration rejected.";
      } else {
        _errorMessage =
            "Registration server error: ${e.response?.statusCode ?? 'unknown'}.";
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = "Server error occurred during sign up";
      _isLoading = false;
      notifyListeners();
      return false;
    }

    if (registerSuccess) {
      try {
        final String targetUsername = finalUsername ?? username;
        final loginRes = await _authService.login(targetUsername, password);

        dynamic loginData = loginRes.data;
        if (loginData is String) {
          try {
            loginData = jsonDecode(loginData);
          } catch (_) {}
        }

        if (loginData is Map && loginData['success'] == true) {
          String? loginToken;
          if (loginData['data'] != null && loginData['data'] is Map) {
            final dataEnv = loginData['data'];
            if (dataEnv['tokens'] != null && dataEnv['tokens'] is Map) {
              loginToken = dataEnv['tokens']['access_token'];
            }
          }

          if (loginToken != null) {
            _token = loginToken;
            await _storage.write(key: "access_token", value: _token);
            _isLoading = false;
            notifyListeners();
            return true;
          }
        }
        _errorMessage =
            "Account created successfully as $targetUsername! Please log in manually.";
      } catch (e) {
        _errorMessage = "Profile configured! Please switch tabs to log in.";
      }
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _token = null;
    await _storage.delete(key: "access_token");
    notifyListeners();
  }

  void logoutSilently() {
    if (_token != null) {
      _token = null;
      _storage.delete(key: "access_token");
      notifyListeners();
    }
  }
}
