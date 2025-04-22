import 'package:envied/envied.dart';
import 'package:flutter/material.dart';

part 'env.g.dart';

@Envied(path: '.env')
final class Env {
  @EnviedField(varName: 'URL', obfuscate: true)
  static String appurl = _Env.appurl;

  @EnviedField(varName: 'API_TOKEN', obfuscate: true)
  static String apitoken = _Env.apitoken;

  @EnviedField(varName: 'BACKEND_URL', obfuscate: true)
  static String backendurl = _Env.backendurl;

  @EnviedField(varName: 'CLOUD_URL', obfuscate: true)
  static String cloudurl = _Env.cloudurl;

  @EnviedField(varName: 'CHAT_URL', obfuscate: true)
  static String chaturl = _Env.chaturl;

  @EnviedField(varName: 'PRIMARY_COLOR', obfuscate: false)
  static String primaryColor = _Env.primaryColor;

  // Getter für die primäre Farbe als Color-Objekt
  static Color get primaryColorObj =>
      Color(int.parse(primaryColor.replaceAll("0x", ""), radix: 16));

  /// Extracts the base domain with a leading dot (e.g., .example.com) from appurl.
  static String get baseDomain {
    try {
      final uri = Uri.parse(appurl);
      final parts = uri.host.split('.');
      if (parts.length >= 2) {
        // Take the last two parts and prepend a dot.
        return '.${parts.sublist(parts.length - 2).join('.')}';
      } else {
        // Fallback or error handling if the host is too simple (e.g., localhost)
        return uri.host; // Or return an empty string/throw error?
      }
    } catch (e) {
      return ''; // Return empty string on error
    }
  }
}
