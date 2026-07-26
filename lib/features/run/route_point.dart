import 'dart:ui';
import 'package:latlong2/latlong.dart';

class RoutePoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  const RoutePoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  LatLng get latLng => LatLng(latitude, longitude);

  Map<String, dynamic> toJson() => {
        'lat': latitude,
        'lng': longitude,
        'ts': timestamp.toIso8601String(),
      };

  factory RoutePoint.fromJson(Map<String, dynamic> json) => RoutePoint(
        latitude: json['lat'] as double,
        longitude: json['lng'] as double,
        timestamp: DateTime.parse(json['ts'] as String),
      );
}

class PaceSegment {
  final RoutePoint start;
  final RoutePoint end;
  final double paceMinPerKm; // minutes per km

  PaceSegment({required this.start, required this.end, required this.paceMinPerKm});

  LatLng get startLatLng => start.latLng;
  LatLng get endLatLng => end.latLng;

  Color get color {
    if (paceMinPerKm <= 0) return _paceColors[5]; // unknown = red
    if (paceMinPerKm < 4.0) return _paceColors[0]; // very fast
    if (paceMinPerKm < 5.0) return _paceColors[1]; // fast
    if (paceMinPerKm < 6.0) return _paceColors[2]; // medium
    if (paceMinPerKm < 7.0) return _paceColors[3]; // slow
    return _paceColors[4]; // very slow
  }

  // Strava-inspired: green = fast, red = slow
  static const List<Color> _paceColors = [
    Color(0xFF10B981), // < 4:00 /km
    Color(0xFF34D399), // 4:00–4:59
    Color(0xFFFBBF24), // 5:00–5:59
    Color(0xFFF97316), // 6:00–6:59
    Color(0xFFEF4444), // >= 7:00
    Color(0xFF6B7280), // unknown
  ];

  static String paceLabel(double pace) {
    if (pace <= 0) return '--';
    final min = pace.floor();
    final sec = ((pace - min) * 60).round();
    return '$min:${sec.toString().padLeft(2, '0')}';
  }
}
