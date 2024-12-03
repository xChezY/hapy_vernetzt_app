import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'package:http/http.dart' as http;

import 'main.dart';

class IOSWebViewPage extends StatefulWidget {
  const IOSWebViewPage({super.key});

  @override
  State<StatefulWidget> createState() => _IOSWebViewPageState();
}

class _IOSWebViewPageState extends State<IOSWebViewPage> {
  String _previousurl = '';
  final ValueNotifier<int> _progress = ValueNotifier<int>(0);

  @override
  void dispose() {
    super.dispose();
    selectnotificationstream.close();
  }

  Future<bool> _iOSControllerFuture() async {
    String? sessionid = await storage.read(key: 'sessionid');

    if (sessionid != null) {
      Map<String, dynamic> json = jsonDecode((await http.get(
        Uri.parse('https://hapy-vernetzt.de/api/v3/authinfo'),
        headers: <String, String>{'Cookie': 'hameln-sessionid=$sessionid'},
      ))
          .body);

      if (json['data']['authenticated'] == true) {
        starturl = 'https://hapy-vernetzt.de/dashboard/';
      } else {
        await storage.delete(key: 'sessionid');
      }
    }

    ioscontroller =
        WebKitWebViewController(WebKitWebViewControllerCreationParams())
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..enableZoom(false)
          //..setAllowsBackForwardNavigationGestures(true) // there is no way to customize the back gesture on iOS
          ..loadRequest(LoadRequestParams(uri: Uri.parse(starturl)));

    ioscontroller!.setPlatformNavigationDelegate(WebKitNavigationDelegate(
      const WebKitNavigationDelegateCreationParams(),
    )
      ..setOnProgress((int progress) {
        _progress.value = progress;
      })
      ..setOnPageFinished(
        (url) async {
          String removebanner = '''
                                  const banner = document.querySelector('.footer-icon-frame');
                                  if (banner) {
                                    banner.remove();
                                  }
                                ''';
          ioscontroller!.runJavaScript(removebanner);
          if (url != 'https://hapy-vernetzt.de/dashboard/' &&
              url != 'https://hapy-vernetzt.de/login/' &&
              url != 'https://hapy-vernetzt.de/signup/' &&
              url != 'https://hapy-vernetzt.de/logout/' &&
              url != 'https://hapy-vernetzt.de/password_reset/') {
            String jscode = '''
                              var element = document.querySelector('div.nav-section.nav-brand');
                              if (element) {
                                const arrowLink = document.createElement('a');
                                arrowLink.href = 'javascript:window.history.back();';
                                arrowLink.classList.add('nav-button');    
                                arrowLink.innerHTML = `<i class="fas fa-chevron-left"></i>`;
                                element.prepend(arrowLink);
                              }
                            ''';
            ioscontroller!.clearCache();
            ioscontroller!.runJavaScript(jscode);
          }
          if (_previousurl == 'https://hapy-vernetzt.de/login/' &&
              url == 'https://hapy-vernetzt.de/dashboard/') {
            Map<String, String> cookies = await getCookies(ioscontroller!);
            if (cookies.containsKey('hameln-sessionid')) {
              await storage.write(key: 'sessionid', value: cookies['hameln-sessionid']);
            }
          }
          if (url == 'https://hapy-vernetzt.de/logout/') {
            await storage.delete(key: 'sessionid');
          }
          _previousurl = url;
        },
      ));

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
                  return const SizedBox(height: 0);
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
