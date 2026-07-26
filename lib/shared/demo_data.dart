import 'dart:math' as math;
import 'package:uuid/uuid.dart';
import '../features/run/run_activity.dart';
import '../features/run/route_point.dart';
import '../core/database/activity_database.dart';

class DemoData {
  static const _uuid = Uuid();

  /// Generate a realistic running loop route.
  /// Returns points simulating a ~5km route with varied pace.
  static List<RoutePoint> _generateLoopRoute({
    required double startLat,
    required double startLng,
    required DateTime startTime,
    required int totalPoints,
    required double totalDistanceKm,
  }) {
    final points = <RoutePoint>[];
    final rng = math.Random(42); // fixed seed for reproducibility
    final metersPerDeg = 111320.0;

    // Pre-calculate steps: a loop that goes out and comes back
    // Uses sin/cos to create a smooth elliptical/rounded loop
    var lat = startLat;
    var lng = startLng;
    var time = startTime;

    // Loop radius in degrees (~2-3 km radius)
    final radiusDeg = (totalDistanceKm / (2 * math.pi)) / 111.0;

    for (int i = 0; i < totalPoints; i++) {
      final fraction = i / totalPoints;
      final angle = fraction * 2 * math.pi;

      // Smooth elliptical loop
      final targetLat = startLat + radiusDeg * math.sin(angle) * 0.7;
      final targetLng = startLng + radiusDeg * math.cos(angle);

      // Move smoothly toward target with slight randomness
      final stepsToTarget = (totalPoints / 6).ceil();

      if (i > 0) {
        final prevTargetIdx = ((i - 1) ~/ stepsToTarget) * stepsToTarget;
        final prevFraction = prevTargetIdx / totalPoints;
        final prevAngle = prevFraction * 2 * math.pi;
        final prevTargetLat = startLat + radiusDeg * math.sin(prevAngle) * 0.7;
        final prevTargetLng = startLng + radiusDeg * math.cos(prevAngle);

        // Interpolate toward current segment target
        final t = (i % stepsToTarget) / stepsToTarget;
        lat = prevTargetLat + (targetLat - prevTargetLat) * t;
        lng = prevTargetLng + (targetLng - prevTargetLng) * t;

        // Add small random jitter (±15m) to look natural
        lat += (rng.nextDouble() - 0.5) * 15 / metersPerDeg;
        lng += (rng.nextDouble() - 0.5) * 15 / metersPerDeg;
      }

      // Simulate variable pace: 5-15 seconds between points
      final secondsBetween = 5 + rng.nextInt(10);
      time = time.add(Duration(seconds: secondsBetween));

      points.add(RoutePoint(
        latitude: lat,
        longitude: lng,
        timestamp: time,
      ));
    }

    return points;
  }

  /// Run A: Fast 5K loop
  static RunActivity _fastRun() {
    final start = DateTime.now().subtract(const Duration(days: 1));
    final route = _generateLoopRoute(
      startLat: -6.2088, // Jakarta area
      startLng: 106.8456,
      startTime: start,
      totalPoints: 120,
      totalDistanceKm: 5.0,
    );
    final end = route.last.timestamp;

    return RunActivity(
      id: _uuid.v4(),
      startTime: start,
      endTime: end,
      route: route,
      distance: 5.0,
    );
  }

  /// Run B: Medium 3K out-and-back
  static RunActivity _mediumRun() {
    final start = DateTime.now().subtract(const Duration(days: 3));
    final route = _generateLoopRoute(
      startLat: -6.2146,
      startLng: 106.8451,
      startTime: start,
      totalPoints: 80,
      totalDistanceKm: 3.0,
    );
    final end = route.last.timestamp;

    return RunActivity(
      id: _uuid.v4(),
      startTime: start,
      endTime: end,
      route: route,
      distance: 3.0,
    );
  }

  /// Run C: Slow 2K recovery run
  static RunActivity _slowRun() {
    final start = DateTime.now().subtract(const Duration(days: 7));
    final route = _generateLoopRoute(
      startLat: -6.2012,
      startLng: 106.8521,
      startTime: start,
      totalPoints: 60,
      totalDistanceKm: 2.0,
    );
    final end = route.last.timestamp;

    return RunActivity(
      id: _uuid.v4(),
      startTime: start,
      endTime: end,
      route: route,
      distance: 2.0,
    );
  }

  /// Run D: Long 10K run
  static RunActivity _longRun() {
    final start = DateTime.now().subtract(const Duration(days: 14));
    final route = _generateLoopRoute(
      startLat: -6.2254,
      startLng: 106.8374,
      startTime: start,
      totalPoints: 200,
      totalDistanceKm: 10.0,
    );
    final end = route.last.timestamp;

    return RunActivity(
      id: _uuid.v4(),
      startTime: start,
      endTime: end,
      route: route,
      distance: 10.0,
    );
  }

  /// Load all demo data into Hive.
  static Future<void> loadAll() async {
    final runs = [_fastRun(), _mediumRun(), _slowRun(), _longRun()];
    for (final run in runs) {
      await ActivityDatabase.saveActivity(run);
    }

    // Set sample goals
    await ActivityDatabase.saveGoal('weekly_distance', 15.0);
    await ActivityDatabase.saveGoal('weekly_duration', 120.0);
    await ActivityDatabase.saveGoal('weekly_runs', 3.0);
    await ActivityDatabase.saveGoal('monthly_distance', 50.0);
    await ActivityDatabase.saveGoal('monthly_duration', 400.0);
    await ActivityDatabase.saveGoal('monthly_runs', 10.0);
  }
}
