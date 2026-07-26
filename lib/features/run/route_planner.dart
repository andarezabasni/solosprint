import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class RoutePlanner extends StatefulWidget {
  final LatLng? initialPosition;
  final double avgPaceMinPerKm; // user's average pace

  const RoutePlanner({
    super.key,
    this.initialPosition,
    this.avgPaceMinPerKm = 6.0,
  });

  @override
  State<RoutePlanner> createState() => _RoutePlannerState();
}

class _RoutePlannerState extends State<RoutePlanner> {
  final _waypoints = <LatLng>[];
  double _totalDistance = 0;
  bool _loopMode = false;

  LatLng get _center => _waypoints.isNotEmpty
      ? _waypoints.first
      : (widget.initialPosition ?? const LatLng(-6.2, 106.8));

  void _addWaypoint(TapPosition tap, LatLng point) {
    setState(() {
      _waypoints.add(point);
      _recalculate();
    });
  }

  void _undo() {
    if (_waypoints.isEmpty) return;
    setState(() {
      _waypoints.removeLast();
      _recalculate();
    });
  }

  void _clear() {
    setState(() {
      _waypoints.clear();
      _totalDistance = 0;
    });
  }

  void _recalculate() {
    double d = 0;
    for (int i = 1; i < _waypoints.length; i++) {
      d += const Distance().distance(_waypoints[i - 1], _waypoints[i]);
    }
    // Close loop if enabled
    if (_loopMode && _waypoints.length >= 3) {
      d += const Distance().distance(_waypoints.last, _waypoints.first);
    }
    _totalDistance = d;
  }

  String get _distanceKm => (_totalDistance / 1000).toStringAsFixed(2);
  int get _estMinutes => ((_totalDistance / 1000) * widget.avgPaceMinPerKm).round();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan Route'),
        actions: [
          Row(
            children: [
              if (_waypoints.length >= 2)
                _loopToggle(),
              IconButton(
                icon: const Icon(Icons.undo),
                tooltip: 'Undo last point',
                onPressed: _waypoints.isNotEmpty ? _undo : null,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Clear all',
                onPressed: _waypoints.isNotEmpty ? _clear : null,
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Map
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: _center,
                initialZoom: 15.0,
                onTap: _addWaypoint,
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
                // Planned route line
                if (_waypoints.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _loopMode && _waypoints.length >= 3
                            ? [..._waypoints, _waypoints.first]
                            : _waypoints,
                        color: const Color(0xFFFF6B35),
                        strokeWidth: 4,
                      ),
                    ],
                  ),
                // Waypoint markers
                MarkerLayer(
                  markers: _waypoints.asMap().entries.map((e) {
                    return Marker(
                      point: e.value,
                      width: 28,
                      height: 28,
                      child: Container(
                        decoration: BoxDecoration(
                          color: e.key == 0
                              ? const Color(0xFF10B981)
                              : const Color(0xFFFF6B35),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            '${e.key + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Stats panel
          if (_waypoints.length >= 2)
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFFFF6B35),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem('DISTANCE', '$_distanceKm km'),
                  _statItem(
                      'EST. TIME', '$_estMinutes min'),
                  _statItem('POINTS', _waypoints.length.toString()),
                ],
              ),
            ),

          // Hint when empty
          if (_waypoints.length < 2)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app, size: 18, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    'Tap on the map to place route waypoints',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: _waypoints.length >= 2
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pop(context, {
                'waypoints': _waypoints,
                'distance': _totalDistance / 1000,
                'estMinutes': _estMinutes,
              }),
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.check),
              label: const Text('Confirm Route'),
            )
          : null,
    );
  }

  Widget _loopToggle() {
    return GestureDetector(
      onTap: () => setState(() {
        _loopMode = !_loopMode;
        _recalculate();
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: _loopMode
              ? const Color(0xFF10B981).withValues(alpha: 0.15)
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                _loopMode ? const Color(0xFF10B981) : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.loop,
              size: 16,
              color: _loopMode ? const Color(0xFF10B981) : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              'Loop',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _loopMode ? const Color(0xFF10B981) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value) {
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
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
