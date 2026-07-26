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
          // Dark overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: imagePath != null ? 0.30 : 0.0),
                  Colors.black.withValues(alpha: imagePath != null ? 0.40 : 0.0),
                  Colors.black.withValues(alpha: imagePath != null ? 0.55 : 0.0),
                  Colors.black.withValues(alpha: imagePath != null ? 0.70 : 0.0),
                ],
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
                        shadows: [Shadow(blurRadius: 4, color: Colors.black45)],
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

          // Route polyline in the middle area (centered, moderate size)
          if (routePoints.length >= 2)
            Positioned(
              left: 80,
              right: 80,
              top: 320,
              bottom: 420,
              child: CustomPaint(
                painter: _RoutePainter(
                  points: routePoints,
                  color: const Color(0xFFFC4C02),
                  strokeWidth: 14,
                ),
              ),
            ),

          // Stats at bottom (no background card)
          Positioned(
            left: 0,
            right: 0,
            bottom: 120,
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

          // Empty state
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

/// Draws route polyline centered in the available canvas area.
class _RoutePainter extends CustomPainter {
  final List<LatLng> _originalPoints;
  final Color color;
  final double strokeWidth;

  _RoutePainter({
    required List<LatLng> points,
    required this.color,
    required this.strokeWidth,
  }) : _originalPoints = points;

  @override
  void paint(Canvas canvas, Size size) {
    if (_originalPoints.length < 2) return;

    // Project GPS to pixel coordinates within the available canvas area
    final projected = _projectToCanvas(_originalPoints, size);

    // Draw polyline
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(projected[0].dx, projected[0].dy);
    for (int i = 1; i < projected.length; i++) {
      path.lineTo(projected[i].dx, projected[i].dy);
    }
    canvas.drawPath(path, paint);

    // Start marker (green)
    canvas.drawCircle(
      projected[0],
      strokeWidth * 0.7,
      Paint()..color = const Color(0xFF10B981)..style = PaintingStyle.fill,
    );

    // End marker (orange)
    canvas.drawCircle(
      projected.last,
      strokeWidth * 0.7,
      Paint()..color = color..style = PaintingStyle.fill,
    );
  }

  /// Convert GPS coords to pixel coords fitting within [size] with padding.
  List<Offset> _projectToCanvas(List<LatLng> gps, Size size) {
    double minLat = double.infinity, maxLat = double.negativeInfinity;
    double minLng = double.infinity, maxLng = double.negativeInfinity;
    for (final p in gps) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final latRange = maxLat - minLat;
    final lngRange = maxLng - minLng;
    if (latRange == 0 && lngRange == 0) return [];

    const pad = 0.12; // 12% padding inside the allocated area
    final drawW = size.width * (1 - 2 * pad);
    final drawH = size.height * (1 - 2 * pad);

    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;

    // Scale to fit while preserving aspect ratio
    final scale = math.min(drawW / lngRange, drawH / latRange);

    return gps.map((p) {
      final x = size.width / 2 + (p.longitude - centerLng) * scale;
      final y = size.height / 2 - (p.latitude - centerLat) * scale;
      return Offset(x, y);
    }).toList();
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) => true;
}
