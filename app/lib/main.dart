import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hapy_vernetzt_app/android_webview.dart';
import 'package:hapy_vernetzt_app/firebase_options.dart';
import 'package:hapy_vernetzt_app/notifications.dart';
import 'package:hapy_vernetzt_app/ios_webview.dart';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

final FlutterLocalNotificationsPlugin flutterlocalnotificationsplugin =
      FlutterLocalNotificationsPlugin();

late AndroidNotificationChannel channel;

final cookieManager = WebviewCookieManager();

final StreamController<String?> selectnotificationstream =
    StreamController<String?>.broadcast();

WebKitWebViewController? ioscontroller;

AndroidWebViewController? androidcontroller;

FlutterSecureStorage storage = const FlutterSecureStorage();

bool isFlutterLocalNotificationsInitialized = false;

String starturl = 'https://hapy-vernetzt.de/signup/';

int id = 0;

int notificationid = -1;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  initializeNotifications();
  showNotification();
  debugPrint('Handling a background message ${message.messageId}');
}

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  initializeNotifications();

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('Message data: ${message.data}');
    showNotification();
  });

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  debugPrint('Token: ${await FirebaseMessaging.instance.getToken()}');

  if (Platform.isIOS) {
    runApp(const IOSWebViewPage());
  } else {
    runApp(const AndroidWebViewPage());
  }
}
