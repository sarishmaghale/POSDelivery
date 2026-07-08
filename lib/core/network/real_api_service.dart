import 'package:dio/dio.dart';

import '../../../dto/dashboard_response.dart';
import '../../../dto/delivery_request.dart';
import '../../../dto/delivery_response.dart';
import '../../../dto/estimate_request.dart';
import '../../../dto/estimate_response.dart';
import '../../../dto/sales_invoice_request.dart';
import '../../../dto/sales_invoice_response.dart';
import 'api_config.dart';
import 'api_service.dart';
import 'mock_api_service.dart';

class RealApiService implements ApiService {
  late final Dio _dio;
  final MockApiService _fallback;

  RealApiService()
      : _fallback = MockApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      headers: {
        'Authorization': 'Bearer ${ApiConfig.staticBearerToken}',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
  }

  Future<List<Map<String, dynamic>>> _fetchList(String endpoint) async {
    final response = await _dio.get(endpoint);
    final body = response.data as Map<String, dynamic>;
    if (body['Status'] != true) {
      throw Exception(body['Message'] ?? 'API returned status false');
    }
    final data = body['Data'];
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchCategories({
    required String customerId,
    required String transactionDate,
  }) async {
    return _fetchList(
      '${ApiConfig.categoryEndpoint}?customerId=$customerId&transactionDate=$transactionDate',
    );
  }

  @override
  Future<DashboardResponse> fetchDashboard() => _fallback.fetchDashboard();

  @override
  Future<List<Map<String, dynamic>>> fetchCustomers() async {
    try {
      final url = '${_dio.options.baseUrl}${ApiConfig.customerEndpoint}';
      print('[API] Calling: $url?customernamesearch=');
      final response = await _dio.get(
        ApiConfig.customerEndpoint,
        queryParameters: {'customernamesearch': ''},
      );
      print('[API] Response status: ${response.statusCode}');
      print('[API] Response body: ${response.data}');
      final body = response.data as Map<String, dynamic>;
      final status = body['Status'] ?? body['status'] ?? false;
      if (status != true) {
        throw Exception(body['Message'] ?? body['message'] ?? 'API returned status false');
      }
      final data = body['Data'] ?? body['data'] ?? [];
      if (data is List) {
        print('[API] Got ${data.length} customers');
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('[API] ERROR: $e');
      print('[API] Falling back to mock');
      return _fallback.fetchCustomers();
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchProducts({
    required String customerId,
    required String transactionDate,
  }) async {
    try {
      final response = await _dio.get(
        ApiConfig.productEndpoint,
        queryParameters: {
          'customerId': customerId,
          'transactionDate': transactionDate,
        },
      );
      final body = response.data as Map<String, dynamic>;
      if (body['Status'] != true) {
        throw Exception(body['Message'] ?? 'API returned status false');
      }
      final data = body['Data'];
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return _fallback.fetchProducts(
        customerId: customerId,
        transactionDate: transactionDate,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> fetchDriver() => _fallback.fetchDriver();

  @override
  Future<List<Map<String, dynamic>>> fetchStock() => _fallback.fetchStock();

  @override
  Future<List<Map<String, dynamic>>> fetchPaymentModes() =>
      _fallback.fetchPaymentModes();

  @override
  Future<DeliveryResponse> createDelivery(DeliveryRequest request) =>
      _fallback.createDelivery(request);

  @override
  Future<EstimateResponse> createEstimate(EstimateRequest request) =>
      _fallback.createEstimate(request);

  @override
  Future<bool> createSalesReturn(Map<String, dynamic> data) =>
      _fallback.createSalesReturn(data);

  @override
  Future<bool> syncData(Map<String, dynamic> payload) =>
      _fallback.syncData(payload);

  @override
  Future<SalesInvoiceResponse> createSalesInvoice(SalesInvoiceRequest request) async {
    try {
      final response = await _dio.post(
        ApiConfig.salesInvoiceAddEndpoint,
        data: request.toJson(),
      );
      final body = response.data as Map<String, dynamic>;
      return SalesInvoiceResponse.fromJson(body);
    } catch (_) {
      return _fallback.createSalesInvoice(request);
    }
  }
}
