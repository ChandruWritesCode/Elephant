import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants.dart';

class AuthService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  AuthService._internal() {
    _dio.options.baseUrl = Env.httpBaseUrl;
  }

  String? _cachedAccessToken;
  String? _cachedRefreshToken;

  Future<void> initTokens() async {
    _cachedAccessToken = await _storage.read(key: "access_token");
    _cachedRefreshToken = await _storage.read(key: "refresh_token");
  }

  Future<String?> getToken() async => _cachedAccessToken;
  Future<String?> getRefreshToken() async => _cachedRefreshToken;

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    _cachedAccessToken = accessToken;
    _cachedRefreshToken = refreshToken;
    await _storage.write(key: "access_token", value: accessToken);
    await _storage.write(key: "refresh_token", value: refreshToken);
  }

  Future<void> logout() async {
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    await _storage.delete(key: "access_token");
    await _storage.delete(key: "refresh_token");
  }

  Future<Response> login(String username, String password) async {
    return await _dio.post(
      "/auth/login",
      data: {"username": username, "password": password},
    );
  }

  Future<Response> register(
    String username,
    String displayName,
    String password,
  ) async {
    return await _dio.post(
      "/auth/register",
      data: {
        "username": username,
        "display_name": displayName,
        "password": password,
      },
    );
  }

  Future<Response> refreshAccessToken(String refreshToken) async {
    return await _dio.post(
      "/auth/refresh",
      data: {"refresh_token": refreshToken},
    );
  }

  Future<Response> getCurrentUser(String token) async {
    return await _dio.get(
      '/users/me',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

}
