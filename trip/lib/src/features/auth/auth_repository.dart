import '../../services/api_client.dart';

class AuthRepository {
  final ApiClient _api;
  AuthRepository(this._api);

  Future<Map<String, dynamic>> login(String username, String password) async {
    final res = await _api.post(
      'auth/token/',
      data: {'username': username, 'password': password},
    );
    final data = Map<String, dynamic>.from(res.data as Map);
    _api.accessToken = data['access'];
    return data;
  }

  Future<Map<String, dynamic>> signup(String email, String password) async {
    final username = email; // minimal: use email as username
    final res = await _api.post(
      'auth/signup/',
      data: {'email': email, 'username': username, 'password': password},
    );
    return Map<String, dynamic>.from(res.data as Map);
  }
}
