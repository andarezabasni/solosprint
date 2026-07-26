import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/database/activity_database.dart';
import '../../core/notification_service.dart';

class StepProvider extends ChangeNotifier {
  int _todaySteps = 0;
  int _lastRawSteps = -1;
  DateTime? _lastStepTime;
  String _status = 'unknown';
  StreamSubscription<StepCount>? _stepSubscription;
  StreamSubscription<PedestrianStatus>? _statusSubscription;
  Timer? _saveTimer;
  String _todayKey = '';
  bool _hasPermission = false;

  static const _maxStepRate = 4; // >4 steps/sec = vehicle
  int _readingsSinceReset = 0;
  int _lastNotifCheckSteps = -1;

  int get todaySteps => _todaySteps;
  String get status => _status;
  bool get hasPermission => _hasPermission;

  int getStepsForDay(String dateKey) => ActivityDatabase.getDailySteps(dateKey);

  Map<String, int> get lastWeekSteps {
    final result = <String, int>{};
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    for (int i = 0; i < 7; i++) {
      final d = monday.add(Duration(days: i));
      final key = _dateKey(d);
      result[key] = key == _dateKey(now) ? _todaySteps : ActivityDatabase.getDailySteps(key);
    }
    return result;
  }

  Map<String, int> getWeekSteps(DateTime monday) {
    final result = <String, int>{};
    final now = _dateKey(DateTime.now());
    for (int i = 0; i < 7; i++) {
      final d = monday.add(Duration(days: i));
      final key = _dateKey(d);
      result[key] = key == now ? _todaySteps : ActivityDatabase.getDailySteps(key);
    }
    return result;
  }

  /// Start listening to pedometer.
  Future<void> startListening() async {
    _todayKey = _dateKey(DateTime.now());
    _todaySteps = ActivityDatabase.getGoal('saved_steps', defaultValue: 0).toInt();

    // Request ACTIVITY_RECOGNITION permission (required on Android 10+)
    try {
      final status = await Permission.activityRecognition.request();
      _hasPermission = status.isGranted;
      if (!_hasPermission) {
        debugPrint('StepProvider: ACTIVITY_RECOGNITION denied');
      }
    } catch (e) {
      // Not supported on this platform (e.g., Windows)
      _hasPermission = true;
      debugPrint('StepProvider: permission_handler unavailable ($e)');
    }

    _stepSubscription = Pedometer.stepCountStream.listen(
      (stepCount) => _processStepCount(stepCount.steps),
      onError: (error) {
        debugPrint('StepProvider error: $error');
        notifyListeners();
      },
    );

    _statusSubscription = Pedometer.pedestrianStatusStream.listen(
      (status) {
        _status = status.status;
        notifyListeners();
      },
      onError: (error) {
        _status = 'unknown';
        notifyListeners();
      },
    );

    _saveTimer = Timer.periodic(const Duration(seconds: 30), (_) => _save());
  }

  void _processStepCount(int rawSteps) {
    // Day change detection
    final newKey = _dateKey(DateTime.now());
    if (newKey != _todayKey) {
      ActivityDatabase.saveDailySteps(_todayKey, _todaySteps);
      _todayKey = newKey;
      _todaySteps = 0;
      _lastRawSteps = -1;
      _readingsSinceReset = 0;
    }

    // First reading: store baseline, don't count
    if (_lastRawSteps < 0) {
      _lastRawSteps = rawSteps;
      _lastStepTime = DateTime.now();
      _readingsSinceReset = 1;
      return;
    }

    final now = DateTime.now();
    final deltaSteps = rawSteps - _lastRawSteps;
    final deltaMs = now.difference(_lastStepTime!).inMilliseconds;

    _lastRawSteps = rawSteps;
    _lastStepTime = now;

    if (deltaSteps <= 0) return;

    final rate = deltaSteps / (deltaMs / 1000.0);
    _readingsSinceReset++;

    // Vehicle filter: only apply after first few readings
    if (_readingsSinceReset > 3 && rate > _maxStepRate) {
      debugPrint('StepProvider: vehicle rate detected ($rate/s), ignoring');
      notifyListeners();
      return;
    }

    // Accept steps immediately after first baseline reading
    _todaySteps += deltaSteps;
    if (_todaySteps > 100000) _todaySteps = 100000;
    _checkNotification();
    notifyListeners();
  }

  void _save() {
    ActivityDatabase.saveGoal('saved_steps', _todaySteps.toDouble());
    ActivityDatabase.saveDailySteps(_todayKey, _todaySteps);
  }

  void stopListening() {
    _save();
    _saveTimer?.cancel();
    _stepSubscription?.cancel();
    _statusSubscription?.cancel();
    _stepSubscription = null;
    _statusSubscription = null;
    _saveTimer = null;
  }

  void addSteps(int steps) {
    if (steps > 0) {
      _todaySteps += steps;
      notifyListeners();
    }
  }

  void resetSteps() {
    _todaySteps = 0;
    _lastRawSteps = -1;
    _readingsSinceReset = 0;
    ActivityDatabase.saveGoal('saved_steps', 0);
    ActivityDatabase.saveDailySteps(_todayKey, 0);
    notifyListeners();
  }

  void _checkNotification() {
    if ((_todaySteps - _lastNotifCheckSteps).abs() < 500) return;
    _lastNotifCheckSteps = _todaySteps;
    NotificationService.checkAndNotify(_todaySteps);
  }

  static String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
