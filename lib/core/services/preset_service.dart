import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import '../models/app_metadata.dart';

class PresetService {
  static const String presetFileName = 'appimage_studio.yaml';

  /// Checks if a preset file exists in the directory
  static bool hasPreset(String directoryPath) {
    final file = File(p.join(directoryPath, presetFileName));
    return file.existsSync();
  }

  /// Loads AppMetadata from preset file if it exists
  static Future<AppMetadata?> loadPreset(String directoryPath) async {
    final file = File(p.join(directoryPath, presetFileName));
    if (!await file.exists()) {
      return null;
    }

    try {
      final content = await file.readAsString();
      final yaml = loadYaml(content);
      if (yaml is! Map) return null;

      AppCategory category = AppCategory.utility;
      final categoryStr = yaml['category']?.toString();
      if (categoryStr != null) {
        category = AppCategory.values.firstWhere(
          (c) => c.freedesktopName.toLowerCase() == categoryStr.toLowerCase() ||
                 c.name.toLowerCase() == categoryStr.toLowerCase(),
          orElse: () => AppCategory.utility,
        );
      }

      return AppMetadata(
        appName: yaml['appName']?.toString() ?? '',
        executableName: yaml['executableName']?.toString() ?? '',
        version: yaml['version']?.toString() ?? '1.0.0',
        description: yaml['description']?.toString() ?? '',
        category: category,
        bundlePath: yaml['bundlePath']?.toString() ?? directoryPath,
        iconPath: yaml['iconPath']?.toString(),
        outputPath: yaml['outputPath']?.toString() ?? '',
        integrateInMenu: yaml['integrateInMenu'] == true,
      );
    } catch (_) {
      return null;
    }
  }

  /// Saves AppMetadata to appimage_studio.yaml in target directory
  static Future<File> savePreset(String directoryPath, AppMetadata metadata) async {
    final file = File(p.join(directoryPath, presetFileName));
    final yamlBuffer = StringBuffer();

    yamlBuffer.writeln('# ==========================================');
    yamlBuffer.writeln('# AppImage Studio Configuration Preset');
    yamlBuffer.writeln('# Generated automatically for fast rebuilds');
    yamlBuffer.writeln('# ==========================================');
    yamlBuffer.writeln('appName: "${metadata.appName}"');
    yamlBuffer.writeln('executableName: "${metadata.executableName}"');
    yamlBuffer.writeln('version: "${metadata.version}"');
    yamlBuffer.writeln('description: "${metadata.description.replaceAll('"', r'\"')}"');
    yamlBuffer.writeln('category: "${metadata.category.freedesktopName}"');
    yamlBuffer.writeln('bundlePath: "${metadata.bundlePath}"');
    if (metadata.iconPath != null && metadata.iconPath!.isNotEmpty) {
      yamlBuffer.writeln('iconPath: "${metadata.iconPath}"');
    }
    yamlBuffer.writeln('outputPath: "${metadata.outputPath}"');
    yamlBuffer.writeln('integrateInMenu: ${metadata.integrateInMenu}');

    await file.writeAsString(yamlBuffer.toString());
    return file;
  }
}

