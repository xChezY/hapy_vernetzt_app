import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hapy_vernetzt_app/main.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import 'package:http/http.dart' as http;
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

class AndroidWebViewPage extends StatefulWidget {
  const AndroidWebViewPage({super.key});

  @override
  State<StatefulWidget> createState() => _AndroidWebViewPageState();
}

class _AndroidWebViewPageState extends State<AndroidWebViewPage> {
  final List<String> _history = <String>[];

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
    )..setOnPageFinished(
        (url) async {
          if (_history.isNotEmpty &&
              _history[_history.length - 1] ==
                  'https://hapy-vernetzt.de/login/') {
            List<Cookie> cookies = await cookiemanager
                .getCookies('https://hapy-vernetzt.de/dashboard/');
            for (Cookie cookie in cookies) {
              if (cookie.name == 'hameln-sessionid') {
                await storage.write(key: 'sessionid', value: cookie.value);
              }
            }
          }
          if (url == 'https://hapy-vernetzt.de/logout/') {
            await storage.delete(key: 'sessionid');
          }
          if (_history.isEmpty || _history[_history.length - 1] != url) {
            if (url == 'https://hapy-vernetzt.de/dashboard/') {
              _history.clear();
            }
            _history.add(url);
          }
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
            return androidWebView(context, snapshot, _history);
          }),
    );
  }
}

Widget androidWebView(
    BuildContext context, AsyncSnapshot<bool> snapshot, List<String> history) {
  return PopScope(
    onPopInvoked: (didPop) async {
      if (history.length > 1) {
        ioscontroller!.loadRequest(
            LoadRequestParams(uri: Uri.parse(history[history.length - 2])));
        history.removeLast();
      }
    },
    canPop: false,
    child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          toolbarHeight: 25,
        ),
        body: snapshot.connectionState == ConnectionState.done
            ? AndroidWebViewWidget(AndroidWebViewWidgetCreationParams(
                    controller: androidcontroller!))
                .build(context)
            : const Center(
                child: CircularProgressIndicator(
                color: Color.fromRGBO(47, 133, 90, 1),
              ))),
  );
}
