class SelectionOption {
  final String id;
  final String name;
  final bool isActive;

  const SelectionOption({required this.id, required this.name, this.isActive = false});

  factory SelectionOption.fromJson(Map<String, dynamic> json) {
    return SelectionOption(
      id: json['Id'] as String? ?? json['id'] as String? ?? '',
      name: json['Name'] as String? ?? json['name'] as String? ?? '',
      isActive: json['IsActive'] != null && (json['IsActive'] as int) == 1,
    );
  }
}
