import 'package:hapy_vernetzt_app/core/env.dart';

class UrlHandler {
  static final List<String> whitelist = [
    Env.appurl,
    Env.cloudurl,
    Env.chaturl,
    "https://newassets.hcaptcha.com",
  ];

  // Checks if navigation back should be allowed based *only* on the URL pattern.
  // The 'dontgoback' flag needs to be handled separately in the navigation logic.
  static bool canGoBackBasedOnUrl(String url) {
    if (url.startsWith('${Env.appurl}/dashboard/?v=3') ||
        url.startsWith('${Env.appurl}/login/?v=3') ||
        url.startsWith('${Env.appurl}/signup/?v=3') ||
        url.startsWith('${Env.appurl}/logout/?v=3') ||
        url.startsWith('${Env.appurl}/password_reset/?v=3') ||
        url.startsWith('${Env.appurl}/messages/?v=3')) {
      return false;
    }
    return true;
  }

  static bool isWhitelistedUrl(String url) {
    // Check if the URL belongs to any whitelisted domain (allows resource loading).
    for (final String domain in whitelist) {
      // Normalize domain by removing scheme for regex
      final domainWithoutScheme =
          domain.replaceAll('https://', '').replaceAll('http://', '');
      // Escape special characters for regex
      final escapedDomain = RegExp.escape(domainWithoutScheme);
      // Regex to match scheme, optional subdomain, escaped domain, and optional path
      final pattern =
          r'^https?:\/\/([a-zA-Z0-9-]+\.)?' + escapedDomain + r'(\/.*)?$';
      if (RegExp(pattern).hasMatch(url)) {
        return true;
      }
    }
    return false;
  }

  static bool isChatAuthUrl(String url) {
    return url.startsWith('${Env.chaturl}/_oauth');
  }
}
