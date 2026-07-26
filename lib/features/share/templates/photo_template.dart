import 'dart:io';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../../shared/widgets/app_logo.dart';
import '../../run/run_activity.dart';
import '../share_service.dart';

/// Strava-style share card: photo background + route polyline overlay + stats.
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
    final routePts = activity.route.map((r) => r.latLng).toList();

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
          // Dark gradient overlay for readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.25),
                  Colors.black.withValues(alpha: 0.35),
                  Colors.black.withValues(alpha: 0.50),
                  Colors.black.withValues(alpha: 0.65),
                ],
              ),
            ),
          ),

          // Logo + date (top)
          Positioned(
            top: 60,
            left: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const AppLogo(size: 36),
                    const SizedBox(width: 12),
                    const Text('SoloSprint',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            shadows: [
                              Shadow(blurRadius: 4, color: Colors.black45)
                            ])),
                  ],
                ),
                const SizedBox(height: 8),
                Text(ShareService.formatDate(activity.startTime),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        shadows: [
                          Shadow(blurRadius: 3, color: Colors.black45)
                        ])),
              ],
            ),
          ),

          // Route polyline area (middle section of photo)
          if (routePts.length >= 2)
            Positioned.fill(
              left: 60,
              right: 60,
              top: 300,
              bottom: 360,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: _RoutePainter(
                        points: routePts,
                        color: const Color(0xFFFC4C02),
                        strokeWidth: 16,
                      ),
                    );
                  },
                ),
              ),
            ),

          // Stats row (bottom, no background card)
          Positioned(
            left: 30,
            right: 30,
            bottom: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _stat('DISTANCE', activity.distance.toStringAsFixed(1), 'km'),
                _stat('PACE', ShareService.formatPace(activity.pace), '/km'),
                _stat('DURATION', ShareService.formatDuration(activity.duration), ''),
              ],
            ),
          ),

          // Empty-state hint
          if (imagePath == null)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_a_photo, color: Colors.white54, size: 64),
                  SizedBox(height: 16),
                  Text('Tap "Choose Photo" to add your photo',
                      style: TextStyle(color: Colors.white54, fontSize: 16)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, String unit) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                letterSpacing: 1.5)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(blurRadius: 4, color: Colors.black54)
                    ])),
            if (unit.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 5),
                child: Text(unit,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        shadows: [
                          Shadow(blurRadius: 3, color: Colors.black45)
                        ])),
              ),
          ],
        ),
      ],
    );
  }
}

/// Paints the route polyline using GPS-to-pixel projection.
/// Uses simple min-max normalization to guarantee the route fills the canvas area.
class _RoutePainter extends CustomPainter {
  final List<LatLng> _points;
  final Color color;
  final double strokeWidth;

  _RoutePainter({
    required List<LatLng> points,
    required this.color,
    required this.strokeWidth,
  }) : _points = points;

  @override
  void paint(Canvas canvas, Size size) {
    if (_points.length < 2) return;

    // 1. Find bounding box of the route
    double minLat = double.infinity, maxLat = double.negativeInfinity;
    double minLng = double.infinity, maxLng = double.negativeInfinity;
    for (final p in _points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final latRange = maxLat - minLat;
    final lngRange = maxLng - minLng;
    if (latRange == 0 && lngRange == 0) return;

    // 2. Padding inside the canvas (12%)
    final padX = size.width * 0.12;
    final padY = size.height * 0.12;
    final drawW = size.width - 2 * padX;
    final drawH = size.height - 2 * padY;

    // 3. Project each point: simple normalization to [0,1] then scale to draw area
    final projected = <Offset>[];
    for (final p in _points) {
      final nx = (p.longitude - minLng) / lngRange; // 0..1
      final ny = 1.0 - (p.latitude - minLat) / latRange; // 0..1 (flip Y)

      final x = padX + nx * drawW;
      final y = padY + ny * drawH;

      projected.add(Offset(x, y));
    }

    // 4. Draw the polyline
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

    // 5. Start marker (green circle)
    canvas.drawCircle(
      projected[0],
      strokeWidth * 0.7,
      Paint()
        ..color = const Color(0xFF10B981)
        ..style = PaintingStyle.fill,
    );

    // 6. End marker (orange filled circle)
    canvas.drawCircle(
      projected.last,
      strokeWidth * 0.7,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) => true;
}
