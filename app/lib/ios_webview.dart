import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hapy_vernetzt_app/env.dart';
import 'package:hapy_vernetzt_app/notifications.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'main.dart';

class IOSWebViewPage extends StatefulWidget {
  final String gobackjs = '''
                              var element = document.querySelector('div.nav-section.nav-brand');
                              if (element) {
                                const arrowLink = document.createElement('a');
                                arrowLink.href = 'javascript:window.history.back();';
                                arrowLink.classList.add('nav-button');    
                                arrowLink.innerHTML = `<i class="fas fa-chevron-left"></i>`;
                                element.prepend(arrowLink);
                              }
                            ''';

  final String removebannerjs = '''
                                  const banner = document.querySelector('.footer-icon-frame');
                                  if (banner) {
                                    banner.remove();
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
        starturl = '${Env.appurl}/dashboard/';
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
      ..setOnNavigationRequest((NavigationRequest request) {
        final regexPattern = r'^https?:\/\/([a-zA-Z0-9-]+\.)?' +
            RegExp.escape(Env.appurl
                .replaceAll('https://', '')
                .replaceAll('http://', '')) +
            r'\/?$';
        if (RegExp(regexPattern).hasMatch(request.url)) {
          return NavigationDecision.prevent;
        }
        return NavigationDecision.navigate;
      })
      ..setOnProgress((int progress) {
        _progress.value = progress;
      })
      ..setOnPageFinished(
        (url) async {
          ioscontroller!.runJavaScript(widget.removebannerjs);
          if (canGoBack(url)) {
            ioscontroller!.clearCache();
            ioscontroller!.runJavaScript(widget.gobackjs);
          }
          if (_previousurl == '${Env.appurl}/login/' &&
              url == '${Env.appurl}/dashboard/') {
            await storage.write(key: 'logout', value: 'false');
            List<Cookie> cookies = await cookieManager.getCookies(url);
            for (Cookie cookie in cookies) {
              if (cookie.name == 'hameln-sessionid') {
                await storage.write(key: 'sessionid', value: cookie.value);
              }
            }
          }
          if (url == '${Env.appurl}/logout/') {
            notificationid = -1;
            await storage.write(key: 'logout', value: 'true');
            await storage.delete(key: 'sessionid');
          }
          _previousurl = url;
        },
      )
      ..setOnHttpError((HttpResponseError error) async {
        if (error.response!.statusCode == 403 &&
            error.request!.uri.toString() == '${Env.appurl}/logout/') {
          notificationid = -1;
          await storage.write(key: 'logout', value: 'true');
        }
      }));

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      Color.fromRGBO(47, 133, 90, 1)),
                );
              }),
          Expanded(
            child: ValueListenableBuilder(
                valueListenable: progress,
                builder: (context, value, child) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return value == 100 || (value <= 50 && value >= 1)
                        ? WebKitWebViewWidget(WebKitWebViewWidgetCreationParams(
                                controller: ioscontroller!))
                            .build(context)
                        : const Center(
                            child: CupertinoActivityIndicator(
                            color: Color.fromRGBO(47, 133, 90, 1),
                          ));
                  }
                  return const Center(
                      child: CupertinoActivityIndicator(
                    color: Color.fromRGBO(47, 133, 90, 1),
                  ));
                }),
          ),
        ],
      ),
    ),
  );
}
