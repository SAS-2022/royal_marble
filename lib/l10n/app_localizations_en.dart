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

  @override
  String get teamStatus => 'Team status';

  @override
  String get onSiteNow => 'On site now';

  @override
  String get phoneAlerts => 'Phone alerts';

  @override
  String get pendingLabel => 'Pending';

  @override
  String get needsAttention => 'Needs attention';

  @override
  String get seeAll => 'See all';

  @override
  String get todaysAttendance => 'Today\'s attendance';

  @override
  String get alertLog => 'Alert log';

  @override
  String activeProjects(int count) {
    return 'Active projects ($count)';
  }

  @override
  String activeMockups(int count) {
    return 'Active mock-ups ($count)';
  }

  @override
  String potentialProjects(int count) {
    return 'Potential projects ($count)';
  }

  @override
  String get nobodyCheckedInToday => 'Nobody has checked in yet today.';

  @override
  String get details => 'Details';

  @override
  String get changeStatus => 'Change status';

  @override
  String get myVisits => 'My visits';

  @override
  String get site => 'Site';

  @override
  String get problemSilent => 'Not reporting';

  @override
  String get problemLocationOff => 'Location off';

  @override
  String problemPermission(String value) {
    return 'Permission: $value';
  }

  @override
  String get problemTrackingStopped => 'Tracking stopped';

  @override
  String get problemOffline => 'Offline';

  @override
  String get problemApproximate => 'Approximate location';

  @override
  String get problemBatterySaver => 'Battery saver on';

  @override
  String problemBattery(int percent) {
    return 'Battery $percent%';
  }

  @override
  String get permWhenInUse => 'while in use';

  @override
  String get permDenied => 'denied';

  @override
  String get permRestricted => 'restricted';

  @override
  String get permNotDetermined => 'not set';

  @override
  String get permAlways => 'all the time';

  @override
  String get unknownUser => 'Unknown';

  @override
  String get timeNever => 'never';

  @override
  String get timeJustNow => 'just now';

  @override
  String timeMinAgo(int n) {
    return '$n min ago';
  }

  @override
  String timeHoursAgo(int n) {
    return '$n h ago';
  }

  @override
  String seenAgo(String when) {
    return 'seen $when';
  }

  @override
  String lastSeen(String when) {
    return 'Last seen $when';
  }

  @override
  String get phonesTab => 'Phones';

  @override
  String get alertsTab => 'Alerts';

  @override
  String get noActiveWorkers => 'No active workers';

  @override
  String get notOnNewApp => 'Not on the new app version yet';

  @override
  String get allGood => 'All good';

  @override
  String gpsShort(int meters) {
    return 'GPS ±$meters m';
  }

  @override
  String get alertsNotEnabled => 'Alerts are not enabled on the server yet.';

  @override
  String get alertsLoadError => 'Could not load alerts. Check your connection.';

  @override
  String get noAlertsYet => 'No alerts yet';

  @override
  String get evLocationOff => 'Location services turned OFF';

  @override
  String get evLocationOn => 'Location services turned back on';

  @override
  String get evGpsOff => 'GPS turned off (only network location)';

  @override
  String get evGpsOn => 'GPS turned back on';

  @override
  String get evPreciseOff => 'Precise location turned off';

  @override
  String get evPreciseOn => 'Precise location turned back on';

  @override
  String evPermission(String value) {
    return 'Location permission changed to \"$value\"';
  }

  @override
  String get evOffline => 'Phone lost internet connection';

  @override
  String get evOnline => 'Phone is back online';

  @override
  String get evPowerSaveOn =>
      'Battery saver turned on (tracking may be delayed)';

  @override
  String get evPowerSaveOff => 'Battery saver turned off';

  @override
  String get evTrackingStopped => 'Location tracking stopped';

  @override
  String get evTrackingStarted => 'Location tracking started';

  @override
  String get evAppClosed => 'App was closed (tracking continues)';

  @override
  String get evDeviceBoot => 'Phone restarted';

  @override
  String get evMock => 'Fake GPS / mock location detected';

  @override
  String get evMockCleared => 'Real GPS restored';

  @override
  String evBatteryLow(int percent) {
    return 'Battery low ($percent%)';
  }

  @override
  String get evBatteryOk => 'Battery recovered';

  @override
  String get evSilent =>
      'Phone stopped reporting. It may be switched off, offline, or the app was force-stopped.';

  @override
  String get usersAll => 'All';

  @override
  String activeTab(int count) {
    return 'Active ($count)';
  }

  @override
  String pendingTab(int count) {
    return 'Pending ($count)';
  }

  @override
  String get searchUsers => 'Search name, email or phone';

  @override
  String get noActiveUsersMatch => 'No active users match.';

  @override
  String get nobodyWaiting => 'Nobody is waiting for approval.';

  @override
  String get review => 'Review';

  @override
  String roleChangedTo(String role) {
    return 'Role changed to $role';
  }

  @override
  String get roleChangeFailed => 'Could not change the role.';

  @override
  String get accountActivated => 'Account activated';

  @override
  String get accountDeactivated => 'Account deactivated';

  @override
  String get accessUpdateFailed => 'Could not update access.';

  @override
  String deleteUserTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get deleteUserBody =>
      'Their profile is removed permanently. Past timesheets are kept.';

  @override
  String get delete => 'Delete';

  @override
  String get statusActive => 'Active';

  @override
  String get statusPendingInactive => 'Pending / inactive';

  @override
  String get waitingForAccess => 'This account is waiting for access.';

  @override
  String get approve => 'Approve';

  @override
  String get sectionContact => 'Contact';

  @override
  String get sectionWork => 'Work';

  @override
  String get noSiteAssigned => 'No site assigned';

  @override
  String get assignedSite => 'Assigned site';

  @override
  String get phoneReportingNormally => 'Phone is reporting normally';

  @override
  String get recentAlerts => 'Recent alerts';

  @override
  String get sectionPay => 'Pay';

  @override
  String get sectionRole => 'Role';

  @override
  String get sectionAccess => 'Access';

  @override
  String get deactivateAccount => 'Deactivate account';

  @override
  String get activateAccount => 'Activate account';

  @override
  String get deactivateBeforeDeleting => 'Deactivate before deleting';

  @override
  String get deletePermanently => 'Delete account permanently';

  @override
  String get userTitle => 'User';

  @override
  String get project => 'Project';

  @override
  String get mockup => 'Mock-up';

  @override
  String get edit => 'Edit';

  @override
  String checkInRadius(int meters) {
    return 'Check-in radius $meters m';
  }

  @override
  String get directions => 'Directions';

  @override
  String get today => 'Today';

  @override
  String get contractor => 'Contractor';

  @override
  String teamCount(int count) {
    return 'Team ($count)';
  }

  @override
  String get manage => 'Manage';

  @override
  String get nobodyAssigned => 'Nobody is assigned yet.';

  @override
  String peopleAssigned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people assigned.',
      one: '1 person assigned.',
    );
    return '$_temp0';
  }

  @override
  String get onSite => 'On site';

  @override
  String get away => 'Away';

  @override
  String get teamUpdated => 'Team updated';

  @override
  String get teamUpdateFailed => 'Could not update the team.';

  @override
  String teamOf(String site) {
    return 'Team · $site';
  }

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get searchPeople => 'Search people';

  @override
  String get saveTeam => 'Save team';

  @override
  String currentlyAt(String site) {
    return 'also at $site';
  }

  @override
  String get payUnavailable => 'Pay details are not available yet.';

  @override
  String get noPayDetails => 'No pay details yet.';

  @override
  String get setPayDetails => 'Set pay details';

  @override
  String get editPayDetails => 'Edit pay details';

  @override
  String get paySaved => 'Pay details saved';

  @override
  String get enterValidAmount => 'Enter a valid amount';

  @override
  String payFor(String name) {
    return 'Pay · $name';
  }

  @override
  String get monthly => 'Monthly';

  @override
  String get daily => 'Daily';

  @override
  String get hourly => 'Hourly';

  @override
  String get monthlyAllowances => 'Monthly allowances';

  @override
  String get allowance => 'Allowance';

  @override
  String get nameIt => 'Name it';

  @override
  String get amount => 'Amount';

  @override
  String get addAllowance => 'Add another allowance';

  @override
  String get effectiveFromLabel => 'Effective from';

  @override
  String get notesOptional => 'Notes (optional)';

  @override
  String get summary => 'Summary';

  @override
  String get savePayDetails => 'Save pay details';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get thisWeek => 'This week';

  @override
  String get lastWeek => 'Last week';

  @override
  String get thisMonth => 'This month';

  @override
  String get lastMonth => 'Last month';

  @override
  String get customRange => 'Custom…';

  @override
  String get reportLoadError =>
      'Could not load the report. Check your connection.';

  @override
  String get nothingToExport => 'Nothing to export for this period.';

  @override
  String get pdfSubtitle => 'Preview, print or share';

  @override
  String get excelSubtitle => 'Daily entries and a summary sheet';

  @override
  String get export => 'Export';

  @override
  String get everyone => 'Everyone';

  @override
  String get rolesMasons => 'Masons';

  @override
  String get rolesSiteEngineers => 'Site Engineers';

  @override
  String get rolesSupervisors => 'Supervisors';

  @override
  String get people => 'People';

  @override
  String get hours => 'Hours';

  @override
  String get areaM2 => 'Area m²';

  @override
  String missingCheckouts(int count) {
    return 'Entries without check-out: $count. Those hours are not counted.';
  }

  @override
  String get viewBy => 'View by';

  @override
  String get person => 'Person';

  @override
  String get day => 'Day';

  @override
  String get noAttendance => 'No attendance in this period.';

  @override
  String get noSalesTeam => 'No sales team members.';

  @override
  String get salespeople => 'Salespeople';

  @override
  String get noVisits => 'No visits in this period.';

  @override
  String get client => 'Client';

  @override
  String get noOut => 'No out';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String salesSummary(int days, int client, int project) {
    return '$days working days · $client client · $project project visits';
  }

  @override
  String peopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return '$_temp0';
  }

  @override
  String get nowLabel => 'now';

  @override
  String get switchHere => 'Switch to this site';

  @override
  String get switchSiteTitle => 'Switch site?';

  @override
  String switchSiteBody(String from, String to) {
    return 'You will be checked out of $from and checked in at $to.';
  }

  @override
  String outsideSiteSince(String time) {
    return 'Outside the site since $time';
  }

  @override
  String get autoCheckedOut => 'Checked out automatically';

  @override
  String evLeftSite(String site) {
    return 'Left $site while checked in';
  }

  @override
  String evReturnedToSite(String site) {
    return 'Returned to $site';
  }

  @override
  String evAutoCheckout(String site) {
    return 'Checked out automatically from $site';
  }

  @override
  String get allSites => 'All sites';

  @override
  String autoCheckoutsToReview(int count) {
    return 'Automatic check-outs to review: $count.';
  }

  @override
  String autoCheckoutsToReviewTap(int count) {
    return 'Automatic check-outs to review: $count. Tap an entry to fix or approve it.';
  }

  @override
  String awayFor(String duration) {
    return 'away $duration';
  }

  @override
  String get autoLeftSiteShort => 'Auto: left site';

  @override
  String get autoEndOfDayShort => 'Auto: end of day';

  @override
  String get editedByAdmin => 'Edited';

  @override
  String noOutCount(int count) {
    return '$count no out';
  }

  @override
  String get errEndBeforeStart => 'Check-out must be after check-in.';

  @override
  String get errOnlyLastOpen =>
      'Only the last stay can be left without a check-out.';

  @override
  String get errSessionsOverlap => 'Two stays overlap. Adjust the times.';

  @override
  String get attendanceSaved => 'Attendance saved';

  @override
  String get errNotAdmin => 'Only admins can correct attendance.';

  @override
  String get reviewHint =>
      'The system closed this day automatically. Fix the times if needed, or approve them as they are.';

  @override
  String get addSession => 'Add a stay';

  @override
  String get correctionNote => 'Reason';

  @override
  String get correctionNoteHint =>
      'e.g. Forgot to check out, confirmed by supervisor';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get approveAsIs => 'Approve as is';

  @override
  String get correctionHistory => 'Change history';

  @override
  String previously(String sessions) {
    return 'Before: $sessions';
  }

  @override
  String get removeSession => 'Remove this stay';

  @override
  String get inLabel => 'In';

  @override
  String get outLabel => 'Out';

  @override
  String get setCheckOut => 'Set check-out';

  @override
  String get leaveOpen => 'Leave open (still on site)';

  @override
  String get leftAt => 'Left';

  @override
  String get returnedAt => 'Back';

  @override
  String get siteStatusActive => 'Active';

  @override
  String get siteStatusPotential => 'Potential';

  @override
  String get siteStatusClosed => 'Closed';

  @override
  String get siteStatus => 'Status';

  @override
  String get siteName => 'Site name';

  @override
  String get siteDetails => 'Description (optional)';

  @override
  String get siteLocation => 'Location';

  @override
  String get noPinYet => 'No location set yet';

  @override
  String get pinRequired => 'Place the site on the map.';

  @override
  String get setPin => 'Set on map';

  @override
  String get movePin => 'Move';

  @override
  String get checkInRadiusLabel => 'Check-in radius';

  @override
  String metersShort(int meters) {
    return '$meters m';
  }

  @override
  String get radiusHint =>
      'Workers can check in within this distance of the pin. Use at least 150 m so leaving the site is detected reliably.';

  @override
  String get contractorCompany => 'Contractor company';

  @override
  String get contactPerson => 'Contact person';

  @override
  String get contactPhone => 'Phone';

  @override
  String get enterValidPhone => 'Enter a valid phone number';

  @override
  String get createSite => 'Create site';

  @override
  String get editProject => 'Edit project';

  @override
  String get editMockup => 'Edit mock-up';

  @override
  String get siteSaved => 'Site saved';

  @override
  String get siteSaveFailed =>
      'Could not save the site. Check your connection and try again.';

  @override
  String get deleteSite => 'Delete site';

  @override
  String deleteSiteTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String deleteSiteBody(int count) {
    return 'The site is removed for good and $count assigned people lose it from their list. Past attendance is kept.';
  }

  @override
  String get placePin => 'Place the site';

  @override
  String get searchAddress => 'Search an address or area';

  @override
  String get addressNotFound =>
      'Address not found. Try another search or move the map.';

  @override
  String get myLocation => 'My location';

  @override
  String get usePinHere => 'Use this location';

  @override
  String get siteNotFound => 'This site no longer exists.';

  @override
  String get newSite => 'New site';

  @override
  String get searchSites => 'Search name, address or contractor';

  @override
  String get everything => 'All';

  @override
  String get projectsLabel => 'Projects';

  @override
  String get mockupsLabel => 'Mock-ups';

  @override
  String get noSitesFound => 'No sites match.';

  @override
  String get siteAddress => 'Address';

  @override
  String get callAction => 'Call';

  @override
  String helpersCount(int count) {
    return 'Helpers ($count)';
  }

  @override
  String get noHelpers => 'No helpers assigned.';

  @override
  String get noHelpersYet => 'No helpers yet. Add one with the button above.';

  @override
  String helpersMax(int count) {
    return 'A mason can have at most $count helpers.';
  }

  @override
  String helpersOf(String name) {
    return 'Helpers · $name';
  }

  @override
  String get addHelper => 'Add helper';

  @override
  String get editHelper => 'Edit helper';

  @override
  String get saveHelpers => 'Save helpers';

  @override
  String get helpersSaved => 'Helpers updated';

  @override
  String get helpersSaveFailed => 'Could not update the helpers.';

  @override
  String deleteHelperTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get deleteHelperBody =>
      'They are removed from the helper list and from every mason they work with.';

  @override
  String get profileSaved => 'Profile saved';

  @override
  String get profileSaveFailed =>
      'Could not save your profile. Check your connection and try again.';

  @override
  String get sectionAccount => 'Account';

  @override
  String get deleteMyAccount => 'Delete my account';

  @override
  String get deleteMyAccountTitle => 'Delete your account?';

  @override
  String get deleteMyAccountBody =>
      'Your profile and login are deleted for good and you can no longer sign in. Attendance and pay records stay with the company. Enter your password to confirm.';

  @override
  String get errWrongPassword => 'Wrong password.';

  @override
  String get deleteAccountFailed =>
      'Could not delete the account. Check your connection and try again.';

  @override
  String get clientName => 'Client name';

  @override
  String get editClient => 'Edit client';

  @override
  String get deleteClient => 'Delete client';

  @override
  String deleteClientTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get deleteClientBody =>
      'The client is removed from the list. Past visits keep the client\'s name.';

  @override
  String get clientSaved => 'Client saved';

  @override
  String get clientSaveFailed =>
      'Could not save the client. Check your connection and try again.';

  @override
  String get clientLocation => 'Location';

  @override
  String get clientLocationHint =>
      'Optional. A pin on the map lets you open directions later.';

  @override
  String get placeClient => 'Place the client';

  @override
  String get clientNotFound => 'This client was deleted.';

  @override
  String get searchClients => 'Search name, contact, phone or area';

  @override
  String clientsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count clients',
      one: '1 client',
      zero: 'No clients',
    );
    return '$_temp0';
  }

  @override
  String get noClientsYet =>
      'No clients yet. Add your first one with the button below.';

  @override
  String get noClientsFound => 'No clients found';

  @override
  String get pinOnly => 'Pinned on the map';

  @override
  String visitsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count visits',
      one: '1 visit',
      zero: 'Visits',
    );
    return '$_temp0';
  }

  @override
  String get noVisitsYet => 'No visits recorded yet.';

  @override
  String get noVisitsToday => 'No visits recorded today.';

  @override
  String get noVisitsInPeriod => 'No visits in this period.';

  @override
  String todaysVisits(int count) {
    return 'Today\'s visits ($count)';
  }

  @override
  String visitsSummary(int total, int clients, int projects) {
    return '$total visits · $clients clients · $projects projects';
  }

  @override
  String get salesperson => 'Salesperson';

  @override
  String get meLabel => 'Me';

  @override
  String get last7Days => 'Last 7 days';

  @override
  String get clientWord => 'Client';

  @override
  String get projectWord => 'Project';

  @override
  String get chooseClient => 'Choose a client';

  @override
  String get chooseProject => 'Choose a project';

  @override
  String get visitStepWho => 'Who did you visit?';

  @override
  String get visitStepWhat => 'What happened';

  @override
  String get metWith => 'Met with';

  @override
  String get visitPurpose => 'Purpose';

  @override
  String get choosePurpose => 'Choose a purpose';

  @override
  String get visitNotes => 'Notes';

  @override
  String get visitNotesHint => 'What was discussed, agreed or promised?';

  @override
  String notesTooShort(int min, int count) {
    return 'Write at least $min characters ($count so far)';
  }

  @override
  String get visitTime => 'Visit time';

  @override
  String get rightNow => 'Now';

  @override
  String get change => 'Change';

  @override
  String get saveVisit => 'Save visit';

  @override
  String get visitSaved => 'Visit saved';

  @override
  String get visitSaveFailed =>
      'Could not save the visit. Check your connection and try again.';

  @override
  String get visitDetails => 'Visit';

  @override
  String get managerComment => 'Manager\'s comment';

  @override
  String get managerCommentHint => 'Feedback or next steps for the salesperson';

  @override
  String get noManagerComment => 'No comment from your manager yet.';

  @override
  String get saveComment => 'Save comment';

  @override
  String get purposeCollectPayment => 'Collecting payment';

  @override
  String get purposeRequestPayment => 'Requesting payment';

  @override
  String get purposeNewOrder => 'New order';

  @override
  String get purposeOrderFollowUp => 'Order follow-up';

  @override
  String get purposeQuotationFollowUp => 'Quotation follow-up';

  @override
  String get purposeSamples => 'Sample submission';

  @override
  String get purposeComplaint => 'Handling a complaint';

  @override
  String get purposeNewProduct => 'Presenting a new product';

  @override
  String get purposeProjectDiscussion => 'Project discussion';

  @override
  String get purposeNewClient => 'New client';

  @override
  String get purposeReestablish => 'Re-establishing business';

  @override
  String get purposeCatchUp => 'Catch-up visit';

  @override
  String get purposeOther => 'Other';
}
