import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'webview_downloader.dart';
// Import necessary classes/services
import 'package:hapy_vernetzt_app/core/env.dart';
import 'package:hapy_vernetzt_app/core/services/notification_service.dart';
import 'package:hapy_vernetzt_app/features/notifications/notifications.dart';
import 'package:hapy_vernetzt_app/features/webview/url_handler.dart';
import 'package:hapy_vernetzt_app/core/services/storage_service.dart';
import 'package:hapy_vernetzt_app/main.dart';
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
  double _progress = 0;
  late String _startUrl;
  String _previousUrl = '';
  bool _dontGoBack = false;

  final ReceivePort _port = ReceivePort();

  // Init ChromeSafariBrowser
  final ChromeSafariBrowser browser = ChromeSafariBrowser();

  StreamSubscription<String?>? _notificationSubscription;

  final GlobalKey webViewKey = GlobalKey();
  PullToRefreshController? _pullToRefreshController;
  InAppWebViewController? _webViewController;
  final InAppWebViewSettings _settings = InAppWebViewSettings(
      mediaPlaybackRequiresUserGesture: false,
      allowsInlineMediaPlayback: true,
      iframeAllowFullscreen: true,
      javaScriptCanOpenWindowsAutomatically: true,
      useShouldOverrideUrlLoading: true,
      userAgent:
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36",
      iframeAllow: "camera; microphone",
      javaScriptEnabled: true,
      domStorageEnabled: true,
      supportZoom: false,
      isInspectable: true,
      useOnDownloadStart: true,
      enableViewportScale: false);

  void _handlePopInvoked(bool didPop) {
    if (didPop) return;
    if (_webViewController == null) {
      if (Platform.isAndroid) {
        SystemNavigator.pop();
      }
      return;
    }
    _webViewController!.canGoBack().then((canGoBack) async {
      if (canGoBack) {
        await _webViewController!.goBack();
      } else {
        if (Platform.isAndroid) {
          SystemNavigator.pop();
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _startUrl = widget.initialUrl.isNotEmpty
        ? widget.initialUrl
        : '${Env.appurl}/signup/?v=3';

    // Check if user has session
    StorageService()
        .getSessionId()
        .then((sessionid) => isSessiondIDValid().then((valid) {
              setState(() {
                if ((sessionid == null || valid) &&
                    _startUrl != widget.initialUrl) {
                  _startUrl = '${Env.appurl}/dashboard/?v=3';
                }
              });
            }));

    // Init Flutter Downloader
    IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) async {
      if (data[1] == 3) {
        await FlutterDownloader.loadTasks();
        if (Platform.isIOS) {
          //TODO on iOS I only download a file once
          FlutterDownloader.open(taskId: data[0]);
        }
      }
    });

    FlutterDownloader.registerCallback(downloadCallback);

    // Init pullToRefresh
    _pullToRefreshController = kIsWeb ||
            ![TargetPlatform.iOS, TargetPlatform.android]
                .contains(defaultTargetPlatform)
        ? null
        : PullToRefreshController(
            settings: PullToRefreshSettings(
              color: Env.primaryColorObj,
            ),
            onRefresh: () async {
              if (defaultTargetPlatform == TargetPlatform.android) {
                _webViewController?.reload();
              } else if (defaultTargetPlatform == TargetPlatform.iOS) {
                _webViewController?.loadUrl(
                    urlRequest:
                        URLRequest(url: await _webViewController?.getUrl()));
              }
            },
          );

    NotificationService().registerSetDontGoBackCallback((value) {
      if (mounted) {
        setState(() {
          _dontGoBack = value;
        });
      }
    });
    // Listen to notification stream
    _notificationSubscription = selectnotificationstream.stream.listen((url) {
      if (url != null &&
          url.isNotEmpty &&
          _webViewController != null &&
          mounted) {
        _webViewController!.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: Env.primaryColorObj,
        ),
        home: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) => _handlePopInvoked(didPop),
          child: Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  if (_progress == 1)
                    const SizedBox(height: 4)
                  else
                    LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.grey[200],
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Env.primaryColorObj),
                    ),
                  Expanded(
                      child: InAppWebView(
                    key: webViewKey,
                    initialSettings: _settings,
                    initialUrlRequest: URLRequest(url: WebUri(_startUrl)),
                    pullToRefreshController: _pullToRefreshController,
                    initialUserScripts: UnmodifiableListView<UserScript>([
                      WebViewJS.userScriptremoveBannerJS,
                      WebViewJS.autoClickChatButtonJS,
                    ]),
                    onPermissionRequest: (controller, permissionRequest) async {
                      return PermissionResponse(
                          resources: permissionRequest.resources,
                          action: PermissionResponseAction.GRANT);
                    },
                    onDownloadStarting:
                        (controller, downloadStartRequest) async {
                      await downloadFile(
                        downloadStartRequest.url.toString(),
                        downloadStartRequest.suggestedFilename,
                        downloadStartRequest.mimeType,
                      );
                      return null;
                    },
                    shouldOverrideUrlLoading:
                        (controller, navigationAction) async {
                      String url = navigationAction.request.url!.toString();
                      if (!UrlHandler.isWhitelistedUrl(url)) {
                        if (url.contains("http")) {
                          browser.open(
                            url: WebUri(url),
                          );
                        }
                        return NavigationActionPolicy.CANCEL;
                      }
                      if (UrlHandler.isChatAuthUrl(url)) {
                        final currentSessionId =
                            await StorageService().getSessionId();
                        final authresponse =
                            await http.get(Uri.parse(url), headers: {
                          'Cookie': 'hameln-sessionid=$currentSessionId',
                        });
                        RegExp tokenRegex =
                            RegExp(r'"credentialToken":"(.*?)"');
                        RegExp secretRegex =
                            RegExp(r'"credentialSecret":"(.*?)"');
                        var tokenMatch =
                            tokenRegex.firstMatch(authresponse.body);
                        var secretMatch =
                            secretRegex.firstMatch(authresponse.body);

                        if (tokenMatch != null && secretMatch != null) {
                          var credentialToken = tokenMatch.group(1);
                          var credentialSecret = secretMatch.group(1);

                          final String loginbody = '''
                          {"message":"{\\"msg\\":\\"method\\",\\"id\\":\\"5\\",\\"method\\":\\"login\\",\\"params\\":[{\\"oauth\\":{\\"credentialToken\\":\\"$credentialToken\\",\\"credentialSecret\\":\\"$credentialSecret\\"}}]}"}
                        ''';

                          final oauthresponse = await http.post(
                            Uri.parse(
                                '${Env.chaturl}/api/v1/method.callAnon/login'),
                            headers: {
                              'Content-Type': 'application/json',
                              'Cookie': 'hameln-sessionid=$currentSessionId',
                            },
                            body: loginbody,
                          );
                          var jsonData = jsonDecode(oauthresponse.body);
                          var messageData = jsonDecode(jsonData['message']);

                          controller.addUserScript(
                              userScript: UserScript(
                            source: WebViewJS.addSessionToLocalStorage(
                              messageData['result']['userId'],
                              messageData['result']['token'],
                            ),
                            injectionTime:
                                UserScriptInjectionTime.AT_DOCUMENT_START,
                            forMainFrameOnly: false,
                          ));
                        }
                        controller.loadUrl(
                            urlRequest: URLRequest(
                                url: WebUri("${Env.appurl}/messages/?v=3")));
                      }
                      return NavigationActionPolicy.ALLOW;
                    },
                    onUpdateVisitedHistory: (controller, url, isReload) async {
                      bool shouldShowBackButton = !_dontGoBack &&
                          UrlHandler.canGoBackBasedOnUrl(url.toString());
                      if (shouldShowBackButton) {
                        controller.evaluateJavascript(
                            source: WebViewJS.goBackJS);
                      }
                      if (_dontGoBack && mounted) {
                        setState(() {
                          _dontGoBack = false;
                        });
                      }
                      if (_previousUrl == '${Env.appurl}/login/?v=3' &&
                          url.toString() == '${Env.appurl}/dashboard/') {
                        await StorageService().setLogoutFlag(false);
                        if (url != null) {
                          List<Cookie> cookies =
                              await CookieManager().getCookies(url: url);
                          for (Cookie cookie in cookies) {
                            if (cookie.name == 'hameln-sessionid') {
                              await StorageService().setSessionId(cookie.value);
                            }
                          }
                        }
                      }
                      if (url.toString() == '${Env.appurl}/logout/?v=3') {
                        await StorageService().setLogoutFlag(true);
                        await StorageService().deleteSessionId();
                      }
                      if (UrlHandler.isChatAuthUrl(url.toString())) {
                        controller.loadUrl(
                            urlRequest: URLRequest(
                                url: WebUri("${Env.appurl}/messages/?v=3")));
                      }
                      _previousUrl = url.toString();
                    },
                    onReceivedHttpError:
                        (controller, request, errorResponse) async {
                      if (errorResponse.statusCode == 403 &&
                          request.url.toString() ==
                              '${Env.appurl}/logout/?v=3') {
                        await StorageService().setLogoutFlag(true);
                        return;
                      }
                      controller.reload();
                    },
                    onLoadStop: (controller, url) {},
                    onWebViewCreated: (controller) =>
                        _webViewController = controller,
                    onProgressChanged: (controller, progress) {
                      if (progress == 100) {
                        _pullToRefreshController?.endRefreshing();
                      }
                      setState(() {
                        _progress = progress / 100;
                      });
                    },
                  )),
                ],
              ),
            ),
          ),
        ));
  }
}
