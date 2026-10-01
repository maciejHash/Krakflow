import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool shouldShowTaskDoneNotification({
    required bool previousValue,
    required bool newValue,
  }) {
    return !previousValue && newValue;
  }

  static Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
          defaultPresentAlert: true,
          defaultPresentBadge: true,
          defaultPresentSound: true,
        );
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _notifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('Notification tapped: ${response.payload}');
      },
    );
    await requestAndroidPermission();
    await requestIOSPermission();
  }

  static Future<void> requestAndroidPermission() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();
  }

  static Future<void> requestIOSPermission() async {
    final iosPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static Future<void> showTaskDoneNotification(String taskTitle) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'krakflow_tasks',
          'KrakFlow tasks',
          channelDescription: 'Powiadomienia o zadaniach w aplikacji KrakFlow',
          importance: Importance.high,
          priority: Priority.high,
        );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _notifications.show(
      id: 1,
      title: 'Zadanie wykonane',
      body: taskTitle,
      notificationDetails: notificationDetails,
    );
  }
}
