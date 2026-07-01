import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../core/database/providers.dart';
import '../core/network/api_service.dart';
import '../core/network/providers.dart';
import '../models/category.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(
    apiService: ref.read(apiServiceProvider),
    db: ref.read(databaseServiceProvider).db,
  );
});

class CategoryRepository {
  final ApiService _apiService;
  final Database _db;

  CategoryRepository({
    required ApiService apiService,
    required Database db,
  })  : _apiService = apiService,
        _db = db;

  Future<List<Category>> getCategories() async {
    final cached = await _db.query('category');
    if (cached.isNotEmpty) {
      return cached.map((map) => Category.fromMap(map)).toList();
    }
    return _fetchAndCacheCategories();
  }

  Future<List<Category>> refreshCategories() async {
    return _fetchAndCacheCategories();
  }

  Future<List<Category>> getCachedCategories() async {
    final maps = await _db.query('category');
    return maps.map((map) => Category.fromMap(map)).toList();
  }

  Future<List<Category>> _fetchAndCacheCategories() async {
    final data = await _apiService.fetchCategories();
    final categories = data.map((json) {
      final cat = Category();
      cat.serverId = json['Id'] as String? ?? json['id'] as String;
      cat.name = json['Name'] as String? ?? json['name'] as String;
      cat.japaneseName = json['JapaneseName'] as String?;
      cat.description = json['description'] as String?;
      cat.icon = json['icon'] as String?;
      final rawImageList = json['ImageList'] as List? ?? json['imageList'] as List?;
      if (rawImageList != null) {
        cat.imageList = rawImageList.map((e) {
          if (e is String) return e;
          if (e is Map) return (e['imageUrl'] ?? e['url'] ?? e['path'] ?? '') as String;
          return e.toString();
        }).toList();
        if (cat.imageList.isNotEmpty) {
          cat.imageUrl ??= cat.imageList.first;
        }
      }
      return cat;
    }).toList();

    if (categories.isNotEmpty) {
      await _db.transaction((txn) async {
        await txn.delete('category');
        for (final c in categories) {
          txn.insert('category', c.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });
    }

    return categories;
  }
}

