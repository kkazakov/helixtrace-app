class PointModel {
  final String id;
  final double lat;
  final double lon;
  final double elevation;
  final bool public;
  final String? label;
  final int categoryId;
  final String? user;

  PointModel({
    required this.id,
    required this.lat,
    required this.lon,
    required this.elevation,
    required this.public,
    this.label,
    required this.categoryId,
    this.user,
  });

  factory PointModel.fromJson(Map<String, dynamic> json) {
    return PointModel(
      id: json['id'] as String,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      elevation: (json['elevation'] as num).toDouble(),
      public: json['public'] as bool,
      label: json['label'] as String?,
      categoryId: json['category_id'] as int,
      user: json['user'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lat': lat,
      'lon': lon,
      'elevation': elevation,
      'public': public,
      'label': label,
      'category_id': categoryId,
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'lat': lat,
      'lon': lon,
      'public': public,
      'label': label,
      'category_id': categoryId,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    final Map<String, dynamic> data = {};
    if (label != null) data['label'] = label;
    data['public'] = public;
    return data;
  }
}
