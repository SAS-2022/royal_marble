// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get languageName => 'English';

  @override
  String get language => 'Language';

  @override
  String get chooseLanguage => 'Choose language';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get back => 'Back';

  @override
  String get continueLabel => 'Continue';

  @override
  String get required => 'Required';

  @override
  String get settings => 'Settings';

  @override
  String get allow => 'Allow';

  @override
  String get fix => 'Fix';

  @override
  String get turnOn => 'Turn on';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleSupervisor => 'Supervisor';

  @override
  String get roleSales => 'Sales';

  @override
  String get roleSiteEngineer => 'Site Engineer';

  @override
  String get roleMason => 'Mason';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get signInToContinue => 'Sign in to continue';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get enterValidEmail => 'Enter a valid email';

  @override
  String get enterPassword => 'Enter your password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get signIn => 'Sign in';

  @override
  String get newToApp => 'New to Royal Marble?';

  @override
  String get createAccount => 'Create account';

  @override
  String get errInvalidEmail => 'That email address doesn\'t look right.';

  @override
  String get errUserDisabled =>
      'This account has been disabled. Contact your admin.';

  @override
  String get errTooManyRequests =>
      'Too many attempts. Wait a few minutes and try again.';

  @override
  String get errNoInternet => 'No internet connection.';

  @override
  String get errWrongCredentials => 'Wrong email or password.';

  @override
  String get errSignInGeneric => 'Could not sign in. Please try again.';

  @override
  String get resetPassword => 'Reset password';

  @override
  String get resetIntro =>
      'Enter the email you sign in with and we\'ll send you a link to choose a new password.';

  @override
  String get sendResetLink => 'Send reset link';

  @override
  String get checkYourEmail => 'Check your email';

  @override
  String resetSent(String email) {
    return 'We sent a reset link to $email.';
  }

  @override
  String get backToSignIn => 'Back to sign in';

  @override
  String get resetError =>
      'Could not send the email. Check the address and try again.';

  @override
  String stepOf(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get stepAboutYou => 'About you';

  @override
  String get stepContact => 'Contact';

  @override
  String get stepAccount => 'Account';

  @override
  String get addPhotoHint => 'Add a clear photo of your face';

  @override
  String get tapToChange => 'Tap to change';

  @override
  String get takePhoto => 'Take a photo';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get firstName => 'First name';

  @override
  String get lastName => 'Last name';

  @override
  String get nationality => 'Nationality';

  @override
  String get mobileNumber => 'Mobile number';

  @override
  String get mobileInvalid => 'Enter a UAE mobile number (05X XXX XXXX)';

  @override
  String get company => 'Company';

  @override
  String get homeAddress => 'Home address';

  @override
  String get passwordHelper => 'At least 6 characters';

  @override
  String get passwordTooShort => 'Use at least 6 characters';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get passwordsDontMatch => 'Passwords do not match';

  @override
  String get approvalNotice =>
      'An admin reviews new accounts. You can sign in once yours is approved.';

  @override
  String get photoRequired =>
      'Add a photo so your supervisor can recognise you.';

  @override
  String get nationalityRequired => 'Select your nationality.';

  @override
  String get homeRequired => 'Set your home address on the map.';

  @override
  String get cameraError => 'Could not open the camera or gallery.';

  @override
  String get emailInUse =>
      'An account with this email already exists. Try signing in.';

  @override
  String get registerFailed =>
      'Could not create the account. Check your details and try again.';

  @override
  String get somethingWrong => 'Something went wrong. Please try again.';

  @override
  String greetingMorning(String name) {
    return 'Good morning, $name';
  }

  @override
  String greetingAfternoon(String name) {
    return 'Good afternoon, $name';
  }

  @override
  String greetingEvening(String name) {
    return 'Good evening, $name';
  }

  @override
  String get offlineBanner =>
      'You are offline. Changes will sync when you reconnect.';

  @override
  String get pendingTitle => 'Thanks for signing up';

  @override
  String get pendingBody =>
      'Your account is waiting for approval. You will get access once an admin activates it.';

  @override
  String get yourSite => 'Your site';

  @override
  String get yourSites => 'Your sites';

  @override
  String get noSiteTitle => 'No site assigned yet';

  @override
  String get noSiteBody => 'Your supervisor will assign you to a project.';

  @override
  String get noSitesAssigned => 'No sites assigned.';

  @override
  String yourTeam(int count) {
    return 'Your team ($count)';
  }

  @override
  String get nobodyYet => 'Nobody yet.';

  @override
  String onSiteAtSince(String site, String time) {
    return 'On site at $site since $time';
  }

  @override
  String get checkedOut => 'Checked out';

  @override
  String get notCheckedIn => 'Not checked in';

  @override
  String durationHm(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String durationM(int minutes) {
    return '${minutes}m';
  }

  @override
  String onSiteSince(String time, String duration) {
    return 'On site since $time · $duration';
  }

  @override
  String checkedInAtSite(String site) {
    return 'Checked in at $site';
  }

  @override
  String doneToday(String duration) {
    return 'Done today · $duration';
  }

  @override
  String get withinSiteArea => 'Within site area';

  @override
  String kmAway(String km) {
    return '$km km away';
  }

  @override
  String metersAway(int meters) {
    return '$meters m away';
  }

  @override
  String get gettingGpsFix => 'Getting an accurate GPS fix…';

  @override
  String get checkIn => 'Check in';

  @override
  String get checkOut => 'Check out';

  @override
  String get workCompletedTitle => 'Work completed today';

  @override
  String get workSystem => 'System';

  @override
  String get workTiles => 'Tiles';

  @override
  String get workOthers => 'Others';

  @override
  String get describeWork => 'Describe the work';

  @override
  String get areaCompleted => 'Area completed';

  @override
  String get enterNumber => 'Enter a number';

  @override
  String checkedInAt(String time) {
    return 'Checked in at $time. Have a good day!';
  }

  @override
  String checkedOutAt(String time) {
    return 'Checked out at $time. Thank you!';
  }

  @override
  String get errLocationUnavailable =>
      'Could not get your location. Make sure location is turned on and try again.';

  @override
  String get errNoServer =>
      'No connection to the server. Check your internet and try again.';

  @override
  String errCheckInFailed(String code) {
    return 'Check-in failed ($code).';
  }

  @override
  String get errSignInAgain => 'Please sign in again.';

  @override
  String get errNotActive => 'Your account is not active.';

  @override
  String get errMockLocation =>
      'A fake GPS app was detected. Turn it off to check in.';

  @override
  String errWeakGps(int meters) {
    return 'GPS signal is too weak (±$meters m). Step outside or wait a moment and try again.';
  }

  @override
  String get errNoSiteLocation =>
      'This site has no location set. Contact your admin.';

  @override
  String errOutOfRange(int meters) {
    return 'You are $meters m outside the site.';
  }

  @override
  String errAlreadyCheckedIn(String site) {
    return 'You are already checked in at $site.';
  }

  @override
  String get errNotCheckedIn => 'You are not checked in.';

  @override
  String errCheckedInElsewhere(String site) {
    return 'You are checked in at $site. Check out from there.';
  }

  @override
  String get errNotAssigned => 'You are not assigned to this site.';

  @override
  String get trackingActive => 'Tracking is active';

  @override
  String get waitingForGps => 'Waiting for GPS…';

  @override
  String gpsAccuracy(int meters) {
    return 'GPS accuracy ±$meters m';
  }

  @override
  String get locationOffTitle => 'Location is turned off';

  @override
  String get locationOffBody =>
      'Your admin has been notified. Turn it on to continue.';

  @override
  String get allowAlwaysTitle => 'Allow location \"All the time\"';

  @override
  String get allowAlwaysBody =>
      'Needed so check-in works when the app is closed.';

  @override
  String get preciseOffTitle => 'Precise location is off';

  @override
  String get preciseOffBody => 'Turn on \"Use precise location\" for this app.';

  @override
  String get noInternetTitle => 'No internet connection';

  @override
  String get noInternetBody =>
      'Location is saved and will upload when you reconnect.';

  @override
  String get batterySaverTitle => 'Battery saver is on';

  @override
  String get batterySaverBody =>
      'Tracking may be delayed. Turn it off during work hours.';

  @override
  String get batteryOptTitle => 'Battery optimization is on';

  @override
  String get batteryOptBody =>
      'Your phone may stop tracking in the background.';

  @override
  String get myPay => 'My pay';

  @override
  String get yourPackage => 'Your package';

  @override
  String get payNotAddedTitle => 'Your pay details haven\'t been added yet.';

  @override
  String get payNotAddedBody =>
      'Ask your admin if you think this is a mistake.';

  @override
  String get payTypeMonthly => 'Monthly salary';

  @override
  String get payTypeDaily => 'Daily rate';

  @override
  String get payTypeHourly => 'Hourly rate';

  @override
  String get perMonth => '/ month';

  @override
  String get perDay => '/ day';

  @override
  String get perHour => '/ hour';

  @override
  String get basic => 'Basic';

  @override
  String get housing => 'Housing';

  @override
  String get transportation => 'Transportation';

  @override
  String get food => 'Food';

  @override
  String get totalPerMonth => 'Total per month';

  @override
  String get allowancesMonthly => 'Allowances are monthly amounts.';

  @override
  String effectiveFrom(String date) {
    return 'From $date';
  }

  @override
  String get myProfile => 'My profile';

  @override
  String get sectionTeam => 'Team';

  @override
  String get teamStatusAlerts => 'Team status & alerts';

  @override
  String get liveMap => 'Live map';

  @override
  String get users => 'Users';

  @override
  String get sectionSites => 'Sites';

  @override
  String get newProject => 'New project';

  @override
  String get newMockup => 'New mock-up';

  @override
  String get sectionSales => 'Sales';

  @override
  String get clients => 'Clients';

  @override
  String get addClient => 'Add client';

  @override
  String get newVisit => 'New visit';

  @override
  String get visits => 'Visits';

  @override
  String get sectionReports => 'Reports';

  @override
  String get attendance => 'Attendance';

  @override
  String get salesActivity => 'Sales activity';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutTitle => 'Sign out?';

  @override
  String get signOutBody =>
      'Location tracking stops and you won\'t be able to check in until you sign in again.';
}
