import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _tokenKey = 'auth_final_token';
const _baseUrlKey = 'auth_base_url';
const _customerIdKey = 'auth_customer_id';
const _driverIdKey = 'auth_driver_id';

const _storage = FlutterSecureStorage();

Future<String?> getSavedToken() async {
  return _storage.read(key: _tokenKey);
}

Future<String?> getSavedBaseUrl() async {
  return _storage.read(key: _baseUrlKey);
}

Future<String?> getSavedCustomerId() async {
  return _storage.read(key: _customerIdKey);
}

Future<String?> getSavedDriverId() async {
  return _storage.read(key: _driverIdKey);
}

Future<void> saveAuthData({
  required String token,
  required String baseUrl,
  String? customerId,
  String? driverId,
}) async {
  await _storage.write(key: _tokenKey, value: token);
  await _storage.write(key: _baseUrlKey, value: baseUrl);
  if (customerId != null) {
    await _storage.write(key: _customerIdKey, value: customerId);
  }
  if (driverId != null) {
    await _storage.write(key: _driverIdKey, value: driverId);
  }
}

Future<void> clearAuthData() async {
  await _storage.delete(key: _tokenKey);
  await _storage.delete(key: _baseUrlKey);
  await _storage.delete(key: _customerIdKey);
  await _storage.delete(key: _driverIdKey);
}

Future<bool> hasSavedAuth() async {
  final token = await _storage.read(key: _tokenKey);
  return token != null && token.isNotEmpty;
}
