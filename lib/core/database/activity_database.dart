import 'package:hive_flutter/hive_flutter.dart';
import '../../features/run/run_activity.dart';

class ActivityDatabase {
  static const _boxName = 'activities';
  static const _goalsBoxName = 'goals';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
    await Hive.openBox(_goalsBoxName);
  }

  static Box get _box => Hive.box(_boxName);
  static Box get _goalsBox => Hive.box(_goalsBoxName);

  static Future<void> saveActivity(RunActivity activity) async {
    await _box.put(activity.id, activity.toJson());
  }

  static List<RunActivity> getAllActivities() {
    final result = <RunActivity>[];
    for (final value in _box.values) {
      if (value is Map) {
        result.add(RunActivity.fromJson(Map<String, dynamic>.from(value)));
      }
    }
    result.sort((a, b) => b.startTime.compareTo(a.startTime));
    return result;
  }

  static List<RunActivity> getActivitiesInRange(DateTime start, DateTime end) {
    return getAllActivities().where((a) {
      return a.startTime.isAfter(start) && a.startTime.isBefore(end);
    }).toList();
  }

  static double getTotalDistance(DateTime start, DateTime end) {
    return getActivitiesInRange(start, end)
        .fold(0.0, (sum, a) => sum + a.distance);
  }

  static int getTotalDuration(DateTime start, DateTime end) {
    return getActivitiesInRange(start, end)
        .fold(0, (sum, a) => sum + a.duration.inMinutes);
  }

  static int getTotalRuns(DateTime start, DateTime end) {
    return getActivitiesInRange(start, end).length;
  }

  // Goals
  static Future<void> saveGoal(String key, double value) async {
    await _goalsBox.put(key, value);
  }

  static double getGoal(String key, {double defaultValue = 0.0}) {
    final value = _goalsBox.get(key, defaultValue: defaultValue);
    if (value is num) return value.toDouble();
    return defaultValue;
  }

  static Map<String, double> getAllGoals() {
    return _goalsBox.toMap().map((k, v) => MapEntry(k, (v as num).toDouble()));
  }
}
