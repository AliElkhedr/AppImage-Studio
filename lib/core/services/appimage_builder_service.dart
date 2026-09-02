import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/app_metadata.dart';
import '../models/build_log_entry.dart';
import 'appimagetool_service.dart';
import 'desktop_integrator_service.dart';

class AppImageBuilderService {
  /// Stream controller for live log events
  final _logController = StreamController<BuildLogEntry>.broadcast();
  Stream<BuildLogEntry> get logStream => _logController.stream;

  void _log(String message, {LogLevel level = LogLevel.info}) {
    _logController.add(BuildLogEntry(message, level: level));
  }

  /// Builds the AppImage based on given metadata
  Future<String> build(AppMetadata metadata) async {
    _log('🚀 بدء عملية تجهيز وبناء الحزمة...', level: LogLevel.header);

    // 1. Validation
    final bundleDir = Directory(metadata.bundlePath);
    if (!await bundleDir.exists()) {
      _log('خطأ: مجلد التطبيق غير موجود: ${metadata.bundlePath}', level: LogLevel.error);
      throw Exception('مجلد التطبيق غير موجود');
    }

    final execFile = File(p.join(metadata.bundlePath, metadata.executableName));
    if (!await execFile.exists()) {
      _log('تحذير: لم يتم العثور على الملف التنفيذي المباشر: ${execFile.path}', level: LogLevel.warning);
    }

    // 2. Ensure appimagetool is ready
    _log('🔍 التحقق من توفر أداة appimagetool...');
    final toolBinary = await AppImageToolService.ensureToolAvailable(onLog: (entry) {
      _logController.add(entry);
    });

    // 3. Create temporary AppDir
    final systemTemp = Directory.systemTemp;
    final cleanAppName = metadata.appName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');
    final appDir = Directory(p.join(systemTemp.path, 'appimage_studio_${cleanAppName}_AppDir'));

    if (await appDir.exists()) {
      await appDir.delete(recursive: true);
    }
    await appDir.create(recursive: true);
    _log('📁 تم إنشاء مجلد البناء المؤقت: ${appDir.path}');

    // 4. Copy Bundle content to AppDir
    _log('📦 جاري نسخ ملفات التطبيق والمكتبات إلى AppDir...');
    await _copyDirectory(bundleDir, appDir);

    // Ensure main executable in AppDir is executable
    final targetExec = File(p.join(appDir.path, metadata.executableName));
    if (await targetExec.exists()) {
      await Process.run('chmod', ['+x', targetExec.path]);
    }

    // 5. Generate Advanced Portable AppRun script
    _log('⚙️ توليد سكربت التشغيل الذكي الشامل (AppRun)...');
    final appRunContent = '''#!/bin/sh
set -e

# Determine the absolute base directory
HERE="\$(dirname "\$(readlink -f "\${0}")")"

# 1. Export Library Search Paths
export LD_LIBRARY_PATH="\${HERE}/lib:\${HERE}:\${LD_LIBRARY_PATH}"
export PATH="\${HERE}:\${PATH}"

# 2. Configure Desktop & GLib environments
if [ -d "\${HERE}/share/glib-2.0/schemas" ]; then
  export GSETTINGS_SCHEMA_DIR="\${HERE}/share/glib-2.0/schemas:\${GSETTINGS_SCHEMA_DIR}"
fi
export XDG_DATA_DIRS="\${HERE}/share:\${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"

# 3. Change working directory to bundle root and execute
cd "\${HERE}"
exec "\${HERE}/${metadata.executableName}" "\$@"
''';
    final appRunFile = File(p.join(appDir.path, 'AppRun'));
    await appRunFile.writeAsString(appRunContent);
    await Process.run('chmod', ['+x', appRunFile.path]);

    // 6. Setup Icon (Provide fallback if none chosen)
    String iconBaseName = cleanAppName;
    bool iconCopied = false;

    if (metadata.iconPath != null && metadata.iconPath!.isNotEmpty) {
      final srcIcon = File(metadata.iconPath!);
      if (await srcIcon.exists()) {
        final ext = p.extension(metadata.iconPath!);
        final destIcon = File(p.join(appDir.path, '$iconBaseName$ext'));
        await srcIcon.copy(destIcon.path);
        iconCopied = true;

        try {
          await srcIcon.copy(p.join(appDir.path, '.DirIcon'));
        } catch (_) {}
      }
    }

    // If no icon was provided or found, create a beautiful default SVG icon
    if (!iconCopied) {
      _log('ℹ️ لم يتم تحديد أيقونة، جاري إنشاء أيقونة افتراضية للحزمة...');
      final defaultSvgContent = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256">
  <defs>
    <linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#00E5FF"/>
      <stop offset="100%" stop-color="#7C4DFF"/>
    </linearGradient>
  </defs>
  <rect width="256" height="256" rx="56" fill="#131824"/>
  <rect x="6" y="6" width="244" height="244" rx="50" fill="none" stroke="url(#grad)" stroke-width="4" stroke-opacity="0.8"/>
  <path d="M128 52 L204 96 L204 184 L128 228 L52 184 L52 96 Z" fill="none" stroke="url(#grad)" stroke-width="12" stroke-linejoin="round"/>
  <path d="M128 52 L128 140 M128 140 L204 96 M128 140 L52 96" fill="none" stroke="#00E5FF" stroke-width="8" stroke-linecap="round"/>
  <circle cx="128" cy="140" r="16" fill="#7C4DFF"/>
</svg>''';

      final defaultIconFile = File(p.join(appDir.path, '$iconBaseName.svg'));
      await defaultIconFile.writeAsString(defaultSvgContent);

      try {
        final dirIconFile = File(p.join(appDir.path, '.DirIcon'));
        await dirIconFile.writeAsString(defaultSvgContent);
      } catch (_) {}
    }

    // 7. Generate .desktop file
    _log('📝 توليد ملف التعريف (.desktop)...');
    final desktopContent = '''[Desktop Entry]
Type=Application
Name=${metadata.appName}
Comment=${metadata.description.replaceAll('\n', ' ')}
Exec=AppRun %U
Icon=$iconBaseName
Categories=${metadata.category.freedesktopName};
Terminal=false
StartupNotify=true
''';
    final desktopFile = File(p.join(appDir.path, '$cleanAppName.desktop'));
    await desktopFile.writeAsString(desktopContent);
    await Process.run('chmod', ['+x', desktopFile.path]);

    // 8. Prepare Output Path
    final outputDir = Directory(metadata.outputPath);
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }
    final outputFileName = '${metadata.appName}-${metadata.version}-x86_64.AppImage';
    final outputAppImagePath = p.join(outputDir.path, outputFileName);

    // 9. Execute appimagetool
    // Set ARCH environment variable
    final env = Map<String, String>.from(Platform.environment)..['ARCH'] = 'x86_64';

    final process = await Process.start(
      toolBinary,
      [appDir.path, outputAppImagePath],
      environment: env,
    );

    final List<String> processOutput = [];

    // Stream process outputs
    process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
      if (line.trim().isNotEmpty) {
        processOutput.add(line);
        _log(line, level: LogLevel.info);
      }
    });

    process.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
      if (line.trim().isNotEmpty) {
        processOutput.add(line);
        _log(line, level: LogLevel.warning);
      }
    });

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      final combinedLog = processOutput.join('\n');
      String friendlyMessage = 'فشلت أداة appimagetool أثناء ضغط الحزمة (رمز الخطأ: $exitCode)';
      String suggestion = 'يرجى مراجعة سجل المخرجات أعلاه للتحقق من المشكلة.';

      if (combinedLog.contains('defined in desktop file but not found')) {
        friendlyMessage = 'تعذر العثور على ملف أيقونة التطبيق داخل الحزمة.';
        suggestion = 'يرجى التأكد من اختيار أيقونة بصيغة PNG أو SVG صالحة، أو ترك البرنامج يولد أيقونة افتراضية.';
      } else if (combinedLog.contains('Permission denied') || combinedLog.contains('Read-only file system')) {
        friendlyMessage = 'لا توجد صلاحيات كتابة في مسار مجلد الإخراج المحدد.';
        suggestion = 'يرجى تغيير مجلد الإخراج إلى مجلد تملك فيه صلاحيات الكتابة (مثل سطح المكتب أو التنزيلات).';
      } else if (combinedLog.contains('No space left on device')) {
        friendlyMessage = 'المساحة التخزينية في القرص غير كافية لضغط الملف.';
        suggestion = 'يرجى تفريغ مساحة على القرص الصلب وإعادة المحاولة.';
      } else if (combinedLog.contains('mksquashfs')) {
        friendlyMessage = 'خطأ أثناء عملية ضغط نظام الملفات SquashFS.';
        suggestion = 'يرجى التأكد من أن جميع ملفات التطبيق قابلة للقراءة ولا تحتوي على روابط مكسورة.';
      }

      _log('──────────────────────────────────────────────────────', level: LogLevel.error);
      _log('❌ سبب الخطأ: $friendlyMessage', level: LogLevel.error);
      _log('💡 الحل المقترح: $suggestion', level: LogLevel.warning);
      _log('──────────────────────────────────────────────────────', level: LogLevel.error);

      throw AppImageBuildException(friendlyMessage, suggestion);
    }

    // Make final AppImage executable
    await Process.run('chmod', ['+x', outputAppImagePath]);
    _log('🎉 تم إنشاء ملف الـ AppImage بنجاح!', level: LogLevel.success);
    _log('📍 المسار النهائي: $outputAppImagePath', level: LogLevel.success);

    // 10. Optional Desktop Integration
    if (metadata.integrateInMenu) {
      _log('📌 جاري تثبيت التطبيق في قائمة تطبيقات النظام...');
      await DesktopIntegratorService.integrate(
        metadata: metadata,
        appImagePath: outputAppImagePath,
        onLog: (entry) => _logController.add(entry),
      );
    }

    // Clean up temporary AppDir
    try {
      await appDir.delete(recursive: true);
    } catch (_) {}

    return outputAppImagePath;
  }

  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await destination.create(recursive: true);
    await for (final entity in source.list(recursive: false)) {
      if (entity is Directory) {
        final newDirectory = Directory(p.join(destination.path, p.basename(entity.path)));
        await _copyDirectory(entity, newDirectory);
      } else if (entity is File) {
        final newFile = File(p.join(destination.path, p.basename(entity.path)));
        await entity.copy(newFile.path);
        // Preserve execute permission if any
        final stat = await entity.stat();
        if (stat.mode & 0x49 != 0) {
          await Process.run('chmod', ['+x', newFile.path]);
        }
      }
    }
  }

  void dispose() {
    _logController.close();
  }
}

class AppImageBuildException implements Exception {
  final String message;
  final String suggestion;

  AppImageBuildException(this.message, this.suggestion);

  @override
  String toString() => message;
}
