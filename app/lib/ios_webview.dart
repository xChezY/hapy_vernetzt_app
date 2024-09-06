import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hapy_vernetzt_app/ios_appbar.dart';
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

  final ValueNotifier<bool> _canGoBack = ValueNotifier<bool>(false);

  final List<String> _history = <String>[]; 

  @override
  initState() {
    super.initState();
    _requestIOSPermissions();
  }

  @override
  void dispose() {
    super.dispose();
    selectnotificationstream.close();
  }

  Future<void> _requestIOSPermissions() async {
    await flutterlocalnotificationsplugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          sound: true,
        );
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
          _canGoBack.value = _history.length > 1;
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
            return iOSWebView(context, _canGoBack, snapshot, _history);
          }),
    );
  }
}

Widget iOSWebView(BuildContext context, ValueListenable<bool> canGoBack,
    AsyncSnapshot<bool> snapshot, List<String> history) {
  return CupertinoPageScaffold(
    backgroundColor: Colors.white,
    navigationBar: snapshot.connectionState == ConnectionState.done
        ? iOSAppBar(context, canGoBack, history)
        : null,
    child: Container(
        decoration: const BoxDecoration(
          border: Border(
              bottom: BorderSide(
            color: Colors.white,
            width: 30.0,
          )),
        ),
        child: snapshot.connectionState == ConnectionState.done
            ? WebKitWebViewWidget(WebKitWebViewWidgetCreationParams(
                    controller: ioscontroller!))
                .build(context)
            : const Center(
                child: CupertinoActivityIndicator(
                color: Color.fromRGBO(47, 133, 90, 1),
              ))),
  );
}
