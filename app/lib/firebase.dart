import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hapy_vernetzt_app/env.dart';
import 'package:hapy_vernetzt_app/main.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

void initToken() async {
  String token = '';
  if (token.isNotEmpty) {
    return;
  }
  if (Platform.isIOS) {
    token = await FirebaseMessaging.instance.getAPNSToken() ?? '';
  }
  if (Platform.isAndroid) {
    token = await FirebaseMessaging.instance.getToken() ?? '';
  }
  if (token.isNotEmpty) {
    Response res = await http
        .post(Uri.parse('${Env.backendurl}/api/send-device-token'), headers: {
      'Authorization': 'Bearer ${Env.apitoken}',
    }, body: {
      'Token': token,
    });
    await storage.write(key: 'token', value: token);
  }
}

void initOnTokenRefresh() {
  FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
    await http
        .post(Uri.parse('${Env.backendurl}/api/send-device-token'), headers: {
      'Authorization': 'Bearer ${Env.apitoken}',
    }, body: {
      'Token': token,
    });
    await storage.write(key: 'token', value: token);
  });
}
