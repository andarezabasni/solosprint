import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../run/run_activity.dart';
import '../share_service.dart';

class ClassicTemplate extends StatelessWidget {
  final RunActivity activity;
  final bool darkMode;

  const ClassicTemplate({
    super.key,
    required this.activity,
    this.darkMode = true,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = darkMode ? const Color(0xFF1A1A2E) : Colors.white;
    final textColor = darkMode ? Colors.white : const Color(0xFF1A1A2E);
    final subtextColor = darkMode ? Colors.white70 : Colors.grey[700]!;
    final cardBg = darkMode ? const Color(0xFF252540) : const Color(0xFFF5F5F5);
    final routePoints = activity.route.map((r) => r.latLng).toList();

    return Container(
      width: 1080,
      height: 1920,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(color: bgColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Row(
            children: [
              const AppLogo(size: 52),
              const SizedBox(width: 12),
              Text(
                'SoloSprint',
                style: TextStyle(
                  color: textColor,
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            ShareService.formatDate(activity.startTime),
            style: TextStyle(color: subtextColor, fontSize: 22),
          ),
          const SizedBox(height: 40),

          // Route polyline
          Expanded(
            child: routePoints.length < 2
                ? Center(
                    child: Icon(Icons.route, size: 120, color: subtextColor),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: FlutterMap(
                      key: ValueKey('classic-${activity.id}'),
                      options: MapOptions(
                        initialCameraFit: CameraFit.bounds(
                          bounds: _getBounds(routePoints),
                          padding: const EdgeInsets.all(30),
                        ),
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                          subdomains: const ['a', 'b', 'c', 'd'],
                          userAgentPackageName: 'com.solosprint.solosprint',
                          fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          maxZoom: 19,
                        ),
                        // Render as individual segment polylines for reliability
                        PolylineLayer(
                          polylines: [
                            for (int i = 0; i < routePoints.length - 1; i++)
                              Polyline(
                                points: [routePoints[i], routePoints[i + 1]],
                                color: const Color(0xFFFC4C02),
                                strokeWidth: 6,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 32),

          // Stats card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem('DISTANCE', activity.distance.toStringAsFixed(2), 'km', textColor, subtextColor),
                _statItem('PACE', ShareService.formatPace(activity.pace), '/km', textColor, subtextColor),
                _statItem('DURATION', ShareService.formatDuration(activity.duration), '', textColor, subtextColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  LatLngBounds _getBounds(List<LatLng> points) {
    double minLat = double.infinity, maxLat = double.negativeInfinity;
    double minLng = double.infinity, maxLng = double.negativeInfinity;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    return LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );
  }

  Widget _statItem(String label, String value, String unit, Color textColor, Color subtextColor) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: subtextColor, fontSize: 16, letterSpacing: 1.5)),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(value, style: TextStyle(color: textColor, fontSize: 44, fontWeight: FontWeight.bold)),
            if (unit.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 6),
                child: Text(unit, style: TextStyle(color: subtextColor, fontSize: 20)),
              ),
          ],
        ),
      ],
    );
  }
}
