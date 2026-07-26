import 'package:geolocator/geolocator.dart';
import 'route_point.dart';

class RunActivity {
  final String id;
  final DateTime startTime;
  DateTime? endTime;
  final List<RoutePoint> route;
  double distance; // in km
  int stepCount;

  RunActivity({
    required this.id,
    required this.startTime,
    this.endTime,
    List<RoutePoint>? route,
    this.distance = 0.0,
    this.stepCount = 0,
  }) : route = route ?? [];

  Duration get duration {
    if (endTime == null) return Duration.zero;
    return endTime!.difference(startTime);
  }

  double get pace {
    if (distance <= 0) return 0;
    return duration.inMinutes / distance;
  }

  List<PaceSegment> get paceSegments {
    if (route.length < 2) return [];
    final segments = <PaceSegment>[];
    for (int i = 0; i < route.length - 1; i++) {
      final a = route[i];
      final b = route[i + 1];
      final dt = b.timestamp.difference(a.timestamp).inSeconds;
      final distKm = Geolocator.distanceBetween(
            a.latitude, a.longitude, b.latitude, b.longitude,
          ) /
          1000.0;
      final pace = distKm > 0 ? (dt / 60) / distKm : 0.0;
      segments.add(PaceSegment(start: a, end: b, paceMinPerKm: pace));
    }
    return segments;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'route': route.map((r) => r.toJson()).toList(),
      'distance': distance,
      'stepCount': stepCount,
    };
  }

  factory RunActivity.fromJson(Map<String, dynamic> json) {
    final routeList = <RoutePoint>[];
    if (json['route'] is List) {
      for (final r in json['route'] as List) {
        if (r is Map) {
          routeList.add(RoutePoint.fromJson(Map<String, dynamic>.from(r)));
        }
      }
    }
    return RunActivity(
      id: '${json['id']}',
      startTime: DateTime.parse('${json['startTime']}'),
      endTime: json['endTime'] != null ? DateTime.parse('${json['endTime']}') : null,
      route: routeList,
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      stepCount: (json['stepCount'] as num?)?.toInt() ?? 0,
    );
  }
}
