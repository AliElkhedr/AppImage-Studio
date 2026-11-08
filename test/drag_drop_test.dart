import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:appimage_studio/ui/screens/home_screen.dart';
import 'package:appimage_studio/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: HomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    final dropTargetFinder = find.byType(DropTarget);
    expect(dropTargetFinder, findsOneWidget);

    final dropTarget = tester.widget<DropTarget>(dropTargetFinder);
    await tester.runAsync(() async {
      dropTarget.onDragDone?.call(
        DropDoneDetails(
          files: [DropItemFile(tempDir.path)],
          localPosition: Offset.zero,
          globalPosition: Offset.zero,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();

    expect(find.text(tempDir.path), findsOneWidget);
  });

  testWidgets('Drag and drop contained files ("ما بدخله") detects parent directory and executable', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final tempDir = Directory.systemTemp.createTempSync('drag_files_');
    addTearDown(() => tempDir.deleteSync(recursive: true));

    final execFile = File('${tempDir.path}/app_binary');
    execFile.writeAsStringSync('\x7FELFbinarycode');
    final iconFile = File('${tempDir.path}/app_icon.png');
    iconFile.writeAsStringSync('fakepngdata');

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: HomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    final dropTarget = tester.widget<DropTarget>(find.byType(DropTarget));
    await tester.runAsync(() async {
      dropTarget.onDragDone?.call(
        DropDoneDetails(
          files: [DropItemFile(execFile.path), DropItemFile(iconFile.path)],
          localPosition: Offset.zero,
          globalPosition: Offset.zero,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();

    // Verify parent directory was set
    expect(find.text(tempDir.path), findsOneWidget);
    // Verify executable was detected
    expect(find.text('app_binary'), findsAtLeastNWidgets(1));
  });
}
