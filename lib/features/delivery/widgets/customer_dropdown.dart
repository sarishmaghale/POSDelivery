import 'package:flutter/material.dart';

import '../../../models/customer.dart';

class CustomerDropdown extends StatelessWidget {
  final List<Customer> customers;
  final Customer? selectedCustomer;
  final ValueChanged<Customer?> onChanged;

  const CustomerDropdown({
    super.key,
    required this.customers,
    required this.selectedCustomer,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SearchCustomerField(
      customers: customers,
      selectedCustomer: selectedCustomer,
      onChanged: onChanged,
    );
  }
}

class SearchCustomerField extends StatefulWidget {
  final List<Customer> customers;
  final Customer? selectedCustomer;
  final ValueChanged<Customer?> onChanged;

  const SearchCustomerField({
    super.key,
    required this.customers,
    required this.selectedCustomer,
    required this.onChanged,
  });

  @override
  State<SearchCustomerField> createState() => _SearchCustomerFieldState();
}

class _SearchCustomerFieldState extends State<SearchCustomerField> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSearching = false;
  List<Customer> _results = [];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() => _isSearching = false);
      }
    });
  }

  @override
  void didUpdateWidget(SearchCustomerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCustomer != oldWidget.selectedCustomer) {
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
        _results = widget.customers
            .where((c) =>
                c.name.toLowerCase().contains(q) ||
                (c.phone?.toLowerCase().contains(q) ?? false))
            .take(5)
            .toList();
      }
    });
  }

  void _selectCustomer(Customer customer) {
    widget.onChanged(customer);
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _searchController,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: widget.selectedCustomer?.name ?? 'Search Customer',
            hintText: widget.selectedCustomer != null ? '' : 'Type to search...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: widget.selectedCustomer != null
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
              'No customers found',
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
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final customer = _results[index];
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      customer.name.isNotEmpty
                          ? customer.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(customer.name),
                  subtitle: customer.phone != null
                      ? Text(customer.phone!)
                      : null,
                  onTap: () => _selectCustomer(customer),
                );
              },
            ),
          ),
      ],
    );
  }
}
