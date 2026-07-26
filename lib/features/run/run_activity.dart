import 'package:latlong2/latlong.dart';

class RunActivity {
  final String id;
  final DateTime startTime;
  DateTime? endTime;
  final List<LatLng> route;
  double distance; // in km
  int stepCount;

  RunActivity({
    required this.id,
    required this.startTime,
    this.endTime,
    List<LatLng>? route,
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'route': route.map((l) => {'lat': l.latitude, 'lng': l.longitude}).toList(),
      'distance': distance,
      'stepCount': stepCount,
    };
  }

  factory RunActivity.fromJson(Map<String, dynamic> json) {
    return RunActivity(
      id: json['id'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      route: (json['route'] as List)
          .map((l) => LatLng(l['lat'] as double, l['lng'] as double))
          .toList(),
      distance: (json['distance'] as num).toDouble(),
      stepCount: json['stepCount'] as int,
    );
  }
}
