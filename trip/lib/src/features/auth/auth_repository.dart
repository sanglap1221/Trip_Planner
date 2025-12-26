import '../../services/api_client.dart';

class AuthRepository {
  final ApiClient _api;
  String? _cachedAccessToken;

  AuthRepository(this._api);

  Future<Map<String, dynamic>> login(String username, String password) async {
    final res = await _api.post(
      'auth/token/',
      data: {'username': username, 'password': password},
    );
    final data = Map<String, dynamic>.from(res.data as Map);
    final accessToken = data['access'] as String;
    _api.accessToken = accessToken;
    _cachedAccessToken = accessToken;
    return data;
  }

  Future<void> logout() async {
    _api.accessToken = null;
    _cachedAccessToken = null;
  }

  Future<String?> getAccessToken() async {
    return _cachedAccessToken ?? _api.accessToken;
  }

  Future<Map<String, dynamic>> signup(String username, String password) async {
    // Convert username to valid email format for backend
    final email = '$username@tripplanner.local';
    final res = await _api.post(
      'auth/signup/',
      data: {'email': email, 'username': username, 'password': password},
    );
    return Map<String, dynamic>.from(res.data as Map);
  }
}
