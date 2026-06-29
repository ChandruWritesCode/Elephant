import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants.dart';

class AuthService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthService() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        options.baseUrl = Env.httpBaseUrl;
        return handler.next(options);
      },
    ));
  }

  Future<String?> getToken() async {
    return await _storage.read(key: "access_token");
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: "access_token", value: token);
  }

  Future<void> logout() async {
    await _storage.delete(key: "access_token");
  }

  Future<Response> login(String username, String password) async {
    return await _dio.post("/auth/login", data: {
      "username": username,
      "password": password,
    });
  }

  Future<Response> register(String username, String displayName, String password) async {
    return await _dio.post("/auth/register", data: {
      "username": username,
      "display_name": displayName,
      "password": password,
    });
  }
}