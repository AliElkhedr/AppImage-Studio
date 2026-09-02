import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import '../models/build_log_entry.dart';

class AppImageToolService {
  static const String _downloadUrl =
      'https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage';
  static const String _assetPath = 'assets/bin/appimagetool';

  /// Returns the path to the appimagetool binary if available.
  static Future<String?> findExistingTool() async {
    // 1. Check local AppImage Studio directory first
    final localPath = _getLocalToolPath();
    final file = File(localPath);
    if (await file.exists()) {
      return localPath;
    }

    // 2. Check system PATH
    try {
      final result = await Process.run('which', ['appimagetool']);
      if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
        return result.stdout.toString().trim();
      }
    } catch (_) {}

    return null;
  }

  static String _getLocalToolPath() {
    final home = Platform.environment['HOME'] ?? '';
    return p.join(home, '.local', 'share', 'appimage_studio', 'bin', 'appimagetool');
  }

  /// Ensures appimagetool is ready (checks cache/PATH -> extracts bundled asset -> downloads if needed)
  static Future<String> ensureToolAvailable({
    Function(BuildLogEntry)? onLog,
  }) async {
    final existing = await findExistingTool();
    if (existing != null) {
      onLog?.call(BuildLogEntry('تم العثور على أداة appimagetool في: $existing', level: LogLevel.info));
      return existing;
    }

    final localPath = _getLocalToolPath();
    final localFile = File(localPath);
    await localFile.parent.create(recursive: true);

    // 1. Try extracting bundled asset (100% Offline)
    try {
      onLog?.call(BuildLogEntry(
        'جاري استخراج أداة appimagetool المدمجة بالتطبيق (بدون إنترنت)...',
        level: LogLevel.info,
      ));
      final byteData = await rootBundle.load(_assetPath);
      final buffer = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      await localFile.writeAsBytes(buffer);
      await Process.run('chmod', ['+x', localPath]);

      onLog?.call(BuildLogEntry(
        'تم استخراج appimagetool بنجاح وجاهزة للاستخدام.',
        level: LogLevel.success,
      ));
      return localPath;
    } catch (assetError) {
      onLog?.call(BuildLogEntry(
        'تعذر الاستخراج من الحزمة المدمجة ($assetError)، جاري محاولة التنزيل عبر الإنترنت...',
        level: LogLevel.warning,
      ));
    }

    // 2. Fallback: Download via HTTP if bundled asset failed
    try {
      final response = await http.get(Uri.parse(_downloadUrl));
      if (response.statusCode == 200) {
        await localFile.writeAsBytes(response.bodyBytes);
        await Process.run('chmod', ['+x', localPath]);
        onLog?.call(BuildLogEntry(
          'تم تنزيل appimagetool بنجاح وضبط الصلاحيات التنفيذية.',
          level: LogLevel.success,
        ));
        return localPath;
      } else {
        throw Exception('فشل التنزيل برمز استجابة: ${response.statusCode}');
      }
    } catch (e) {
      onLog?.call(BuildLogEntry('خطأ أثناء تجهيز appimagetool: $e', level: LogLevel.error));
      rethrow;
    }
  }
}
