import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hapy_vernetzt_app/env.dart';
import 'package:hapy_vernetzt_app/main.dart';
import 'package:http/http.dart' as http;

void initToken() async {
  String token = '';
  token = await FirebaseMessaging.instance.getToken() ?? '';
  if (token.isNotEmpty) {
    await http
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
