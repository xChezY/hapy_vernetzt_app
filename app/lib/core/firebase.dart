import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hapy_vernetzt_app/core/env.dart';
import 'package:hapy_vernetzt_app/main.dart';
import 'package:http/http.dart' as http;
import 'package:hapy_vernetzt_app/core/services/notification_backend_api_service.dart';

void initToken() async {
  String token = await FirebaseMessaging.instance.getToken() ?? '';
  if (token.isNotEmpty) {
    await NotificationBackendApiService().sendDeviceToken(token);
    await storage.write(key: 'token', value: token);
  }
}

void initOnTokenRefresh() {
  FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
    await NotificationBackendApiService().sendDeviceToken(token);
    await storage.write(key: 'token', value: token);
  });
}
