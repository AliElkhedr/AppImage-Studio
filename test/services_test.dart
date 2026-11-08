import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:appimage_studio/core/models/app_metadata.dart';
import 'package:appimage_studio/core/services/preset_service.dart';
import 'package:appimage_studio/core/services/project_detector_service.dart';
import 'package:appimage_studio/core/services/build_script_generator_service.dart';

void main() {
  group('PresetService Tests', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('preset_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('should save and load preset correctly', () async {
      final metadata = AppMetadata(
        appName: 'Test App',
        executableName: 'test_app',
        version: '2.1.0',
        description: 'A test application',
        category: AppCategory.development,
        bundlePath: tempDir.path,
        iconPath: '/path/to/icon.png',
        outputPath: '/path/to/output',
        integrateInMenu: true,
      );

      expect(PresetService.hasPreset(tempDir.path), isFalse);

      final file = await PresetService.savePreset(tempDir.path, metadata);
      expect(file.existsSync(), isTrue);
      expect(PresetService.hasPreset(tempDir.path), isTrue);

      final loaded = await PresetService.loadPreset(tempDir.path);
      expect(loaded, isNotNull);
      expect(loaded!.appName, equals('Test App'));
      expect(loaded.executableName, equals('test_app'));
      expect(loaded.version, equals('2.1.0'));
      expect(loaded.description, equals('A test application'));
      expect(loaded.category, equals(AppCategory.development));
      expect(loaded.integrateInMenu, isTrue);
    });
  });

  group('BuildScriptGeneratorService Tests', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('script_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('should generate executable bash script with correct metadata', () async {
      final metadata = AppMetadata(
        appName: 'ScriptApp',
        executableName: 'script_app',
        version: '1.2.3',
        description: 'Test build script',
        bundlePath: tempDir.path,
        outputPath: tempDir.path,
      );

      final scriptFile = await BuildScriptGeneratorService.generateScript(
        targetDirectory: tempDir.path,
        metadata: metadata,
      );

      expect(scriptFile.existsSync(), isTrue);
      final content = await scriptFile.readAsString();
      expect(content, contains('#!/usr/bin/env bash'));
      expect(content, contains('APP_NAME="ScriptApp"'));
      expect(content, contains('VERSION="1.2.3"'));
      expect(content, contains('appimagetool'));
    });
  });

  group('ProjectDetectorService Tests', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('detector_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('should detect Flutter project from pubspec.yaml', () async {
      final pubspec = File('${tempDir.path}/pubspec.yaml');
      await pubspec.writeAsString('''
name: my_flutter_tool
description: A great flutter tool
version: 1.5.0+3
environment:
  sdk: ^3.0.0
''');

      final result = await ProjectDetectorService.detect(tempDir.path);
      expect(result.type, equals(DetectedProjectType.flutter));
      expect(result.appName, equals('My Flutter Tool'));
      expect(result.executableName, equals('my_flutter_tool'));
      expect(result.version, equals('1.5.0'));
      expect(result.description, equals('A great flutter tool'));
      expect(result.category, equals(AppCategory.development));
    });

    test('should detect Rust project from Cargo.toml', () async {
      final cargo = File('${tempDir.path}/Cargo.toml');
      await cargo.writeAsString('''
[package]
name = "rusty_cli"
version = "0.3.0"
description = "A rust cli application"
edition = "2021"
''');

      final result = await ProjectDetectorService.detect(tempDir.path);
      expect(result.type, equals(DetectedProjectType.rust));
      expect(result.appName, equals('Rusty Cli'));
      expect(result.executableName, equals('rusty_cli'));
      expect(result.version, equals('0.3.0'));
      expect(result.description, equals('A rust cli application'));
    });

    test('should detect Electron project from package.json', () async {
      final pkg = File('${tempDir.path}/package.json');
      await pkg.writeAsString('''{
  "name": "electron_player",
  "productName": "Awesome Player",
  "version": "2.0.1",
  "description": "Desktop media player"
}''');

      final result = await ProjectDetectorService.detect(tempDir.path);
      expect(result.type, equals(DetectedProjectType.electron));
      expect(result.appName, equals('Awesome Player'));
      expect(result.version, equals('2.0.1'));
      expect(result.description, equals('Desktop media player'));
    });
  });
}

