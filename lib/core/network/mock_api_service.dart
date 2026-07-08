import 'dart:convert';
import 'package:flutter/services.dart';

import '../../dto/dashboard_response.dart';
import '../../dto/delivery_request.dart';
import '../../dto/delivery_response.dart';
import '../../dto/estimate_request.dart';
import '../../dto/estimate_response.dart';
import '../../dto/sales_invoice_request.dart';
import '../../dto/sales_invoice_response.dart';
import 'api_service.dart';

class MockApiService implements ApiService {
  Future<Map<String, dynamic>> _loadJson(String path) async {
    final data = await rootBundle.loadString(path);
    return json.decode(data) as Map<String, dynamic>;
  }

  Future<List<dynamic>> _loadJsonList(String path) async {
    final data = await rootBundle.loadString(path);
    return json.decode(data) as List<dynamic>;
  }

  @override
  Future<DashboardResponse> fetchDashboard() async {
    await Future.delayed(const Duration(milliseconds: 800));
    final json = await _loadJson('assets/dummy/dashboard.json');
    return DashboardResponse.fromJson(json);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchCustomers() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final list = await _loadJsonList('assets/dummy/customers.json');
    return list.cast<Map<String, dynamic>>();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchCategories({
    required String customerId,
    required String transactionDate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final list = await _loadJsonList('assets/dummy/categories.json');
    return list.cast<Map<String, dynamic>>();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchProducts({
    required String customerId,
    required String transactionDate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final list = await _loadJsonList('assets/dummy/products.json');
    return list.cast<Map<String, dynamic>>();
  }

  @override
  Future<Map<String, dynamic>> fetchDriver() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return await _loadJson('assets/dummy/driver.json');
  }

  @override
  Future<List<Map<String, dynamic>>> fetchStock() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final list = await _loadJsonList('assets/dummy/stock.json');
    return list.cast<Map<String, dynamic>>();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPaymentModes() async {
    await Future.delayed(const Duration(milliseconds: 200));
    final list = await _loadJsonList('assets/dummy/payment_modes.json');
    return list.cast<Map<String, dynamic>>();
  }

  @override
  Future<DeliveryResponse> createDelivery(DeliveryRequest request) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    return DeliveryResponse(
      deliveryId: DateTime.now().millisecondsSinceEpoch.toString(),
      success: true,
      message: 'Delivery created successfully',
    );
  }

  @override
  Future<EstimateResponse> createEstimate(EstimateRequest request) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    return EstimateResponse(
      estimateId: DateTime.now().millisecondsSinceEpoch.toString(),
      success: true,
      message: 'Estimate created successfully',
    );
  }

  @override
  Future<bool> createSalesReturn(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    return true;
  }

  @override
  Future<bool> syncData(Map<String, dynamic> payload) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    return true;
  }

  @override
  Future<SalesInvoiceResponse> createSalesInvoice(SalesInvoiceRequest request) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    return SalesInvoiceResponse(
      success: true,
      message: 'Sales invoice created successfully',
      invoiceId: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }
}
