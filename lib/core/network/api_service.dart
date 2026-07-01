import '../../dto/dashboard_response.dart';
import '../../dto/delivery_request.dart';
import '../../dto/delivery_response.dart';
import '../../dto/estimate_request.dart';
import '../../dto/estimate_response.dart';

abstract class ApiService {
  Future<DashboardResponse> fetchDashboard();

  Future<List<Map<String, dynamic>>> fetchCustomers();
  Future<List<Map<String, dynamic>>> fetchCategories();
  Future<List<Map<String, dynamic>>> fetchProducts();
  Future<Map<String, dynamic>> fetchDriver();
  Future<List<Map<String, dynamic>>> fetchStock();

  Future<DeliveryResponse> createDelivery(DeliveryRequest request);
  Future<EstimateResponse> createEstimate(EstimateRequest request);
  Future<bool> createSalesReturn(Map<String, dynamic> data);

  Future<bool> syncData(Map<String, dynamic> payload);
}
