import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';

class StepProvider extends ChangeNotifier {
  int _todaySteps = 0;
  StreamSubscription<StepCount>? _stepSubscription;
  StreamSubscription<PedestrianStatus>? _statusSubscription;
  String _status = 'unknown';

  int get todaySteps => _todaySteps;
  String get status => _status;

  void startListening() {
    _stepSubscription = Pedometer.stepCountStream.listen(
      (stepCount) {
        _todaySteps = stepCount.steps;
        notifyListeners();
      },
      onError: (error) {
        _todaySteps = 0;
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
  }

  void stopListening() {
    _stepSubscription?.cancel();
    _statusSubscription?.cancel();
    _stepSubscription = null;
    _statusSubscription = null;
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
