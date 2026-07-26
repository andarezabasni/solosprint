import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../../core/database/activity_database.dart';
import '../../features/run/run_activity.dart';
import '../../features/run/route_point.dart';
import '../../features/share/share_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<RunActivity> _activities = [];

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  void _loadActivities() {
    setState(() {
      _activities = ActivityDatabase.getAllActivities();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadActivities,
          ),
        ],
      ),
      body: _activities.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No activities yet',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _activities.length,
              itemBuilder: (context, index) {
                final activity = _activities[index];
                return _buildActivityCard(context, activity);
              },
            ),
    );
  }

  Widget _buildActivityCard(BuildContext context, RunActivity activity) {
    final dateStr = DateFormat('EEE, MMM d').format(activity.startTime);
    final timeStr = DateFormat('HH:mm').format(activity.startTime);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _viewDetail(context, activity),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(dateStr,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Row(
                    children: [
                      Text(timeStr, style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SharePage(activity: activity),
                            ),
                          );
                        },
                        child: const Icon(Icons.share_outlined,
                            color: Color(0xFFFF6B35), size: 20),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMiniStat('Distance',
                      '${activity.distance.toStringAsFixed(2)} km'),
                  _buildMiniStat('Duration', _formatDuration(activity.duration)),
                  _buildMiniStat(
                      'Pace',
                      activity.pace > 0
                          ? '${activity.pace.toStringAsFixed(1)} /km'
                          : '--'),
                ],
              ),
              if (activity.route.length > 1) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text('Tap to view route map',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(value,
            style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  void _viewDetail(BuildContext context, RunActivity activity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ActivityDetailPage(activity: activity),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }
}

/// Detail page showing route map with colored polyline (StatMaps).
class _ActivityDetailPage extends StatelessWidget {
  final RunActivity activity;
  const _ActivityDetailPage({required this.activity});

  @override
  Widget build(BuildContext context) {
    final segments = activity.paceSegments;
    final dateStr = DateFormat('EEE, MMM d, HH:mm').format(activity.startTime);

    return Scaffold(
      appBar: AppBar(
        title: Text('Run Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SharePage(activity: activity),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            color: const Color(0xFFFF6B35),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statCol('Distance', '${activity.distance.toStringAsFixed(2)} km'),
                _statCol('Duration', _fmt(activity.duration)),
                _statCol('Pace', activity.pace > 0 ? '${activity.pace.toStringAsFixed(1)} /km' : '--'),
              ],
            ),
          ),
          // Map with StatMaps
          Expanded(
            child: segments.isEmpty
                ? const Center(child: Text('No route data'))
                : FlutterMap(
                    options: MapOptions(
                      initialCameraFit: CameraFit.bounds(
                        bounds: _calcBounds(segments),
                        padding: const EdgeInsets.all(40),
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.solosprint.solosprint',
                      ),
                      PolylineLayer(
                        polylines: segments.map((seg) {
                          return Polyline(
                            points: [seg.startLatLng, seg.endLatLng],
                            color: seg.color,
                            strokeWidth: 5,
                          );
                        }).toList(),
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: segments.first.startLatLng,
                            width: 24,
                            height: 24,
                            child: const Icon(Icons.circle,
                                color: Color(0xFF10B981), size: 16),
                          ),
                          Marker(
                            point: segments.last.endLatLng,
                            width: 24,
                            height: 24,
                            child: const Icon(Icons.flag,
                                color: Color(0xFFFF6B35), size: 24),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          // Pace legend
          Container(
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
          ),
          const SizedBox(height: 8),
          Text(dateStr, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _statCol(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _legendDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  LatLngBounds _calcBounds(List<PaceSegment> segments) {
    double minLat = double.infinity, maxLat = double.negativeInfinity;
    double minLng = double.infinity, maxLng = double.negativeInfinity;
    for (final s in segments) {
      for (final p in [s.startLatLng, s.endLatLng]) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLng) minLng = p.longitude;
        if (p.longitude > maxLng) maxLng = p.longitude;
      }
    }
    return LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );
  }
}
