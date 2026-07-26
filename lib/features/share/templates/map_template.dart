import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../shared/widgets/app_logo.dart';
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
    final routePoints = activity.route.map((r) => r.latLng).toList();

    return SizedBox(
      width: 1080,
      height: 1920,
      child: routePoints.length < 2
          ? Container(color: const Color(0xFF1A1A2E))
          : Stack(
              children: [
                // Full background map
                Positioned.fill(
                  child: FlutterMap(
                    key: ValueKey('map-${activity.id}'),
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
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.solosprint.solosprint',
                      ),
                      // Segment-based polyline
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

                // Dark overlay at bottom with gradient
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
                            const AppLogo(size: 36),
                            const SizedBox(width: 12),
                            Text(
                              'SoloSprint',
                              style: const TextStyle(
                                color: Colors.white,
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
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 18),
                        ),
                        const SizedBox(height: 24),
                        // Stats row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _statItem('DISTANCE',
                                activity.distance.toStringAsFixed(2), 'km'),
                            _statItem(
                                'PACE',
                                ShareService.formatPace(activity.pace),
                                '/km'),
                            _statItem(
                                'DURATION',
                                ShareService.formatDuration(activity.duration),
                                ''),
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

  Widget _statItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white70, fontSize: 14, letterSpacing: 1.5)),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold)),
            if (unit.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 6),
                child: Text(unit,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 16)),
              ),
          ],
        ),
      ],
    );
  }
}
