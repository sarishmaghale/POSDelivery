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
    return DropdownButtonFormField<Customer>(
      initialValue: selectedCustomer,
      decoration: const InputDecoration(
        labelText: 'Select Customer',
        prefixIcon: Icon(Icons.store),
      ),
      items: customers.map((customer) {
        return DropdownMenuItem(
          value: customer,
          child: Text(customer.name),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
