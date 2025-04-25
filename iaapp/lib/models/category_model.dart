class Category {
  final String id;
  final String name;
  
  Category({
    required this.id,
    required this.name,
  });
  
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['type_id']?.toString() ?? '',
      name: json['type_name']?.toString() ?? '',
    );
  }
} 