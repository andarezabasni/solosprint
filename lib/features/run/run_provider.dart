import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'run_activity.dart';
import 'route_point.dart';
import '../../core/database/activity_database.dart';

class RunProvider extends ChangeNotifier {
  bool _isTracking = false;
  bool _isPaused = false;
  DateTime? _startTime;
  final List<RoutePoint> _route = [];
  double _distance = 0.0;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _timer;
  int _elapsedSeconds = 0;
  static const _uuid = Uuid();
  static final _notif = FlutterLocalNotificationsPlugin();
  static const _runChannelId = 'run_tracking';
  static const _runChannelName = 'Run Tracking';
  Timer? _notifTimer;

  bool get isTracking => _isTracking;
  bool get isPaused => _isPaused;
  DateTime? get startTime => _startTime;
  List<RoutePoint> get route => List.unmodifiable(_route);
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

  Future<void> startTracking() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) return;

    // Ensure run tracking notification channel exists
    try {
      final android = _notif.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _runChannelId,
          _runChannelName,
          importance: Importance.low,
          playSound: false,
          enableVibration: false,
        ),
      );
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

    _updateNotif();
    _notifTimer = Timer.periodic(const Duration(seconds: 5), (_) => _updateNotif());

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((position) {
      final point = RoutePoint(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
      );
      if (_route.isNotEmpty) {
        final last = _route.last;
        _distance += Geolocator.distanceBetween(
              last.latitude, last.longitude, point.latitude, point.longitude,
            ) /
            1000.0;
      }
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
    // Show paused notification
    _notif.show(
      999,
      'SoloSprint Paused',
      '${_distance.toStringAsFixed(2)} km | ${_formatDuration(_elapsedSeconds)}',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _runChannelId,
          _runChannelName,
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          showWhen: false,
        ),
      ),
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
    _notifTimer = Timer.periodic(const Duration(seconds: 5), (_) => _updateNotif());
    _updateNotif();

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

    _cancelNotif();

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

  void _updateNotif() {
    final km = _distance.toStringAsFixed(2);
    final dur = _formatDuration(_elapsedSeconds);
    _notif.show(
      999,
      'SoloSprint Running',
      '$km km | $dur',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _runChannelId,
          _runChannelName,
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          showWhen: false,
          autoCancel: false,
          showProgress: false,
        ),
      ),
    );
  }

  void _cancelNotif() {
    _notif.cancel(999);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _notifTimer?.cancel();
    _positionSubscription?.cancel();
    _cancelNotif();
    super.dispose();
  }
}
