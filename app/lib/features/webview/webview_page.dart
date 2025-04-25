import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter/cupertino.dart'; // Import Cupertino widgets
// Import necessary classes/services
import 'package:hapy_vernetzt_app/core/env.dart';
import 'package:hapy_vernetzt_app/features/webview/url_handler.dart';
import 'package:hapy_vernetzt_app/core/services/storage_service.dart';
import 'package:http/http.dart' as http;
// Import WebViewJS and dart:io for Cookie
import 'package:hapy_vernetzt_app/features/webview/webview_js.dart';

class WebViewPage extends StatefulWidget {
  // Add constructor to accept initialUrl
  final String initialUrl;
  const WebViewPage({required this.initialUrl, super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  // Use CookieManager singleton from the plugin
  final CookieManager _cookieManager = CookieManager.instance();
  InAppWebViewController? _webViewController;
  double _progress = 0;
  // Add state variables from old implementations
  String _previousUrl = '';
  bool _dontGoBack = false;

  final GlobalKey webViewKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    // Determine initial URL based on widget parameter or env
    final Uri initialUri = Uri.parse(widget.initialUrl ?? Env.appurl);

    // Define the core page content (PopScope -> Scaffold -> Stack -> InAppWebView)
    Widget pageContent = PopScope(
      canPop: false, // Prevent default pop
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        // Only handle if the pop wasn't already handled (e.g., by system)
        if (!didPop && _webViewController != null) {
          debugPrint(
              '[WebView] Pop invoked. Can go back? ${await _webViewController!.canGoBack()}. DontGoBack? $_dontGoBack');
          // Check if webview can go back and if the current URL allows it
          if (await _webViewController!.canGoBack() && !_dontGoBack) {
            debugPrint('[WebView] Going back in webview.');
            _webViewController!.goBack();
          } else {
            // If webview cannot go back or shouldn't, allow Flutter navigation to pop
            debugPrint(
                '[WebView] Cannot go back in webview or dontGoBack is true. Popping route.');
            // Check if the navigator can pop before actually popping
            // Use the correct context depending on the App type (Material/Cupertino)
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          }
        }
      },
      child: Scaffold(
        // Use Scaffold for structure within both app types
        // backgroundColor: Platform.isIOS ? CupertinoColors.systemGroupedBackground : null, // Optional: iOS specific background
        appBar: AppBar(
          toolbarHeight: 0, // Hide AppBar
          // Optional: Use CupertinoNavigationBar for iOS? Requires more changes.
        ),
        body: Stack(
          children: [
            InAppWebView(
              key: webViewKey,
              initialUrlRequest: URLRequest(url: WebUri.uri(initialUri)),
              initialSettings: InAppWebViewSettings(
                useShouldOverrideUrlLoading: true,
                mediaPlaybackRequiresUserGesture: false,
                allowsInlineMediaPlayback: true,
                iframeAllowFullscreen: true,
                javaScriptEnabled: true,
                domStorageEnabled: true,
                javaScriptCanOpenWindowsAutomatically: true,
                enableViewportScale: false,
              ),
              onWebViewCreated: (controller) {
                _webViewController = controller;
              },
              onLoadStart: (controller, url) {
                debugPrint('[WebView] onLoadStart: ${url?.toString()}');
                setState(() {
                  _progress = 0; // Start progress indicator
                });
              },
              onLoadStop: (controller, url) async {
                // Equivalent to setOnPageFinished
                if (url == null) return;
                String urlString = url.toString();
                debugPrint("WebView finished loading: $urlString");

                // Declare canGoBack here
                bool canGoBack = UrlHandler.canGoBackBasedOnUrl(urlString);

                // 1. Execute common JS (remove banner)
                try {
                  await _webViewController?.evaluateJavascript(
                      source: WebViewJS.removeBannerJS);
                } catch (e) {
                  debugPrint("Error executing removeBannerJS: $e");
                }

                // 2. Handle back button visibility based on state
                if (!_dontGoBack && canGoBack) {
                  try {
                    await _webViewController?.evaluateJavascript(
                        source: WebViewJS.goBackJS);
                  } catch (e) {
                    debugPrint("Error executing goBackJS: $e");
                  }
                }

                // 3. Reset dontGoBack flag if it was set
                if (_dontGoBack) {
                  if (mounted) {
                    setState(() {
                      _dontGoBack = false;
                    });
                  }
                }

                // 4. Handle Login/Dashboard transition (Session Cookie Saving)
                if (_previousUrl == '${Env.appurl}/login/?v=3' &&
                    urlString == '${Env.appurl}/dashboard/?v=3') {
                  debugPrint("Login detected, saving session cookie.");
                  await StorageService().setLogoutFlag(false);
                  // Use InAppWebView CookieManager to get cookies
                  List<Cookie> cookies =
                      await _cookieManager.getCookies(url: url);
                  for (Cookie cookie in cookies) {
                    // Use dart:io Cookie properties here (name, value)
                    if (cookie.name == 'hameln-sessionid') {
                      await StorageService().setSessionId(cookie.value);
                      debugPrint("Session ID saved.");
                      break; // Found the cookie, exit loop
                    }
                  }
                }

                // 5. Handle Logout
                if (urlString == '${Env.appurl}/logout/?v=3') {
                  debugPrint("Logout detected.");
                  await StorageService().setLogoutFlag(true);
                  await StorageService().deleteSessionId();
                  // Optionally clear cookies as well?
                  // await _cookieManager.deleteAllCookies();
                }

                // 6. Update previous URL
                _previousUrl = urlString;
              },
              onProgressChanged: (controller, progress) {
                setState(() {
                  _progress = progress / 100;
                });
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                var uri = navigationAction.request.url!;
                var url = uri.toString();
                debugPrint("WebView trying to load: $url");

                // Implement logic from old setOnNavigationRequest
                // 1. Check Whitelist
                if (!UrlHandler.isWhitelistedUrl(url)) {
                  debugPrint("URL blocked by whitelist: $url");
                  return NavigationActionPolicy.CANCEL;
                }

                // 2. Handle Chat Auth URL
                if (UrlHandler.isChatAuthUrl(url)) {
                  debugPrint("Handling chat auth URL: $url");
                  try {
                    // Fetch session ID from storage
                    final sessionid = await StorageService().getSessionId();
                    if (sessionid == null) {
                      debugPrint("Chat auth failed: No session ID found.");
                      // Optionally navigate to login?
                      return NavigationActionPolicy.CANCEL;
                    }

                    final authResponse = await http.get(Uri.parse(url),
                        headers: {'Cookie': 'hameln-sessionid=$sessionid'});

                    if (authResponse.statusCode == 200) {
                      RegExp tokenRegex = RegExp(r'"credentialToken":"(.*?)"');
                      RegExp secretRegex =
                          RegExp(r'"credentialSecret":"(.*?)"');
                      var tokenMatch = tokenRegex.firstMatch(authResponse.body);
                      var secretMatch =
                          secretRegex.firstMatch(authResponse.body);

                      if (tokenMatch != null && secretMatch != null) {
                        var credentialToken = tokenMatch.group(1);
                        var credentialSecret = secretMatch.group(1);

                        final loginBody = '''
                          {"message":"{\"msg\":\"method\",\"id\":\"5\",\"method\":\"login\",\"params\":[{\"oauth\":{\"credentialToken\":\"$credentialToken\",\"credentialSecret\":\"$credentialSecret\"}}]}"}
                        ''';

                        final oauthResponse = await http.post(
                          Uri.parse(
                              '${Env.chaturl}/api/v1/method.callAnon/login'),
                          headers: {
                            'Content-Type': 'application/json',
                            'Cookie': 'hameln-sessionid=$sessionid',
                          },
                          body: loginBody,
                        );

                        if (oauthResponse.statusCode == 200) {
                          var jsonData = jsonDecode(oauthResponse.body);
                          // Check if message exists and is a string before decoding
                          if (jsonData['message'] is String) {
                            var messageData = jsonDecode(jsonData['message']);
                            final userId = messageData?['result']?['id'];
                            final loginToken = messageData?['result']?['token'];

                            if (userId != null && loginToken != null) {
                              // Set cookies using InAppWebView's CookieManager
                              // Correct cookie names to match old implementation (rc_session_...)
                              // Set URL parameter to chat domain, as it needs to read the cookie.
                              await _cookieManager.setCookie(
                                url: WebUri(
                                    Env.chaturl), // Set cookie for chat domain
                                name: 'rc_session_uid', // Corrected name
                                value: userId,
                                domain: Env.baseDomain, // Use base domain
                                path: '/',
                                isSecure: true,
                              );
                              await _cookieManager.setCookie(
                                url: WebUri(
                                    Env.chaturl), // Set cookie for chat domain
                                name: 'rc_session_token', // Corrected name
                                value: loginToken,
                                domain: Env.baseDomain, // Use base domain
                                path: '/',
                                isSecure: true,
                              );
                              debugPrint(
                                  "Chat auth cookies (rc_session_uid, rc_session_token) set for domain ${Env.baseDomain} associated with URL ${Env.chaturl}.");

                              // Remove explicit navigation. Let the original flow continue or
                              // rely on the user already navigating to the messages page.
                              // controller.loadUrl(
                              //     urlRequest: URLRequest(
                              //         url: WebUri(
                              //             "${Env.appurl}/messages/?v=3")));
                              return NavigationActionPolicy
                                  .CANCEL; // Prevent original navigation
                            }
                          }
                        }
                      }
                    }
                  } catch (e) {
                    debugPrint("Error during chat auth: $e");
                  }
                  // Cancel navigation if chat auth fails or an error occurs
                  return NavigationActionPolicy.CANCEL;
                }

                // 3. Allow navigation by default if not handled above
                return NavigationActionPolicy.ALLOW;
              },
              onReceivedHttpError: (controller, request, errorResponse) async {
                // Equivalent to setOnHttpError
                debugPrint(
                    "WebView onReceivedHttpError: ${request.url}, status: ${errorResponse.statusCode}");
                final logoutUrl = '${Env.appurl}/logout/?v=3';
                // Check for specific 403 error on logout URL
                if (errorResponse.statusCode == 403 &&
                    request.url.toString() == logoutUrl) {
                  debugPrint("Logout detected via HTTP 403 error.");
                  await StorageService().setLogoutFlag(true);
                  // Also delete session ID here for consistency
                  await StorageService().deleteSessionId();
                } else {
                  // Reload for other HTTP errors
                  controller.reload();
                }
              },
            ),
            if (_progress < 1.0)
              LinearProgressIndicator(
                value: _progress,
                // Use color from Env
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(Env.primaryColorObj),
              ),
          ],
        ),
      ),
    );

    // Check the platform and return the appropriate App widget
    // Always return MaterialApp to provide MaterialLocalizations
    // if (Platform.isIOS) {
    //   return CupertinoApp(
    //     debugShowCheckedModeBanner: false,
    //     theme: CupertinoThemeData(
    //       primaryColor: Env.primaryColorObj, // Use color from Env
    //       // brightness: Brightness.light, // Optional: Set brightness
    //     ),
    //     home: pageContent, // Use the common page content
    //   );
    // } else {
    // Return MaterialApp for Android and other platforms
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Env.primaryColorObj, // Use color from Env
      ),
      home: pageContent, // Use the common page content
    );
    // }
  }
}
