import 'dart:io';
import 'package:cupertino_ui/cupertino_ui.dart' show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart' show GlobalWidgetsLocalizations;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appimage_studio/ui/screens/home_screen.dart';
import 'package:appimage_studio/l10n/app_localizations.dart';

const _testLocalizationsDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
];

void main() {
  testWidgets('Drag and drop directory updates HomeScreen fields', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final tempDir = Directory.systemTemp.createTempSync('drag_dir_');
    addTearDown(() => tempDir.deleteSync(recursive: true));

    final execFile = File('${tempDir.path}/my_game');
    execFile.writeAsStringSync('#!/bin/sh\necho hi');
    Process.runSync('chmod', ['+x', execFile.path]);

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: _testLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    const codec = StandardMethodCodec();
    final ByteData message = codec.encodeMethodCall(
      MethodCall('dragDropped', [tempDir.path]),
    );

    await tester.runAsync(() async {
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'appimage_studio/native_drop',
        message,
        (_) {},
      );
      await Future.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();

    expect(find.text(tempDir.path), findsOneWidget);
  });

  testWidgets('Drag and drop contained files & subdirs ("ما بدخله" e.g. binary + data/ + lib/) detects parent bundle directory', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final tempDir = Directory.systemTemp.createTempSync('drag_bundle_');
    addTearDown(() => tempDir.deleteSync(recursive: true));

    final dataDir = Directory('${tempDir.path}/data')..createSync();
    final libDir = Directory('${tempDir.path}/lib')..createSync();
    final execFile = File('${tempDir.path}/app_binary');
    execFile.writeAsStringSync('\x7FELFbinarycode');
    final iconFile = File('${tempDir.path}/app_icon.png');
    iconFile.writeAsStringSync('fakepngdata');

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: _testLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Simulate Native GTK3 drop channel delivering [data/, lib/, app_binary, app_icon.png]
    const codec = StandardMethodCodec();
    final ByteData message = codec.encodeMethodCall(
      MethodCall('dragDropped', [
        dataDir.path,
        libDir.path,
        execFile.path,
        iconFile.path,
      ]),
    );

    await tester.runAsync(() async {
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'appimage_studio/native_drop',
        message,
        (_) {},
      );
      await Future.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();

    // Verify parent directory was set (NOT data/ or lib/)
    expect(find.text(tempDir.path), findsOneWidget);
    // Verify executable was detected
    expect(find.text('app_binary'), findsAtLeastNWidgets(1));
  });
}
