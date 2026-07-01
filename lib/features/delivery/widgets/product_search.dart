import 'package:flutter/material.dart';

import '../../../models/product.dart';

class ProductSearch extends StatelessWidget {
  final String query;
  final ValueChanged<String> onQueryChanged;
  final List<Product> products;
  final void Function(Product product, double quantity) onAddToCart;

  const ProductSearch({
    super.key,
    required this.query,
    required this.onQueryChanged,
    required this.products,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: TextEditingController(text: query),
          onChanged: onQueryChanged,
          decoration: InputDecoration(
            hintText: 'Search products...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => onQueryChanged(''),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 12),
        ...products.map((product) {
          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              title: Text(product.name),
              subtitle: product.unit != null
                  ? Text('Per ${product.unit}')
                  : null,
              trailing: _QuantityAdder(
                onAdd: (qty) => onAddToCart(product, qty),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _QuantityAdder extends StatefulWidget {
  final void Function(double quantity) onAdd;

  const _QuantityAdder({required this.onAdd});

  @override
  State<_QuantityAdder> createState() => _QuantityAdderState();
}

class _QuantityAdderState extends State<_QuantityAdder> {
  double _quantity = 1;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 60,
          child: TextFormField(
            initialValue: _quantity.toStringAsFixed(0),
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(vertical: 8),
              isDense: true,
            ),
            onChanged: (value) {
              setState(() {
                _quantity = double.tryParse(value) ?? 1;
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.tonalIcon(
          onPressed: () => widget.onAdd(_quantity),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add'),
        ),
      ],
    );
  }
}
