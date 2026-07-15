import 'package:dio/dio.dart';

import '../auth/shared_auth_state.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      if (!sharedAuthState.isLoggingOut) {
        sharedAuthState.isLoggingOut = true;
        sharedAuthState.onUnauthorized?.call();
      }
      handler.next(err);
      return;
    }
    handler.next(err);
  }
}
