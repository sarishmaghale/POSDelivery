import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ImagePrefetchService {
  final DefaultCacheManager _cacheManager;

  ImagePrefetchService({DefaultCacheManager? cacheManager})
      : _cacheManager = cacheManager ?? DefaultCacheManager();

  Future<void> prefetchImages(List<String> urls) async {
    final validUrls = urls.where((url) => url.isNotEmpty).toList();
    if (validUrls.isEmpty) return;

    await Future.wait(
      validUrls.map((url) => _cacheManager.downloadFile(url)),
      eagerError: true,
    );
  }
}