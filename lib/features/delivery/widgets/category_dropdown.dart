import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
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
    final langCode = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context)!;
    return DropdownButtonFormField<Category>(
      initialValue: selectedCategory,
      decoration: InputDecoration(
        labelText: l10n.selectCategory,
        prefixIcon: const Icon(Icons.category),
      ),
      items: categories.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Text(category.localizedName(langCode)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
