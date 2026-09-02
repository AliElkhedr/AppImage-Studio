import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'AppImage Studio'**
  String get appTitle;

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Convert any bundled app folder (Flutter, Rust, Go, C++, etc.) into a standalone AppImage in one click'**
  String get appSubtitle;

  /// No description provided for @switchLanguage.
  ///
  /// In en, this message translates to:
  /// **'Switch Language'**
  String get switchLanguage;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'v1.0.0'**
  String get appVersion;

  /// No description provided for @developedBy.
  ///
  /// In en, this message translates to:
  /// **'Developed with ❤️ by Ali El Khedr & Contributors'**
  String get developedBy;

  /// No description provided for @sourceCardTitle.
  ///
  /// In en, this message translates to:
  /// **'1. App Bundle Path & Executable'**
  String get sourceCardTitle;

  /// No description provided for @bundleDirLabel.
  ///
  /// In en, this message translates to:
  /// **'App Bundle Directory'**
  String get bundleDirLabel;

  /// No description provided for @bundleDirHint.
  ///
  /// In en, this message translates to:
  /// **'Choose bundle directory or compiled project folder...'**
  String get bundleDirHint;

  /// No description provided for @executableLabel.
  ///
  /// In en, this message translates to:
  /// **'Executable Binary Name'**
  String get executableLabel;

  /// No description provided for @executableHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. my_app or runner'**
  String get executableHint;

  /// No description provided for @autoDetectedExecutables.
  ///
  /// In en, this message translates to:
  /// **'Auto-Detected Executables'**
  String get autoDetectedExecutables;

  /// No description provided for @browseButton.
  ///
  /// In en, this message translates to:
  /// **'Browse...'**
  String get browseButton;

  /// No description provided for @metadataCardTitle.
  ///
  /// In en, this message translates to:
  /// **'2. App Metadata & Details'**
  String get metadataCardTitle;

  /// No description provided for @appNameLabel.
  ///
  /// In en, this message translates to:
  /// **'App Name'**
  String get appNameLabel;

  /// No description provided for @appNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. My Awesome App'**
  String get appNameHint;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get versionLabel;

  /// No description provided for @versionHint.
  ///
  /// In en, this message translates to:
  /// **'1.0.0'**
  String get versionHint;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @iconLabel.
  ///
  /// In en, this message translates to:
  /// **'App Icon (PNG or SVG)'**
  String get iconLabel;

  /// No description provided for @iconHint.
  ///
  /// In en, this message translates to:
  /// **'Choose an image in PNG or SVG format...'**
  String get iconHint;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Short App Description'**
  String get descriptionLabel;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Short description that appears in OS search...'**
  String get descriptionHint;

  /// No description provided for @outputCardTitle.
  ///
  /// In en, this message translates to:
  /// **'3. Output Directory & Preferences'**
  String get outputCardTitle;

  /// No description provided for @outputDirLabel.
  ///
  /// In en, this message translates to:
  /// **'AppImage Output Directory'**
  String get outputDirLabel;

  /// No description provided for @outputDirHint.
  ///
  /// In en, this message translates to:
  /// **'Choose output folder...'**
  String get outputDirHint;

  /// No description provided for @integrateMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'Install application in desktop menu (Start menu) upon completion'**
  String get integrateMenuTitle;

  /// No description provided for @integrateMenuSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Creates a standard system shortcut to launch the app from search and dock immediately'**
  String get integrateMenuSubtitle;

  /// No description provided for @buildButton.
  ///
  /// In en, this message translates to:
  /// **'Build AppImage Now'**
  String get buildButton;

  /// No description provided for @validationError.
  ///
  /// In en, this message translates to:
  /// **'Please fill all required fields and select the bundle path and executable'**
  String get validationError;

  /// No description provided for @filePickError.
  ///
  /// In en, this message translates to:
  /// **'Error picking path: {error}'**
  String filePickError(String error);

  /// No description provided for @buildingTitle.
  ///
  /// In en, this message translates to:
  /// **'Building AppImage Package...'**
  String get buildingTitle;

  /// No description provided for @buildingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please wait while packaging and compressing files'**
  String get buildingSubtitle;

  /// No description provided for @buildSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'AppImage Built Successfully!'**
  String get buildSuccessTitle;

  /// No description provided for @buildFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Build Failed'**
  String get buildFailedTitle;

  /// No description provided for @openFolder.
  ///
  /// In en, this message translates to:
  /// **'Open Output Folder'**
  String get openFolder;

  /// No description provided for @testRunApp.
  ///
  /// In en, this message translates to:
  /// **'Test & Run AppImage Now'**
  String get testRunApp;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @failedToRun.
  ///
  /// In en, this message translates to:
  /// **'Failed to launch application: {error}'**
  String failedToRun(String error);

  /// No description provided for @catUtility.
  ///
  /// In en, this message translates to:
  /// **'Utilities'**
  String get catUtility;

  /// No description provided for @catDevelopment.
  ///
  /// In en, this message translates to:
  /// **'Development & Programming'**
  String get catDevelopment;

  /// No description provided for @catGame.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get catGame;

  /// No description provided for @catGraphics.
  ///
  /// In en, this message translates to:
  /// **'Design & Graphics'**
  String get catGraphics;

  /// No description provided for @catAudioVideo.
  ///
  /// In en, this message translates to:
  /// **'Audio & Video'**
  String get catAudioVideo;

  /// No description provided for @catOffice.
  ///
  /// In en, this message translates to:
  /// **'Office & Productivity'**
  String get catOffice;

  /// No description provided for @catNetwork.
  ///
  /// In en, this message translates to:
  /// **'Internet & Network'**
  String get catNetwork;

  /// No description provided for @catEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get catEducation;

  /// No description provided for @aboutTooltip.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get aboutTooltip;

  /// No description provided for @aboutAppTitle.
  ///
  /// In en, this message translates to:
  /// **'About AppImage Studio'**
  String get aboutAppTitle;

  /// No description provided for @aboutAppDescription.
  ///
  /// In en, this message translates to:
  /// **'A modern, standalone open-source desktop studio to package and distribute Linux applications as AppImages in one click with zero dependencies.'**
  String get aboutAppDescription;

  /// No description provided for @developerLabel.
  ///
  /// In en, this message translates to:
  /// **'Lead Developer & Founder:'**
  String get developerLabel;

  /// No description provided for @developerName.
  ///
  /// In en, this message translates to:
  /// **'Ali El Khedr'**
  String get developerName;

  /// No description provided for @websiteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Visit Developer Website'**
  String get websiteTooltip;

  /// No description provided for @blogPostButton.
  ///
  /// In en, this message translates to:
  /// **'Read Full Article on Blog'**
  String get blogPostButton;

  /// No description provided for @contributorsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Community & Contributors'**
  String get contributorsSectionTitle;

  /// No description provided for @contributorsPrompt.
  ///
  /// In en, this message translates to:
  /// **'This project is fully open source. All contributions and community pull requests on GitHub are warmly welcome!'**
  String get contributorsPrompt;

  /// No description provided for @githubRepoButton.
  ///
  /// In en, this message translates to:
  /// **'GitHub Repository'**
  String get githubRepoButton;

  /// No description provided for @contributorsButton.
  ///
  /// In en, this message translates to:
  /// **'Contributors on GitHub'**
  String get contributorsButton;

  /// No description provided for @licenseNotice.
  ///
  /// In en, this message translates to:
  /// **'License: Open Source under GNU GPLv3'**
  String get licenseNotice;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
