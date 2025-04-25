import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hapy_vernetzt_app/main.dart' show selectnotificationstream;
import 'package:webview_cookie_manager/webview_cookie_manager.dart';
import 'package:hapy_vernetzt_app/core/env.dart';
import 'package:hapy_vernetzt_app/features/notifications/notifications.dart'
    show isSessiondIDValid;
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:http/http.dart' as http;
import 'package:hapy_vernetzt_app/features/webview/webview_js.dart';
import 'package:hapy_vernetzt_app/features/webview/url_handler.dart';
import 'dart:async';

import '../../../main.dart';
import 'package:hapy_vernetzt_app/core/services/notification_service.dart';
import 'package:hapy_vernetzt_app/core/services/storage_service.dart';

class IOSWebViewPage extends StatefulWidget {
  const IOSWebViewPage({super.key});

  @override
  State<StatefulWidget> createState() => _IOSWebViewPageState();
}

class _IOSWebViewPageState extends State<IOSWebViewPage> {
  WebKitWebViewController? _controller;
  StreamSubscription<String?>? _notificationSubscription;

  String _previousurl = '';
  final ValueNotifier<int> _progress = ValueNotifier<int>(0);
  bool _dontGoBack = false;

  @override
  void initState() {
    super.initState();
    // Register callback with NotificationService instance
    NotificationService().registerSetDontGoBackCallback((value) {
      if (mounted) {
        setState(() {
          _dontGoBack = value;
        });
      }
    });
    // Listen to notification stream
    _notificationSubscription = selectnotificationstream.stream.listen((url) {
      if (url != null && url.isNotEmpty && _controller != null && mounted) {
        debugPrint('Received URL from notification stream: $url');
        _controller!.loadRequest(LoadRequestParams(uri: Uri.parse(url)));
      }
    });
  }

  @override
  void dispose() {
    // Unregister callback from NotificationService instance
    NotificationService().unregisterSetDontGoBackCallback();
    // Cancel stream subscription
    _notificationSubscription?.cancel();
    super.dispose();
  }

  Future<bool> _iOSControllerFuture() async {
    String? sessionid = await StorageService().getSessionId();
    String starturl = '${Env.appurl}/signup/?v=3';

    if (sessionid != null) {
      if (await isSessiondIDValid()) {
        starturl = '${Env.appurl}/dashboard/?v=3';
      } else {
        await StorageService().deleteSessionId();
      }
    }

    // Initialize local controller
    _controller =
        WebKitWebViewController(WebKitWebViewControllerCreationParams())
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..enableZoom(false)
          ..loadRequest(LoadRequestParams(uri: Uri.parse(starturl)));

    // Use local controller
    _controller!.setPlatformNavigationDelegate(WebKitNavigationDelegate(
      const PlatformNavigationDelegateCreationParams(),
    )
      ..setOnNavigationRequest((NavigationRequest request) async {
        if (!UrlHandler.isWhitelistedUrl(request.url)) {
          return NavigationDecision.prevent;
        }
        if (UrlHandler.isChatAuthUrl(request.url)) {
          final currentSessionId = await StorageService().getSessionId();
          final authresponse = await http.get(Uri.parse(request.url), headers: {
            'Cookie': 'hameln-sessionid=$currentSessionId',
          });
          RegExp tokenRegex = RegExp(r'"credentialToken":"(.*?)"');
          RegExp secretRegex = RegExp(r'"credentialSecret":"(.*?)"');
          var tokenMatch = tokenRegex.firstMatch(authresponse.body);
          var secretMatch = secretRegex.firstMatch(authresponse.body);

          if (tokenMatch != null && secretMatch != null) {
            var credentialToken = tokenMatch.group(1);
            var credentialSecret = secretMatch.group(1);

            final String loginbody = '''
                {"message":"{\\"msg\\":\\"method\\",\\"id\\":\\"5\\",\\"method\\":\\"login\\",\\"params\\":[{\\"oauth\\":{\\"credentialToken\\":\\"$credentialToken\\",\\"credentialSecret\\":\\"$credentialSecret\\"}}]}"}
              ''';

            final oauthresponse = await http.post(
              Uri.parse('${Env.chaturl}/api/v1/method.callAnon/login'),
              headers: {
                'Content-Type': 'application/json',
                'Cookie': 'hameln-sessionid=$currentSessionId',
              },
              body: loginbody,
            );
            var jsonData = jsonDecode(oauthresponse.body);
            var messageData = jsonDecode(jsonData['message']);

            // Create dart:io Cookie objects
            final idCookie =
                Cookie('rc_session_uid', messageData['result']['id'])
                  ..domain = Env.baseDomain
                  ..path = "/"
                  ..httpOnly = false
                  ..secure = true;

            final tokenCookie =
                Cookie('rc_session_token', messageData['result']['token'])
                  ..domain = Env.baseDomain
                  ..path = "/"
                  ..httpOnly = false
                  ..secure = true;

            // Use global cookieManager again
            await WebviewCookieManager().setCookies([idCookie, tokenCookie]);
          }
          return NavigationDecision.prevent;
        }
        return NavigationDecision.navigate;
      })
      ..setOnProgress((int progress) {
        if (mounted) {
          _progress.value = progress;
        }
      })
      ..setOnPageFinished(
        (url) async {
          _controller!.clearCache();
          _controller!.runJavaScript(WebViewJS.removeBannerJS);
          bool shouldShowBackButton =
              !_dontGoBack && UrlHandler.canGoBackBasedOnUrl(url);
          if (shouldShowBackButton) {
            _controller!.runJavaScript(WebViewJS.goBackJS);
          }
          if (_dontGoBack) {
            if (mounted) {
              setState(() {
                _dontGoBack = false;
              });
            }
          }
          if (_previousurl == '${Env.appurl}/login/?v=3' &&
              url == '${Env.appurl}/dashboard/?v=3') {
            await StorageService().setLogoutFlag(false);
            List<Cookie> cookies = await WebviewCookieManager().getCookies(url);
            for (Cookie cookie in cookies) {
              if (cookie.name == 'hameln-sessionid') {
                await StorageService().setSessionId(cookie.value);
              }
            }
          }
          if (url == '${Env.appurl}/logout/?v=3') {
            await StorageService().setLogoutFlag(true);
            await StorageService().deleteSessionId();
          }
          _previousurl = url;
        },
      )
      ..setOnWebResourceError((onWebResourceError) {
        _controller!.reload();
      })
      ..setOnHttpError((HttpResponseError error) async {
        if (error.response!.statusCode == 403 &&
            error.request!.uri.toString() == '${Env.appurl}/logout/?v=3') {
          await StorageService().setLogoutFlag(true);
          return;
        }
        _controller!.reload();
      }));

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        primaryColor: Env.primaryColorObj,
      ),
      home: FutureBuilder(
          future: _iOSControllerFuture(),
          builder: (context, snapshot) {
            // Pass local controller to widget function
            return iOSWebView(context, _progress, snapshot, _controller);
          }),
    );
  }
}

Widget iOSWebView(BuildContext context, ValueNotifier<int> progress,
    AsyncSnapshot<bool> snapshot, WebKitWebViewController? controller) {
  return CupertinoPageScaffold(
    backgroundColor: Colors.white,
    child: SafeArea(
      bottom: false,
      child: Column(
        children: [
          ValueListenableBuilder(
              valueListenable: progress,
              builder: (context, progress, child) {
                if (progress == 100) {
                  return const SizedBox(height: 4);
                }
                return LinearProgressIndicator(
                  value: progress / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Env.primaryColorObj),
                );
              }),
          Expanded(
            child: snapshot.connectionState == ConnectionState.done &&
                    controller != null
                ? WebKitWebViewWidget(WebKitWebViewWidgetCreationParams(
                        controller: controller))
                    .build(context)
                : Center(
                    child: CupertinoActivityIndicator(
                    color: Env.primaryColorObj,
                  )),
          ),
        ],
      ),
    ),
  );
}
