import '../../l10n/app_localizations.dart';

enum AppCategory {
  utility('Utility'),
  development('Development'),
  game('Game'),
  graphics('Graphics'),
  audioVideo('AudioVideo'),
  office('Office'),
  network('Network'),
  education('Education');

  final String freedesktopName;

  const AppCategory(this.freedesktopName);

  String getLocalizedLabel(AppLocalizations l10n) {
    switch (this) {
      case AppCategory.utility:
        return l10n.catUtility;
      case AppCategory.development:
        return l10n.catDevelopment;
      case AppCategory.game:
        return l10n.catGame;
      case AppCategory.graphics:
        return l10n.catGraphics;
      case AppCategory.audioVideo:
        return l10n.catAudioVideo;
      case AppCategory.office:
        return l10n.catOffice;
      case AppCategory.network:
        return l10n.catNetwork;
      case AppCategory.education:
        return l10n.catEducation;
    }
  }
}

class AppMetadata {
  String bundlePath;
  String appName;
  String executableName;
  String version;
  String description;
  AppCategory category;
  String? iconPath;
  String outputPath;
  bool integrateInMenu;

  AppMetadata({
    this.bundlePath = '',
    this.appName = '',
    this.executableName = '',
    this.version = '1.0.0',
    this.description = '',
    this.category = AppCategory.utility,
    this.iconPath,
    this.outputPath = '',
    this.integrateInMenu = false,
  });

  bool get isValid {
    return bundlePath.isNotEmpty &&
        appName.isNotEmpty &&
        executableName.isNotEmpty &&
        version.isNotEmpty &&
        outputPath.isNotEmpty;
  }
}
