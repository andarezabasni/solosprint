import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../features/run/run_activity.dart';
import '../features/run/route_point.dart';
import '../core/database/activity_database.dart';

class DemoData {
  static const _uuid = Uuid();

  /// Generate a rectangular running route using explicit waypoints.
  /// Creates a visible loop that spans ~1-2km across the map.
  static List<RoutePoint> _generateRoute({
    required double startLat,
    required double startLng,
    required DateTime startTime,
    required double distanceKm,
  }) {
    final rng = math.Random(42);
    final metersPerDeg = 111320.0;

    // Calculate loop dimensions based on desired distance
    // A rectangular loop: 2*(width + height) = distanceKm * 1000
    final halfPerimeter = distanceKm * 500; // in meters
    final widthM = halfPerimeter * 0.6; // 60% for longer sides
    final heightM = halfPerimeter * 0.4; // 40% for shorter sides

    final widthDeg = widthM / metersPerDeg;
    final heightDeg = heightM / metersPerDeg;

    // 4 corners of the rectangular loop
    final corners = [
      LatLng(startLat, startLng), // start (bottom-left)
      LatLng(startLat + heightDeg, startLng), // top-left
      LatLng(startLat + heightDeg, startLng + widthDeg), // top-right
      LatLng(startLat, startLng + widthDeg), // bottom-right
    ];

    // Number of points per side (proportional to side length)
    final totalPointsPerSide = [
      (60 * heightM / (widthM + heightM)).round(),
      (60 * widthM / (widthM + heightM)).round(),
      (60 * heightM / (widthM + heightM)).round(),
      (60 * widthM / (widthM + heightM)).round(),
    ];
    // Ensure at least 3 points per side
    for (int i = 0; i < 4; i++) {
      if (totalPointsPerSide[i] < 3) totalPointsPerSide[i] = 3;
    }

    final points = <RoutePoint>[];
    var time = startTime;

    for (int side = 0; side < 4; side++) {
      final from = corners[side];
      final to = corners[(side + 1) % 4];
      final steps = totalPointsPerSide[side];

      for (int j = 0; j < steps; j++) {
        final t = (j + 1) / steps;

        // Interpolate with slight curve outward for natural look
        var lat = from.latitude + (to.latitude - from.latitude) * t;
        var lng = from.longitude + (to.longitude - from.longitude) * t;

        // Add outward bulge (perpendicular to direction) to avoid straight lines
        final bulgeDirLat = -(to.longitude - from.longitude);
        final bulgeDirLng = (to.latitude - from.latitude);
        final bulgeLen = math.sqrt(bulgeDirLat * bulgeDirLat + bulgeDirLng * bulgeDirLng);
        if (bulgeLen > 0) {
          final bulgeAmount = 0.0002 * math.sin(t * math.pi);
          lat += bulgeDirLat / bulgeLen * bulgeAmount;
          lng += bulgeDirLng / bulgeLen * bulgeAmount;
        }

        // Add small random jitter (±10m)
        lat += (rng.nextDouble() - 0.5) * 20 / metersPerDeg;
        lng += (rng.nextDouble() - 0.5) * 20 / metersPerDeg;

        final secondsBetween = 5 + rng.nextInt(8);
        time = time.add(Duration(seconds: secondsBetween));

        points.add(RoutePoint(
          latitude: lat,
          longitude: lng,
          timestamp: time,
        ));
      }
    }

    // Close the loop: replace last few points to end near start
    final closeSteps = 5;
    for (int i = 0; i < closeSteps && i < points.length; i++) {
      final idx = points.length - 1 - i;
      final t = (i + 1) / closeSteps;
      final old = points[idx];
      points[idx] = RoutePoint(
        latitude: old.latitude + (startLat - old.latitude) * t * 0.4,
        longitude: old.longitude + (startLng - old.longitude) * t * 0.4,
        timestamp: old.timestamp,
      );
    }

    return points;
  }

  /// Run A: Fast 5K rectangular loop
  static RunActivity _fastRun() {
    final start = DateTime.now().subtract(const Duration(days: 1));
    final route = _generateRoute(
      startLat: -6.2088,
      startLng: 106.8456,
      startTime: start,
      distanceKm: 5.0,
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

  /// Run B: Medium 3K loop
  static RunActivity _mediumRun() {
    final start = DateTime.now().subtract(const Duration(days: 3));
    final route = _generateRoute(
      startLat: -6.2146,
      startLng: 106.8451,
      startTime: start,
      distanceKm: 3.0,
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

  /// Run C: Slow 2K loop
  static RunActivity _slowRun() {
    final start = DateTime.now().subtract(const Duration(days: 7));
    final route = _generateRoute(
      startLat: -6.2012,
      startLng: 106.8521,
      startTime: start,
      distanceKm: 2.0,
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

  /// Run D: Long 10K loop
  static RunActivity _longRun() {
    final start = DateTime.now().subtract(const Duration(days: 14));
    final route = _generateRoute(
      startLat: -6.2254,
      startLng: 106.8374,
      startTime: start,
      distanceKm: 10.0,
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

    await ActivityDatabase.saveGoal('weekly_distance', 15.0);
    await ActivityDatabase.saveGoal('weekly_duration', 120.0);
    await ActivityDatabase.saveGoal('weekly_runs', 3.0);
    await ActivityDatabase.saveGoal('monthly_distance', 50.0);
    await ActivityDatabase.saveGoal('monthly_duration', 400.0);
    await ActivityDatabase.saveGoal('monthly_runs', 10.0);
  }
}
