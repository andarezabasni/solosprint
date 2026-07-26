import 'dart:math' as math;
import 'package:uuid/uuid.dart';
import '../features/run/run_activity.dart';
import '../features/run/route_point.dart';
import '../core/database/activity_database.dart';

class DemoData {
  static const _uuid = Uuid();
  static final _rng = math.Random(42);

  /// Generate route following a city grid pattern (realistic street layout).
  static List<RoutePoint> _gridRoute({
    required double startLat,
    required double startLng,
    required DateTime startTime,
    required int blocks, // number of blocks to traverse
    double blockSizeDeg = 0.0018, // ~200m per block
  }) {
    final points = <RoutePoint>[];
    var time = startTime;
    // Direction sequence: 0=up, 1=right, 2=down, 3=left
    final dirs = [0, 1, 0, 1, 2, 1, 2, 3, 0, 3, 0, 1, 2, 3, 0, 1];

    var lat = startLat;
    var lng = startLng;

    // First point
    time = time.add(const Duration(seconds: 1));
    points.add(RoutePoint(latitude: lat, longitude: lng, timestamp: time));

    for (int d = 0; d < dirs.length && d < blocks; d++) {
      final dir = dirs[d];
      // Each block = 20 steps with slight curve
      for (int s = 0; s < 20; s++) {
        final t = (s + 1) / 20.0;
        final smooth = t * t * (3 - 2 * t); // smoothstep

        // Move in grid direction
        double newLat = lat;
        double newLng = lng;
        switch (dir) {
          case 0: // up (north)
            newLat += blockSizeDeg * smooth * 0.1;
            newLng += 0.00005 * math.sin(s * 0.5);
            break;
          case 1: // right (east)
            newLng += blockSizeDeg * smooth * 0.1;
            newLat += 0.00005 * math.cos(s * 0.3);
            break;
          case 2: // down (south)
            newLat -= blockSizeDeg * smooth * 0.1;
            newLng += 0.00005 * math.sin(s * 0.4);
            break;
          case 3: // left (west)
            newLng -= blockSizeDeg * smooth * 0.1;
            newLat += 0.00005 * math.cos(s * 0.3);
            break;
        }

        // Corner transition: slight curve at end of each block
        if (s > 15) {
          final cornerWeight = (s - 15) / 5.0;
          final nextDir = dirs[(d + 1) % dirs.length];
          switch (nextDir) {
            case 0:
              newLat += blockSizeDeg * 0.02 * cornerWeight;
              break;
            case 1:
              newLng += blockSizeDeg * 0.02 * cornerWeight;
              break;
            case 2:
              newLat -= blockSizeDeg * 0.02 * cornerWeight;
              break;
            case 3:
              newLng -= blockSizeDeg * 0.02 * cornerWeight;
              break;
          }
        }

        lat = newLat;
        lng = newLng;

        time = time.add(Duration(milliseconds: 400 + _rng.nextInt(300)));
        points.add(RoutePoint(latitude: lat, longitude: lng, timestamp: time));
      }
    }

    // Close the loop: return toward start
    for (int i = 0; i < 30; i++) {
      final t = (i + 1) / 30.0;
      lat += (startLat - lat) * t * 0.1;
      lng += (startLng - lng) * t * 0.1;
      lat += (_rng.nextDouble() - 0.5) * 0.00005;
      lng += (_rng.nextDouble() - 0.5) * 0.00005;
      time = time.add(Duration(milliseconds: 400 + _rng.nextInt(200)));
      points.add(RoutePoint(latitude: lat, longitude: lng, timestamp: time));
    }

    return points;
  }

  /// Generate an out-and-back route (lurus lalu balik).
  static List<RoutePoint> _outAndBackRoute({
    required double startLat,
    required double startLng,
    required DateTime startTime,
    required double lengthDeg,
  }) {
    final points = <RoutePoint>[];
    var time = startTime;
    var lat = startLat;
    var lng = startLng;

    // Go east
    for (int i = 0; i < 40; i++) {
      lng += lengthDeg / 40;
      lat += (_rng.nextDouble() - 0.5) * 0.00008;
      time = time.add(Duration(milliseconds: 500 + _rng.nextInt(300)));
      points.add(RoutePoint(latitude: lat, longitude: lng, timestamp: time));
    }
    // Turn around and go west
    for (int i = 0; i < 40; i++) {
      lng -= lengthDeg / 40;
      lat += (_rng.nextDouble() - 0.5) * 0.00008;
      time = time.add(Duration(milliseconds: 500 + _rng.nextInt(300)));
      points.add(RoutePoint(latitude: lat, longitude: lng, timestamp: time));
    }
    return points;
  }

  // ─── Run A: Jakarta (Menteng) ~5km ───
  // Grid route di area Menteng, Jakarta Pusat
  static RunActivity _jakartaRun() {
    final start = DateTime.now().subtract(const Duration(days: 1));
    final route = _gridRoute(
      startLat: -6.1982,
      startLng: 106.8320,
      startTime: start,
      blocks: 16,
      blockSizeDeg: 0.0015,
    );
    final end = route.last.timestamp;
    return RunActivity(
      id: _uuid.v4(), startTime: start, endTime: end,
      route: route, distance: 5.0,
    );
  }

  // ─── Run B: Makassar (Pantai Losari) ~3km ───
  // Out-and-back di sepanjang pantai
  static RunActivity _makassarRun() {
    final start = DateTime.now().subtract(const Duration(days: 3));
    final route = _outAndBackRoute(
      startLat: -5.1375,
      startLng: 119.4050,
      startTime: start,
      lengthDeg: 0.018,
    );
    final end = route.last.timestamp;
    return RunActivity(
      id: _uuid.v4(), startTime: start, endTime: end,
      route: route, distance: 3.0,
    );
  }

  // ─── Run C: Bandung (Dago) ~2.5km ───
  // Grid route kecil di area Dago
  static RunActivity _bandungRun() {
    final start = DateTime.now().subtract(const Duration(days: 7));
    final route = _gridRoute(
      startLat: -6.8762,
      startLng: 107.6172,
      startTime: start,
      blocks: 10,
      blockSizeDeg: 0.0012,
    );
    final end = route.last.timestamp;
    return RunActivity(
      id: _uuid.v4(), startTime: start, endTime: end,
      route: route, distance: 2.5,
    );
  }

  // ─── Run D: Surabaya (Tunjungan) ~8km ───
  // Grid route besar di pusat Surabaya
  static RunActivity _surabayaRun() {
    final start = DateTime.now().subtract(const Duration(days: 14));
    final route = _gridRoute(
      startLat: -7.2575,
      startLng: 112.7390,
      startTime: start,
      blocks: 24,
      blockSizeDeg: 0.0020,
    );
    final end = route.last.timestamp;
    return RunActivity(
      id: _uuid.v4(), startTime: start, endTime: end,
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
