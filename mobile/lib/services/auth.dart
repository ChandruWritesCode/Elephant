import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants.dart';
import '../controllers/auth.dart';

class AuthService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthService() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.baseUrl = Env.httpBaseUrl;
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          if (e.response?.statusCode == 401) {
            if (AuthState.onGlobalUnauthorized != null) {
              AuthState.onGlobalUnauthorized!();
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  Future<String?> getToken() async {
    return await _storage.read(key: "access_token");
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: "refresh_token");
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: "access_token", value: accessToken);
    await _storage.write(key: "refresh_token", value: refreshToken);
  }

  Future<void> logout() async {
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
