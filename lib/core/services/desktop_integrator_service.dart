import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/app_metadata.dart';
import '../models/build_log_entry.dart';

class DesktopIntegratorService {
  /// Integrates the generated AppImage into the local Linux desktop menu
  static Future<void> integrate({
    required AppMetadata metadata,
    required String appImagePath,
    Function(BuildLogEntry)? onLog,
  }) async {
    try {
      final home = Platform.environment['HOME'] ?? '';
      final appsDir = Directory(p.join(home, '.local', 'share', 'applications'));
      final iconsDir = Directory(p.join(home, '.local', 'share', 'icons', 'hicolor', '512x512', 'apps'));

      await appsDir.create(recursive: true);
      await iconsDir.create(recursive: true);

      // 1. Copy icon if provided, or generate fallback SVG icon
      String iconName = metadata.appName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');
      bool iconSaved = false;
      if (metadata.iconPath != null && metadata.iconPath!.isNotEmpty) {
        final srcIcon = File(metadata.iconPath!);
        if (await srcIcon.exists()) {
          final ext = p.extension(metadata.iconPath!);
          final targetIcon = File(p.join(iconsDir.path, '$iconName$ext'));
          await srcIcon.copy(targetIcon.path);
          iconSaved = true;
        }
      }

      if (!iconSaved) {
        final scalableIconsDir = Directory(p.join(home, '.local', 'share', 'icons', 'hicolor', 'scalable', 'apps'));
        await scalableIconsDir.create(recursive: true);
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
        final targetIcon = File(p.join(scalableIconsDir.path, '$iconName.svg'));
        await targetIcon.writeAsString(defaultSvgContent);
      }

      // 2. Create .desktop file
      final safeName = metadata.appName.replaceAll('"', '');
      final desktopContent = '''[Desktop Entry]
Type=Application
Name=$safeName
Comment=${metadata.description.replaceAll('\n', ' ')}
Exec="$appImagePath" %U
Icon=$iconName
Categories=${metadata.category.freedesktopName};
Terminal=false
StartupNotify=true
''';

      final desktopFile = File(p.join(appsDir.path, '$iconName.desktop'));
      await desktopFile.writeAsString(desktopContent);
      await Process.run('chmod', ['+x', desktopFile.path]);

      // Update desktop database if available
      try {
        await Process.run('update-desktop-database', [appsDir.path]);
      } catch (_) {}

      onLog?.call(BuildLogEntry(
        'تم تثبيت التطبيق بنجاح في قائمة البرامج: ${desktopFile.path}',
        level: LogLevel.success,
      ));
    } catch (e) {
      onLog?.call(BuildLogEntry(
        'تعذر التثبيت في قائمة البرامج: $e',
        level: LogLevel.warning,
      ));
    }
  }
}
