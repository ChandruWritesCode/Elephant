import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../controllers/auth.dart';
import 'auth.dart';

class ApiService {
  final Dio _dio = Dio();
  final AuthService _auth = AuthService();

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
            final refreshToken = await _auth.getRefreshToken();

            if (refreshToken != null) {
              try {
                final refreshResponse = await _auth.refreshAccessToken(
                  refreshToken,
                );
                final resData = refreshResponse.data;

                if (resData['success'] == true) {
                  final newAccessToken = resData['data']['access_token'];
                  final newRefreshToken = resData['data']['refresh_token'];

                  await _auth.saveTokens(newAccessToken, newRefreshToken);

                  final cloneOptions = e.requestOptions;
                  cloneOptions.headers["Authorization"] =
                      "Bearer $newAccessToken";

                  final retryResponse = await _dio.fetch(cloneOptions);
                  return handler.resolve(retryResponse);
                }
              } catch (refreshError) {
                if (AuthState.onGlobalUnauthorized != null) {
                  AuthState.onGlobalUnauthorized!();
                }
                return handler.next(e);
              }
            }

            if (AuthState.onGlobalUnauthorized != null) {
              AuthState.onGlobalUnauthorized!();
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  Future<Response> getConversations() async {
    return await _dio.get("/messages/conversations");
  }

  Future<Response> getChatHistory(String partnerId, {String? before}) async {
    final Map<String, dynamic> params = {"with": partnerId, "limit": 40};
    if (before != null) params["before"] = before;
    return await _dio.get("/messages", queryParameters: params);
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
}
