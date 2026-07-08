import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../controllers/auth.dart';
import 'auth.dart';

class ApiService {
  final Dio _dio = Dio();
  final AuthService _auth = AuthService();

  Future<void>? _refreshFuture;

  ApiService() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.baseUrl = Env.httpBaseUrl;
          final token = await _auth.getToken();
          if (token != null) {
            options.headers["Authorization"] = "Bearer $token";
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            try {
              _refreshFuture ??= _refreshToken();
              await _refreshFuture;

              final clone = e.requestOptions;
              clone.headers["Authorization"] =
                  "Bearer ${await _auth.getToken()}";

              final retry = await _dio.fetch(clone);
              return handler.resolve(retry);
            } catch (refreshError) {
              AuthState.onGlobalUnauthorized?.call();
              rethrow;
            } finally {
              _refreshFuture = null;
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  Future<void> _refreshToken() async {
    final refreshToken = await _auth.getRefreshToken();

    if (refreshToken == null) {
      throw Exception("No refresh token");
    }

    final response = await _auth.refreshAccessToken(refreshToken);
    final data = response.data;

    if (data["success"] != true) {
      throw Exception("Refresh failed");
    }

    await _auth.saveTokens(
      data["data"]["access_token"],
      data["data"]["refresh_token"],
    );
  }

  Future<Response> getConversations() async {
    return await _dio.get("/messages/conversations");
  }

  Future<Response> getChatHistory(
    String targetId, {
    String? before,
    bool isGroup = false,
  }) async {
    final Map<String, dynamic> params = {"limit": 40};
    if (before != null) params["before"] = before;

    if (isGroup) {
      return await _dio.get(
        "/groups/$targetId/messages",
        queryParameters: params,
      );
    } else {
      params["with"] = targetId;
      return await _dio.get("/messages", queryParameters: params);
    }
  }

  Future<Response> getGroupMembers(String groupId) async {
    try {
      return await _dio.get("/groups/$groupId/members");
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> searchUsers(String query) async {
    return await _dio.get(
      "/users/search",
      queryParameters: {
        "q": query,
        "query": query,
        "search": query,
        "keyword": query,
        "username": query,
        "searchTerm": query,
      },
    );
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return await _dio.post(path, data: data, queryParameters: queryParameters);
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return await _dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
    );
  }
}
