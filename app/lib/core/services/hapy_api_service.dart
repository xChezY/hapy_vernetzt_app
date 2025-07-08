import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:hapy_vernetzt_app/core/env.dart';

/// Service für die Kommunikation mit der HaPy API.
/// Enthält Methoden für Authentifizierung und anderen HaPy-spezifischen API-Aufrufe.
class HaPyApiService {
  /// Singleton-Pattern für die HaPyApiService
  static final HaPyApiService _instance = HaPyApiService._internal();

  factory HaPyApiService() {
    return _instance;
  }

  HaPyApiService._internal();

  /// Prüft, ob eine Session-ID gültig ist.
  ///
  /// [sessionId] Die zu prüfende Session-ID
  ///
  /// Gibt `true` zurück, wenn die Session gültig ist, andernfalls `false`.
  Future<bool> isSessionIdValid(String? sessionId) async {
    if (sessionId == null) return false;

    try {
      final response = await http.get(
        Uri.parse('${Env.appurl}/api/v3/authinfo'),
        headers: <String, String>{'Cookie': 'hameln-sessionid=$sessionId'},
      );

      if (response.statusCode != 200) return false;

      final Map<String, dynamic> json = jsonDecode(response.body);
      return json['data']['authenticated'] ?? false;
    } catch (e) {
      debugPrint('Error checking session validity: $e');
      return false;
    }
  }

  /// Holt die Navigation Alerts für den Benutzer.
  ///
  /// [sessionId] Die Session-ID des Benutzers
  ///
  /// Gibt eine Map mit den Alert-Daten zurück oder null bei einem Fehler.
  Future<Map<String, dynamic>?> getNavigationAlerts(String? sessionId) async {
    if (sessionId == null) return null;

    try {
      final response = await http.get(
        Uri.parse('${Env.appurl}/api/v3/navigation/alerts'),
        headers: <String, String>{'Cookie': 'hameln-sessionid=$sessionId'},
      );

      if (response.statusCode != 200) return null;

      final Map<String, dynamic> json = jsonDecode(response.body);
      return json;
    } catch (e) {
      debugPrint('Error fetching navigation alerts: $e');
      return null;
    }
  }
}
