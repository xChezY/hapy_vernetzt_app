import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hapy_vernetzt_app/env.dart';
import 'package:hapy_vernetzt_app/notifications.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:http/http.dart' as http;

import '../main.dart';

class IOSWebViewPage extends StatefulWidget {
  final String gobackjs = '''
                              var element = document.querySelector('nav');
                              if (element) {
                                const arrowLink = document.createElement('a');
                                arrowLink.id = 'goback'
                                arrowLink.href = 'javascript:window.history.back();';
                                arrowLink.style = 'padding: 8px';   
                                arrowLink.innerHTML = `<i class="fas fa-chevron-left"></i>`;
                                element.prepend(arrowLink);
                              }
                            ''';

  final String removebannerjs = '''
                                  if(document.querySelector('footer')) {
                                    document.querySelector('footer').remove();
                                  }
                                ''';

  const IOSWebViewPage({super.key});

  @override
  State<StatefulWidget> createState() => _IOSWebViewPageState();
}

class _IOSWebViewPageState extends State<IOSWebViewPage> {
  String _previousurl = '';
  final ValueNotifier<int> _progress = ValueNotifier<int>(0);

  Future<bool> _iOSControllerFuture() async {
    String? sessionid = await storage.read(key: 'sessionid');

    if (sessionid != null) {
      if (await isSessiondIDValid()) {
        starturl = '${Env.appurl}/dashboard/?v=3';
      } else {
        await storage.delete(key: 'sessionid');
      }
    }

    ioscontroller =
        WebKitWebViewController(WebKitWebViewControllerCreationParams())
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..enableZoom(false)
          ..loadRequest(LoadRequestParams(uri: Uri.parse(starturl)));

    ioscontroller!.setPlatformNavigationDelegate(WebKitNavigationDelegate(
      const PlatformNavigationDelegateCreationParams(),
    )
      ..setOnNavigationRequest((NavigationRequest request) async {
        if (!isWhitelistedUrl(request.url)) {
          return NavigationDecision.prevent;
        }
        if (isChatAuthUrl(request.url)) {
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

            WebViewCookie id = WebViewCookie(
                name: 'rc_session_uid',
                value: messageData['result']['id'],
                domain: ".hapy-vernetzt.de");
            WebViewCookie token = WebViewCookie(
                name: 'rc_session_token',
                value: messageData['result']['token'],
                domain: ".hapy-vernetzt.de");
            WebViewCookieManager().setCookie(id);
            WebViewCookieManager().setCookie(token);
          }
          return NavigationDecision.prevent;
        }
        return NavigationDecision.navigate;
      })
      ..setOnProgress((int progress) {
        _progress.value = progress;
      })
      ..setOnPageFinished(
        (url) async {
          ioscontroller!.clearCache();
          ioscontroller!.runJavaScript(widget.removebannerjs);
          if (canGoBack(url)) {
            ioscontroller!.runJavaScript(widget.gobackjs);
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
          _previousurl = url;
        },
      )
      ..setOnWebResourceError((onWebResourceError) {
        ioscontroller!.reload();
      })
      ..setOnHttpError((HttpResponseError error) async {
        if (error.response!.statusCode == 403 &&
            error.request!.uri.toString() == '${Env.appurl}/logout/?v=3') {
          notificationid = -1;
          await storage.write(key: 'logout', value: 'true');
          return;
        }
        ioscontroller!.reload();
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
            return iOSWebView(context, _progress, snapshot);
          }),
    );
  }
}

Widget iOSWebView(BuildContext context, ValueNotifier<int> progress,
    AsyncSnapshot<bool> snapshot) {
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
            child: snapshot.connectionState == ConnectionState.done
                ? WebKitWebViewWidget(WebKitWebViewWidgetCreationParams(
                        controller: ioscontroller!))
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
