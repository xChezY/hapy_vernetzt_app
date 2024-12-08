import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
final class Env {
  @EnviedField(varName: 'URL', obfuscate: true)
  static String appurl = _Env.appurl;

  @EnviedField(varName: 'API_TOKEN', obfuscate: true)
  static String apitoken = _Env.apitoken;

  @EnviedField(varName: 'BACKEND_URL', obfuscate: true)
  static String backendurl = _Env.backendurl;
}