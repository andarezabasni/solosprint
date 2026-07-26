import 'package:uuid/uuid.dart';
import '../features/run/run_activity.dart';
import '../features/run/route_point.dart';
import '../core/database/activity_database.dart';

class DemoData {
  static const _uuid = Uuid();

  /// Generate fake GPS points simulating a run with varied pace.
  static List<RoutePoint> _generateRoute({
    required double startLat,
    required double startLng,
    required int pointCount,
    required DateTime startTime,
  }) {
    final points = <RoutePoint>[];
    var lat = startLat;
    var lng = startLng;
    var time = startTime;

    for (int i = 0; i < pointCount; i++) {
      time = time.add(Duration(
        seconds: (2 + (i % 5)).round(),
      ));

      // Simulate direction changes
      lat += 0.0001 * (i % 3 - 1);
      lng += 0.0001 * ((i + 1) % 3 - 1);

      points.add(RoutePoint(
        latitude: lat,
        longitude: lng,
        timestamp: time,
      ));
    }
    return points;
  }

  /// Run A: Fast run with good pace
  static RunActivity _fastRun() {
    final start = DateTime.now().subtract(const Duration(days: 1));
    final route = _generateRoute(
      startLat: -6.2088,
      startLng: 106.8456,
      pointCount: 60,
      startTime: start,
    );
    final end = route.last.timestamp;
    final distance = 5.2; // km

    return RunActivity(
      id: _uuid.v4(),
      startTime: start,
      endTime: end,
      route: route,
      distance: distance,
    );
  }

  /// Run B: Medium pace run
  static RunActivity _mediumRun() {
    final start = DateTime.now().subtract(const Duration(days: 3));
    final route = _generateRoute(
      startLat: -6.2146,
      startLng: 106.8451,
      pointCount: 80,
      startTime: start,
    );
    final end = route.last.timestamp;
    final distance = 3.8;

    return RunActivity(
      id: _uuid.v4(),
      startTime: start,
      endTime: end,
      route: route,
      distance: distance,
    );
  }

  /// Run C: Slow / recovery run
  static RunActivity _slowRun() {
    final start = DateTime.now().subtract(const Duration(days: 7));
    final route = _generateRoute(
      startLat: -6.2012,
      startLng: 106.8521,
      pointCount: 40,
      startTime: start,
    );
    final end = route.last.timestamp;
    final distance = 2.1;

    return RunActivity(
      id: _uuid.v4(),
      startTime: start,
      endTime: end,
      route: route,
      distance: distance,
    );
  }

  /// Run D: Long run with varied pace
  static RunActivity _longRun() {
    final start = DateTime.now().subtract(const Duration(days: 14));
    final route = _generateRoute(
      startLat: -6.2254,
      startLng: 106.8374,
      pointCount: 120,
      startTime: start,
    );
    final end = route.last.timestamp;
    final distance = 10.0;

    return RunActivity(
      id: _uuid.v4(),
      startTime: start,
      endTime: end,
      route: route,
      distance: distance,
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
