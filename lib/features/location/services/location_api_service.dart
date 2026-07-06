import 'package:dio/dio.dart';
import '../models/location_record.dart';

class LocationApiService {
  final Dio _dio;

  LocationApiService(this._dio);

  Future<void> sendLocation(LocationRecord record) async {
    await _dio.post('/locations', data: record.toJson());
  }

  Future<void> sendBatch(List<Map<String, dynamic>> records) async {
    await _dio.post('/locations/batch', data: {'locations': records});
  }
}