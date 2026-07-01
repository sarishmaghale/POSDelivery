import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../core/database/providers.dart';
import '../core/network/api_service.dart';
import '../core/network/providers.dart';
import '../models/customer.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository(
    apiService: ref.read(apiServiceProvider),
    db: ref.read(databaseServiceProvider).db,
  );
});

class CustomerRepository {
  final ApiService _apiService;
  final Database _db;

  CustomerRepository({
    required ApiService apiService,
    required Database db,
  })  : _apiService = apiService,
        _db = db;

  Future<List<Customer>> getCustomers() async {
    final cached = await _db.query('customer');
    if (cached.isNotEmpty) {
      return cached.map((map) => Customer.fromMap(map)).toList();
    }
    return _fetchAndCacheCustomers();
  }

  Future<List<Customer>> refreshCustomers() async {
    return _fetchAndCacheCustomers();
  }

  Future<List<Customer>> getCachedCustomers() async {
    final maps = await _db.query('customer');
    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  Future<List<Customer>> _fetchAndCacheCustomers() async {
    final data = await _apiService.fetchCustomers();
    final customers = data.map((json) => Customer()
      ..serverId = json['id'] as String
      ..name = json['name'] as String
      ..phone = json['phone'] as String?
      ..address = json['address'] as String?).toList();

    if (customers.isNotEmpty) {
      await _db.transaction((txn) async {
        await txn.delete('customer');
        for (final c in customers) {
          txn.insert('customer', c.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });
    }

    return customers;
  }
}
