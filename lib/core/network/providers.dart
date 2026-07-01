import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_service.dart';
import 'real_api_service.dart';
import 'network_checker.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return RealApiService();
});

final networkCheckerProvider = Provider<NetworkChecker>((ref) {
  return NetworkChecker();
});
