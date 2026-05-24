import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dailylogr/services/hive_service.dart';
import 'package:dailylogr/utils/date_helper.dart';
import 'package:intl/intl.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
      
  static const String _prefDailyReminders = 'pref_daily_reminders';

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap if needed
      },
    );
    
    // Automatically reschedule on init if enabled
    final isEnabled = await isDailyRemindersEnabled();
    if (isEnabled) {
      await scheduleDailyReminders();
    }
    
    // Check for the closing window warning
    _checkAndScheduleClosingWarning();
  }
  
  void _checkAndScheduleClosingWarning() {
    final now = DateTime.now();
    final closingDate = now.subtract(const Duration(days: 3)); // The day that is about to lock
    final closingDateKey = DayKey.of(DayKey.normalize(closingDate));
    
    // Check if the entry exists and is not deleted
    final box = HiveService.journalBox;
    final entry = box.get(closingDateKey);
    final isEntryEmpty = entry == null || entry.isDeleted;
    
    if (isEntryEmpty) {
      final dayOfWeek = DateFormat('EEEE').format(closingDate);
      scheduleClosingWindowWarning(dayOfWeek);
    }
  }

  Future<bool> isDailyRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefDailyReminders) ?? false; // Default off
  }

  Future<void> setDailyRemindersEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefDailyReminders, enabled);
    
    if (enabled) {
      final hasPermission = await requestPermissions();
      if (hasPermission) {
        await scheduleDailyReminders();
      } else {
        await prefs.setBool(_prefDailyReminders, false);
      }
    } else {
      await cancelAll();
    }
  }

  Future<bool> requestPermissions() async {
    bool? granted = await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    
    // For iOS
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
        
    return granted ?? true;
  }

  /// Cancels all notifications (when toggled off in settings)
  Future<void> cancelAll() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Fire an immediate test notification to verify configuration
  Future<void> showTestNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Used to test if notifications are working',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      999,
      'Test Notification 🚀',
      'It works! DailyLogR local notifications are set up successfully.',
      platformDetails,
    );
  }

  /// Schedule standard daily reminders
  Future<void> scheduleDailyReminders() async {
    if (!(await isDailyRemindersEnabled())) return;
    // We can use a stable ID for the 8:30 PM reminder
    const int dailyReminderId = 100;
    const int lateReminderId = 101;

    // 8:30 PM Reminder
    await _scheduleDailyTime(
      id: dailyReminderId,
      title: 'DailyLogR',
      body: 'How was your day? Take a minute to write down your thoughts.',
      hour: 20,
      minute: 30,
    );

    // 11:00 PM Late Reminder
    await _scheduleDailyTime(
      id: lateReminderId,
      title: 'Almost time for bed! 🌙',
      body: 'Day almost over, quickly write a few lines, just the highlights.',
      hour: 23,
      minute: 0,
    );
  }

  Future<void> _scheduleDailyTime({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'daily_reminders',
      'Daily Reminders',
      channelDescription: 'Reminders to write your daily log',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Schedule the 4-day closing window warning
  Future<void> scheduleClosingWindowWarning(String dayOfWeek) async {
    const int closingWarningId = 200; // Noon warning
    const int closingWarningId2 = 201; // 6 PM warning

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'urgent_warnings',
      'Urgent Warnings',
      channelDescription: 'Alerts before you lose your edit window',
      importance: Importance.max,
      priority: Priority.max,
      color: Colors.red,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    // Schedule for today at 12:00 PM
    var noonDate = _nextInstanceOfTime(12, 0);
    if (!noonDate.isBefore(tz.TZDateTime.now(tz.local))) {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        closingWarningId,
        "Last Chance! ⏳",
        "The editing window for $dayOfWeek closes tonight. Don't lose your streak!",
        noonDate,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    // Schedule for today at 6:00 PM
    var eveningDate = _nextInstanceOfTime(18, 0);
    if (!eveningDate.isBefore(tz.TZDateTime.now(tz.local))) {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        closingWarningId2,
        "Last Chance! ⏳",
        "The editing window for $dayOfWeek closes tonight. Don't lose your streak!",
        eveningDate,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  /// Called when an entry is successfully saved to prevent bugging the user for today
  Future<void> cancelRemindersForToday() async {
    // If they logged today, they don't need the 8:30 PM or 11:00 PM reminder
    await _flutterLocalNotificationsPlugin.cancel(100);
    await _flutterLocalNotificationsPlugin.cancel(101);
  }

  /// Called if they logged the closing window day, to cancel the warning
  Future<void> cancelClosingWindowWarning() async {
    await _flutterLocalNotificationsPlugin.cancel(200);
    await _flutterLocalNotificationsPlugin.cancel(201);
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    return scheduledDate;
  }
}
