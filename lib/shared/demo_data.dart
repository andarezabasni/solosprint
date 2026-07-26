import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../features/run/run_activity.dart';
import '../features/run/route_point.dart';
import '../core/database/activity_database.dart';

class DemoData {
  static const _uuid = Uuid();

  /// Generate route points from explicit waypoints (follows real roads).
  /// Each waypoint is a (lat, lng) on an actual street.
  /// Segment pace is assigned manually so StatMaps colors show correctly.
  static List<RoutePoint> _waypointRoute({
    required List<LatLng> waypoints,
    required DateTime startTime,
    required List<double> segmentPace, // min/km for each segment
    int pointsPerSegment = 30,
  }) {
    final pts = <RoutePoint>[];
    var time = startTime;

    for (int w = 0; w < waypoints.length - 1; w++) {
      final from = waypoints[w];
      final to = waypoints[w + 1];
      final pace = segmentPace[w];
      final segDistM = Geolocator.distanceBetween(
          from.latitude, from.longitude, to.latitude, to.longitude);
      final totalSec = (pace * segDistM / 1000 * 60).round(); // pace → seconds
      final stepSec = totalSec / pointsPerSegment;

      for (int i = 0; i < pointsPerSegment; i++) {
        final t = (i + 1) / pointsPerSegment;
        final lat = from.latitude + (to.latitude - from.latitude) * t;
        final lng = from.longitude + (to.longitude - from.longitude) * t;
        time = time.add(Duration(milliseconds: (stepSec * 1000).round()));
        pts.add(RoutePoint(latitude: lat, longitude: lng, timestamp: time));
      }
    }
    return pts;
  }

  // ─── Run A: Jakarta — Jl. Sudirman (5km, varied pace) ───
  // Route along Jl. Jend. Sudirman (main road, clearly visible on OSM)
  static RunActivity _jakartaRun() {
    final start = DateTime.now().subtract(const Duration(days: 1));
    final waypoints = [
      const LatLng(-6.2250, 106.8020), // Semanggi
      const LatLng(-6.2200, 106.8070), // Bendungan Hilir
      const LatLng(-6.2150, 106.8130), // Dukuh Atas
      const LatLng(-6.2120, 106.8180), // Bundaran HI
      const LatLng(-6.2150, 106.8130), // kembali Dukuh Atas
      const LatLng(-6.2200, 106.8070), // Bendungan Hilir
      const LatLng(-6.2250, 106.8020), // kembali Semanggi
    ];
    final route = _waypointRoute(
      waypoints: waypoints,
      startTime: start,
      segmentPace: [4.2, 4.5, 5.8, 6.5, 5.0, 4.8],
      // ^ fast, fast, medium, slow, medium, fast
    );
    return RunActivity(
      id: _uuid.v4(), startTime: start, endTime: route.last.timestamp,
      route: route, distance: 5.2,
    );
  }

  // ─── Run B: Makassar — Pantai Losari (3km, easy pace) ───
  static RunActivity _makassarRun() {
    final start = DateTime.now().subtract(const Duration(days: 3));
    final waypoints = [
      const LatLng(-5.1340, 119.4080), // Losari Utara
      const LatLng(-5.1355, 119.4070),
      const LatLng(-5.1370, 119.4060), // tengah Losari
      const LatLng(-5.1385, 119.4050),
      const LatLng(-5.1400, 119.4040), // Losari Selatan
      const LatLng(-5.1385, 119.4050), // balik
      const LatLng(-5.1370, 119.4060),
      const LatLng(-5.1355, 119.4070),
      const LatLng(-5.1340, 119.4080), // finish
    ];
    final route = _waypointRoute(
      waypoints: waypoints,
      startTime: start,
      segmentPace: [5.5, 5.3, 5.6, 5.8, 6.0, 5.7, 5.4, 5.2],
    );
    return RunActivity(
      id: _uuid.v4(), startTime: start, endTime: route.last.timestamp,
      route: route, distance: 3.0,
    );
  }

  // ─── Run C: Bandung — Jl. Asia Afrika (2km, slow) ───
  static RunActivity _bandungRun() {
    final start = DateTime.now().subtract(const Duration(days: 7));
    final waypoints = [
      const LatLng(-6.9210, 107.6070), // Alun-Alun
      const LatLng(-6.9190, 107.6075), // Asia Afrika
      const LatLng(-6.9170, 107.6070), // Museum Konferensi
      const LatLng(-6.9150, 107.6075),
      const LatLng(-6.9155, 107.6100), // Braga
      const LatLng(-6.9170, 107.6120),
      const LatLng(-6.9190, 107.6120), // Merdeka
      const LatLng(-6.9210, 107.6100),
    ];
    final route = _waypointRoute(
      waypoints: waypoints,
      startTime: start,
      segmentPace: [6.2, 6.0, 6.5, 6.8, 7.0, 6.5, 6.0],
    );
    return RunActivity(
      id: _uuid.v4(), startTime: start, endTime: route.last.timestamp,
      route: route, distance: 2.1,
    );
  }

  // ─── Run D: Surabaya — Tunjungan (8km, interval training) ───
  static RunActivity _surabayaRun() {
    final start = DateTime.now().subtract(const Duration(days: 14));
    final waypoints = [
      const LatLng(-7.2570, 112.7390), // Tunjungan
      const LatLng(-7.2600, 112.7390),
      const LatLng(-7.2630, 112.7395), // Gubernur Suryo
      const LatLng(-7.2660, 112.7400),
      const LatLng(-7.2690, 112.7405), // ITS
      const LatLng(-7.2660, 112.7400), // balik
      const LatLng(-7.2630, 112.7395),
      const LatLng(-7.2600, 112.7390),
      const LatLng(-7.2570, 112.7390), // finish
    ];
    final route = _waypointRoute(
      waypoints: waypoints,
      startTime: start,
      segmentPace: [5.0, 4.5, 4.0, 3.8, 4.5, 5.0, 5.5, 6.0],
      // ^ progressive: fast interval then recovery
    );
    return RunActivity(
      id: _uuid.v4(), startTime: start, endTime: route.last.timestamp,
      route: route, distance: 8.0,
    );
  }

  static Future<void> loadAll() async {
    await ActivityDatabase.clearAll();
    final runs = [_jakartaRun(), _makassarRun(), _bandungRun(), _surabayaRun()];
    for (final run in runs) {
      await ActivityDatabase.saveActivity(run);
    }
    await ActivityDatabase.saveGoal('weekly_distance', 15.0);
    await ActivityDatabase.saveGoal('weekly_duration', 120.0);
    await ActivityDatabase.saveGoal('weekly_runs', 3.0);
    await ActivityDatabase.saveGoal('monthly_distance', 50.0);
    await ActivityDatabase.saveGoal('monthly_duration', 400.0);
    await ActivityDatabase.saveGoal('monthly_runs', 10.0);
  }
}
