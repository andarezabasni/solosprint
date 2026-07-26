import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../run/run_activity.dart';
import '../share_service.dart';

class PhotoTemplate extends StatelessWidget {
  final RunActivity activity;
  final String? imagePath;

  const PhotoTemplate({
    super.key,
    required this.activity,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final routePoints = activity.route.map((r) => r.latLng).toList();
    final hasRoute = routePoints.length >= 2;

    return Container(
      width: 1080,
      height: 1920,
      decoration: imagePath != null
          ? BoxDecoration(
              image: DecorationImage(
                image: FileImage(File(imagePath!)),
                fit: BoxFit.cover,
              ),
            )
          : const BoxDecoration(color: Color(0xFF1A1A2E)),
      child: Stack(
        children: [
          // Dark overlay (lighter when photo present)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: imagePath != null ? 0.35 : 0.0),
                  Colors.black.withValues(alpha: imagePath != null ? 0.55 : 0.0),
                  Colors.black.withValues(alpha: imagePath != null ? 0.70 : 0.0),
                ],
              ),
            ),
          ),

          // Route polyline drawn on photo
          if (hasRoute)
            Positioned.fill(
              child: CustomPaint(
                painter: _RoutePainter(
                  points: routePoints,
                  color: const Color(0xFFFC4C02),
                  strokeWidth: 12,
                ),
              ),
            ),

          // Logo & Date at top
          Positioned(
            top: 60,
            left: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.directions_run,
                        color: Color(0xFFFF6B35), size: 36),
                    const SizedBox(width: 12),
                    const Text(
                      'SoloSprint',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(blurRadius: 4, color: Colors.black45),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  ShareService.formatDate(activity.startTime),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    shadows: [Shadow(blurRadius: 3, color: Colors.black45)],
                  ),
                ),
              ],
            ),
          ),

          // Stats at bottom - without background card
          Positioned(
            left: 0,
            right: 0,
            bottom: 80,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statItem(
                      'DISTANCE',
                      activity.distance.toStringAsFixed(1),
                      'km',
                    ),
                    _statItem(
                      'PACE',
                      ShareService.formatPace(activity.pace),
                      '/km',
                    ),
                    _statItem(
                      'DURATION',
                      ShareService.formatDuration(activity.duration),
                      '',
                    ),
                  ],
                ),
              ),
            ),
          ),

          // "Tap to add photo" placeholder
          if (imagePath == null)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_a_photo, color: Colors.white54, size: 64),
                  SizedBox(height: 16),
                  Text(
                    'Tap "Choose Photo" to add your photo',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            letterSpacing: 1.5,
            shadows: [Shadow(blurRadius: 3, color: Colors.black45)],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
              ),
            ),
            if (unit.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 6),
                child: Text(
                  unit,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    shadows: [Shadow(blurRadius: 3, color: Colors.black45)],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Draws route polyline on the photo using GPS-to-pixel conversion.
class _RoutePainter extends CustomPainter {
  final List<Offset> _points; // pixel coordinates
  final Color color;
  final double strokeWidth;

  _RoutePainter({
    required List<LatLng> points,
    required this.color,
    required this.strokeWidth,
  }) : _points = _projectPoints(points);

  /// Convert GPS coordinates to canvas pixel coordinates (1080x1920).
  static List<Offset> _projectPoints(List<LatLng> gpsPoints) {
    if (gpsPoints.isEmpty) return [];

    double minLat = double.infinity, maxLat = double.negativeInfinity;
    double minLng = double.infinity, maxLng = double.negativeInfinity;
    for (final p in gpsPoints) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final latRange = maxLat - minLat;
    final lngRange = maxLng - minLng;
    if (latRange == 0 && lngRange == 0) return [];

    const canvasW = 1080.0;
    const canvasH = 1920.0;
    const pad = 0.10;
    final drawW = canvasW * (1 - 2 * pad);
    final drawH = canvasH * (1 - 2 * pad);
    final offsetX = canvasW * pad;
    final offsetY = canvasH * pad;

    final scaleX = drawW / lngRange;
    final scaleY = drawH / latRange;
    final scale = math.min(scaleX, scaleY);

    final centerX = (minLng + maxLng) / 2;
    final centerY = (minLat + maxLat) / 2;

    return gpsPoints.map((p) {
      final x = offsetX + drawW / 2 + (p.longitude - centerX) * scale;
      final y = offsetY + drawH / 2 - (p.latitude - centerY) * scale;
      return Offset(
        x.clamp(0.0, canvasW),
        y.clamp(0.0, canvasH),
      );
    }).toList();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_points.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(_points[0].dx, _points[0].dy);
    for (int i = 1; i < _points.length; i++) {
      path.lineTo(_points[i].dx, _points[i].dy);
    }
    canvas.drawPath(path, paint);

    // Start marker (green)
    canvas.drawCircle(
      _points[0],
      strokeWidth * 0.8,
      Paint()..color = const Color(0xFF10B981)..style = PaintingStyle.fill,
    );

    // End marker (orange)
    canvas.drawCircle(
      _points.last,
      strokeWidth * 0.8,
      Paint()..color = color..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) => true;
}
