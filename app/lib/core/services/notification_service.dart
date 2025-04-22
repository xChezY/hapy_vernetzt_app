import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hapy_vernetzt_app/main.dart';
import 'package:hapy_vernetzt_app/features/notifications/notifications.dart'
    show
        HapyAlerts,
        getHapyAlerts,
        isSessiondIDValid; // Remove onDidReceiveNotificationResponse from import
import './notification/android_notification.dart';
import './notification/ios_notification.dart';
import 'package:hapy_vernetzt_app/core/env.dart'; // Import Env

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() {
    return _instance;
  }
  NotificationService._internal();

  // Moved from main.dart
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Moved from main.dart
  int _notificationId = 0;

  // Callback handling logic moved from NotificationHandler
  Function(bool)? _setDontGoBackCallback;

  void registerSetDontGoBackCallback(Function(bool) callback) {
    debugPrint("NotificationService: Registering setDontGoBack callback.");
    _setDontGoBackCallback = callback;
  }

  void unregisterSetDontGoBackCallback() {
    debugPrint("NotificationService: Unregistering setDontGoBack callback.");
    _setDontGoBackCallback = null;
  }

  void _setDontGoBack(bool value) {
    debugPrint(
        "NotificationService: Setting dontGoBack to $value via callback.");
    _setDontGoBackCallback?.call(value);
  }

  /// Handles the response when a notification is tapped.
  /// Moved from top-level function in notifications.dart
  Future<void> _onDidReceiveNotificationResponse(
      NotificationResponse notificationResponse) async {
    final String? payload = notificationResponse.payload;
    if (notificationResponse.payload != null && payload!.isNotEmpty) {
      // Use internal method to trigger the callback
      _setDontGoBack(true);
      final String targetUrl = "${Env.appurl}${payload}";
      debugPrint('Notification tapped, adding URL to stream: $targetUrl');
      // Use global stream (consider passing it in or using a different event mechanism later)
      selectnotificationstream.add(targetUrl);
    }
  }

  /// Initializes the notification service.
  /// Sets up local notifications plugin and handlers.
  /// Returns the payload URL if the app was launched from a notification.
  Future<String?> initialize() async {
    final InitializationSettings initializationSettings =
        InitializationSettings(
      iOS: initialiseIOSNotification(),
      android: initialiseAndroidNotification(),
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      // Use the internal handler method
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    final NotificationAppLaunchDetails? notificationAppLaunchDetails =
        await _flutterLocalNotificationsPlugin
            .getNotificationAppLaunchDetails();

    if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
      debugPrint(
          "App launched from notification payload: ${notificationAppLaunchDetails!.notificationResponse?.payload}");
      return notificationAppLaunchDetails.notificationResponse?.payload;
    }
    return null;
  }

  /// Requests notification permissions from the user.
  Future<void> requestPermissions() async {
    PermissionStatus status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }

  /// Fetches alerts and displays them as notifications.
  Future<void> showNotifications() async {
    // Logic moved from showNotification() in notifications.dart
    String? sessionid = await storage.read(key: 'sessionid');
    bool logout = await storage.read(key: 'logout') == 'true';

    // Use isSessiondIDValid from notifications.dart (for now)
    bool validSession = await isSessiondIDValid();

    if (logout && (!validSession || sessionid == null)) {
      await storage.write(key: 'logout', value: 'false');
      await _flutterLocalNotificationsPlugin.show(
        0, // Use a fixed ID for the logout notification
        "Keine Benachrichtigungen",
        "Du bist abgemeldet. Melde dich wieder an, um weiterhin Benachrichtigungen zu erhalten.",
        NotificationDetails(
          android: initialiseAndroidNotificationDetails(),
          // TODO: Add iOS details if needed for logout notification
        ),
        payload: '/login/?v=3',
      );
      _notificationId = 1; // Reset counter after logout notification
      return;
    }

    // Use getHapyAlerts from notifications.dart (for now)
    List<HapyAlerts> alerts = await getHapyAlerts(sessionid);
    for (HapyAlerts alert in alerts) {
      await _flutterLocalNotificationsPlugin.show(
        _notificationId++, // Use internal counter
        alert.group,
        alert.text.replaceAll("<b>", "").replaceAll("</b>", ""),
        NotificationDetails(
          android: initialiseAndroidNotificationDetails(),
          // Use DarwinNotificationDetails for iOS specifics if needed
          iOS: const DarwinNotificationDetails(),
        ),
        payload: alert.url,
      );
    }
    debugPrint(
        "Checked for notifications, found ${alerts.length}. Next ID: $_notificationId");
  }
}
