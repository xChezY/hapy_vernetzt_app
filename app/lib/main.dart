import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hapy_vernetzt_app/android_webview.dart';
import 'package:hapy_vernetzt_app/env.dart';
import 'package:hapy_vernetzt_app/firebase.dart';
import 'package:hapy_vernetzt_app/firebase_options.dart';
import 'package:hapy_vernetzt_app/notifications.dart';
import 'package:hapy_vernetzt_app/ios_webview.dart';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

final FlutterLocalNotificationsPlugin flutterlocalnotificationsplugin =
    FlutterLocalNotificationsPlugin();

final cookieManager = WebviewCookieManager();

final StreamController<String?> selectnotificationstream =
    StreamController<String?>.broadcast();

WebKitWebViewController? ioscontroller;

AndroidWebViewController? androidcontroller;

FlutterSecureStorage storage = const FlutterSecureStorage();

bool dontgoback = false;

String starturl = '${Env.appurl}/signup/';

int notificationid = 0;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  initNotifications();
  showNotification();
}

bool canGoBack(String url) {
  if (dontgoback) {
    dontgoback = false;
    return false;
  }
  if (url == '${Env.appurl}/dashboard/' ||
      url == '${Env.appurl}/login/' ||
      url == '${Env.appurl}/signup/' ||
      url == '${Env.appurl}/logout/' ||
      url == '${Env.appurl}/password_reset/') {
    return false;
  }
  return true;
}

void setLogout() async{
  String? logout = await storage.read(key: 'logout');
  if (logout == null){
    await storage.write(key: 'logout', value: 'false');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  setLogout();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  initToken();
  initOnTokenRefresh();

  initNotifications();

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    showNotification();
  });

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  if (Platform.isIOS) {
    runApp(const IOSWebViewPage());
  } else {
    runApp(const AndroidWebViewPage());
  }
}
