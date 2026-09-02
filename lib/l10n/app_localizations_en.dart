// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AppImage Studio';

  @override
  String get appSubtitle =>
      'Convert any bundled app folder (Flutter, Rust, Go, C++, etc.) into a standalone AppImage in one click';

  @override
  String get switchLanguage => 'Switch Language';

  @override
  String get appVersion => 'v1.0.0';

  @override
  String get developedBy => 'Developed with ❤️ by Ali El Khedr & Contributors';

  @override
  String get sourceCardTitle => '1. App Bundle Path & Executable';

  @override
  String get bundleDirLabel => 'App Bundle Directory';

  @override
  String get bundleDirHint =>
      'Choose bundle directory or compiled project folder...';

  @override
  String get executableLabel => 'Executable Binary Name';

  @override
  String get executableHint => 'e.g. my_app or runner';

  @override
  String get autoDetectedExecutables => 'Auto-Detected Executables';

  @override
  String get browseButton => 'Browse...';

  @override
  String get metadataCardTitle => '2. App Metadata & Details';

  @override
  String get appNameLabel => 'App Name';

  @override
  String get appNameHint => 'e.g. My Awesome App';

  @override
  String get versionLabel => 'Version';

  @override
  String get versionHint => '1.0.0';

  @override
  String get categoryLabel => 'Category';

  @override
  String get iconLabel => 'App Icon (PNG or SVG)';

  @override
  String get iconHint => 'Choose an image in PNG or SVG format...';

  @override
  String get descriptionLabel => 'Short App Description';

  @override
  String get descriptionHint =>
      'Short description that appears in OS search...';

  @override
  String get outputCardTitle => '3. Output Directory & Preferences';

  @override
  String get outputDirLabel => 'AppImage Output Directory';

  @override
  String get outputDirHint => 'Choose output folder...';

  @override
  String get integrateMenuTitle =>
      'Install application in desktop menu (Start menu) upon completion';

  @override
  String get integrateMenuSubtitle =>
      'Creates a standard system shortcut to launch the app from search and dock immediately';

  @override
  String get buildButton => 'Build AppImage Now';

  @override
  String get validationError =>
      'Please fill all required fields and select the bundle path and executable';

  @override
  String filePickError(String error) {
    return 'Error picking path: $error';
  }

  @override
  String get buildingTitle => 'Building AppImage Package...';

  @override
  String get buildingSubtitle =>
      'Please wait while packaging and compressing files';

  @override
  String get buildSuccessTitle => 'AppImage Built Successfully!';

  @override
  String get buildFailedTitle => 'Build Failed';

  @override
  String get openFolder => 'Open Output Folder';

  @override
  String get testRunApp => 'Test & Run AppImage Now';

  @override
  String get close => 'Close';

  @override
  String failedToRun(String error) {
    return 'Failed to launch application: $error';
  }

  @override
  String get catUtility => 'Utilities';

  @override
  String get catDevelopment => 'Development & Programming';

  @override
  String get catGame => 'Games';

  @override
  String get catGraphics => 'Design & Graphics';

  @override
  String get catAudioVideo => 'Audio & Video';

  @override
  String get catOffice => 'Office & Productivity';

  @override
  String get catNetwork => 'Internet & Network';

  @override
  String get catEducation => 'Education';

  @override
  String get aboutTooltip => 'About App';

  @override
  String get aboutAppTitle => 'About AppImage Studio';

  @override
  String get aboutAppDescription =>
      'A modern, standalone open-source desktop studio to package and distribute Linux applications as AppImages in one click with zero dependencies.';

  @override
  String get developerLabel => 'Lead Developer & Founder:';

  @override
  String get developerName => 'Ali El Khedr';

  @override
  String get websiteTooltip => 'Visit Developer Website';

  @override
  String get blogPostButton => 'Read Full Article on Blog';

  @override
  String get contributorsSectionTitle => 'Community & Contributors';

  @override
  String get contributorsPrompt =>
      'This project is fully open source. All contributions and community pull requests on GitHub are warmly welcome!';

  @override
  String get githubRepoButton => 'GitHub Repository';

  @override
  String get contributorsButton => 'Contributors on GitHub';

  @override
  String get licenseNotice => 'License: Open Source under GNU GPLv3';
}
