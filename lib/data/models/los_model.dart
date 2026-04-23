import 'dart:math' as math;

enum LOSStatus { unknown, clear, blocked }

class TracePoint {
  final double lat;
  final double lng;
  final double elv;
  const TracePoint({required this.lat, required this.lng, required this.elv});

  factory TracePoint.fromJson(Map<String, dynamic> json) => TracePoint(
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        elv: (json['elv'] as num).toDouble(),
      );
}

class TraceData {
  final List<TracePoint> points;
  final int count;
  final double distanceBetweenPoints;
  const TraceData({
    required this.points,
    required this.count,
    required this.distanceBetweenPoints,
  });

  factory TraceData.fromJson(Map<String, dynamic> json) => TraceData(
        points: (json['points'] as List)
            .map((p) => TracePoint.fromJson(p as Map<String, dynamic>))
            .toList(),
        count: json['count'] as int,
        distanceBetweenPoints: (json['distance_between_points'] as num).toDouble(),
      );
}

class TraceResult {
  final TraceData traceData;
  final double fromElevation;
  final double toElevation;
  final String fromLabel;
  final String toLabel;
  final LOSStatus losStatus;
  const TraceResult({
    required this.traceData,
    required this.fromElevation,
    required this.toElevation,
    required this.fromLabel,
    required this.toLabel,
    required this.losStatus,
  });
}

const double _earthRadius = 6371000.0;

double haversineDistance(double lat1, double lon1, double lat2, double lon2) {
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLon = (lon2 - lon1) * math.pi / 180;
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * math.pi / 180) *
          math.cos(lat2 * math.pi / 180) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  return _earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

LOSStatus computeLOSStatus(TraceData traceData, double fromElevation, double toElevation) {
  if (traceData.points.length < 2) return LOSStatus.unknown;

  final points = traceData.points;
  final first = points.first;
  final last = points.last;
  final totalDistance = haversineDistance(first.lat, first.lng, last.lat, last.lng);

  final cumulativeDistances = <double>[0];
  for (int i = 1; i < points.length; i++) {
    cumulativeDistances.add(
      cumulativeDistances[i - 1] +
          haversineDistance(points[i - 1].lat, points[i - 1].lng, points[i].lat, points[i].lng),
    );
  }

  final curvatureDrops = cumulativeDistances.map((d) {
    return totalDistance > 0 ? (d * (totalDistance - d)) / (2 * _earthRadius) : 0.0;
  }).toList();

  final elevations = List.generate(points.length, (i) => points[i].elv - curvatureDrops[i]);
  final allElevations = [...elevations, fromElevation, toElevation];
  final minE = allElevations.reduce(math.min);
  final maxE = allElevations.reduce(math.max);
  final elevationRange = maxE - minE > 0 ? maxE - minE : 1.0;
  final ePadding = elevationRange * 0.1;
  const innerHeight = 100.0;

  double yScale(double elevation) {
    return innerHeight - ((elevation - (minE - ePadding)) / (elevationRange + ePadding * 2)) * innerHeight;
  }

  final terrainYs = elevations.map(yScale).toList();
  final fromY = yScale(fromElevation);
  final toY = yScale(toElevation);

  double losYAt(int idx) {
    final t = points.length > 1 ? idx / (points.length - 1) : 0.0;
    return fromY + t * (toY - fromY);
  }

  for (int i = 1; i < terrainYs.length - 1; i++) {
    if (terrainYs[i] < losYAt(i)) {
      return LOSStatus.blocked;
    }
  }

  return LOSStatus.clear;
}

class _SegmentResult {
  final List<String> blockedPaths;
  final List<String> clearPaths;
  const _SegmentResult({required this.blockedPaths, required this.clearPaths});
}

_SegmentResult _computeSegments(
  List<TracePoint> points,
  double distanceBetweenPoints,
  double fromY,
  double toY,
  double Function(double) xScale,
  double Function(double) yScale,
) {
  final terrainCoords = <({double x, double y})>[];
  for (int i = 0; i < points.length; i++) {
    terrainCoords.add((x: xScale(i * distanceBetweenPoints), y: yScale(points[i].elv)));
  }

  double losYAt(int i) {
    final t = points.length > 1 ? i / (points.length - 1) : 0.0;
    return fromY + t * (toY - fromY);
  }

  final blockedPaths = <String>[];
  final clearPaths = <String>[];

  var segStart = 0;
  var isCurrentlyBlocked = terrainCoords[0].y < losYAt(0);

  for (int i = 1; i < terrainCoords.length; i++) {
    final above = terrainCoords[i].y < losYAt(i);
    if (above != isCurrentlyBlocked) {
      final paths = isCurrentlyBlocked ? blockedPaths : clearPaths;
      final sb = StringBuffer('M ${terrainCoords[segStart].x.toStringAsFixed(1)} ${terrainCoords[segStart].y.toStringAsFixed(1)}');
      for (int k = segStart + 1; k < i; k++) {
        sb.write(' L ${terrainCoords[k].x.toStringAsFixed(1)} ${terrainCoords[k].y.toStringAsFixed(1)}');
      }
      sb.write(' L ${terrainCoords[i - 1].x.toStringAsFixed(1)} ${losYAt(i - 1).toStringAsFixed(1)}');
      for (int k = i - 1; k >= segStart; k--) {
        sb.write(' L ${terrainCoords[k].x.toStringAsFixed(1)} ${losYAt(k).toStringAsFixed(1)}');
      }
      sb.write(' Z');
      paths.add(sb.toString());
      segStart = i - 1;
      isCurrentlyBlocked = above;
    }
  }

  final paths = isCurrentlyBlocked ? blockedPaths : clearPaths;
  final last = terrainCoords.length - 1;
  final sb = StringBuffer('M ${terrainCoords[segStart].x.toStringAsFixed(1)} ${terrainCoords[segStart].y.toStringAsFixed(1)}');
  for (int k = segStart + 1; k <= last; k++) {
    sb.write(' L ${terrainCoords[k].x.toStringAsFixed(1)} ${terrainCoords[k].y.toStringAsFixed(1)}');
  }
  sb.write(' L ${terrainCoords[last].x.toStringAsFixed(1)} ${losYAt(last).toStringAsFixed(1)}');
  for (int k = last; k >= segStart; k--) {
    sb.write(' L ${terrainCoords[k].x.toStringAsFixed(1)} ${losYAt(k).toStringAsFixed(1)}');
  }
  sb.write(' Z');
  paths.add(sb.toString());

  return _SegmentResult(blockedPaths: blockedPaths, clearPaths: clearPaths);
}

class GraphData {
  final String terrainPath;
  final String losPath;
  final List<String> blockedPaths;
  final List<String> clearPaths;
  final double minElevation;
  final double maxElevation;
  final double Function(double) xScale;
  final double Function(double) yScale;
  final List<double> yTicks;
  final List<double> xTicks;
  final List<String> xTickLabels;
  final double totalDistance;
  final double dimsLeft;
  final double dimsTop;
  final double dimsWidth;
  final double dimsHeight;
  final double innerWidth;
  final double innerHeight;

  const GraphData({
    required this.terrainPath,
    required this.losPath,
    required this.blockedPaths,
    required this.clearPaths,
    required this.minElevation,
    required this.maxElevation,
    required this.xScale,
    required this.yScale,
    required this.yTicks,
    required this.xTicks,
    required this.xTickLabels,
    required this.totalDistance,
    required this.dimsLeft,
    required this.dimsTop,
    required this.dimsWidth,
    required this.dimsHeight,
    required this.innerWidth,
    required this.innerHeight,
  });
}

GraphData computeGraphData(TraceData traceData, double fromElevation, double toElevation) {
  const dimsLeft = 36.0;
  const dimsTop = 24.0;
  const dimsWidth = 320.0;
  const dimsHeight = 160.0;
  const dimsRight = 24.0;
  const dimsBottom = 28.0;
  final innerWidth = dimsWidth - dimsLeft - dimsRight;
  final innerHeight = dimsHeight - dimsTop - dimsBottom;

  final points = traceData.points;
  final totalDistance = (traceData.count - 1) * traceData.distanceBetweenPoints;

  final elevations = points.map((p) => p.elv).toList();
  final allElevations = [...elevations, fromElevation, toElevation];
  final minE = allElevations.reduce(math.min);
  final maxE = allElevations.reduce(math.max);
  final elevationRange = maxE - minE > 0 ? maxE - minE : 1.0;
  final ePadding = elevationRange * 0.1;

  double xScale(double distance) => dimsLeft + (distance / totalDistance) * innerWidth;
  double yScale(double elevation) => dimsTop + innerHeight - ((elevation - (minE - ePadding)) / (elevationRange + ePadding * 2)) * innerHeight;

  final terrainPathSB = StringBuffer();
  for (int i = 0; i < points.length; i++) {
    final distance = i * traceData.distanceBetweenPoints;
    final x = xScale(distance);
    final y = yScale(points[i].elv);
    if (i == 0) {
      terrainPathSB.write('M ${x.toStringAsFixed(1)} ${y.toStringAsFixed(1)}');
    } else {
      terrainPathSB.write(' L ${x.toStringAsFixed(1)} ${y.toStringAsFixed(1)}');
    }
  }
  final terrainPath = terrainPathSB.toString();

  final fromX = xScale(0);
  final fromY = yScale(fromElevation);
  final toX = xScale(totalDistance);
  final toY = yScale(toElevation);
  final losPath = 'M ${fromX.toStringAsFixed(1)} ${fromY.toStringAsFixed(1)} L ${toX.toStringAsFixed(1)} ${toY.toStringAsFixed(1)}';

  final segments = _computeSegments(points, traceData.distanceBetweenPoints, fromY, toY, xScale, yScale);

  final yAxisRange = (maxE + ePadding) - (minE - ePadding);
  final yTickStep = yAxisRange > 500 ? 200.0 : yAxisRange > 200 ? 100.0 : yAxisRange > 100 ? 50.0 : 20.0;
  final yTicks = <double>[];
  {
    final start = ((minE - ePadding) / yTickStep).ceil() * yTickStep;
    final end = ((maxE + ePadding) / yTickStep).floor() * yTickStep;
    for (var v = start; v <= end; v += yTickStep) {
      yTicks.add(v);
    }
  }

  final xTickStep = totalDistance > 5000 ? 1000.0 : totalDistance > 2000 ? 500.0 : 200.0;
  final xTicks = <double>[];
  final xTickLabels = <String>[];
  {
    const minGap = 30.0;
    var lastX = -minGap;
    for (var d = 0.0; d <= totalDistance; d += xTickStep) {
      final x = xScale(d);
      if (x >= lastX + minGap) {
        xTicks.add(d);
        xTickLabels.add(d >= 1000 ? '${(d / 1000).toStringAsFixed(1)}km' : '${d.round()}m');
        lastX = x;
      }
    }
  }

  return GraphData(
    terrainPath: terrainPath,
    losPath: losPath,
    blockedPaths: segments.blockedPaths,
    clearPaths: segments.clearPaths,
    minElevation: minE - ePadding,
    maxElevation: maxE + ePadding,
    xScale: xScale,
    yScale: yScale,
    yTicks: yTicks,
    xTicks: xTicks,
    xTickLabels: xTickLabels,
    totalDistance: totalDistance,
    dimsLeft: dimsLeft,
    dimsTop: dimsTop,
    dimsWidth: dimsWidth,
    dimsHeight: dimsHeight,
    innerWidth: innerWidth,
    innerHeight: innerHeight,
  );
}