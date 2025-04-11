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
}
