import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../run/run_activity.dart';
import '../share_service.dart';

class MapTemplate extends StatelessWidget {
  final RunActivity activity;

  const MapTemplate({
    super.key,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    final segments = activity.paceSegments;
    final textColor = Colors.white;
    final subtextColor = Colors.white70;

    return SizedBox(
      width: 1080,
      height: 1920,
      child: Stack(
        children: [
          // Full background map
          if (segments.length >= 2)
            Positioned.fill(
              child: ClipRRect(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: segments.first.startLatLng,
                    initialZoom: 14.0,
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.solosprint.solosprint',
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: activity.route.map((r) => r.latLng).toList(),
                          color: const Color(0xFFFC4C02),
                          strokeWidth: 6,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          if (segments.length < 2)
            Positioned.fill(
              child: Container(color: const Color(0xFF1A1A2E)),
            ),

          // Dark overlay at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xDD000000)],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(40, 80, 40, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  Row(
                    children: [
                      const Icon(Icons.directions_run, color: Color(0xFFFF6B35), size: 36),
                      const SizedBox(width: 12),
                      Text(
                        'SoloSprint',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ShareService.formatDate(activity.startTime),
                    style: TextStyle(color: subtextColor, fontSize: 18),
                  ),
                  const SizedBox(height: 24),

                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statItem('DISTANCE', activity.distance.toStringAsFixed(2), 'km', textColor, subtextColor),
                      _statItem('PACE', ShareService.formatPace(activity.pace), '/km', textColor, subtextColor),
                      _statItem('DURATION', ShareService.formatDuration(activity.duration), '', textColor, subtextColor),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, String unit, Color textColor, Color subtextColor) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: subtextColor, fontSize: 14, letterSpacing: 1.5)),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(value, style: TextStyle(color: textColor, fontSize: 32, fontWeight: FontWeight.bold)),
            if (unit.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 6),
                child: Text(unit, style: TextStyle(color: subtextColor, fontSize: 16)),
              ),
          ],
        ),
      ],
    );
  }
}
