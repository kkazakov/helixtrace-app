class ElevationModel {
  final double lat;
  final double lon;
  final double elevation;

  ElevationModel({
    required this.lat,
    required this.lon,
    required this.elevation,
  });

  factory ElevationModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return ElevationModel(
      lat: (data['lat'] as num).toDouble(),
      lon: (data['lon'] as num).toDouble(),
      elevation: (data['elevation'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lon': lon,
      'elevation': elevation,
    };
  }
}
