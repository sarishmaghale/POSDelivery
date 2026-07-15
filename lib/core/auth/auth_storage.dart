import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _tokenKey = 'auth_final_token';
const _baseUrlKey = 'auth_base_url';

const _storage = FlutterSecureStorage();

Future<String?> getSavedToken() async {
  return _storage.read(key: _tokenKey);
}

Future<String?> getSavedBaseUrl() async {
  return _storage.read(key: _baseUrlKey);
}

Future<void> saveAuthData({
  required String token,
  required String baseUrl,
}) async {
  await _storage.write(key: _tokenKey, value: token);
  await _storage.write(key: _baseUrlKey, value: baseUrl);
}

Future<void> clearAuthData() async {
  await _storage.delete(key: _tokenKey);
  await _storage.delete(key: _baseUrlKey);
}

Future<bool> hasSavedAuth() async {
  final token = await _storage.read(key: _tokenKey);
  return token != null && token.isNotEmpty;
}
