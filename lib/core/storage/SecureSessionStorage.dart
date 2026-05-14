import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureSessionStorage {
  static const String _tokenKey = 'mecanaut_token';
  static const String _userJsonKey = 'mecanaut_user';
  static const String _userIdKey = 'mecanaut_user_id';
  static const String _usernameKey = 'mecanaut_username';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> clearToken() => _storage.delete(key: _tokenKey);

  Future<void> saveUserJson(String json) =>
      _storage.write(key: _userJsonKey, value: json);

  Future<String?> readUserJson() => _storage.read(key: _userJsonKey);

  Future<void> clearUserJson() => _storage.delete(key: _userJsonKey);

  Future<void> saveUserId(int id) =>
      _storage.write(key: _userIdKey, value: id.toString());

  Future<int?> readUserId() async {
    final value = await _storage.read(key: _userIdKey);
    if (value == null || value.isEmpty) return null;
    return int.tryParse(value);
  }

  Future<void> clearUserId() => _storage.delete(key: _userIdKey);

  Future<void> saveUsername(String username) =>
      _storage.write(key: _usernameKey, value: username);

  Future<String?> readUsername() => _storage.read(key: _usernameKey);

  Future<void> clearUsername() => _storage.delete(key: _usernameKey);

  Future<void> clearLegacyKeys() async {
    const legacyKeys = <String>[
      'token',
      'authToken',
      'jwt',
      'accessToken',
      'user',
      'userId',
      'username',
      'profile',
    ];
    await Future.wait(legacyKeys.map((key) => _storage.delete(key: key)));
  }

  Future<void> clearAll() async {
    await Future.wait(<Future<void>>[
      clearToken(),
      clearUserJson(),
      clearUserId(),
      clearUsername(),
    ]);
    await clearLegacyKeys();
  }
}
