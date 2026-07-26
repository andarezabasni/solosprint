import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import 'run_activity.dart';
import 'route_point.dart';
import '../../core/database/activity_database.dart';
import '../../core/notification_service.dart';

class RunProvider extends ChangeNotifier {
  bool _isTracking = false;
  bool _isPaused = false;
  DateTime? _startTime;
  final List<RoutePoint> _route = [];
  double _distance = 0.0;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _timer;
  int _elapsedSeconds = 0;
  LatLng? _initialPosition;
  List<LatLng> _plannedRoute = [];
  static const _uuid = Uuid();
  Timer? _notifTimer;

  bool get isTracking => _isTracking;
  bool get isPaused => _isPaused;
  DateTime? get startTime => _startTime;
  List<RoutePoint> get route => List.unmodifiable(_route);
  LatLng? get initialPosition => _initialPosition;
  List<LatLng> get plannedRoute => List.unmodifiable(_plannedRoute);
  double get distance => _distance;
  int get elapsedSeconds => _elapsedSeconds;
  String get formattedDuration => _formatDuration(_elapsedSeconds);

  double get pace {
    if (_distance <= 0) return 0;
    return (_elapsedSeconds / 60) / _distance;
  }

  String get formattedPace {
    if (_distance <= 0) return '--';
    final p = pace;
    final min = p.floor();
    final sec = ((p - min) * 60).round();
    return '$min:$sec';
  }

  /// Returns colored segments for the current route (for StatMaps rendering).
  List<PaceSegment> get paceSegments {
    if (_route.length < 2) return [];
    final segments = <PaceSegment>[];
    for (int i = 0; i < _route.length - 1; i++) {
      final a = _route[i];
      final b = _route[i + 1];
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

  Future<bool> requestPermission() async {
    final permission = await Geolocator.requestPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Start tracking with optional pre-planned route waypoints.
  void setPlannedRoute(List<LatLng> waypoints) {
    _plannedRoute = List.from(waypoints);
    notifyListeners();
  }

  void clearPlannedRoute() {
    _plannedRoute = [];
    notifyListeners();
  }

  Future<void> startTracking() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) return;

    // Get current location for map center
    try {
      // Try last known first, then request current
      var pos = await Geolocator.getLastKnownPosition();
      pos ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 10),
      );
      _initialPosition = LatLng(pos.latitude, pos.longitude);
      notifyListeners();
    } catch (_) {}

    _isTracking = true;
    _isPaused = false;
    _startTime = DateTime.now();
    _route.clear();
    _distance = 0.0;
    _elapsedSeconds = 0;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds++;
      notifyListeners();
    });

    NotificationService.showRunNotification(
      distance: _distance.toStringAsFixed(1),
      duration: _formatDuration(_elapsedSeconds),
    );
    _notifTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      NotificationService.showRunNotification(
        distance: _distance.toStringAsFixed(1),
        duration: _formatDuration(_elapsedSeconds),
      );
    });

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
        timeLimit: Duration(seconds: 10), // stop after 10s no movement
      ),
    ).listen((position) {
      // Skip if accuracy is too poor (GPS not locked)
      if (position.accuracy > 30) return; // skip if accuracy > 30m

      final point = RoutePoint(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
      );

      if (_route.isEmpty) {
        // First position: just set baseline, don't count distance
        _route.add(point);
        notifyListeners();
        return;
      }

      final last = _route.last;
      final distKm = Geolocator.distanceBetween(
            last.latitude, last.longitude, point.latitude, point.longitude,
          ) /
          1000.0;

      // Skip if movement is less than 10m (GPS drift filter)
      if (distKm < 0.01) return;

      // Also skip if speed suggests not walking (< 0.5 m/s ≈ 1.8 km/h)
      // Skip if speed is available and too slow for walking
      if (_route.length > 3 && position.speed < 0.3 && distKm < 0.05) return;

      _distance += distKm;
      _route.add(point);
      notifyListeners();
    });

    notifyListeners();
  }

  void pauseTracking() {
    if (!_isTracking || _isPaused) return;
    _isPaused = true;
    _notifTimer?.cancel();
    _timer?.cancel();
    _positionSubscription?.pause();
    NotificationService.showRunNotification(
      distance: _distance.toStringAsFixed(1),
      duration: _formatDuration(_elapsedSeconds),
      paused: true,
    );
    notifyListeners();
  }

  void resumeTracking() {
    if (!_isTracking || !_isPaused) return;
    _isPaused = false;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds++;
      notifyListeners();
    });
    _notifTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      NotificationService.showRunNotification(
        distance: _distance.toStringAsFixed(1),
        duration: _formatDuration(_elapsedSeconds),
      );
    });
    NotificationService.showRunNotification(
      distance: _distance.toStringAsFixed(1),
      duration: _formatDuration(_elapsedSeconds),
    );

    _positionSubscription?.resume();
    notifyListeners();
  }

  RunActivity stopTracking() {
    _isTracking = false;
    _isPaused = false;
    _timer?.cancel();
    _notifTimer?.cancel();
    _positionSubscription?.cancel();
    _timer = null;
    _notifTimer = null;
    _positionSubscription = null;

    NotificationService.cancelRunNotification();

    final activity = RunActivity(
      id: _uuid.v4(),
      startTime: _startTime ?? DateTime.now(),
      endTime: DateTime.now(),
      route: List.from(_route),
      distance: _distance,
    );

    ActivityDatabase.saveActivity(activity);
    notifyListeners();
    return activity;
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _notifTimer?.cancel();
    _positionSubscription?.cancel();
    NotificationService.cancelRunNotification();
    super.dispose();
  }
}
