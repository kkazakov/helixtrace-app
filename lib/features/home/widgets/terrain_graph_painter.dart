import 'package:flutter/material.dart';
import 'package:helixtrace/data/models/los_model.dart';

class TerrainGraphPainter extends CustomPainter {
  final GraphData data;
  final String fromLabel;
  final String toLabel;
  final LOSStatus losStatus;

  TerrainGraphPainter({
    required this.data,
    required this.fromLabel,
    required this.toLabel,
    required this.losStatus,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / data.dimsWidth;
    double scaleX(double x) => x * scale;
    double scaleY(double y) => y * (size.height / data.dimsHeight);

    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (final tick in data.yTicks) {
      final y = scaleY(data.yScale(tick));
      canvas.drawLine(
        Offset(scaleX(data.dimsLeft), y),
        Offset(scaleX(data.dimsWidth - 24), y),
        gridPaint,
      );

      final tp = TextPainter(
        text: TextSpan(
          text: tick.round().toString(),
          style: TextStyle(fontSize: 8 * scale, color: Colors.grey),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(scaleX(data.dimsLeft - 4) - tp.width, y - tp.height / 2));
    }

    for (int i = 0; i < data.xTicks.length; i++) {
      final x = scaleX(data.xScale(data.xTicks[i]));
      canvas.drawLine(
        Offset(x, scaleY(data.dimsTop)),
        Offset(x, scaleY(data.dimsHeight - data.dimsHeight + data.dimsHeight - 28)),
        gridPaint,
      );

      final tp = TextPainter(
        text: TextSpan(
          text: data.xTickLabels[i],
          style: TextStyle(fontSize: 8 * scale, color: Colors.grey),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, scaleY(data.dimsHeight - 28 + data.dimsHeight - data.dimsHeight + 14)));
    }

    final clipRect = Rect.fromLTRB(
      scaleX(data.dimsLeft),
      scaleY(data.dimsTop),
      scaleX(data.dimsWidth - 24),
      scaleY(data.dimsHeight - 28),
    );
    canvas.save();
    canvas.clipRect(clipRect);

    for (final pathStr in data.clearPaths) {
      final path = _parsePath(pathStr, scaleX, scaleY);
      canvas.drawPath(path, Paint()..color = const Color(0x3F4CAF50));
    }

    for (final pathStr in data.blockedPaths) {
      final path = _parsePath(pathStr, scaleX, scaleY);
      canvas.drawPath(path, Paint()..color = const Color(0x3FF44336));
    }

    final terrainPath = _parsePath(data.terrainPath, scaleX, scaleY);
    canvas.drawPath(
      terrainPath,
      Paint()
        ..color = const Color(0xFF2196F3)
        ..strokeWidth = 1.5 * scale
        ..style = PaintingStyle.stroke,
    );

    final losPath = _parsePath(data.losPath, scaleX, scaleY);
    canvas.drawPath(
      losPath,
      Paint()
        ..color = const Color(0xFFD32F2F)
        ..strokeWidth = 1.5 * scale
        ..style = PaintingStyle.stroke,
    );

    canvas.restore();

    final fromTP = TextPainter(
      text: TextSpan(
        text: fromLabel,
        style: TextStyle(fontSize: 9 * scale, fontWeight: FontWeight.w600, color: Colors.black87),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    fromTP.paint(canvas, Offset(scaleX(data.dimsLeft), scaleY(data.dimsHeight - 8)));

    final toTP = TextPainter(
      text: TextSpan(
        text: toLabel,
        style: TextStyle(fontSize: 9 * scale, fontWeight: FontWeight.w600, color: Colors.black87),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    toTP.paint(canvas, Offset(scaleX(data.dimsWidth - 24) - toTP.width, scaleY(data.dimsHeight - 8)));

    final statusColor = losStatus == LOSStatus.clear ? const Color(0xFF4CAF50) : losStatus == LOSStatus.blocked ? const Color(0xFFD32F2F) : Colors.grey;
    final statusText = losStatus == LOSStatus.clear ? 'LOS: Clear' : losStatus == LOSStatus.blocked ? 'LOS: Blocked' : 'LOS: Unknown';
    final statusTP = TextPainter(
      text: TextSpan(
        text: statusText,
        style: TextStyle(fontSize: 9 * scale, fontWeight: FontWeight.w700, color: statusColor),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    statusTP.paint(canvas, Offset(scaleX(data.dimsWidth - 24) - statusTP.width, scaleY(4)));
  }

  Path _parsePath(String d, double Function(double) scaleX, double Function(double) scaleY) {
    final path = Path();
    final parts = d.split(RegExp(r'\s+'));
    double? lastX;
    double? lastY;

    for (int i = 0; i < parts.length; i++) {
      final part = parts[i].trim();
      if (part.isEmpty) continue;

      if (part == 'M' || part == 'L') {
        final x = double.parse(parts[i + 1]);
        final y = double.parse(parts[i + 2]);
        i += 2;
        final sx = scaleX(x);
        final sy = scaleY(y);
        if (part == 'M') {
          path.moveTo(sx, sy);
        } else {
          path.lineTo(sx, sy);
        }
        lastX = sx;
        lastY = sy;
      } else if (part == 'Z') {
        path.close();
      } else if (double.tryParse(part) != null && lastX != null && lastY != null) {
        final x = scaleX(double.parse(part));
        i++;
        final y = scaleY(double.parse(parts[i]));
        path.lineTo(x, y);
        lastX = x;
        lastY = y;
      }
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant TerrainGraphPainter oldDelegate) =>
      data.terrainPath != oldDelegate.data.terrainPath ||
      data.losPath != oldDelegate.data.losPath ||
      fromLabel != oldDelegate.fromLabel ||
      toLabel != oldDelegate.toLabel ||
      losStatus != oldDelegate.losStatus;
}