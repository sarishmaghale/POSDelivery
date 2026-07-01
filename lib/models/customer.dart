class Customer {
  int? id;
  late String serverId;
  late String name;
  String? phone;
  String? address;

  Customer();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'server_id': serverId,
      'name': name,
      'phone': phone,
      'address': address,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    final customer = Customer();
    customer.id = map['id'] as int?;
    customer.serverId = map['server_id'] as String;
    customer.name = map['name'] as String;
    customer.phone = map['phone'] as String?;
    customer.address = map['address'] as String?;
    return customer;
  }
}
