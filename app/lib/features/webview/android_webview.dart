import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hapy_vernetzt_app/core/env.dart';
import 'package:hapy_vernetzt_app/main.dart';
import 'package:hapy_vernetzt_app/features/notifications/notifications.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:hapy_vernetzt_app/features/webview/webview_js.dart';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';
import 'package:hapy_vernetzt_app/features/webview/url_handler.dart';

class AndroidWebViewPage extends StatefulWidget {
  const AndroidWebViewPage({super.key});

  @override
  State<StatefulWidget> createState() => _AndroidWebViewPageState();
}

class _AndroidWebViewPageState extends State<AndroidWebViewPage> {
  String _previousurl = '';
  final ValueNotifier<int> _progress = ValueNotifier<int>(0);
  bool _dontGoBack = false;

  @override
  void initState() {
    super.initState();
    // Register callback with NotificationHandler
    NotificationHandler.registerSetDontGoBackCallback((value) {
      setState(() {
        _dontGoBack = value;
      });
    });
  }

  @override
  void dispose() {
    // Unregister callback
    NotificationHandler.unregisterSetDontGoBackCallback();
    super.dispose();
  }

  Future<bool> _androidControllerFuture() async {
    String? sessionid = await storage.read(key: 'sessionid');

    if (sessionid != null) {
      if (await isSessiondIDValid()) {
        starturl = '${Env.appurl}/dashboard/?v=3';
      } else {
        await storage.delete(key: 'sessionid');
      }
    }

    androidcontroller =
        AndroidWebViewController(AndroidWebViewControllerCreationParams())
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..enableZoom(false)
          ..loadRequest(LoadRequestParams(uri: Uri.parse(starturl)));

    androidcontroller!.setPlatformNavigationDelegate(AndroidNavigationDelegate(
      const PlatformNavigationDelegateCreationParams(),
    )
      ..setOnNavigationRequest((NavigationRequest request) async {
        if (!UrlHandler.isWhitelistedUrl(request.url)) {
          return NavigationDecision.prevent;
        }
        if (UrlHandler.isChatAuthUrl(request.url)) {
          final authresponse = await http.get(Uri.parse(request.url), headers: {
            'Cookie': 'hameln-sessionid=$sessionid',
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
                'Cookie': 'hameln-sessionid=$sessionid',
              },
              body: loginbody,
            );
            var jsonData = jsonDecode(oauthresponse.body);
            var messageData = jsonDecode(jsonData['message']);
            androidcontroller!.runJavaScript('''
              localStorage.setItem('Meteor.userId', '${messageData['result']['id']}');
              localStorage.setItem('Meteor.loginToken', '${messageData['result']['token']}');
            ''');
          }
        }
        return NavigationDecision.navigate;
      })
      ..setOnProgress((int progress) {
        _progress.value = progress;
      })
      ..setOnPageFinished(
        (url) async {
          androidcontroller!.runJavaScript(WebViewJS.removeBannerJS);
          bool shouldShowBackButton =
              !_dontGoBack && UrlHandler.canGoBackBasedOnUrl(url);
          if (shouldShowBackButton) {
            androidcontroller!.runJavaScript(WebViewJS.goBackJS);
          }
          if (_dontGoBack) {
            setState(() {
              _dontGoBack = false;
            });
          }
          if (_previousurl == '${Env.appurl}/login/?v=3' &&
              url == '${Env.appurl}/dashboard/?v=3') {
            await storage.write(key: 'logout', value: 'false');
            List<Cookie> cookies = await cookieManager.getCookies(url);
            for (Cookie cookie in cookies) {
              if (cookie.name == 'hameln-sessionid') {
                await storage.write(key: 'sessionid', value: cookie.value);
              }
            }
          }
          if (url == '${Env.appurl}/logout/?v=3') {
            notificationid = -1;
            await storage.write(key: 'logout', value: 'true');
            await storage.delete(key: 'sessionid');
          }
          if (UrlHandler.isChatAuthUrl(url)) {
            androidcontroller!.loadRequest(LoadRequestParams(
                uri: Uri.parse("${Env.appurl}/messages/?v=3")));
          }
          _previousurl = url;
        },
      )
      ..setOnWebResourceError((onWebResourceError) {
        androidcontroller!.reload();
      })
      ..setOnHttpError((HttpResponseError error) async {
        if (error.response!.statusCode == 403 &&
            error.request!.uri.toString() == '${Env.appurl}/logout/?v=3') {
          notificationid = -1;
          await storage.write(key: 'logout', value: 'true');
          return;
        }
        androidcontroller!.reload();
      }));

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Env.primaryColorObj,
      ),
      home: FutureBuilder(
          future: _androidControllerFuture(),
          builder: (context, snapshot) {
            return androidWebView(context, _progress, snapshot, _previousurl,
                (val) => setState(() => _dontGoBack = val), _dontGoBack);
          }),
    );
  }
}

Widget androidWebView(
    BuildContext context,
    ValueNotifier<int> progress,
    AsyncSnapshot<bool> snapshot,
    String previousurl,
    Function(bool) setDontGoBack,
    bool dontGoBackState) {
  return PopScope(
    onPopInvokedWithResult: (didPop, result) async {
      bool allowPop = false;
      if (!dontGoBackState) {
        if (UrlHandler.canGoBackBasedOnUrl(previousurl)) {
          androidcontroller!.goBack();
        } else {
          allowPop = true;
        }
      } else {
        setDontGoBack(false);
      }
    },
    canPop: false,
    child: Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
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
              child: snapshot.connectionState == ConnectionState.done
                  ? AndroidWebViewWidget(AndroidWebViewWidgetCreationParams(
                          controller: androidcontroller!))
                      .build(context)
                  : Center(
                      child: CircularProgressIndicator(
                      color: Env.primaryColorObj,
                    )),
            ),
          ],
        ),
      ),
    ),
  );
}
