import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hapy_vernetzt_app/main.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

CupertinoNavigationBar iOSAppBar(BuildContext context,
    ValueListenable<bool> canGoBack, List<String> history) {
  return CupertinoNavigationBar(
    backgroundColor: Colors.white,
    leading: ValueListenableBuilder<bool>(
      valueListenable: canGoBack,
      builder: (context, canGoBack, child) {
        return IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          color: canGoBack ? Colors.black : Colors.grey,
          onPressed: canGoBack
              ? () async {
                  if (history.length > 1) {
                    ioscontroller!.loadRequest(LoadRequestParams(
                        uri: Uri.parse(history[history.length - 2])));
                    history.removeLast();
                  }
                }
              : null,
        );
      },
    ),
  );
}
