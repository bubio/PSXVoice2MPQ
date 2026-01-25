import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_be.dart';
import 'app_localizations_bg.dart';
import 'app_localizations_cs.dart';
import 'app_localizations_da.dart';
import 'app_localizations_de.dart';
import 'app_localizations_el.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_et.dart';
import 'app_localizations_fi.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hr.dart';
import 'app_localizations_hu.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ro.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_sv.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_uk.dart';
import 'app_localizations_zh.dart';

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
    Locale('be'),
    Locale('bg'),
    Locale('cs'),
    Locale('da'),
    Locale('de'),
    Locale('el'),
    Locale('en'),
    Locale('es'),
    Locale('et'),
    Locale('fi'),
    Locale('fr'),
    Locale('hr'),
    Locale('hu'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('pl'),
    Locale('pt'),
    Locale('pt', 'BR'),
    Locale('ro'),
    Locale('ru'),
    Locale('sv'),
    Locale('tr'),
    Locale('uk'),
    Locale('zh'),
    Locale('zh', 'CN'),
    Locale('zh', 'TW'),
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

  /// Converting WAV to MP3 step
  ///
  /// In en, this message translates to:
  /// **'Converting WAV to MP3 from {streamName}...'**
  String convertingToMp3(String streamName);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'be',
    'bg',
    'cs',
    'da',
    'de',
    'el',
    'en',
    'es',
    'et',
    'fi',
    'fr',
    'hr',
    'hu',
    'it',
    'ja',
    'ko',
    'pl',
    'pt',
    'ro',
    'ru',
    'sv',
    'tr',
    'uk',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'pt':
      {
        switch (locale.countryCode) {
          case 'BR':
            return AppLocalizationsPtBr();
        }
        break;
      }
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'CN':
            return AppLocalizationsZhCn();
          case 'TW':
            return AppLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'be':
      return AppLocalizationsBe();
    case 'bg':
      return AppLocalizationsBg();
    case 'cs':
      return AppLocalizationsCs();
    case 'da':
      return AppLocalizationsDa();
    case 'de':
      return AppLocalizationsDe();
    case 'el':
      return AppLocalizationsEl();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'et':
      return AppLocalizationsEt();
    case 'fi':
      return AppLocalizationsFi();
    case 'fr':
      return AppLocalizationsFr();
    case 'hr':
      return AppLocalizationsHr();
    case 'hu':
      return AppLocalizationsHu();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ro':
      return AppLocalizationsRo();
    case 'ru':
      return AppLocalizationsRu();
    case 'sv':
      return AppLocalizationsSv();
    case 'tr':
      return AppLocalizationsTr();
    case 'uk':
      return AppLocalizationsUk();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
