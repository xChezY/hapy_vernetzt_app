import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hapy_vernetzt_app/core/services/storage_service.dart';
import 'package:hapy_vernetzt_app/features/webview/android_webview.dart';
import 'package:hapy_vernetzt_app/core/env.dart';
import 'package:hapy_vernetzt_app/features/webview/ios_webview.dart';
import 'package:hapy_vernetzt_app/core/services/firebase_service.dart';
import 'package:hapy_vernetzt_app/core/services/notification_service.dart';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';

FlutterSecureStorage storage = const FlutterSecureStorage();

String starturl = '${Env.appurl}/signup/?v=3';

void setLogout() async {
  String? logout = await storage.read(key: 'logout');
  if (logout == null) {
    await storage.write(key: 'logout', value: 'false');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await StorageService().initializeLogoutFlag();

  final notificationPayload = await NotificationService().initialize();
  if (notificationPayload != null && notificationPayload.isNotEmpty) {
    starturl = "${Env.appurl}$notificationPayload";
  }

  await FirebaseService().initialize();

  await NotificationService().requestPermissions();

  if (Platform.isIOS) {
    runApp(const IOSWebViewPage());
  } else {
    runApp(const AndroidWebViewPage());
  }
}

final StreamController<String?> selectnotificationstream =
    StreamController<String?>.broadcast();
