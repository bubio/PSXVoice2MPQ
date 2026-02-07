import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_sv.dart';

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
    Locale('de'),
    Locale('en'),
    Locale('fr'),
    Locale('ja'),
    Locale('sv'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'PSXVoice2MPQ'**
  String get appTitle;

  /// Label for input folder selection
  ///
  /// In en, this message translates to:
  /// **'Input Folder'**
  String get inputFolder;

  /// Label for output folder selection
  ///
  /// In en, this message translates to:
  /// **'Output Folder'**
  String get outputFolder;

  /// Dialog title for selecting input folder
  ///
  /// In en, this message translates to:
  /// **'Select ps1_assets folder'**
  String get selectInputFolder;

  /// Dialog title for selecting output folder
  ///
  /// In en, this message translates to:
  /// **'Select output folder for MPQ files'**
  String get selectOutputFolder;

  /// Build button label
  ///
  /// In en, this message translates to:
  /// **'Build MPQ'**
  String get buildMpq;

  /// Building in progress label
  ///
  /// In en, this message translates to:
  /// **'Building...'**
  String get building;

  /// Browse button label
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get browse;

  /// Placeholder when no folder is selected
  ///
  /// In en, this message translates to:
  /// **'Not selected'**
  String get notSelected;

  /// Hint text for input folder
  ///
  /// In en, this message translates to:
  /// **'Folder containing STREAM*.DIR/BIN files from PS1 disc'**
  String get inputFolderHint;

  /// Hint text for output folder
  ///
  /// In en, this message translates to:
  /// **'Destination folder for generated MPQ files'**
  String get outputFolderHint;

  /// Initial help message
  ///
  /// In en, this message translates to:
  /// **'Click Build to start'**
  String get clickBuildToStart;

  /// Initial build step
  ///
  /// In en, this message translates to:
  /// **'Starting...'**
  String get starting;

  /// Processing file message
  ///
  /// In en, this message translates to:
  /// **'Processing: {fileName}'**
  String processing(String fileName);

  /// File progress counter
  ///
  /// In en, this message translates to:
  /// **'{processed} / {total} files'**
  String filesProgress(int processed, int total);

  /// Initialization step
  ///
  /// In en, this message translates to:
  /// **'Initializing...'**
  String get initializing;

  /// Binary extraction step
  ///
  /// In en, this message translates to:
  /// **'Extracting binaries...'**
  String get extractingBinaries;

  /// Finding stream files step
  ///
  /// In en, this message translates to:
  /// **'Finding stream files...'**
  String get findingStreamFiles;

  /// Extracting stream step
  ///
  /// In en, this message translates to:
  /// **'Extracting {streamName}...'**
  String extractingStream(String streamName);

  /// Converting VAG files step
  ///
  /// In en, this message translates to:
  /// **'Converting VAG files from {streamName}...'**
  String convertingVagFiles(String streamName);

  /// Creating MPQ step
  ///
  /// In en, this message translates to:
  /// **'Creating MPQ for {streamName}...'**
  String creatingMpq(String streamName);

  /// Cleanup step
  ///
  /// In en, this message translates to:
  /// **'Cleaning up...'**
  String get cleaningUp;

  /// Completion message
  ///
  /// In en, this message translates to:
  /// **'Complete!'**
  String get complete;

  /// Message shown when build fails
  ///
  /// In en, this message translates to:
  /// **'Build Failed'**
  String get buildFailed;

  /// Error when smpq is not found
  ///
  /// In en, this message translates to:
  /// **'smpq command not found.'**
  String get errorSmpqNotFound;

  /// Error when no stream files are found
  ///
  /// In en, this message translates to:
  /// **'No STREAM*.DIR files found in the selected folder.'**
  String get errorNoStreamFiles;

  /// Error when output directory is not found
  ///
  /// In en, this message translates to:
  /// **'Output directory does not exist.'**
  String get errorOutputDirectoryNotFound;

  /// Converting WAV to MP3 step
  ///
  /// In en, this message translates to:
  /// **'Converting WAV to MP3 from {streamName}...'**
  String convertingToMp3(String streamName);

  /// AudioSR enhancement step
  ///
  /// In en, this message translates to:
  /// **'Enhancing audio with AudioSR from {streamName}...'**
  String enhancingAudio(String streamName);

  /// Checkbox label for enabling AudioSR
  ///
  /// In en, this message translates to:
  /// **'Enhance audio quality (AudioSR)'**
  String get enableAudioSr;

  /// Message when audiosr is not found
  ///
  /// In en, this message translates to:
  /// **'Please specify the audiosr executable.'**
  String get audioSrNotFound;

  /// Button to browse for audiosr executable
  ///
  /// In en, this message translates to:
  /// **'Browse...'**
  String get browseAudioSr;

  /// Settings dialog title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Language section label in settings
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Button to clear intermediate/cache files
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get clearCache;

  /// Message shown after cache is cleared
  ///
  /// In en, this message translates to:
  /// **'Cache cleared'**
  String get cacheCleared;

  /// Note about AudioSR processing time
  ///
  /// In en, this message translates to:
  /// **'Processing may take a very long time.'**
  String get audioSrNote;

  /// Title for cache found dialog
  ///
  /// In en, this message translates to:
  /// **'Previous data found'**
  String get cacheFoundTitle;

  /// Message for cache found dialog
  ///
  /// In en, this message translates to:
  /// **'Data from a previous interrupted build was found. Would you like to continue from where it left off, or start fresh?'**
  String get cacheFoundMessage;

  /// Button to continue from cached data
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueFromCache;

  /// Button to clear cache and start fresh
  ///
  /// In en, this message translates to:
  /// **'Start Fresh'**
  String get startFresh;

  /// Version label in settings
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// Button to show open source licenses
  ///
  /// In en, this message translates to:
  /// **'Open Source Licenses'**
  String get licenses;

  /// Section title for licenses in settings
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get licensesSection;

  /// Checkbox label for running AudioSR on CPU
  ///
  /// In en, this message translates to:
  /// **'Process on CPU'**
  String get audioSrUseCpu;

  /// Dropdown label for AudioSR chunk duration in seconds
  ///
  /// In en, this message translates to:
  /// **'Chunk duration (seconds)'**
  String get audioSrChunkSeconds;
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
      <String>['de', 'en', 'fr', 'ja', 'sv'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'ja':
      return AppLocalizationsJa();
    case 'sv':
      return AppLocalizationsSv();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
