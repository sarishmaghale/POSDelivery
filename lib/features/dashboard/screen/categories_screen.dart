import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/category.dart';
import '../../../repositories/category_repository.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final categories = await ref.read(categoryRepositoryProvider).getCachedCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.categories)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? Center(
                  child: Text(
                    'No categories available',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: cat.firstImageUrl != null
                                ? ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: cat.firstImageUrl!,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                      errorWidget: (_, __, ___) => Text(
                                        cat.name.isNotEmpty
                                            ? cat.name[0].toUpperCase()
                                            : '?',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          color: theme.colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                  )
                                : Text(
                                    cat.name.isNotEmpty
                                        ? cat.name[0].toUpperCase()
                                        : '?',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: theme.colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                          ),
                          title: Text(cat.name),
                          subtitle: cat.japaneseName != null
                              ? Text(cat.japaneseName!)
                              : null,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
