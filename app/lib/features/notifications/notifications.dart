import 'dart:async';
import 'package:hapy_vernetzt_app/core/env.dart';
import 'package:flutter/foundation.dart';
import 'package:hapy_vernetzt_app/core/services/hapy_api_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hapy_vernetzt_app/core/services/storage_service.dart';
import 'package:hapy_vernetzt_app/main.dart' show selectnotificationstream;

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

Future<bool> isSessiondIDValid() async {
  String? sessionid = await StorageService().getSessionId();

  return await HaPyApiService().isSessionIdValid(sessionid);
}

Future<List<HapyAlerts>> getHapyAlerts(String? sessionid) async {
  if (sessionid == null) {
    return [];
  }

  List<HapyAlerts> unreadedalerts = [];

  final json = await HaPyApiService().getNavigationAlerts(sessionid);
  if (json == null) return [];

  List<dynamic>? listalertsreaded =
      await StorageService().getReadAlerts() ?? [];
  List<dynamic> newlist = [];

  final items = json['data']?['items'];
  if (items is List) {
    for (var item in items) {
      final itemId = item?['id'];
      final itemIsEmphasized = item?['is_emphasized'];
      final itemGroup = item?['group'];
      final itemText = item?['text'];
      final itemUrl = item?['url'];

      if (itemId != null &&
          itemIsEmphasized == true &&
          !listalertsreaded.contains(itemId) &&
          itemGroup != null &&
          itemText != null &&
          itemUrl != null) {
        unreadedalerts.add(HapyAlerts(
          id: itemId.toString(),
          group: itemGroup.toString(),
          text: itemText.toString(),
          url: itemUrl.toString(),
        ));
      }
      if (itemId != null) {
        newlist.add(itemId);
      }
    }
  }

  await StorageService().setReadAlerts(newlist);

  return unreadedalerts;
}

Future<void> onDidReceiveNotificationResponse(
    NotificationResponse notificationResponse) async {
  final String? payload = notificationResponse.payload;
  if (notificationResponse.payload != null && payload!.isNotEmpty) {
    final String targetUrl = "${Env.appurl}${payload}";
    debugPrint(
        'Notification tapped (from notifications.dart), adding URL to stream: $targetUrl');
    selectnotificationstream.add(targetUrl);
  }
}
