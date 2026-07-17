import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/product.dart';

class ProductDropdown extends StatelessWidget {
  final List<Product> products;
  final Product? selectedProduct;
  final ValueChanged<Product?> onChanged;

  const ProductDropdown({
    super.key,
    required this.products,
    required this.selectedProduct,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SearchProductField(
      products: products,
      selectedProduct: selectedProduct,
      onChanged: onChanged,
    );
  }
}

class SearchProductField extends StatefulWidget {
  final List<Product> products;
  final Product? selectedProduct;
  final ValueChanged<Product?> onChanged;

  const SearchProductField({
    super.key,
    required this.products,
    required this.selectedProduct,
    required this.onChanged,
  });

  @override
  State<SearchProductField> createState() => _SearchProductFieldState();
}

class _SearchProductFieldState extends State<SearchProductField> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSearching = false;
  List<Product> _results = [];

  @override
  void didUpdateWidget(SearchProductField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedProduct != oldWidget.selectedProduct) {
      _searchController.clear();
      setState(() {
        _isSearching = false;
        _results = [];
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
      if (query.isEmpty) {
        _results = [];
      } else {
        final q = query.toLowerCase();
        _results = widget.products
            .where((p) => p.name.toLowerCase().contains(q))
            .take(5)
            .toList();
      }
    });
  }

  void _selectProduct(Product product) {
    widget.onChanged(product);
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _results = [];
    });
    _focusNode.unfocus();
  }

  void _clearSelection() {
    widget.onChanged(null);
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _results = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final langCode = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context)!;

    return TapRegion(
      onTapOutside: (_) {
        _focusNode.unfocus();
        setState(() {
          _isSearching = false;
          _results = [];
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _searchController,
            focusNode: _focusNode,
            decoration: InputDecoration(
              labelText: widget.selectedProduct?.name ?? l10n.searchProduct,
              hintText: widget.selectedProduct != null ? '' : l10n.typeToSearch,
              prefixIcon: const Icon(Icons.inventory_2),
              suffixIcon: widget.selectedProduct != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearSelection,
                    )
                  : (_searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null),
              border: const OutlineInputBorder(),
            ),
            onChanged: _onSearchChanged,
          ),
          if (_isSearching && _results.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.noProductsFound,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          if (_isSearching && _results.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final product = _results[index];
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      backgroundImage: product.firstImageUrl != null
                          ? NetworkImage(product.firstImageUrl!)
                          : null,
                      child: product.firstImageUrl == null
                          ? Text(
                              product.localizedName(langCode).isNotEmpty
                                  ? product.localizedName(langCode)[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: theme.colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    title: Text(product.localizedName(langCode)),
                    subtitle: Text(
                      'Rs. ${product.unitPrice.toStringAsFixed(2)}${product.unit != null ? ' / ${product.unit}' : ''}',
                    ),
                    onTap: () => _selectProduct(product),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
