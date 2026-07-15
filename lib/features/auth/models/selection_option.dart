class SelectionOption {
  final String id;
  final String name;

  const SelectionOption({required this.id, required this.name});

  factory SelectionOption.fromJson(Map<String, dynamic> json) {
    return SelectionOption(
      id: json['Id'] as String? ?? json['id'] as String? ?? '',
      name: json['Name'] as String? ?? json['name'] as String? ?? '',
    );
  }
}
