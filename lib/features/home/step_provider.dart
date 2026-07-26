import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
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

  static const _maxStepRate = 4;
  static const _minStepRate = 0.5;
  int _consecutiveValid = 0;
  int _lastNotifCheckSteps = -1;

  int get todaySteps => _todaySteps;
  String get status => _status;

  /// Get daily steps for any date key ('YYYY-MM-DD').
  int getStepsForDay(String dateKey) => ActivityDatabase.getDailySteps(dateKey);

  /// Get last 7 days step data (for weekly summary).
  Map<String, int> get lastWeekSteps {
    final result = <String, int>{};
    final now = DateTime.now();
    // Start from Monday of current week
    final monday = now.subtract(Duration(days: now.weekday - 1));
    for (int i = 0; i < 7; i++) {
      final d = monday.add(Duration(days: i));
      final key = _dateKey(d);
      result[key] = key == _dateKey(now) ? _todaySteps : ActivityDatabase.getDailySteps(key);
    }
    return result;
  }

  /// Get step data for a specific week by its Monday date.
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

  void startListening() {
    _todayKey = _dateKey(DateTime.now());

    // Restore today's saved steps (survives app restart within same day)
    _todaySteps = ActivityDatabase.getGoal('saved_steps', defaultValue: 0).toInt();

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

    // Save every 30 seconds
    _saveTimer = Timer.periodic(const Duration(seconds: 30), (_) => _save());
  }

  void _processStepCount(int rawSteps) {
    // Check for day change
    final newKey = _dateKey(DateTime.now());
    if (newKey != _todayKey) {
      // Day changed — save previous day and reset
      ActivityDatabase.saveDailySteps(_todayKey, _todaySteps);
      _todayKey = newKey;
      _todaySteps = 0;
      _lastRawSteps = -1;
    }

    if (_lastRawSteps < 0) {
      _lastRawSteps = rawSteps;
      _lastStepTime = DateTime.now();
      return;
    }

    final now = DateTime.now();
    final deltaSteps = rawSteps - _lastRawSteps;
    final deltaMs = now.difference(_lastStepTime!).inMilliseconds;

    _lastRawSteps = rawSteps;
    _lastStepTime = now;

    if (deltaSteps <= 0) return;

    final rate = deltaSteps / (deltaMs / 1000.0);

    // Vehicle filter: >4 steps/sec
    if (rate > _maxStepRate) {
      _consecutiveValid = 0;
      notifyListeners();
      return;
    }

    // Noise filter: too slow
    if (rate < _minStepRate && deltaSteps < 3) {
      _consecutiveValid = 0;
      return;
    }

    _consecutiveValid++;
    if (_consecutiveValid >= 3) {
      _todaySteps += deltaSteps;
      if (_todaySteps > 100000) _todaySteps = 100000;
      _checkNotification();
    }

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
    ActivityDatabase.saveGoal('saved_steps', 0);
    ActivityDatabase.saveDailySteps(_todayKey, 0);
    notifyListeners();
  }

  void _checkNotification() {
    // Only check every 500 steps to avoid spam
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
