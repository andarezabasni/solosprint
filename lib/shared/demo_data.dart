import 'dart:math' as math;
import 'package:uuid/uuid.dart';
import '../features/run/run_activity.dart';
import '../features/run/route_point.dart';
import '../core/database/activity_database.dart';

class DemoData {
  static const _uuid = Uuid();
  static final _rng = math.Random(42);

  /// Generate a route that follows a clear rectangular/perimeter block pattern.
  /// Each "street" is a straight segment, corners are smooth curves.
  static List<RoutePoint> _streetRoute({
    required double startLat,
    required double startLng,
    required DateTime startTime,
    required double blockSizeLat, // north-south size in degrees
    required double blockSizeLng, // east-west size in degrees
    int laps = 1,
  }) {
    final points = <RoutePoint>[];
    var time = startTime;

    // Define 4 corners of the rectangle
    final corners = <List<double>>[
      [startLat, startLng],                                     // bottom-left
      [startLat + blockSizeLat, startLng],                      // top-left
      [startLat + blockSizeLat, startLng + blockSizeLng],       // top-right
      [startLat, startLng + blockSizeLng],                      // bottom-right
    ];

    for (int lap = 0; lap < laps; lap++) {
      for (int c = 0; c < 4; c++) {
        final from = corners[c];
        final to = corners[(c + 1) % 4];
        final steps = (c % 2 == 0) ? 25 : 35; // vertical: 25, horizontal: 35

        for (int s = 0; s < steps; s++) {
          final t = (s + 1) / steps;
          // Smoothstep for natural acceleration/deceleration
          final smooth = t * t * (3 - 2 * t);

          final lat = from[0] + (to[0] - from[0]) * smooth;
          final lng = from[1] + (to[1] - from[1]) * smooth;

          // Add slight jitter (max ±3m) so it's not a perfect straight line
          final jitterLat = (_rng.nextDouble() - 0.5) * 6 / 111300;
          final jitterLng = (_rng.nextDouble() - 0.5) * 6 / 111300;

          time = time.add(Duration(milliseconds: 350 + _rng.nextInt(200)));
          points.add(RoutePoint(
            latitude: lat + jitterLat,
            longitude: lng + jitterLng,
            timestamp: time,
          ));
        }

        // Corner curve: smooth 90° turn
        if (c < 3 || lap < laps - 1) {
          final nextCorner = corners[(c + 1) % 4];
          final cornerLat = nextCorner[0];
          final cornerLng = nextCorner[1];
          for (int a = 0; a < 6; a++) {
            final angle = (a + 1) * math.pi / 12; // 0 to 90°
            final r = 0.00012; // corner radius
            final curveLat = cornerLat + r * math.sin(angle);
            final curveLng = cornerLng + r * math.cos(angle);
            time = time.add(const Duration(milliseconds: 300));
            points.add(RoutePoint(
              latitude: curveLat,
              longitude: curveLng,
              timestamp: time,
            ));
          }
        }
      }
    }

    return points;
  }

  /// Out-and-back route along a straight line.
  static List<RoutePoint> _outAndBackRoute({
    required double startLat,
    required double startLng,
    required DateTime startTime,
    required double distanceDeg,
  }) {
    final points = <RoutePoint>[];
    var time = startTime;

    // Going east
    for (int i = 0; i < 40; i++) {
      final t = (i + 1) / 40.0;
      final lng = startLng + distanceDeg * t;
      final lat = startLat + (_rng.nextDouble() - 0.5) * 0.00006;
      time = time.add(Duration(milliseconds: 400 + _rng.nextInt(200)));
      points.add(RoutePoint(latitude: lat, longitude: lng, timestamp: time));
    }
    // Coming back west
    for (int i = 0; i < 40; i++) {
      final t = (i + 1) / 40.0;
      final lng = startLng + distanceDeg * (1 - t);
      final lat = startLat + (_rng.nextDouble() - 0.5) * 0.00006;
      time = time.add(Duration(milliseconds: 400 + _rng.nextInt(200)));
      points.add(RoutePoint(latitude: lat, longitude: lng, timestamp: time));
    }
    return points;
  }

  // ─── Run A: Jakarta (Menteng) ~5km ───
  // Rectangular loop around Menteng streets
  static RunActivity _jakartaRun() {
    final start = DateTime.now().subtract(const Duration(days: 1));
    final route = _streetRoute(
      startLat: -6.1982,
      startLng: 106.8320,
      startTime: start,
      blockSizeLat: 0.0060,  // ~670m N-S
      blockSizeLng: 0.0075,  // ~830m E-W
      laps: 1,
    );
    return RunActivity(
      id: _uuid.v4(), startTime: start, endTime: route.last.timestamp,
      route: route, distance: 5.0,
    );
  }

  // ─── Run B: Makassar (Pantai Losari) ~3km ───
  // Out-and-back along the coast
  static RunActivity _makassarRun() {
    final start = DateTime.now().subtract(const Duration(days: 3));
    final route = _outAndBackRoute(
      startLat: -5.1375,
      startLng: 119.4050,
      startTime: start,
      distanceDeg: 0.018, // ~2km out and back = 4km total
    );
    return RunActivity(
      id: _uuid.v4(), startTime: start, endTime: route.last.timestamp,
      route: route, distance: 3.0,
    );
  }

  // ─── Run C: Bandung (Alun-Alun) ~2km ───
  // Small rectangular loop
  static RunActivity _bandungRun() {
    final start = DateTime.now().subtract(const Duration(days: 7));
    final route = _streetRoute(
      startLat: -6.9219,
      startLng: 107.6068,
      startTime: start,
      blockSizeLat: 0.0040,
      blockSizeLng: 0.0050,
      laps: 1,
    );
    return RunActivity(
      id: _uuid.v4(), startTime: start, endTime: route.last.timestamp,
      route: route, distance: 2.0,
    );
  }

  // ─── Run D: Surabaya (Tunjungan) ~10km ───
  // Large rectangular loop, 2 laps
  static RunActivity _surabayaRun() {
    final start = DateTime.now().subtract(const Duration(days: 14));
    final route = _streetRoute(
      startLat: -7.2575,
      startLng: 112.7390,
      startTime: start,
      blockSizeLat: 0.0080,
      blockSizeLng: 0.0120,
      laps: 2,
    );
    return RunActivity(
      id: _uuid.v4(), startTime: start, endTime: route.last.timestamp,
      route: route, distance: 10.0,
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
