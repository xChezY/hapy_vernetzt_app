import 'package:flutter_local_notifications/flutter_local_notifications.dart';

AndroidInitializationSettings initialiseAndroidNotification() {
  return const AndroidInitializationSettings('notification_icon');
}

AndroidNotificationDetails initialiseAndroidNotificationDetails() {
  return const AndroidNotificationDetails(
    'hapy_vernetzt_channel',
    'Hapy Vernetzt Channel',
    icon: "notification_icon",
  );
}
