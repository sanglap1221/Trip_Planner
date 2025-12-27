import 'package:dio/dio.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiClient {
  late final Dio _dio;

  String? _accessToken;

  ApiClient({String? initialToken}) {
    _accessToken = initialToken;
    _dio = Dio(
      BaseOptions(
        baseUrl: _buildBaseUrl(),
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );
    _setupInterceptors();
  }

  String _buildBaseUrl() {
    // Priority 1: explicit --dart-define override
    final defined = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: '',
    );
    if (defined.isNotEmpty) {
      return _normalizeUrl(defined);
    }

    // Priority 2: auto-detect platform
    String defaultUrl;
    if (kIsWeb) {
      // Chrome web and desktop web: use localhost
      defaultUrl = 'http://localhost:8000/api/';
    } else if (Platform.isAndroid) {
      // Android emulator: use 10.0.2.2 (emulator gateway)
      // Physical Android device: requires --dart-define API_BASE_URL=http://YOUR_MACHINE_IP:8000/api/
      defaultUrl = 'http://10.0.2.2:8000/api/';
    } else if (Platform.isIOS) {
      // iOS simulator and physical device: use localhost for simulator
      // Physical device: requires --dart-define API_BASE_URL=http://YOUR_MACHINE_IP:8000/api/
      defaultUrl = 'http://localhost:8000/api/';
    } else {
      // Fallback for other platforms (Windows, macOS, Linux desktop)
      defaultUrl = 'http://localhost:8000/api/';
    }

    return _normalizeUrl(defaultUrl);
  }

  String _normalizeUrl(String raw) {
    final uri = Uri.parse(raw);

    final scheme = uri.scheme.isEmpty ? 'http' : uri.scheme;
    final host = uri.host;
    final port = uri.hasPort ? uri.port : null;
    var path = uri.path;

    if (!path.endsWith('/')) {
      path = '$path/';
    }
    if (path.isEmpty || path == '/' || path == '//') {
      path = '/api/';
    }
    if (path == '/api') {
      path = '/api/';
    }

    final normalized = Uri(
      scheme: scheme,
      host: host,
      port: port,
      path: path,
    ).toString();
    return normalized;
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Ensure Content-Type is set to application/json for POST requests with data
          if (options.method == 'POST' && options.data != null) {
            options.headers['Content-Type'] = 'application/json';
          }
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

  String? get baseUrl => _dio.options.baseUrl;

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
