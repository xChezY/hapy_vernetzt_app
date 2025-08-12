import 'dart:isolate';
import 'dart:ui';
import 'dart:io';

import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:hapy_vernetzt_app/core/env.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;

class DownloadResult {
  final String? taskId;
  final String filename;
  final String savedDir;

  DownloadResult(
      {required this.taskId, required this.filename, required this.savedDir});
}

Future<DownloadResult?> downloadFile(String url,
    [String? suggestedFilename, String? mimeType]) async {
  List<Cookie> cookies =
      await CookieManager().getCookies(url: WebUri(Env.cloudurl));
  Map<String, String> headercookie = {
    "Cookie": cookies.map((c) => '${c.name}=${c.value}').join('; ')
  };

  final String baseName =
      '${Env.sanitizedAppName}-download_${DateTime.now().millisecondsSinceEpoch}';
  String? filename = suggestedFilename;
  if (filename == null || filename.isEmpty || filename.endsWith('.php')) {
    if (mimeType == 'application/zip') {
      filename = '$baseName.zip';
    } else {
      final urlName = url.split('/').last.split('?').first;
      if (urlName.isNotEmpty && !urlName.endsWith('.php')) {
        filename = urlName;
      } else {
        filename = baseName;
      }
    }
  }

  // iOS: Use native Save As dialog
  if (Platform.isIOS) {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempPath = p.join(tempDir.path, filename);

      // Stream download to temp file (to avoid loading whole file into memory)
      final request = http.Request('GET', Uri.parse(url));
      headercookie.forEach((k, v) => request.headers[k] = v);
      final streamed = await request.send();
      if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
        final file = File(tempPath);
        final sink = file.openWrite();
        await streamed.stream.pipe(sink);
        await sink.close();

        final savePath = await FlutterFileDialog.saveFile(
          params: SaveFileDialogParams(
            sourceFilePath: tempPath,
            fileName: filename,
          ),
        );

        // Cleanup temp file
        try {
          await file.delete();
        } catch (_) {}

        if (savePath != null) {
          return DownloadResult(
              taskId: null, filename: filename, savedDir: p.dirname(savePath));
        }
        return null; // user cancelled
      }
      return null; // download error
    } catch (_) {
      return null;
    }
  }

  // Android: use flutter_downloader to save into public Downloads
  if (Platform.isAndroid) {
    Directory? baseDir;
    try {
      final List<Directory>? dirs = await getExternalStorageDirectories(
        type: StorageDirectory.downloads,
      );
      if (dirs != null && dirs.isNotEmpty) {
        baseDir = dirs.first;
      } else {
        baseDir = await getApplicationDocumentsDirectory();
      }
    } catch (_) {}

    if (baseDir == null) {
      return null;
    }

    final Directory targetDir = Directory(baseDir.path);
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final String? taskId = await FlutterDownloader.enqueue(
      url: url,
      headers: headercookie,
      savedDir: targetDir.path,
      saveInPublicStorage: true,
      fileName: filename,
    );

    if (taskId == null) {
      return null;
    }

    return DownloadResult(
        taskId: taskId, filename: filename, savedDir: targetDir.path);
  }

  // Other platforms are not supported
  return null;
}

@pragma('vm:entry-point')
void downloadCallback(String id, int status, int progress) {
  final SendPort? send =
      IsolateNameServer.lookupPortByName('downloader_send_port');
  send?.send([id, status, progress]);
}
