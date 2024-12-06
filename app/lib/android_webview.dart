import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hapy_vernetzt_app/main.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import 'package:http/http.dart' as http;
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

class AndroidWebViewPage extends StatefulWidget {

  final String gobackjs =   '''
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

  const AndroidWebViewPage({super.key});

  @override
  State<StatefulWidget> createState() => _AndroidWebViewPageState();
}

class _AndroidWebViewPageState extends State<AndroidWebViewPage> {
  String _previousurl = '';
  final ValueNotifier<int> _progress = ValueNotifier<int>(0);

  Future<bool> _androidControllerFuture() async {
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

    androidcontroller =
        AndroidWebViewController(AndroidWebViewControllerCreationParams())
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..enableZoom(false)
          ..loadRequest(LoadRequestParams(uri: Uri.parse(starturl)));

    androidcontroller!.setPlatformNavigationDelegate(AndroidNavigationDelegate(
      const PlatformNavigationDelegateCreationParams(),
    )
      ..setOnProgress((int progress) {
        _progress.value = progress;
      })
      ..setOnPageFinished(
        (url) async {
          androidcontroller!.runJavaScript(widget.removebannerjs);
          if (canGoBack(url)) {
            //TODO Whitelist hinzufügen
            //TODO Loading Bar soll absolut positioniert sein
            //TODO Nur einmal Erinnerungsnachricht bekommen, wenn man sich ausloggt
            //TODO Zusätzlich nur einmal eine Nachricht senden wenn SessionID abgelaufen ist
            //TODO Pull Refresh hinzufügen
            //TODO Dokument zu API Tokens hinzufügen
            //TODO README.md hinzufügen
            androidcontroller!.runJavaScript(widget.gobackjs);
          }
          if (_previousurl == 'https://hapy-vernetzt.de/login/' &&
              url == 'https://hapy-vernetzt.de/dashboard/') {
            List<Cookie> cookies = await cookieManager.getCookies(url);
            for (Cookie cookie in cookies) {
              if (cookie.name == 'hameln-sessionid') {
                await storage.write(key: 'sessionid', value: cookie.value);
              }
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
          future: _androidControllerFuture(),
          builder: (context, snapshot) {
            return androidWebView(context, _progress, snapshot, _previousurl);
          }),
    );
  }
}

Widget androidWebView(BuildContext context, ValueNotifier<int> progress,
    AsyncSnapshot<bool> snapshot, String previousurl) {
  return PopScope(
    onPopInvokedWithResult: (didPop, result) async {
      if (canGoBack(previousurl)) {
        androidcontroller!.goBack();
      }
    },
    canPop: false,
    child: Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
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
                          ? AndroidWebViewWidget(
                                  AndroidWebViewWidgetCreationParams(
                                      controller: androidcontroller!))
                              .build(context)
                          : const Center(
                              child: CircularProgressIndicator(
                              color: Color.fromRGBO(47, 133, 90, 1),
                            ));
                    }
                    return const Center(
                        child: CircularProgressIndicator(
                      color: Color.fromRGBO(47, 133, 90, 1),
                    ));
                  }),
            ),
          ],
        ),
      ),
    ),
  );
}
