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

  set accessToken(String? token) {
    _accessToken = token;
  }

  Future<Response<dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
  }) {
    return _dio.post(
      path,
      data: data,
      queryParameters: query,
      options: _authOptions(),
    );
  }

  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? query}) {
    return _dio.get(path, queryParameters: query, options: _authOptions());
  }

  Options _authOptions() => Options(
    headers: _accessToken == null
        ? null
        : {'Authorization': 'Bearer $_accessToken'},
  );
}
