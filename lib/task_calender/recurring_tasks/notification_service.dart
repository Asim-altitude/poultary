import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'task_calendar_screen.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // Initialize notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone data
    tz.initializeTimeZones();

    // Android settings
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher', // Your app icon
    );

    // iOS settings
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        _handleNotificationTap(response);
      },
    );

    _initialized = true;
  }

  // Request notification permissions (iOS)
  Future<bool> requestPermissions() async {
    if (!_initialized) await initialize();

    final bool? result = await _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    return result ?? true;
  }

  // Schedule a notification for a task
  Future<void> scheduleTaskNotification({
    required String taskId,
    required String title,
    required String description,
    required DateTime taskDateTime,
    required int minutesBefore,
  }) async
  {
    if (!_initialized) await initialize();

    // Calculate notification time
    final notificationTime = taskDateTime.subtract(Duration(minutes: minutesBefore));

    // Don't schedule if notification time is in the past
    if (notificationTime.isBefore(DateTime.now())) {
      return;
    }

    // Create notification details
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'task_reminders', // Channel ID
      'Task Reminders', // Channel name
      channelDescription: 'Notifications for livestock task reminders',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      sound: RawResourceAndroidNotificationSound('notification'),
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Generate unique notification ID from task ID
    final notificationId = _generateNotificationId(taskId);

    // Schedule the notification
    await _notifications.zonedSchedule(
      notificationId,
      '🐔 $title',
      description,
      tz.TZDateTime.from(notificationTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  // Cancel a specific task notification
  Future<void> cancelTaskNotification(String taskId) async {
    if (!_initialized) await initialize();
    
    final notificationId = _generateNotificationId(taskId);
    await _notifications.cancel(notificationId);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    if (!_initialized) await initialize();
    await _notifications.cancelAll();
  }

  // Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_initialized) await initialize();
    return await _notifications.pendingNotificationRequests();
  }

  // Generate unique notification ID from task ID
  int _generateNotificationId(String taskId) {
    // Convert task ID string to a unique integer
    // Using hashCode ensures consistency for the same task ID
    return taskId.hashCode.abs() % 2147483647; // Max int32 value
  }

  // Handle notification tap
  void _handleNotificationTap(NotificationResponse response) {
    // Navigate to task details or calendar screen
    // You can implement navigation logic here
    print('Notification tapped: ${response.payload}');
  }

  // Show immediate notification (for testing)
  Future<void> showImmediateNotification({
    required String title,
    required String body,
  }) async {
    if (!_initialized) await initialize();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      channelDescription: 'Notifications for livestock task reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      details,
    );
  }
}

// Extension methods for easy task notification scheduling
extension TaskNotificationExtension on LivestockTask {
  Future<void> scheduleNotification(DateTime taskDate) async {
    if (!enableNotification || notificationMinutesBefore == null) {
      return;
    }

    // Combine date and time
    final taskDateTime = DateTime(
      taskDate.year,
      taskDate.month,
      taskDate.day,
      time.hour,
      time.minute,
    );

    await NotificationService.instance.scheduleTaskNotification(
      taskId: id,
      title: title,
      description: description,
      taskDateTime: taskDateTime,
      minutesBefore: notificationMinutesBefore!,
    );
  }

  Future<void> cancelNotification() async {
    await NotificationService.instance.cancelTaskNotification(id);
  }
}
