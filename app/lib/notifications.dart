import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hapy_vernetzt_app/android_notification.dart';
import 'package:hapy_vernetzt_app/ios_notification.dart';
import 'package:hapy_vernetzt_app/main.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

class HapyAlerts {
  HapyAlerts({
    required this.id,
    required this.group,
    required this.text,
    required this.url,
  });

  final String id;
  final String group;
  final String text;
  final String url;
}

Future<List<HapyAlerts>> getHapyAlerts(String? sessionid) async {
  if (sessionid == null) {
    return [];
  }
  List<HapyAlerts> unreadedalerts = [];
  Map<String, dynamic> json = jsonDecode((await http.get(
    Uri.parse('https://hapy-vernetzt.de/api/v3/navigation/alerts'),
    headers: <String, String>{'Cookie': 'hameln-sessionid=$sessionid'},
  ))
      .body);

  String? readedalerts = await storage.read(key: 'alerts');
  List<dynamic> listalertsreaded =
      readedalerts != null ? jsonDecode(readedalerts) : [];
  List<dynamic> newlist = [];
  json['data']['items'].forEach((dynamic item) {
    if (!listalertsreaded.contains(item['id']) && item['is_emphasized']) {
      unreadedalerts.add(HapyAlerts(
        id: item['id'],
        group: item['group'],
        text: item['text'],
        url: item['url'],
      ));
    }
    newlist.add(item['id']);
  });

  await storage.write(key: 'alerts', value: jsonEncode(newlist));

  return unreadedalerts;
}

void showNotification() async {
  String? sessionid = await storage.read(key: 'sessionid');
  if (sessionid == null) {
    if (notificationid == -1) {
      notificationid = id++;
    }
    debugPrint('notificationid: $notificationid');
    await flutterlocalnotificationsplugin.show(
      notificationid,
      "Keine Benachrichtigungen",
      "Du bist wieder abgemeldet worden. Melde dich jetzt wieder an, um weiterhin Benachrichtigungen zu erhalten.",
      NotificationDetails(
        android: initialiseAndroidNotificationDetails(),
      ),
      payload: '/login/',
    );
    return;
  } else {
    notificationid = -1;
  }
  List<HapyAlerts> alerts = await getHapyAlerts(sessionid);
  for (HapyAlerts alert in alerts) {
    await flutterlocalnotificationsplugin.show(
      id++,
      alert.group,
      alert.text.replaceAll("<b>", "").replaceAll("</b>", ""),
      NotificationDetails(
        android: initialiseAndroidNotificationDetails(),
      ),
      payload: alert.url,
    );
  }
}

void initNotifications() async {
  final InitializationSettings initializationsettings = InitializationSettings(
    iOS: initialiseIOSNotification(),
    android: initialiseAndroidNotification(),
  );

  await flutterlocalnotificationsplugin.initialize(
    initializationsettings,
    onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
  );

  final NotificationAppLaunchDetails? notificationAppLaunchDetails =
      await flutterlocalnotificationsplugin.getNotificationAppLaunchDetails();

  if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
    starturl =
        notificationAppLaunchDetails!.notificationResponse?.payload ?? starturl;
  }
}

Future<void> onDidReceiveNotificationResponse(
    NotificationResponse notificationResponse) async {
  final String? payload = notificationResponse.payload;
  if (notificationResponse.payload != null) {
    dontgoback = true;
    if (Platform.isIOS) {
      await ioscontroller!.loadRequest(LoadRequestParams(
          uri: Uri.parse("https://hapy-vernetzt.de${payload!}")));
    } else {
      await androidcontroller!.loadRequest(LoadRequestParams(
          uri: Uri.parse("https://hapy-vernetzt.de${payload!}")));
    }
  }
}