import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../data/notification_model.dart';
import '../data/study_repository.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Fresh channel ID to bypass any cached muted settings in Android OS
  static const String _channelId = 'mx_prep_alerts_release_v1';
  static const String _channelName = 'Study Alerts & Reminders';
  static const String _channelDescription =
      'Daily study goals, streaks, and test reminders';

  static const int warningAlarmId = 8801;
  static const String warningNotifId = 'daily_warning_alert';

  static const int appreciateAlarmId = 8802;
  static const String appreciateNotifId = 'daily_appreciate_alert';

  // Global reactive notifier to trigger UI updates for unread badge count
  static final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  static Future<void> initialize() async {
    tz.initializeTimeZones();
    try {
      final String timeZoneName = DateTime.now().timeZoneName;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));
      } catch (_) {
        tz.setLocalLocation(tz.local);
      }
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
    );

    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
      vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await syncPendingNotifications();
    await autoAuditOnAppOpen();
    await setupDailyRoutineAlarms();
  }

  // Audit overdue pending notifications into unread state and update badge counter
  static Future<void> syncPendingNotifications() async {
    final list = await AppNotification.loadAll();
    final now = DateTime.now();
    bool changed = false;

    for (final n in list) {
      if (n.status == 'pending' && n.scheduledTime.isBefore(now)) {
        n.status = 'unread';
        changed = true;
      }
    }

    if (changed) {
      await AppNotification.saveAll(list);
    }

    // Refresh live badge counter
    final unread = list.where((n) => n.status == 'unread' || (n.status == 'pending' && n.scheduledTime.isBefore(now))).length;
    unreadCountNotifier.value = unread;
  }

  // Clear unread warning alarm on launch if user already read pages today
  static Future<void> autoAuditOnAppOpen() async {
    try {
      final pagesToday = StudyRepository.getPagesReadToday();
      if (pagesToday > 0) {
        await cancelAlarm(warningAlarmId, warningNotifId);
      }
    } catch (_) {}
  }

  // Schedule daily morning, noon and night routine alerts
  static Future<void> setupDailyRoutineAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final goalsRaw = prefs.getString('plan_per_book_goals');
    int totalGoal = 0;
    if (goalsRaw != null && goalsRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(goalsRaw) as Map;
        totalGoal = decoded.values.fold(0, (sum, val) => sum + (val as int));
      } catch (_) {}
    }
    if (totalGoal == 0) totalGoal = 25;

    // 1. Morning 8:00 AM
    await _scheduleDailyTimeAlarm(
      alarmId: 101,
      hour: 8,
      minute: 0,
      title: 'শুভ সকাল! ☀️',
      body: 'আজকের পড়ার টার্গেট $totalGoal পেইজ। চলো শুরু করে দিনটা এগিয়ে রাখি!',
      type: 'routine_morning',
    );

    // 2. Noon 1:30 PM
    await _scheduleDailyTimeAlarm(
      alarmId: 102,
      hour: 13,
      minute: 30,
      title: 'দিনের অর্ধেক সময় পার হলো! ⏳',
      body: 'আজকের টার্গেটের কতটুকু পড়া হলো? ব্রেক নিয়ে একটু রিভিশন দিয়ে নাও।',
      type: 'routine_noon',
    );

    // 3. Night 10:30 PM
    await _scheduleDailyTimeAlarm(
      alarmId: 103,
      hour: 22,
      minute: 30,
      title: 'দিনের শেষ অডিট! 🌙',
      body: 'আজকের সব পেইজ পড়া শেষ হয়েছে তো? স্ট্রিক ধরে রাখতে বাকিটুকু শেষ করে ঘুমাও!',
      type: 'routine_night',
    );
  }

  static Future<void> _scheduleDailyTimeAlarm({
    required int alarmId,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required String type,
  }) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      visibility: NotificationVisibility.public,
      fullScreenIntent: true,
      icon: '@mipmap/launcher_icon',
    );

    await _notificationsPlugin.zonedSchedule(
      id: alarmId,
      title: title,
      body: body,
      scheduledDate: tzDate,
      notificationDetails: NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Schedule exact precision alarm with fullScreenIntent to wake up background process
  static Future<void> scheduleAlarm({
    required int alarmId,
    required String notifId,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String type,
  }) async {
    final item = AppNotification(
      id: notifId,
      title: title,
      body: body,
      scheduledTime: scheduledDate,
      status: 'pending',
      type: type,
    );
    await AppNotification.upsert(item);
    await syncPendingNotifications();

    try {
      final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        showWhen: true,
        fullScreenIntent: true,
        visibility: NotificationVisibility.public,
        vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
        audioAttributesUsage: AudioAttributesUsage.notification,
        icon: '@mipmap/launcher_icon',
      );

      await _notificationsPlugin.zonedSchedule(
        id: alarmId,
        title: title,
        body: body,
        scheduledDate: tzDate,
        notificationDetails: NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      debugPrint("Alarm set for: $scheduledDate (ID: $alarmId)");
    } catch (e) {
      debugPrint("Error scheduling alarm: $e");
    }
  }

  static Future<void> cancelAlarm(int alarmId, String notifId) async {
    try {
      await _notificationsPlugin.cancel(id: alarmId);
    } catch (_) {}
    await AppNotification.remove(notifId);
    await syncPendingNotifications();
  }

  // Progress adaptation on page click
  static Future<void> handleDailyProgressUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    final goalsRaw = prefs.getString('plan_per_book_goals');
    int dailyGoal = 0;
    if (goalsRaw != null && goalsRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(goalsRaw) as Map;
        dailyGoal = decoded.values.fold(0, (sum, val) => sum + (val as int));
      } catch (_) {}
    }
    if (dailyGoal <= 0) dailyGoal = 25;

    final pagesReadToday = StudyRepository.getPagesReadToday();

    if (pagesReadToday >= dailyGoal) {
      await cancelAlarm(warningAlarmId, warningNotifId);

      final triggerTime = DateTime.now().add(const Duration(minutes: 2));
      await scheduleAlarm(
        alarmId: appreciateAlarmId,
        notifId: appreciateNotifId,
        title: 'অসাধারণ! টার্গেট কমপ্লিট! 🎉',
        body: 'আজকের $dailyGoal পৃষ্ঠার লক্ষ্য সফলভাবে শেষ করেছ। এই ধারাবাহিকতা ধরে রেখো!',
        scheduledDate: triggerTime,
        type: 'goal_appreciate',
      );
    } else if (pagesReadToday > 0) {
      await cancelAlarm(warningAlarmId, warningNotifId);

      final leftPages = dailyGoal - pagesReadToday;
      final triggerTime = DateTime.now().add(const Duration(hours: 1));
      await scheduleAlarm(
        alarmId: warningAlarmId,
        notifId: warningNotifId,
        title: 'দারুণ গতিতে এগোচ্ছ! 📖',
        body: 'আজকের লক্ষ্য পূরণ করতে আর মাত্র $leftPages পৃষ্ঠা বাকি। আর কিছুক্ষণ পড়লেই ডান!',
        scheduledDate: triggerTime,
        type: 'goal_warning',
      );
    }
  }

  static Future<void> showInstantTestNotification({
    required String title,
    required String body,
  }) async {
    final item = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      scheduledTime: DateTime.now(),
      status: 'unread',
      type: 'test',
    );
    await AppNotification.upsert(item);
    await syncPendingNotifications();

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      showWhen: true,
      visibility: NotificationVisibility.public,
      vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
      audioAttributesUsage: AudioAttributesUsage.notification,
      icon: '@mipmap/launcher_icon',
    );

    await _notificationsPlugin.show(
      id: DateTime.now().millisecond,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: androidDetails),
    );
  }
}