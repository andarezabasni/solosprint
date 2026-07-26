import 'package:hive_flutter/hive_flutter.dart';
import '../../features/run/run_activity.dart';

class ActivityDatabase {
  static const _boxName = 'activities';
  static const _goalsBoxName = 'goals';
  static const _stepsBoxName = 'daily_steps';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
    await Hive.openBox(_goalsBoxName);
    await Hive.openBox(_stepsBoxName);
  }

  static Box get _box => Hive.box(_boxName);
  static Box get _goalsBox => Hive.box(_goalsBoxName);
  static Box get _stepsBox => Hive.box(_stepsBoxName);

  // ─── Activities ───

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

  static Future<void> clearAll() async {
    await _box.clear();
    await _goalsBox.clear();
    await _stepsBox.clear();
  }

  // ─── Daily Steps Log ───

  /// Save step count for a given date (dateStr = 'YYYY-MM-DD').
  static Future<void> saveDailySteps(String dateStr, int steps) async {
    await _stepsBox.put(dateStr, steps);
  }

  /// Get step count for a given date.
  static int getDailySteps(String dateStr) {
    return _stepsBox.get(dateStr, defaultValue: 0) as int;
  }

  /// Get step counts for the last N days (including today).
  static Map<String, int> getRecentDays(int days) {
    final result = <String, int>{};
    final now = DateTime.now();
    for (int i = 0; i < days; i++) {
      final d = now.subtract(Duration(days: i));
      final key = _dateKey(d);
      result[key] = getDailySteps(key);
    }
    return result;
  }

  static String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  // ─── Goals ───

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

  static bool get isFirstLaunch =>
      !_goalsBox.containsKey('onboarding_done');

  static Future<void> setOnboardingDone() async {
    await _goalsBox.put('onboarding_done', 1);
  }
}
