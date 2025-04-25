import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for handling secure storage using FlutterSecureStorage.
/// Provides typed methods for accessing common storage keys.
class StorageService {
  // Singleton pattern
  static final StorageService _instance = StorageService._internal();
  factory StorageService() {
    return _instance;
  }
  StorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // --- Keys --- (Private constants for keys)
  static const String _sessionIdKey = 'sessionid';
  static const String _logoutFlagKey = 'logout';
  static const String _tokenKey = 'token';
  static const String _alertsKey = 'alerts';

  // --- Session ID ---
  Future<String?> getSessionId() => _storage.read(key: _sessionIdKey);
  Future<void> setSessionId(String sessionId) =>
      _storage.write(key: _sessionIdKey, value: sessionId);
  Future<void> deleteSessionId() => _storage.delete(key: _sessionIdKey);

  // --- FCM Token ---
  Future<String?> getToken() => _storage.read(key: _tokenKey);
  Future<void> setToken(String token) =>
      _storage.write(key: _tokenKey, value: token);
  Future<void> deleteToken() => _storage.delete(key: _tokenKey);

  // --- Logout Flag ---
  Future<bool> getLogoutFlag() async {
    // Defaults to false if not set or not 'true'
    return await _storage.read(key: _logoutFlagKey) == 'true';
  }

  Future<void> setLogoutFlag(bool loggedOut) =>
      _storage.write(key: _logoutFlagKey, value: loggedOut.toString());
  Future<void> initializeLogoutFlag() async {
    // Mimics the logic from the old setLogout() function
    final currentFlag = await _storage.read(key: _logoutFlagKey);
    if (currentFlag == null) {
      await setLogoutFlag(false);
    }
  }

  // --- Read Alerts ---
  Future<List<dynamic>?> getReadAlerts() async {
    final String? alertsJson = await _storage.read(key: _alertsKey);
    if (alertsJson != null) {
      try {
        return jsonDecode(alertsJson) as List<dynamic>;
      } catch (e) {
        // Optionally delete corrupted data
        // await deleteReadAlerts();
        return null;
      }
    } else {
      return null; // Return null or empty list? Let's use null for clarity.
    }
  }

  Future<void> setReadAlerts(List<dynamic> alertIds) =>
      _storage.write(key: _alertsKey, value: jsonEncode(alertIds));
  Future<void> deleteReadAlerts() => _storage.delete(key: _alertsKey);
}
