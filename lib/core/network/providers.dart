import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_config.dart';
import 'api_service.dart';
import 'real_api_service.dart';
import 'network_checker.dart';

final dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${ApiConfig.staticBearerToken}',
    },
  ));
});

final apiServiceProvider = Provider<ApiService>((ref) {
  return RealApiService();
});

final networkCheckerProvider = Provider<NetworkChecker>((ref) {
  return NetworkChecker();
});
