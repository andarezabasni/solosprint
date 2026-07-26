import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../features/run/run_activity.dart';
import '../features/run/route_point.dart';
import '../core/database/activity_database.dart';

class DemoData {
  static const _uuid = Uuid();
  static final _rng = math.Random(42);

  /// Generate route points along a list of waypoints with smooth curves.
  static List<RoutePoint> _generateRouteFromWaypoints({
    required List<LatLng> waypoints,
    required DateTime startTime,
    int pointsPerSegment = 15,
    double jitterMeters = 8,
  }) {
    final points = <RoutePoint>[];
    var time = startTime;

    for (int w = 0; w < waypoints.length; w++) {
      final from = waypoints[w];
      final to = waypoints[(w + 1) % waypoints.length];

      for (int j = 0; j < pointsPerSegment; j++) {
        final t = (j + 1) / pointsPerSegment;

        // Smoothstep interpolation for organic curve
        final s = t * t * (3 - 2 * t);
        var lat = from.latitude + (to.latitude - from.latitude) * s;
        var lng = from.longitude + (to.longitude - from.longitude) * s;

        // Add slight outward curve
        final perpLat = -(to.longitude - from.longitude);
        final perpLng = to.latitude - from.latitude;
        final perpLen = math.sqrt(perpLat * perpLat + perpLng * perpLng);
        if (perpLen > 0) {
          final bulge = 0.00015 * math.sin(t * math.pi);
          lat += perpLat / perpLen * bulge;
          lng += perpLng / perpLen * bulge;
        }

        // Random jitter
        lat += (_rng.nextDouble() - 0.5) * 2 * jitterMeters / 111300;
        lng += (_rng.nextDouble() - 0.5) * 2 * jitterMeters / 111300;

        time = time.add(Duration(seconds: 5 + _rng.nextInt(8)));
        points.add(RoutePoint(latitude: lat, longitude: lng, timestamp: time));
      }
    }
    return points;
  }

  // ─── Run A: Monas (Jakarta Pusat) → Bundaran HI → GPI → balik ───
  // Loop ikonik di pusat Jakarta
  static RunActivity _jakartaRun() {
    final start = DateTime.now().subtract(const Duration(days: 1));
    final route = _generateRouteFromWaypoints(
      waypoints: [
        const LatLng(-6.1754, 106.8272), // Monas
        const LatLng(-6.1887, 106.8233), // Tugu Tani
        const LatLng(-6.1951, 106.8229), // Stasiun Gambir
        const LatLng(-6.2007, 106.8227), // Harmoni
        const LatLng(-6.2114, 106.8199), // Sarinah
        const LatLng(-6.2146, 106.8175), // Bundaran HI
        const LatLng(-6.2082, 106.8083), // Kedubes Jerman
        const LatLng(-6.1943, 106.8048), // Grand Indonesia
        const LatLng(-6.1845, 106.8096), // Stasiun Gondangdia
        const LatLng(-6.1784, 106.8185), // Lapangan Banteng
        const LatLng(-6.1754, 106.8272), // kembali ke Monas
      ],
      startTime: start,
      pointsPerSegment: 10,
    );
    return RunActivity(
      id: _uuid.v4(), startTime: start, endTime: route.last.timestamp,
      route: route, distance: 5.0,
    );
  }

  // ─── Run B:沿 Pantai Losari (Makassar) ───
  // Lari menyusuri pantai, bentuk out-and-back
  static RunActivity _makassarRun() {
    final start = DateTime.now().subtract(const Duration(days: 3));
    final route = _generateRouteFromWaypoints(
      waypoints: [
        const LatLng(-5.1369, 119.4103), // Anjungan Pantai Losari
        const LatLng(-5.1373, 119.4064),
        const LatLng(-5.1379, 119.4020),
        const LatLng(-5.1387, 119.3975),
        const LatLng(-5.1399, 119.3934), // Titik balik
        const LatLng(-5.1387, 119.3975),
        const LatLng(-5.1379, 119.4020),
        const LatLng(-5.1373, 119.4064),
        const LatLng(-5.1369, 119.4103), // kembali
      ],
      startTime: start,
      pointsPerSegment: 8,
      jitterMeters: 5,
    );
    return RunActivity(
      id: _uuid.v4(), startTime: start, endTime: route.last.timestamp,
      route: route, distance: 3.2,
    );
  }

  // ─── Run C: Alun-Alun Bandung ───
  // Lari keliling area Alun-Alun Bandung dan sekitarnya
  static RunActivity _bandungRun() {
    final start = DateTime.now().subtract(const Duration(days: 7));
    final route = _generateRouteFromWaypoints(
      waypoints: [
        const LatLng(-6.9219, 107.6068), // Alun-Alun Bandung
        const LatLng(-6.9190, 107.6073), // Jl. Asia Afrika
        const LatLng(-6.9165, 107.6058), // Museum Konferensi
        const LatLng(-6.9147, 107.6073), // Jl. Braga
        const LatLng(-6.9148, 107.6110), // Braga atas
        const LatLng(-6.9164, 107.6141), // Jl. Merdeka
        const LatLng(-6.9191, 107.6137), // Gedung Sate area
        const LatLng(-6.9218, 107.6119), // Jl. Diponegoro
        const LatLng(-6.9228, 107.6093), // Kembali ke Alun-Alun
        const LatLng(-6.9219, 107.6068),
      ],
      startTime: start,
      pointsPerSegment: 8,
    );
    return RunActivity(
      id: _uuid.v4(), startTime: start, endTime: route.last.timestamp,
      route: route, distance: 2.1,
    );
  }

  // ─── Run D: Taman Bungkul (Surabaya) ───
  // Lari keliling area kampus ITS dan Taman Bungkul
  static RunActivity _surabayaRun() {
    final start = DateTime.now().subtract(const Duration(days: 14));
    final route = _generateRouteFromWaypoints(
      waypoints: [
        const LatLng(-7.2929, 112.7363), // Taman Bungkul
        const LatLng(-7.2937, 112.7395),
        const LatLng(-7.2951, 112.7426),
        const LatLng(-7.2972, 112.7445), // Jl. Raya ITS
        const LatLng(-7.3000, 112.7442),
        const LatLng(-7.3025, 112.7430),
        const LatLng(-7.3045, 112.7408), // Gebang
        const LatLng(-7.3032, 112.7377),
        const LatLng(-7.3002, 112.7359),
        const LatLng(-7.2975, 112.7362), // belok
        const LatLng(-7.2952, 112.7368),
        const LatLng(-7.2929, 112.7363), // kembali
      ],
      startTime: start,
      pointsPerSegment: 10,
    );
    return RunActivity(
      id: _uuid.v4(), startTime: start, endTime: route.last.timestamp,
      route: route, distance: 10.2,
    );
  }

  static Future<void> loadAll() async {
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
