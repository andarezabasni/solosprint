import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/language_provider.dart';
import '../../shared/localization.dart';
import 'run_provider.dart';
import 'route_planner.dart';


class RunPage extends StatelessWidget {
  const RunPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _RunPageBody();
  }
}

class _RunPageBody extends StatelessWidget {
  const _RunPageBody();

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    final provider = context.watch<RunProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(Strings.running)),
      body: provider.isTracking
          ? _buildTrackingUI(context, provider)
          : _buildPreRunUI(context, provider),
    );
  }

  Widget _buildPreRunUI(BuildContext context, RunProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.directions_run, size: 80, color: Color(0xFFFF6B35)),
          const SizedBox(height: 24),
          Text(
            'Ready to run?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your route will be tracked with GPS',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 200,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => provider.startTracking(),
              icon: const Icon(Icons.play_arrow, size: 28),
              label: const Text(
                'Start',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 200,
            child: OutlinedButton.icon(
              onPressed: () async {
                final initPos = provider.initialPosition;
                final result = await Navigator.push<Map<String, dynamic>>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RoutePlanner(initialPosition: initPos),
                  ),
                );
                if (result != null && context.mounted) {
                  final waypoints = result['waypoints'] as List<LatLng>;
                  provider.setPlannedRoute(waypoints);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Route set: ${result['distance'].toStringAsFixed(1)} km'
                        ', ~${result['estMinutes']} min est.',
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.route, size: 20),
              label: Text(provider.plannedRoute.isEmpty ? 'Plan Route' : 'Planned ✓'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFF6B35),
                side: const BorderSide(color: Color(0xFFFF6B35)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingUI(BuildContext context, RunProvider provider) {
    return Column(
      children: [
        // Stats row
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          color: const Color(0xFFFF6B35),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                  'Distance', '${provider.distance.toStringAsFixed(2)} km'),
              _buildStatItem('Duration', provider.formattedDuration),
              _buildStatItem('Pace', '${provider.formattedPace} /km'),
            ],
          ),
        ),
        // Map with StatMaps colored segments
        Expanded(
          child: _buildStatMap(provider),
        ),
        // Pace legend
        _buildPaceLegend(),
        // Controls
        Container(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (provider.isPaused)
                FloatingActionButton.extended(
                  heroTag: 'resume',
                  onPressed: () => provider.resumeTracking(),
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Resume'),
                )
              else
                FloatingActionButton.extended(
                  heroTag: 'pause',
                  onPressed: () => provider.pauseTracking(),
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.pause),
                  label: const Text('Pause'),
                ),
              const SizedBox(width: 16),
              FloatingActionButton.extended(
                heroTag: 'stop',
                onPressed: () => _stopRun(context, provider),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.stop),
                label: const Text('Stop'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }

  /// Render map. Shows grey background + GPS-off icon until first fix.
  Widget _buildStatMap(RunProvider provider) {
    final segments = provider.paceSegments;
    final hasPos = provider.route.isNotEmpty;
    final center = hasPos
        ? provider.route.last.latLng
        : (provider.initialPosition ?? const LatLng(-6.2, 106.8));

    final map = FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 16.0,
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.solosprint.solosprint',
          fallbackUrl:
              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          maxZoom: 19,
        ),
        if (segments.isNotEmpty)
          PolylineLayer(
            polylines: segments.map((seg) => Polyline(
                  points: [seg.startLatLng, seg.endLatLng],
                  color: seg.color,
                  strokeWidth: 5,
                )).toList(),
          ),
        // Planned route (dashed) — always show if set
        if (provider.plannedRoute.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: provider.plannedRoute,
                color: const Color(0xFFFF6B35).withValues(alpha: 0.35),
                strokeWidth: 2,
                borderStrokeWidth: 1,
                borderColor: const Color(0xFFFF6B35).withValues(alpha: 0.2),
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            if (segments.isNotEmpty)
              Marker(
                point: provider.route.first.latLng,
                width: 24,
                height: 24,
                child: const Icon(Icons.circle,
                    color: Color(0xFF10B981), size: 16),
              ),
            if (hasPos)
              Marker(
                point: provider.route.last.latLng,
                width: 30,
                height: 30,
                child: const Icon(Icons.my_location,
                    color: Color(0xFFFF6B35), size: 30),
              ),
          ],
        ),
      ],
    );

    // Always return a container (no null/empty states)
    if (hasPos) return map;
    return Stack(
      children: [
        map, // show map even without GPS
        const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.gps_off, size: 40, color: Colors.grey),
              SizedBox(height: 8),
              Text('Waiting for GPS...',
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  /// Small legend showing pace color mapping.
  Widget _buildPaceLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendDot(const Color(0xFF10B981)),
          const Text(' Fast', style: TextStyle(fontSize: 11)),
          const SizedBox(width: 12),
          _legendDot(const Color(0xFFFBBF24)),
          const Text(' Med', style: TextStyle(fontSize: 11)),
          const SizedBox(width: 12),
          _legendDot(const Color(0xFFEF4444)),
          const Text(' Slow', style: TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _legendDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  void _stopRun(BuildContext context, RunProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finish Run?'),
        content: Text(
          'Distance: ${provider.distance.toStringAsFixed(2)} km\n'
          'Duration: ${provider.formattedDuration}\n'
          'Pace: ${provider.formattedPace} /km',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.stopTracking();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
