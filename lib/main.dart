import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';
import 'ui/screens/home_screen.dart';
import 'ui/theme/app_theme.dart';

void main() {
  runApp(const AppImageStudioApp());
}

class AppImageStudioApp extends StatefulWidget {
  const AppImageStudioApp({super.key});

  @override
  State<AppImageStudioApp> createState() => _AppImageStudioAppState();
}

class _AppImageStudioAppState extends State<AppImageStudioApp> {
  Locale? _currentLocale;

  void _setLocale(Locale? locale) {
    setState(() {
      _currentLocale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AppImage Studio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      locale: _currentLocale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: HomeScreen(
        currentLocale: _currentLocale,
        onLocaleChanged: _setLocale,
      ),
    );
  }
}
