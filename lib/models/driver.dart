class Driver {
  int? id;
  late String serverId;
  late String name;
  String? phone;
  String? email;
  List<String> assignedCategoryIds = [];
  List<String> assignedProductIds = [];

  Driver();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'server_id': serverId,
      'name': name,
      'phone': phone,
      'email': email,
      'assigned_category_ids':
          assignedCategoryIds.map((e) => e.toString()).join(','),
      'assigned_product_ids':
          assignedProductIds.map((e) => e.toString()).join(','),
    };
  }

  factory Driver.fromMap(Map<String, dynamic> map) {
    final driver = Driver();
    driver.id = map['id'] as int?;
    driver.serverId = map['server_id'] as String;
    driver.name = map['name'] as String;
    driver.phone = map['phone'] as String?;
    driver.email = map['email'] as String?;
    driver.assignedCategoryIds = (map['assigned_category_ids'] as String?)
            ?.split(',')
            .where((e) => e.isNotEmpty)
            .toList() ??
        [];
    driver.assignedProductIds = (map['assigned_product_ids'] as String?)
            ?.split(',')
            .where((e) => e.isNotEmpty)
            .toList() ??
        [];
    return driver;
  }
}
