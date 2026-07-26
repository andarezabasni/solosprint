import 'dart:math' as math;
import 'package:uuid/uuid.dart';
import '../features/run/run_activity.dart';
import '../features/run/route_point.dart';
import '../core/database/activity_database.dart';

class DemoData {
  static const _uuid = Uuid();
  static final _rng = math.Random(42);

  /// Generate an organic running route that follows approximate street patterns.
  /// Each segment has unique length & slight angle variation for realism.
  static List<RoutePoint> _organicRoute({
    required double startLat,
    required double startLng,
    required DateTime startTime,
    required double totalDistanceKm,
    required int turns,
  }) {
    const metersPerDeg = 111300.0;
    final points = <RoutePoint>[];
    var time = startTime;
    var lat = startLat;
    var lng = startLng;

    // First point
    points.add(RoutePoint(latitude: lat, longitude: lng, timestamp: time));

    // Generate random but realistic turn angles (mostly ~90° with variation)
    final angles = <double>[];
    var currentAngle = _rng.nextDouble() * 2 * math.pi;
    for (int t = 0; t < turns; t++) {
      // Mostly 90° turns (±30°) to simulate street corners
      final turn = (math.pi / 2) + (_rng.nextDouble() - 0.5) * math.pi / 3;
      currentAngle += turn;
      angles.add(currentAngle);
    }

    // Distribute distance across segments (with variation)
    final segDistKm = <double>[];
    var remainingKm = totalDistanceKm;
    for (int s = 0; s < turns; s++) {
      final maxSeg = remainingKm / (turns - s) * (1.5 + _rng.nextDouble() * 0.5);
      segDistKm.add(maxSeg);
      remainingKm -= maxSeg;
    }

    // Generate points for each segment
    for (int s = 0; s < turns; s++) {
      final angle = angles[s];
      final segDistM = segDistKm[s] * 1000;
      final steps = (segDistM / 15).round().clamp(5, 80);
      final dLat = math.cos(angle) * segDistM / metersPerDeg;
      final dLng = math.sin(angle) * segDistM / metersPerDeg;

      for (int i = 0; i < steps; i++) {
        final t = (i + 1) / steps;
        final smooth = t * t * (3 - 2 * t);

        // Move toward target
        var newLat = lat + dLat * smooth;
        var newLng = lng + dLng * smooth;

        // Add drift (gradual curve) for organic feel
        final drift = 0.00004 * math.sin(t * math.pi * 1.5 + s);
        newLat += drift * math.cos(angle + math.pi / 2);
        newLng += drift * math.sin(angle + math.pi / 2);

        // Jitter (±2m)
        newLat += (_rng.nextDouble() - 0.5) * 4 / metersPerDeg;
        newLng += (_rng.nextDouble() - 0.5) * 4 / metersPerDeg;

        time = time.add(Duration(
            milliseconds: (300 + _rng.nextInt(400)).round()));
        points.add(RoutePoint(
            latitude: newLat, longitude: newLng, timestamp: time));

        lat = newLat;
        lng = newLng;
      }

      // Corner curve
      final nextAngle = angles[(s + 1) % angles.length];
      final turnAngle = nextAngle - angle;
      for (int c = 0; c < 6; c++) {
        final ca = angle + turnAngle * (c + 1) / 7;
        final cr = 0.00015; // corner radius
        lat += cr * math.cos(ca);
        lng += cr * math.sin(ca);
        time = time.add(const Duration(milliseconds: 250));
        points.add(RoutePoint(latitude: lat, longitude: lng, timestamp: time));
      }
    }

    // Return to near start (loop closing)
    final closeSteps = 20;
    for (int i = 0; i < closeSteps; i++) {
      final t = (i + 1) / closeSteps;
      lat += (startLat - lat) * t * 0.08;
      lng += (startLng - lng) * t * 0.08;
      lat += (_rng.nextDouble() - 0.5) * 3 / metersPerDeg;
      lng += (_rng.nextDouble() - 0.5) * 3 / metersPerDeg;
      time = time.add(Duration(milliseconds: 300 + _rng.nextInt(200)));
      points.add(RoutePoint(latitude: lat, longitude: lng, timestamp: time));
    }

    return points;
  }

  // ─── Run A: Jakarta (Kuningan - Rasuna Said) ~5km ───
  static RunActivity _jakartaRun() {
    final start = DateTime.now().subtract(const Duration(days: 1));
    final route = _organicRoute(
      startLat: -6.2273, startLng: 106.8296,
      startTime: start,
      totalDistanceKm: 5.0,
      turns: 6,
    );
    return RunActivity(
      id: _uuid.v4(), startTime: start, endTime: route.last.timestamp,
      route: route, distance: 5.0,
    );
  }

  // ─── Run B: Makassar (Pantai Losari) ~3km ───
  static RunActivity _makassarRun() {
    final start = DateTime.now().subtract(const Duration(days: 3));
    final route = _organicRoute(
      startLat: -5.1375, startLng: 119.4050,
      startTime: start,
      totalDistanceKm: 3.0,
      turns: 4,
    );
    return RunActivity(
      id: _uuid.v4(), startTime: start, endTime: route.last.timestamp,
      route: route, distance: 3.0,
    );
  }

  // ─── Run C: Bandung (Riau - Dago) ~2.5km ───
  static RunActivity _bandungRun() {
    final start = DateTime.now().subtract(const Duration(days: 7));
    final route = _organicRoute(
      startLat: -6.8875, startLng: 107.6140,
      startTime: start,
      totalDistanceKm: 2.5,
      turns: 5,
    );
    return RunActivity(
      id: _uuid.v4(), startTime: start, endTime: route.last.timestamp,
      route: route, distance: 2.5,
    );
  }

  // ─── Run D: Surabaya (Basuki Rahmat - Tunjungan) ~8km ───
  static RunActivity _surabayaRun() {
    final start = DateTime.now().subtract(const Duration(days: 14));
    final route = _organicRoute(
      startLat: -7.2625, startLng: 112.7395,
      startTime: start,
      totalDistanceKm: 8.0,
      turns: 8,
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
