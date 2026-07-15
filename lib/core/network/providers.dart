import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_config.dart';
import 'api_service.dart';
import 'auth_interceptor.dart';
import 'real_api_service.dart';
import 'network_checker.dart';

final _authInterceptor = AuthInterceptor();

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${ApiConfig.staticBearerToken}',
    },
  ));
  dio.interceptors.add(_authInterceptor);
  return dio;
});

final apiServiceProvider = Provider<ApiService>((ref) {
  final service = RealApiService();
  service.addInterceptor(_authInterceptor);
  return service;
});

final networkCheckerProvider = Provider<NetworkChecker>((ref) {
  return NetworkChecker();
});
