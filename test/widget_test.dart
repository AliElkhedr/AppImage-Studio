import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appimage_studio/main.dart';

void main() {
  testWidgets('AppImageStudioApp smoke test (English)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const AppImageStudioApp());
    await tester.pumpAndSettle();

    expect(find.text('AppImage Studio'), findsOneWidget);
    expect(find.text('Build AppImage Now'), findsOneWidget);
  });

  testWidgets('AppImageStudioApp smoke test (Arabic)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    tester.platformDispatcher.localesTestValue = [const Locale('ar')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(const AppImageStudioApp());
    await tester.pumpAndSettle();

    expect(find.text('استوديو آب إيمج'), findsOneWidget);
    expect(find.text('توليد وبناء حزمة AppImage الآن'), findsOneWidget);
  });
}
