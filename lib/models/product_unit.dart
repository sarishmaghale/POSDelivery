class ProductUnit {
  final String unitId;
  final String unitName;

  const ProductUnit({required this.unitId, required this.unitName});

  Map<String, dynamic> toJson() => {'UnitId': unitId, 'UnitName': unitName};

  factory ProductUnit.fromJson(Map<String, dynamic> json) {
    final id = json['UnitId'] ?? json['unitId'] ?? json['Id'] ?? json['id'];
    final name =
        json['UnitName'] ?? json['unitName'] ?? json['Name'] ?? json['name'];
    return ProductUnit(
      unitId: id?.toString() ?? '',
      unitName: name?.toString() ?? '',
    );
  }
}
