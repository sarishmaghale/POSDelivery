import '../../dto/sales_invoice_request.dart';
import '../../dto/sales_invoice_response.dart';

abstract class ApiService {
   Future<List<Map<String, dynamic>>> fetchAllProducts();
  Future<List<Map<String, dynamic>>> fetchCustomers();
  Future<List<Map<String, dynamic>>> fetchCategories({
    required String customerId,
    required String transactionDate,
  });
  Future<List<Map<String, dynamic>>> fetchProducts({
    required String customerId,
    required String transactionDate,
  });
  Future<List<Map<String, dynamic>>> fetchPaymentModes();

  Future<SalesInvoiceResponse> createSalesInvoice(SalesInvoiceRequest request);
  Future<bool> createSalesReturn(Map<String, dynamic> data);
}
