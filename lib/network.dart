import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'secureStorage.dart';

// final String host = 'http://13.51.197.245';
final String host =
    'https://14df-2409-4088-be81-b9f5-9fc8-e50a-acae-6b3e.ngrok-free.app';
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: '$host/api/v1',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  final tokenRepository = TokenRepository();

  dio.interceptors.add(AuthInterceptor(tokenRepository));

  // Add auth interceptor to set stored Bearer token
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await TokenRepository().readToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ),
  );

  // Add logging interceptor for easier debugging
  dio.interceptors.add(
    LogInterceptor(
      requestHeader: true,
      requestBody: true,
      responseHeader: false,
      responseBody: true,
      error: true,
    ),
  );

  return dio;
});

class AuthInterceptor extends Interceptor {
  final TokenRepository _tokenRepository;

  AuthInterceptor(this._tokenRepository);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 1. Fetch the token from secure storage
    final token = await _tokenRepository.readToken();

    // 2. If the token exists, attach it to the headers
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // 3. Continue the request pipeline
    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      await _tokenRepository.deleteToken();
      // Navigation logic would be triggered here via a global navigator key or event bus
    }
    return super.onError(err, handler);
  }

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    // 1. Ensure data is a Map before extracting the token
    if (response.data is Map<String, dynamic>) {
      final token = response.data['token'];

      // 2. Persist it if it exists and is a String
      if (token != null && token is String) {
        await _tokenRepository.persistToken(token);
      }
    }
    // 3. Handle unauthorized response
    if (response.statusCode == 401) {
      await _tokenRepository.deleteToken();
    }

    // 4. CRITICAL: Always forward the response to the app!
    return handler.next(response);
  }
}
