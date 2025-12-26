import 'package:dio/dio.dart';

class ApiClient {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://10.0.2.2:8000/api/',
      ),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );

  String? _accessToken;

  ApiClient({String? initialToken}) {
    _accessToken = initialToken;
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Always include token if available
          if (_accessToken != null) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          // Pass error up - caller will handle 401
          return handler.next(error);
        },
      ),
    );
  }

  // ignore: unnecessary_getters_setters
  set accessToken(String? token) {
    _accessToken = token;
  }

  // ignore: unnecessary_getters_setters
  String? get accessToken => _accessToken;

  Future<Response<dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
  }) {
    return _dio.post(path, data: data, queryParameters: query);
  }

  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? query}) {
    return _dio.get(path, queryParameters: query);
  }
}
