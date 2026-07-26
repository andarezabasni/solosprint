import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import '../../core/database/activity_database.dart';

class StepProvider extends ChangeNotifier {
  int _todaySteps = 0;
  int _lastRawSteps = -1;
  DateTime? _lastStepTime;
  String _status = 'unknown';
  StreamSubscription<StepCount>? _stepSubscription;
  StreamSubscription<PedestrianStatus>? _statusSubscription;
  Timer? _saveTimer;

  static const _maxStepRate = 4; // max 4 steps/second (≈running 15 km/h)
  static const _minStepRate = 0.5; // min 1 step/2 seconds (very slow walk)

  int _consecutiveValid = 0;

  int get todaySteps => _todaySteps;
  String get status => _status;

  void startListening() {
    // Restore last saved steps
    _todaySteps = ActivityDatabase.getGoal('saved_steps', defaultValue: 0).toInt();

    _stepSubscription = Pedometer.stepCountStream.listen(
      (stepCount) {
        _processStepCount(stepCount.steps);
      },
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

    // Auto-save every 30 seconds (survives app restart)
    _saveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      ActivityDatabase.saveGoal('saved_steps', _todaySteps.toDouble());
    });
  }

  void _processStepCount(int rawSteps) {
    if (_lastRawSteps < 0) {
      // First reading — just store it, don't count
      _lastRawSteps = rawSteps;
      _lastStepTime = DateTime.now();
      return;
    }

    final now = DateTime.now();
    final deltaSteps = rawSteps - _lastRawSteps;
    final deltaMs = now.difference(_lastStepTime!).inMilliseconds;

    _lastRawSteps = rawSteps;
    _lastStepTime = now;

    // No change — nothing to process
    if (deltaSteps <= 0) return;

    // Calculate step rate (steps per second)
    final rate = deltaSteps / (deltaMs / 1000.0);
    // Vehicle detection: if rate is unrealistically high, ignore
    if (rate > _maxStepRate) {
      _consecutiveValid = 0;
      debugPrint('StepProvider: ignoring $deltaSteps steps (rate ${rate.toStringAsFixed(1)}/s = vehicle?)');
      notifyListeners();
      return;
    }

    // Also ignore if rate is too slow (sensor noise when stopped)
    if (rate < _minStepRate && deltaSteps < 3) {
      _consecutiveValid = 0;
      return;
    }

    // Require consecutive valid readings
    _consecutiveValid++;
    if (_consecutiveValid >= 3) {
      _todaySteps += deltaSteps;
      // Cap at reasonable daily max (100,000 steps)
      if (_todaySteps > 100000) _todaySteps = 100000;
    }

    notifyListeners();
  }

  void stopListening() {
    // Save final count
    ActivityDatabase.saveGoal('saved_steps', _todaySteps.toDouble());
    _saveTimer?.cancel();
    _stepSubscription?.cancel();
    _statusSubscription?.cancel();
    _stepSubscription = null;
    _statusSubscription = null;
    _saveTimer = null;
  }

  /// Manually add steps (e.g., from wearables or trusted source)
  void addSteps(int steps) {
    if (steps > 0) {
      _todaySteps += steps;
      notifyListeners();
    }
  }

  /// Reset today's step count
  void resetSteps() {
    _todaySteps = 0;
    _lastRawSteps = -1;
    ActivityDatabase.saveGoal('saved_steps', 0);
    notifyListeners();
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
