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

String starturl = '${Env.appurl}/signup/?v=3';

final List whitelist = [Env.appurl, Env.cloudurl, Env.chaturl];

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
  if (url.startsWith('${Env.appurl}/dashboard/?v=3') ||
      url.startsWith('${Env.appurl}/login/?v=3') ||
      url.startsWith('${Env.appurl}/signup/?v=3') ||
      url.startsWith('${Env.appurl}/logout/?v=3') ||
      url.startsWith('${Env.appurl}/password_reset/?v=3')) {
    return false;
  }
  return true;
}

bool isWhitelistedUrl(String url) {
  for (final String domain in whitelist) {
    final escapedDomain = RegExp.escape(
        domain.replaceAll('https://', '').replaceAll('http://', ''));
    final pattern =
        r'^https?:\/\/([a-zA-Z0-9-]+\.)?' + escapedDomain + r'(\/.*)?$';
    if (RegExp(pattern).hasMatch(url)) {
      return true;
    }
  }
  return false;
}

bool isChatAuthUrl(String url) {
  return url.startsWith('${Env.chaturl}/_oauth');
}

void setLogout() async {
  String? logout = await storage.read(key: 'logout');
  if (logout == null) {
    await storage.write(key: 'logout', value: 'false');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  setLogout();

  requestPermission();

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
