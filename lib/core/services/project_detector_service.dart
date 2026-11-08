import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import '../models/app_metadata.dart';
import 'preset_service.dart';

enum DetectedProjectType {
  preset,
  flutter,
  rust,
  electron,
  godot,
  generic,
}

class ProjectDetectionResult {
  final DetectedProjectType type;
  final String? appName;
  final String? executableName;
  final String? version;
  final String? description;
  final String? bundlePath;
  final String? iconPath;
  final AppCategory? category;
  final String? frameworkName;
  final AppMetadata? loadedPreset;

  const ProjectDetectionResult({
    required this.type,
    this.appName,
    this.executableName,
    this.version,
    this.description,
    this.bundlePath,
    this.iconPath,
    this.category,
    this.frameworkName,
    this.loadedPreset,
  });
}

class ProjectDetectorService {
  /// Detects project type and pre-fills metadata
  static Future<ProjectDetectionResult> detect(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      return const ProjectDetectionResult(
        type: DetectedProjectType.generic,
      );
    }

    // 1. Check for AppImage Studio preset first
    if (PresetService.hasPreset(path)) {
      final preset = await PresetService.loadPreset(path);
      if (preset != null) {
        return ProjectDetectionResult(
          type: DetectedProjectType.preset,
          appName: preset.appName,
          executableName: preset.executableName,
          version: preset.version,
          description: preset.description,
          bundlePath: preset.bundlePath.isNotEmpty ? preset.bundlePath : path,
          iconPath: preset.iconPath,
          category: preset.category,
          frameworkName: 'Preset (appimage_studio.yaml)',
          loadedPreset: preset,
        );
      }
    }

    // 2. Check for Flutter project
    final flutterResult = await _detectFlutter(path);
    if (flutterResult != null) return flutterResult;

    // 3. Check for Rust project
    final rustResult = await _detectRust(path);
    if (rustResult != null) return rustResult;

    // 4. Check for Electron / Node project
    final electronResult = await _detectElectron(path);
    if (electronResult != null) return electronResult;

    // 5. Check for Godot project
    final godotResult = await _detectGodot(path);
    if (godotResult != null) return godotResult;

    // 6. Generic bundle directory
    return ProjectDetectionResult(
      type: DetectedProjectType.generic,
      bundlePath: path,
    );
  }

  static Future<ProjectDetectionResult?> _detectFlutter(String path) async {
    File? pubspecFile;
    String projectRoot = path;

    // Direct project root
    final directPubspec = File(p.join(path, 'pubspec.yaml'));
    if (await directPubspec.exists()) {
      pubspecFile = directPubspec;
    } else {
      // Check if selected path is inside a flutter project (e.g. build/linux/x64/release/bundle)
      Directory current = Directory(path);
      for (int i = 0; i < 6; i++) {
        final parent = current.parent;
        if (parent.path == current.path) break;
        final candidate = File(p.join(parent.path, 'pubspec.yaml'));
        if (await candidate.exists()) {
          pubspecFile = candidate;
          projectRoot = parent.path;
          break;
        }
        current = parent;
      }
    }

    if (pubspecFile == null) return null;

    try {
      final content = await pubspecFile.readAsString();
      final yaml = loadYaml(content);
      if (yaml is! Map) return null;

      final name = yaml['name']?.toString() ?? '';
      String version = yaml['version']?.toString() ?? '1.0.0';
      if (version.contains('+')) {
        version = version.split('+').first;
      }
      final description = yaml['description']?.toString() ?? '';

      // Check for Linux bundle output
      String bundlePath = path;
      final releaseBundle = Directory(p.join(projectRoot, 'build', 'linux', 'x64', 'release', 'bundle'));
      final armBundle = Directory(p.join(projectRoot, 'build', 'linux', 'arm64', 'release', 'bundle'));
      if (await releaseBundle.exists()) {
        bundlePath = releaseBundle.path;
      } else if (await armBundle.exists()) {
        bundlePath = armBundle.path;
      }

      // Check for icon
      String? iconPath;
      final candidateIcons = [
        p.join(projectRoot, 'linux', 'runner', 'assets', 'app_icon.png'),
        p.join(projectRoot, 'assets', 'images', 'app_icon.png'),
        p.join(projectRoot, 'assets', 'icon.png'),
        p.join(projectRoot, 'assets', 'app_icon.png'),
      ];
      for (final ic in candidateIcons) {
        if (await File(ic).exists()) {
          iconPath = ic;
          break;
        }
      }

      return ProjectDetectionResult(
        type: DetectedProjectType.flutter,
        appName: _formatAppName(name),
        executableName: name,
        version: version,
        description: description,
        bundlePath: bundlePath,
        iconPath: iconPath,
        category: AppCategory.development,
        frameworkName: 'Flutter',
      );
    } catch (_) {
      return null;
    }
  }

  static Future<ProjectDetectionResult?> _detectRust(String path) async {
    final cargoFile = File(p.join(path, 'Cargo.toml'));
    if (!await cargoFile.exists()) return null;

    try {
      final lines = await cargoFile.readAsLines();
      String name = '';
      String version = '1.0.0';
      String description = '';
      bool inPackage = false;

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed == '[package]') {
          inPackage = true;
          continue;
        } else if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
          inPackage = false;
        }

        if (inPackage) {
          if (trimmed.startsWith('name')) {
            name = _extractTomlValue(trimmed);
          } else if (trimmed.startsWith('version')) {
            version = _extractTomlValue(trimmed);
          } else if (trimmed.startsWith('description')) {
            description = _extractTomlValue(trimmed);
          }
        }
      }

      String bundlePath = path;
      final releaseDir = Directory(p.join(path, 'target', 'release'));
      if (await releaseDir.exists()) {
        bundlePath = releaseDir.path;
      }

      return ProjectDetectionResult(
        type: DetectedProjectType.rust,
        appName: _formatAppName(name),
        executableName: name,
        version: version,
        description: description,
        bundlePath: bundlePath,
        category: AppCategory.development,
        frameworkName: 'Rust (Cargo)',
      );
    } catch (_) {
      return null;
    }
  }

  static Future<ProjectDetectionResult?> _detectElectron(String path) async {
    final pkgFile = File(p.join(path, 'package.json'));
    if (!await pkgFile.exists()) return null;

    try {
      final content = await pkgFile.readAsString();
      final json = jsonDecode(content);
      if (json is! Map) return null;

      final name = json['productName']?.toString() ?? json['name']?.toString() ?? '';
      final version = json['version']?.toString() ?? '1.0.0';
      final description = json['description']?.toString() ?? '';

      String bundlePath = path;
      final unpackedDir = Directory(p.join(path, 'dist', 'linux-unpacked'));
      if (await unpackedDir.exists()) {
        bundlePath = unpackedDir.path;
      }

      return ProjectDetectionResult(
        type: DetectedProjectType.electron,
        appName: _formatAppName(name),
        executableName: name.toLowerCase().replaceAll(RegExp(r'\s+'), '-'),
        version: version,
        description: description,
        bundlePath: bundlePath,
        category: AppCategory.utility,
        frameworkName: 'Electron',
      );
    } catch (_) {
      return null;
    }
  }

  static Future<ProjectDetectionResult?> _detectGodot(String path) async {
    final godotFile = File(p.join(path, 'project.godot'));
    if (!await godotFile.exists()) return null;

    try {
      final lines = await godotFile.readAsLines();
      String name = '';
      for (final line in lines) {
        if (line.trim().startsWith('config/name=')) {
          name = line.split('=').last.replaceAll('"', '').trim();
          break;
        }
      }

      return ProjectDetectionResult(
        type: DetectedProjectType.godot,
        appName: name.isNotEmpty ? name : p.basename(path),
        executableName: name.isNotEmpty ? name.toLowerCase().replaceAll(' ', '_') : p.basename(path),
        version: '1.0.0',
        bundlePath: path,
        category: AppCategory.game,
        frameworkName: 'Godot Engine',
      );
    } catch (_) {
      return null;
    }
  }

  static String _extractTomlValue(String line) {
    final parts = line.split('=');
    if (parts.length < 2) return '';
    return parts[1].trim().replaceAll('"', '').replaceAll("'", '');
  }

  static String _formatAppName(String name) {
    if (name.isEmpty) return '';
    final words = name.replaceAll('_', ' ').replaceAll('-', ' ').split(' ');
    return words.map((w) {
      if (w.isEmpty) return '';
      return w[0].toUpperCase() + w.substring(1);
    }).join(' ');
  }
}
