class PointCategory {
  final int id;
  final String name;

  PointCategory({
    required this.id,
    required this.name,
  });

  factory PointCategory.fromJson(Map<String, dynamic> json) {
    return PointCategory(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
