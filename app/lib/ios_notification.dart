import 'package:flutter_local_notifications/flutter_local_notifications.dart';

DarwinInitializationSettings initialiseIOSNotification() {
  return const DarwinInitializationSettings(
    requestAlertPermission: true,
  );
}
