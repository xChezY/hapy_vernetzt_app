import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hapy_vernetzt_app/android_webview.dart';
import 'package:hapy_vernetzt_app/notifications.dart';
import 'package:hapy_vernetzt_app/ios_webview.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

final FlutterLocalNotificationsPlugin flutterlocalnotificationsplugin =
    FlutterLocalNotificationsPlugin();

final StreamController<String?> selectnotificationstream =
    StreamController<String?>.broadcast();

WebKitWebViewController? ioscontroller;

AndroidWebViewController? androidcontroller;

FlutterSecureStorage storage = const FlutterSecureStorage();

bool isFlutterLocalNotificationsInitialized = false;

String starturl = 'https://hapy-vernetzt.de/signup/';

int id = 0;

int notificationid = -1;

Future<Map<String, String>> getCookies(dynamic controller) async {
  String cookies = await controller.runJavaScriptReturningResult('document.cookie') as String;
  List<String> cookielist = cookies.split(';');
  Map<String, String> cookieMap = {};
  for (var cookie in cookielist) {
    var cookieParts = cookie.split('=');
    if (cookieParts.length == 2) {
      cookieMap[cookieParts[0].trim()] = cookieParts[1].trim();
    }
  }
  return cookieMap;
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  showNotification();
  debugPrint('Handling a background message ${message.messageId}');
}

Future<void> main() async {

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint(await FirebaseMessaging.instance.getToken());

  WidgetsFlutterBinding.ensureInitialized();

  initializeNotifications();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);


  if (Platform.isIOS) {
    runApp(const IOSWebViewPage());
  } else {
    runApp(const AndroidWebViewPage());
  }
}
