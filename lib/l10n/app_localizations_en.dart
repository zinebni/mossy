// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Mossy';

  @override
  String get tagline => 'Look closer. Discover more.';

  @override
  String get goodMorning => 'Good morning, Explorer!';

  @override
  String get goodAfternoon => 'Good afternoon, Explorer!';

  @override
  String get goodEvening => 'Good evening, Explorer!';

  @override
  String get home => 'Home';

  @override
  String get explore => 'Explore';

  @override
  String get collection => 'Collection';

  @override
  String get adventures => 'Adventures';

  @override
  String get garden => 'Garden';

  @override
  String get discoverPlant => 'Discover a Plant';

  @override
  String get takePhoto => 'Take a Photo';

  @override
  String get chooseFromGallery => 'Choose from Gallery';

  @override
  String get identifyPlant => 'Identify This Plant';

  @override
  String get retake => 'Retake';

  @override
  String get chooseAnother => 'Choose Another';

  @override
  String get saveToCollection => 'Save to Collection';

  @override
  String get learnMore => 'Learn More';

  @override
  String get identifyAnother => 'Identify Another';

  @override
  String get dailyChallenge => 'Daily Challenge';

  @override
  String get recentDiscoveries => 'Recent Discoveries';

  @override
  String get yourGarden => 'Your Garden';

  @override
  String get achievements => 'Achievements';

  @override
  String get myCollection => 'My Collection';

  @override
  String get searchPlants => 'Search plants...';

  @override
  String get all => 'All';

  @override
  String get favorites => 'Favorites';

  @override
  String get byFamily => 'By Family';

  @override
  String get noDiscoveries => 'No discoveries yet';

  @override
  String get startExploring => 'Start exploring to build your collection!';

  @override
  String get totalSpecies => 'Total Species';

  @override
  String get favoritesCount => 'Favorites';

  @override
  String get daily => 'Daily';

  @override
  String get challenges => 'Challenges';

  @override
  String get completed => 'Completed';

  @override
  String get easy => 'Easy';

  @override
  String get medium => 'Medium';

  @override
  String get hard => 'Hard';

  @override
  String get startMission => 'Start Mission';

  @override
  String get submitDiscovery => 'Submit Discovery';

  @override
  String points(int count) {
    return '$count pts';
  }

  @override
  String gardenLevel(int level) {
    return 'Garden Level $level';
  }

  @override
  String get growYourGarden => 'How to Grow Your Garden';

  @override
  String get gardenTip =>
      'Identify plants, complete adventures, and earn achievements to grow your garden!';

  @override
  String get profile => 'Profile';

  @override
  String explorerLevel(int level) {
    return 'Explorer Level $level';
  }

  @override
  String get totalPoints => 'Total Points';

  @override
  String get totalDiscoveries => 'Total Discoveries';

  @override
  String get adventuresComplete => 'Adventures Complete';

  @override
  String get daysActive => 'Days Active';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get notifications => 'Notifications';

  @override
  String get locationPermissions => 'Location Permissions';

  @override
  String get about => 'About';

  @override
  String get privacy => 'Privacy Information';

  @override
  String get signOut => 'Sign Out';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get discoveryMap => 'Discovery Map';

  @override
  String get noLocations => 'No discoveries with location data yet';

  @override
  String get demoMode => 'Demo Mode';

  @override
  String get demoModeDescription =>
      'You\'re exploring in demo mode. Configure Supabase to save your discoveries.';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Something went wrong';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get confirm => 'Confirm';

  @override
  String get onboarding1Title => 'Discover Plants Around You';

  @override
  String get onboarding1Desc =>
      'Point your camera at any plant and let Mossy identify it for you using advanced AI.';

  @override
  String get onboarding2Title => 'Learn Fascinating Facts';

  @override
  String get onboarding2Desc =>
      'Get interesting facts, observation tips, and educational content about every plant you discover.';

  @override
  String get onboarding3Title => 'Collect & Complete Adventures';

  @override
  String get onboarding3Desc =>
      'Build your personal nature journal and take on exciting exploration challenges.';

  @override
  String get onboarding4Title => 'Grow Your Virtual Garden';

  @override
  String get onboarding4Desc =>
      'Watch your garden bloom as you explore more of the natural world around you.';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get Started';

  @override
  String get lookingClosely => 'Looking closely at your discovery...';

  @override
  String get searchingBotanical => 'Searching the botanical world...';

  @override
  String get consultingEncyclopedia => 'Consulting the plant encyclopedia...';

  @override
  String get preparingSomething => 'Preparing something interesting...';

  @override
  String get almostThere => 'Almost there...';

  @override
  String get veryLikely => 'Very Likely';

  @override
  String get likely => 'Likely';

  @override
  String get possible => 'Possible';

  @override
  String get uncertain => 'Uncertain';

  @override
  String get scientificName => 'Scientific Name';

  @override
  String get commonName => 'Common Name';

  @override
  String get family => 'Family';

  @override
  String discoveredOn(String date) {
    return 'Discovered on $date';
  }

  @override
  String get personalNotes => 'Personal Notes';

  @override
  String get addNotes => 'Add your personal notes...';

  @override
  String get funFacts => 'Fun Facts';

  @override
  String get observationTips => 'Observation Tips';

  @override
  String get safetyNote => 'Safety Note';

  @override
  String get introduction => 'Introduction';

  @override
  String get description => 'Description';

  @override
  String get otherCandidates => 'Other Possible Matches';

  @override
  String get photoTips => 'Photo Tips';

  @override
  String get photoTip1 => 'Get close to the plant';

  @override
  String get photoTip2 => 'Include leaves and flowers';

  @override
  String get photoTip3 => 'Use good lighting';

  @override
  String get photoTip4 => 'Avoid blurry shots';
}
