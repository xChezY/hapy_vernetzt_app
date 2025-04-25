import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hapy_vernetzt_app/core/services/storage_service.dart';
import 'package:hapy_vernetzt_app/core/env.dart';
import 'package:hapy_vernetzt_app/core/services/firebase_service.dart';
import 'package:hapy_vernetzt_app/core/services/notification_service.dart';
import 'package:hapy_vernetzt_app/features/webview/webview_page.dart';

FlutterSecureStorage storage = const FlutterSecureStorage();

void setLogout() async {
  String? logout = await storage.read(key: 'logout');
  if (logout == null) {
    await storage.write(key: 'logout', value: 'false');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String initialUrl = '${Env.appurl}/signup/?v=3';
  await StorageService().initializeLogoutFlag();

  final notificationPayload = await NotificationService().initialize();
  if (notificationPayload != null && notificationPayload.isNotEmpty) {
    initialUrl = "${Env.appurl}${notificationPayload}";
  }

  await FirebaseService().initialize();

  await NotificationService().requestPermissions();

  runApp(WebViewPage(initialUrl: initialUrl));
}

final StreamController<String?> selectnotificationstream =
    StreamController<String?>.broadcast();
