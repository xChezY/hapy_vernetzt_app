import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:hapy_vernetzt_app/core/env.dart';

/// Service für die Kommunikation mit dem Notification-Backend.
/// Enthält Methoden zum Senden von Geräteinformationen und Device-Tokens.
class NotificationBackendApiService {
  /// Singleton-Pattern für den NotificationBackendApiService
  static final NotificationBackendApiService _instance =
      NotificationBackendApiService._internal();

  factory NotificationBackendApiService() {
    return _instance;
  }

  NotificationBackendApiService._internal();

  /// Sendet ein Device-Token an das Backend, um Push-Benachrichtigungen zu ermöglichen.
  ///
  /// [token] Der Device-Token für Push-Benachrichtigungen
  ///
  /// Gibt `true` zurück, wenn das Token erfolgreich gesendet wurde, andernfalls `false`.
  Future<bool> sendDeviceToken(String token) async {
    if (token.isEmpty) return false;

    try {
      final response = await http.post(
        Uri.parse('${Env.backendurl}/api/send-device-token'),
        headers: {
          'Authorization': 'Bearer ${Env.apitoken}',
        },
        body: {
          'Token': token,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error sending device token: $e');
      return false;
    }
  }
}
