import 'dart:async';
import 'dart:io';
import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hapy_vernetzt_app/android_webview.dart';
import 'package:hapy_vernetzt_app/notifications.dart';
import 'package:hapy_vernetzt_app/ios_webview.dart';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

final FlutterLocalNotificationsPlugin flutterlocalnotificationsplugin =
    FlutterLocalNotificationsPlugin();

final StreamController<String?> selectnotificationstream =
    StreamController<String?>.broadcast();

WebKitWebViewController? ioscontroller;

AndroidWebViewController? androidcontroller;

WebviewCookieManager cookiemanager = WebviewCookieManager();

FlutterSecureStorage storage = const FlutterSecureStorage();

String starturl = 'https://hapy-vernetzt.de/cms';

int id = 0;

int notificationid = -1;

Future<void> main() async {
  //TODO Gruppierung von Benachrichtigungen (beide Betriebssysteme)
  //TODO Auch noch Background für Android machen
  WidgetsFlutterBinding.ensureInitialized();

  initializeNotifications();

  await BackgroundFetch.configure(
    BackgroundFetchConfig(
        minimumFetchInterval: 15,
        stopOnTerminate: false,
        enableHeadless: true,
        startOnBoot: true,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresStorageNotLow: false,
        requiresDeviceIdle: false,
        requiredNetworkType: NetworkType.NONE),
    (String taskId) async {
      showNotification();
      BackgroundFetch.finish(taskId);
    },
  );

  repeatNotification();

  if (Platform.isIOS) {
    runApp(const IOSWebViewPage());
  } else {
    runApp(const AndroidWebViewPage());
  }
}
