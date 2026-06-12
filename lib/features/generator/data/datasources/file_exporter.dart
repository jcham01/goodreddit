import 'dart:io';

import 'package:goodreddit/core/error/exceptions.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Writes generated content to a temp file and opens the system share sheet.
class FileExporter {
  Future<void> shareText({
    required String fileName,
    required String content,
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(content);
      await Share.shareXFiles([XFile(file.path)], subject: fileName);
    } catch (e) {
      throw ExportException('Failed to export $fileName: $e');
    }
  }
}
