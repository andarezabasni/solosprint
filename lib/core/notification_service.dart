import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../core/database/activity_database.dart';

class NotificationService {
  static final _notif = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _channelId = 'step_goals';
  static const _channelName = 'Step Goals';

  /// Initialize notifications (call once at app start).
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notif.initialize(
      settings,
      onDidReceiveNotificationResponse: (_) {},
    );

    // Create channel
    final androidPlugin = _notif.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );
  }

  /// Check step target and show appropriate notification.
  /// Show persistent run tracking notification (shows on lock screen).
  static Future<void> showRunNotification({
    required String distance,
    required String duration,
    bool paused = false,
  }) async {
    final title = paused ? 'SoloSprint Paused' : 'SoloSprint Running';
    final body = paused ? '$distance km | $duration' : '$distance km | $duration';
    await _notif.show(
      999,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'run_tracking',
          'Run Tracking',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: !paused,
          showWhen: false,
          autoCancel: false,
        ),
      ),
    );
  }

  /// Cancel the run tracking notification.
  static Future<void> cancelRunNotification() async {
    await _notif.cancel(999);
  }

  static Future<void> checkAndNotify(int todaySteps) async {
    final target = ActivityDatabase.getGoal('daily_step_target', defaultValue: 8000);
    if (target <= 0) return;

    final ratio = todaySteps / target;
    final hour = DateTime.now().hour;

    // Don't notify too early
    if (hour < 10) return;

    if (ratio >= 1.0) {
      await _showNotification(
        id: 1,
        title: '🎉 Target Tercapai!',
        body: 'Kamu sudah mencapai ${todaySteps.toInt()} langkah hari ini! Luar biasa!',
      );
    } else if (ratio >= 0.8) {
      await _showNotification(
        id: 2,
        title: '🔥 Dikit Lagi!',
        body: 'Tinggal ${(target - todaySteps).toInt()} langkah lagi menuju target harian!',
      );
    } else if (hour >= 19 && ratio < 0.5) {
      await _showNotification(
        id: 3,
        title: '🏃 Yuk Jalan!',
        body: 'Target hari ini: ${target.toInt()} langkah. Kamu baru ${todaySteps.toInt()} langkah. Ayo capai targetmu!',
      );
    } else if (hour >= 19 && ratio < 1.0) {
      await _showNotification(
        id: 4,
        title: '💪 Semangat!',
        body: 'Kamu sudah ${todaySteps.toInt()} dari ${target.toInt()} langkah target harian. Ayo kejar!',
      );
    }
  }

  static Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    // Don't spam same notification type
    final lastId = ActivityDatabase.getGoal('last_notif_id', defaultValue: 0);
    if (lastId == id) return;

    final now = DateTime.now();
    final lastTimeStr = ActivityDatabase.getGoal('last_notif_time', defaultValue: 0).toString();
    final lastTime = DateTime.tryParse(lastTimeStr);
    if (lastTime != null && now.difference(lastTime).inMinutes < 30) return;

    await _notif.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );

    ActivityDatabase.saveGoal('last_notif_id', id.toDouble());
    ActivityDatabase.saveGoal('last_notif_time', now.toIso8601String().hashCode.toDouble());
  }
}
