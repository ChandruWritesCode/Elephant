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
}
