import 'package:flutter/material.dart';

import '../../../models/category.dart';

class CategoryDropdown extends StatelessWidget {
  final List<Category> categories;
  final Category? selectedCategory;
  final ValueChanged<Category?> onChanged;

  const CategoryDropdown({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<Category>(
      initialValue: selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Select Category',
        prefixIcon: Icon(Icons.category),
      ),
      items: categories.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Text(category.name),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
