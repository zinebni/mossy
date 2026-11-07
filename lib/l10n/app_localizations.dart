import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

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
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Mossy'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Look closer. Discover more.'**
  String get tagline;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning, Explorer!'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon, Explorer!'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening, Explorer!'**
  String get goodEvening;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// No description provided for @collection.
  ///
  /// In en, this message translates to:
  /// **'Collection'**
  String get collection;

  /// No description provided for @adventures.
  ///
  /// In en, this message translates to:
  /// **'Adventures'**
  String get adventures;

  /// No description provided for @garden.
  ///
  /// In en, this message translates to:
  /// **'Garden'**
  String get garden;

  /// No description provided for @discoverPlant.
  ///
  /// In en, this message translates to:
  /// **'Discover a Plant'**
  String get discoverPlant;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a Photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @identifyPlant.
  ///
  /// In en, this message translates to:
  /// **'Identify This Plant'**
  String get identifyPlant;

  /// No description provided for @retake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get retake;

  /// No description provided for @chooseAnother.
  ///
  /// In en, this message translates to:
  /// **'Choose Another'**
  String get chooseAnother;

  /// No description provided for @saveToCollection.
  ///
  /// In en, this message translates to:
  /// **'Save to Collection'**
  String get saveToCollection;

  /// No description provided for @learnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn More'**
  String get learnMore;

  /// No description provided for @identifyAnother.
  ///
  /// In en, this message translates to:
  /// **'Identify Another'**
  String get identifyAnother;

  /// No description provided for @dailyChallenge.
  ///
  /// In en, this message translates to:
  /// **'Daily Challenge'**
  String get dailyChallenge;

  /// No description provided for @recentDiscoveries.
  ///
  /// In en, this message translates to:
  /// **'Recent Discoveries'**
  String get recentDiscoveries;

  /// No description provided for @yourGarden.
  ///
  /// In en, this message translates to:
  /// **'Your Garden'**
  String get yourGarden;

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @myCollection.
  ///
  /// In en, this message translates to:
  /// **'My Collection'**
  String get myCollection;

  /// No description provided for @searchPlants.
  ///
  /// In en, this message translates to:
  /// **'Search plants...'**
  String get searchPlants;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @byFamily.
  ///
  /// In en, this message translates to:
  /// **'By Family'**
  String get byFamily;

  /// No description provided for @noDiscoveries.
  ///
  /// In en, this message translates to:
  /// **'No discoveries yet'**
  String get noDiscoveries;

  /// No description provided for @startExploring.
  ///
  /// In en, this message translates to:
  /// **'Start exploring to build your collection!'**
  String get startExploring;

  /// No description provided for @totalSpecies.
  ///
  /// In en, this message translates to:
  /// **'Total Species'**
  String get totalSpecies;

  /// No description provided for @favoritesCount.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favoritesCount;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @challenges.
  ///
  /// In en, this message translates to:
  /// **'Challenges'**
  String get challenges;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @easy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get easy;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @hard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get hard;

  /// No description provided for @startMission.
  ///
  /// In en, this message translates to:
  /// **'Start Mission'**
  String get startMission;

  /// No description provided for @submitDiscovery.
  ///
  /// In en, this message translates to:
  /// **'Submit Discovery'**
  String get submitDiscovery;

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'{count} pts'**
  String points(int count);

  /// No description provided for @gardenLevel.
  ///
  /// In en, this message translates to:
  /// **'Garden Level {level}'**
  String gardenLevel(int level);

  /// No description provided for @growYourGarden.
  ///
  /// In en, this message translates to:
  /// **'How to Grow Your Garden'**
  String get growYourGarden;

  /// No description provided for @gardenTip.
  ///
  /// In en, this message translates to:
  /// **'Identify plants, complete adventures, and earn achievements to grow your garden!'**
  String get gardenTip;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @explorerLevel.
  ///
  /// In en, this message translates to:
  /// **'Explorer Level {level}'**
  String explorerLevel(int level);

  /// No description provided for @totalPoints.
  ///
  /// In en, this message translates to:
  /// **'Total Points'**
  String get totalPoints;

  /// No description provided for @totalDiscoveries.
  ///
  /// In en, this message translates to:
  /// **'Total Discoveries'**
  String get totalDiscoveries;

  /// No description provided for @adventuresComplete.
  ///
  /// In en, this message translates to:
  /// **'Adventures Complete'**
  String get adventuresComplete;

  /// No description provided for @daysActive.
  ///
  /// In en, this message translates to:
  /// **'Days Active'**
  String get daysActive;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @locationPermissions.
  ///
  /// In en, this message translates to:
  /// **'Location Permissions'**
  String get locationPermissions;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Information'**
  String get privacy;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @discoveryMap.
  ///
  /// In en, this message translates to:
  /// **'Discovery Map'**
  String get discoveryMap;

  /// No description provided for @noLocations.
  ///
  /// In en, this message translates to:
  /// **'No discoveries with location data yet'**
  String get noLocations;

  /// No description provided for @demoMode.
  ///
  /// In en, this message translates to:
  /// **'Demo Mode'**
  String get demoMode;

  /// No description provided for @demoModeDescription.
  ///
  /// In en, this message translates to:
  /// **'You\'re exploring in demo mode. Configure Supabase to save your discoveries.'**
  String get demoModeDescription;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @onboarding1Title.
  ///
  /// In en, this message translates to:
  /// **'Discover Plants Around You'**
  String get onboarding1Title;

  /// No description provided for @onboarding1Desc.
  ///
  /// In en, this message translates to:
  /// **'Point your camera at any plant and let Mossy identify it for you using advanced AI.'**
  String get onboarding1Desc;

  /// No description provided for @onboarding2Title.
  ///
  /// In en, this message translates to:
  /// **'Learn Fascinating Facts'**
  String get onboarding2Title;

  /// No description provided for @onboarding2Desc.
  ///
  /// In en, this message translates to:
  /// **'Get interesting facts, observation tips, and educational content about every plant you discover.'**
  String get onboarding2Desc;

  /// No description provided for @onboarding3Title.
  ///
  /// In en, this message translates to:
  /// **'Collect & Complete Adventures'**
  String get onboarding3Title;

  /// No description provided for @onboarding3Desc.
  ///
  /// In en, this message translates to:
  /// **'Build your personal nature journal and take on exciting exploration challenges.'**
  String get onboarding3Desc;

  /// No description provided for @onboarding4Title.
  ///
  /// In en, this message translates to:
  /// **'Grow Your Virtual Garden'**
  String get onboarding4Title;

  /// No description provided for @onboarding4Desc.
  ///
  /// In en, this message translates to:
  /// **'Watch your garden bloom as you explore more of the natural world around you.'**
  String get onboarding4Desc;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @lookingClosely.
  ///
  /// In en, this message translates to:
  /// **'Looking closely at your discovery...'**
  String get lookingClosely;

  /// No description provided for @searchingBotanical.
  ///
  /// In en, this message translates to:
  /// **'Searching the botanical world...'**
  String get searchingBotanical;

  /// No description provided for @consultingEncyclopedia.
  ///
  /// In en, this message translates to:
  /// **'Consulting the plant encyclopedia...'**
  String get consultingEncyclopedia;

  /// No description provided for @preparingSomething.
  ///
  /// In en, this message translates to:
  /// **'Preparing something interesting...'**
  String get preparingSomething;

  /// No description provided for @almostThere.
  ///
  /// In en, this message translates to:
  /// **'Almost there...'**
  String get almostThere;

  /// No description provided for @veryLikely.
  ///
  /// In en, this message translates to:
  /// **'Very Likely'**
  String get veryLikely;

  /// No description provided for @likely.
  ///
  /// In en, this message translates to:
  /// **'Likely'**
  String get likely;

  /// No description provided for @possible.
  ///
  /// In en, this message translates to:
  /// **'Possible'**
  String get possible;

  /// No description provided for @uncertain.
  ///
  /// In en, this message translates to:
  /// **'Uncertain'**
  String get uncertain;

  /// No description provided for @scientificName.
  ///
  /// In en, this message translates to:
  /// **'Scientific Name'**
  String get scientificName;

  /// No description provided for @commonName.
  ///
  /// In en, this message translates to:
  /// **'Common Name'**
  String get commonName;

  /// No description provided for @family.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get family;

  /// No description provided for @discoveredOn.
  ///
  /// In en, this message translates to:
  /// **'Discovered on {date}'**
  String discoveredOn(String date);

  /// No description provided for @personalNotes.
  ///
  /// In en, this message translates to:
  /// **'Personal Notes'**
  String get personalNotes;

  /// No description provided for @addNotes.
  ///
  /// In en, this message translates to:
  /// **'Add your personal notes...'**
  String get addNotes;

  /// No description provided for @funFacts.
  ///
  /// In en, this message translates to:
  /// **'Fun Facts'**
  String get funFacts;

  /// No description provided for @observationTips.
  ///
  /// In en, this message translates to:
  /// **'Observation Tips'**
  String get observationTips;

  /// No description provided for @safetyNote.
  ///
  /// In en, this message translates to:
  /// **'Safety Note'**
  String get safetyNote;

  /// No description provided for @introduction.
  ///
  /// In en, this message translates to:
  /// **'Introduction'**
  String get introduction;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @otherCandidates.
  ///
  /// In en, this message translates to:
  /// **'Other Possible Matches'**
  String get otherCandidates;

  /// No description provided for @photoTips.
  ///
  /// In en, this message translates to:
  /// **'Photo Tips'**
  String get photoTips;

  /// No description provided for @photoTip1.
  ///
  /// In en, this message translates to:
  /// **'Get close to the plant'**
  String get photoTip1;

  /// No description provided for @photoTip2.
  ///
  /// In en, this message translates to:
  /// **'Include leaves and flowers'**
  String get photoTip2;

  /// No description provided for @photoTip3.
  ///
  /// In en, this message translates to:
  /// **'Use good lighting'**
  String get photoTip3;

  /// No description provided for @photoTip4.
  ///
  /// In en, this message translates to:
  /// **'Avoid blurry shots'**
  String get photoTip4;
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
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
