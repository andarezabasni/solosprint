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
    final values = _box.values.cast<Map<String, dynamic>>();
    return values.map((json) => RunActivity.fromJson(json)).toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
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
    return _goalsBox.get(key, defaultValue: defaultValue) as double;
  }

  static Map<String, double> getAllGoals() {
    return _goalsBox.toMap().map((k, v) => MapEntry(k, (v as num).toDouble()));
  }
}
