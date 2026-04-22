class TracePathPoint {
  final double lat;
  final double lng;
  final double elv;

  TracePathPoint({
    required this.lat,
    required this.lng,
    required this.elv,
  });

  factory TracePathPoint.fromJson(Map<String, dynamic> json) {
    return TracePathPoint(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      elv: (json['elv'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
      'elv': elv,
    };
  }
}

class TracePathModel {
  final List<TracePathPoint> points;
  final int count;
  final double distanceBetweenPoints;
  final String status;

  TracePathModel({
    required this.points,
    required this.count,
    required this.distanceBetweenPoints,
    required this.status,
  });

  factory TracePathModel.fromJson(Map<String, dynamic> json) {
    final pointsJson = json['points'] as List<dynamic>;
    final points = pointsJson
        .map((p) => TracePathPoint.fromJson(p as Map<String, dynamic>))
        .toList();

    return TracePathModel(
      points: points,
      count: json['count'] as int,
      distanceBetweenPoints: (json['distance_between_points'] as num).toDouble(),
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'points': points.map((p) => p.toJson()).toList(),
      'count': count,
      'distance_between_points': distanceBetweenPoints,
      'status': status,
    };
  }
}
