import 'dart:isolate';
import 'dart:ui';

import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:hapy_vernetzt_app/core/env.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

Future<void> downloadFile(String url,
    [String? suggestedFilename, String? mimeType]) async {
  List<Cookie> cookies =
      await CookieManager().getCookies(url: WebUri(Env.cloudurl));
  Map<String, String> headercookie = {
    "Cookie": cookies.map((c) => '${c.name}=${c.value}').join('; ')
  };

  String fallbackFilename =
      '${Env.sanitizedAppName}-download_${DateTime.now().millisecondsSinceEpoch}';
  String? filename = suggestedFilename;
  if (filename == null || filename.isEmpty || filename.endsWith('.php')) {
    if (mimeType == 'application/zip') {
      filename = '$fallbackFilename.zip';
    } else {
      final urlName = url.split('/').last.split('?').first;
      if (urlName.isNotEmpty && !urlName.endsWith('.php')) {
        filename = urlName;
      } else {
        filename = fallbackFilename;
      }
    }
  }

  final downloadsDir = await getDownloadsDirectory();
  if (downloadsDir != null) {
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }

    await FlutterDownloader.enqueue(
        url: url,
        headers: headercookie,
        savedDir: downloadsDir.path,
        saveInPublicStorage: true,
        fileName: filename);
  }
}

@pragma('vm:entry-point')
void downloadCallback(String id, int status, int progress) {
  final SendPort? send =
      IsolateNameServer.lookupPortByName('downloader_send_port');
  send?.send([id, status, progress]);
}
