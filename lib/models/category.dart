import 'dart:convert';

class Category {
  int? id;
  late String serverId;
  late String name;
  String? japaneseName;
  String? description;
  String? icon;
  String? imageUrl;
  List<String> imageList = [];

  Category();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'server_id': serverId,
      'name': name,
      'japanese_name': japaneseName,
      'description': description,
      'icon': icon,
      'image_url': imageUrl,
      'image_list': imageList.isNotEmpty ? jsonEncode(imageList) : null,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    final category = Category();
    category.id = map['id'] as int?;
    category.serverId = map['server_id'] as String;
    category.name = map['name'] as String;
    category.japaneseName = map['japanese_name'] as String?;
    category.description = map['description'] as String?;
    category.icon = map['icon'] as String?;
    category.imageUrl = map['image_url'] as String?;
    final imageListRaw = map['image_list'] as String?;
    if (imageListRaw != null && imageListRaw.isNotEmpty) {
      category.imageList = (jsonDecode(imageListRaw) as List).cast<String>();
    }
    return category;
  }

  String localizedName(String languageCode) {
    if (languageCode == 'ne' && japaneseName != null && japaneseName!.isNotEmpty) {
      return japaneseName!;
    }
    return name;
  }

  String? get firstImageUrl =>
      imageList.isNotEmpty ? imageList.first : imageUrl;
}
