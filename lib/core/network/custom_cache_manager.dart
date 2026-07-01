import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:io';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

class CustomCacheManager extends DefaultCacheManager {
  static const _cacheFolder = '.cache_flutter';
  static final String _imageCacheDir = Path.join(_cacheFolder, 'images');
  static final String _tempCacheDir = Path.join(_cacheFolder, 'temp');

  static Future<CustomCacheManager> getInstance() async {
    final directory = Directory.current;
    if (!await directory.exists(_cacheFolder)) {
      await directory.create(_cacheFolder);
    }
    if (!await directory.exists(_imageCacheDir)) {
      await directory.create(_imageCacheDir);
    }
    if (!await directory.exists(_tempCacheDir)) {
      await directory.create(_tempCacheDir);
    }
    
    return CustomCacheManager._();
  }

  CustomCacheManager._() {
    _setupCustomInterceptors();
  }

  void _setupCustomInterceptors() {
    _interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        _addBrowserCompatHeaders(options);
        _addCacheControlHeaders(options);
        _addSecurityHeaders(options);
        _addUserAgent(options);
        
        if (options.extra['forceCache'] == true) {
          options.headers['Cache-Control'] = 'max-age=31536000';
        }
        
        handler.next(options);
      },
      onResponse: (response, handler) {
        if (response.data is List<int> && _isImageResponse(response)) {
          _optimizeImageResponse(response.data as List<int>, response);
        }
        _addCacheInfoHeaders(response);
        handler.next(response);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 404) {
          _handleImageNotFound(error);
        } else if (error.response?.statusCode == 403) {
          _handleAccessDenied(error);
        }
        handler.next(error);
      },
    ));
  }

  bool _isImageResponse(Response response) {
    return response.data is List<int> && 
           (response.headers['content-type']?.startsWith('image/') ?? false) &&
           (response.headers['content-length'] != null && 
            int.tryParse(response.headers['content-length']!) ?? 0 > 0);
  }

  void _optimizeImageResponse(List<int> data, Response response) {
    final contentType = response.headers['content-type'];
    if (contentType?.contains('jpeg') ?? false) {
      _optimizeJpegData(data, response);
    } else if (contentType?.contains('png') ?? false) {
      _optimizePngData(data, response);
    } else if (contentType?.contains('webp') ?? false) {
      _optimizeWebpData(data, response);
    }
  }

  void _optimizeJpegData(List<int> data, Response response) {
    if (data.length >= 8 && data[0] == 0xFF && data[1] == 0xD8) {
      final app1Index = _findMarker(data, 0xFFE1);
      if (app1Index != -1) {
        final exifIndex = _findMarker(data, 0xFFE1);
        if (exifIndex != -1) {
          final exifData = _extractMarkerData(data, exifIndex);
          if (exifData.length > 100) {
            response.data = data;
          }
        }
      }
    }
  }

  void _optimizePngData(List<int> data, Response response) {
    if (data.length >= 8 && data[0] == 0x89 && data[1] == 0x50 && 
        data[2] == 0x4E && data[3] == 0x47) {
      final chunkData = _extractPngChunks(data);
      if (chunkData.isNotEmpty) {
        _addPngOptimization(response, chunkData);
      }
    }
  }

  void _optimizeWebpData(List<int> data, Response response) {
    if (data.length >= 12 && 
        data[0] == 0x57 && data[1] == 0x45 && data[2] == 0x42 && data[3] == 0x50) {
      _addWebpOptimization(response);
    }
  }

  List<int> _extractPngChunks(List<int> data) {
    final chunks = <int>[];
    int i = 8;
    
    while (i < data.length - 12) {
      final length = (data[i] << 24) | (data[i + 1] << 16) | (data[i + 2] << 8) | data[i + 3];
      final chunkType = data.getRange(i + 4, i + 8);
      final chunkData = data.getRange(i + 8, i + 8 + length);
      final crc = data.getRange(i + 8 + length, i + 12 + length);
      
      chunks.addAll(chunkData);
      
      i += 12 + length;
      
      if (chunkType.every((b) => b == 0)) {
        break;
      }
    }
    
    return chunks;
  }

  int _findMarker(List<int> data, int marker) {
    int i = 0;
    while (i < data.length - 1) {
      if ((data[i] << 8) | data[i + 1] == marker) {
        return i;
      }
      i++;
    }
    return -1;
  }

  List<int> _extractMarkerData(List<int> data, int markerIndex) {
    final markerSize = (data[markerIndex + 2] << 8) | data[markerIndex + 3];
    return data.getRange(markerIndex + 4, markerIndex + 4 + markerSize).toList();
  }

  void _addBrowserCompatHeaders(Options options) {
    final headers = {
      'Accept': 'image/webp,image/apng,image/png,image/svg+xml,image/*',
      'Accept-Encoding': 'gzip, deflate, br',
      'Accept-Language': 'en-US,en;q=0.9,si-LK;q=0.8,si;q=0.7',
      'DNT': '1',
      'Connection': 'keep-alive',
      'Upgrade-Insecure-Requests': '1',
      'Sec-Fetch-Dest': 'image',
      'Sec-Fetch-Mode': 'no-cors',
      'Sec-Fetch-Site': 'cross-site',
      'Sec-Fetch-User': '?1',
      'User-Agent': 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36',
    };
    
    for (final entry in headers.entries) {
      if (!options.headers.containsKey(entry.key)) {
        options.headers[entry.key] = entry.value;
      }
    }
  }

  void _addCacheControlHeaders(Options options) {
    if (!options.headers.containsKey('Cache-Control')) {
      options.headers['Cache-Control'] = 'no-cache';
    }
    if (!options.headers.containsKey('Pragma')) {
      options.headers['Pragma'] = 'no-cache';
    }
    
    if (options.extra['cacheImage'] == true) {
      options.headers['Cache-Control'] = 'max-age=3600, immutable';
    }
  }

  void _addSecurityHeaders(Options options) {
    if (!options.headers.containsKey('X-Content-Type-Options')) {
      options.headers['X-Content-Type-Options'] = 'nosniff';
    }
    if (!options.headers.containsKey('X-Frame-Options')) {
      options.headers['X-Frame-Options'] = 'DENY';
    }
    if (!options.headers.containsKey('Referrer-Policy')) {
      options.headers['Referrer-Policy'] = 'no-referrer';
    }
  }

  void _addUserAgent(Options options) {
    if (!options.headers.containsKey('User-Agent')) {
      options.headers['User-Agent'] = 'SarishmaApp/1.0.0 (Dart; Flutter ${Platform.version})';
    }
  }

  void _addCacheInfoHeaders(Response response) {
    if (response.data is List<int>) {
      final data = response.data as List<int>;
      response.headers['X-Cache-Size'] = data.length.toString();
      response.headers['X-Cache-Timestamp'] = DateTime.now().millisecondsSinceEpoch.toString();
      response.headers['X-Cache-Source'] = 'browser';
    }
  }

  void _handleImageNotFound(DioException error) {
    print('Image not found: ${error.requestOptions.path}');
    error.response?.data = {'error': 'Image not found'};
  }

  void _handleAccessDenied(DioException error) {
    print('Access denied for image: ${error.requestOptions.path}');
    error.response?.data = {'error': 'Access denied to image resource'};
  }

  Future<String> getCachePath(String fileName, {String subDir = ''}) async {
    final cacheFolder = Directory.current.path;
    final targetDir = subDir.isEmpty ? cacheFolder : Path.join(cacheFolder, subDir);
    
    if (!await Directory(targetDir).exists()) {
      await Directory(targetDir).create(recursive: true);
    }
    
    return Path.join(targetDir, fileName);
  }

  Future<String> getSecureCachePath(String fileName, {String subDir = ''}) async {
    final secureFolder = Path.join(Directory.current.path, '.secure_cache', 'images');
    if (!await Directory(secureFolder).exists()) {
      await Directory(secureFolder).create(recursive: true);
    }
    return Path.join(secureFolder, fileName);
  }

  Future<void> clearImageCache() async {
    final imageDir = Directory(Path.join(Directory.current.path, _imageCacheDir));
    if (await imageDir.exists()) {
      for (final file in await imageDir.list().toList()) {
        if (file is File) {
          await file.delete();
        }
      }
    }
  }

  Future<void> clearExpiredCache() async {
    final imageDir = Directory(Path.join(Directory.current.path, _imageCacheDir));
    if (await imageDir.exists()) {
      final now = DateTime.now();
      for (final entity in await imageDir.list().toList()) {
        if (entity is File) {
          final fileAge = now.difference(await entity.stat().then((s) => s.changed));
          if (fileAge > Duration(days: 30)) {
            await entity.delete();
          }
        }
      }
    }
  }

  Future<Map<String, dynamic>> getCacheInfo() async {
    final imageDir = Directory(Path.join(Directory.current.path, _imageCacheDir));
    final tempDir = Directory(Path.join(Directory.current.path, _tempCacheDir));
    
    int imageFileCount = 0;
    int tempFileCount = 0;
    int totalCacheSize = 0;
    
    if (await imageDir.exists()) {
      for (final entity in await imageDir.list().toList()) {
        if (entity is File) {
          imageFileCount++;
          totalCacheSize += await entity.length();
        }
      }
    }
    
    if (await tempDir.exists()) {
      for (final entity in await tempDir.list().toList()) {
        if (entity is File) {
          tempFileCount++;
          totalCacheSize += await entity.length();
        }
      }
    }
    
    return {
      'imageCacheDir': _imageCacheDir,
      'tempCacheDir': _tempCacheDir,
      'imageFiles': imageFileCount,
      'tempFiles': tempFileCount,
      'totalSize': totalCacheSize,
      'cacheFolder': Directory.current.path,
    };
  }
}