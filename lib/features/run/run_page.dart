import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import 'run_provider.dart';

class RunPage extends StatelessWidget {
  const RunPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RunProvider(),
      child: const _RunPageBody(),
    );
  }
}

class _RunPageBody extends StatelessWidget {
  const _RunPageBody();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RunProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Run')),
      body: provider.isTracking ? _buildTrackingUI(context, provider) : _buildPreRunUI(context, provider),
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
              _buildStatItem('Distance', '${provider.distance.toStringAsFixed(2)} km'),
              _buildStatItem('Duration', provider.formattedDuration),
              _buildStatItem('Pace', '${provider.formattedPace} /km'),
            ],
          ),
        ),
        // Map
        Expanded(
          child: _buildMap(provider),
        ),
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

  Widget _buildMap(RunProvider provider) {
    final route = provider.route;
    if (route.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: route.last,
        initialZoom: 16.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.solosprint.solosprint',
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: route,
              color: const Color(0xFFFF6B35),
              strokeWidth: 4,
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            if (route.length > 1)
              Marker(
                point: route.last,
                width: 30,
                height: 30,
                child: const Icon(
                  Icons.my_location,
                  color: Color(0xFFFF6B35),
                  size: 30,
                ),
              ),
            Marker(
              point: route.first,
              width: 30,
              height: 30,
              child: const Icon(
                Icons.circle,
                color: Color(0xFF10B981),
                size: 16,
              ),
            ),
          ],
        ),
      ],
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
