import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenRepository {
  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'auth_token';

  // Save the token
  Future<void> persistToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // Read the token
  Future<String?> readToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Delete the token (Log out)
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }
}
