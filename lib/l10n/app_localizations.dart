import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ur.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('hi'),
    Locale('ur')
  ];

  /// No description provided for @languageName.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageName;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get chooseLanguage;

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

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @allow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

  /// No description provided for @fix.
  ///
  /// In en, this message translates to:
  /// **'Fix'**
  String get fix;

  /// No description provided for @turnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get turnOn;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @roleSupervisor.
  ///
  /// In en, this message translates to:
  /// **'Supervisor'**
  String get roleSupervisor;

  /// No description provided for @roleSales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get roleSales;

  /// No description provided for @roleSiteEngineer.
  ///
  /// In en, this message translates to:
  /// **'Site Engineer'**
  String get roleSiteEngineer;

  /// No description provided for @roleMason.
  ///
  /// In en, this message translates to:
  /// **'Mason'**
  String get roleMason;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @signInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get signInToContinue;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get enterValidEmail;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @newToApp.
  ///
  /// In en, this message translates to:
  /// **'New to Royal Marble?'**
  String get newToApp;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @errInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'That email address doesn\'t look right.'**
  String get errInvalidEmail;

  /// No description provided for @errUserDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled. Contact your admin.'**
  String get errUserDisabled;

  /// No description provided for @errTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a few minutes and try again.'**
  String get errTooManyRequests;

  /// No description provided for @errNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection.'**
  String get errNoInternet;

  /// No description provided for @errWrongCredentials.
  ///
  /// In en, this message translates to:
  /// **'Wrong email or password.'**
  String get errWrongCredentials;

  /// No description provided for @errSignInGeneric.
  ///
  /// In en, this message translates to:
  /// **'Could not sign in. Please try again.'**
  String get errSignInGeneric;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPassword;

  /// No description provided for @resetIntro.
  ///
  /// In en, this message translates to:
  /// **'Enter the email you sign in with and we\'ll send you a link to choose a new password.'**
  String get resetIntro;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get sendResetLink;

  /// No description provided for @checkYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get checkYourEmail;

  /// No description provided for @resetSent.
  ///
  /// In en, this message translates to:
  /// **'We sent a reset link to {email}.'**
  String resetSent(String email);

  /// No description provided for @backToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get backToSignIn;

  /// No description provided for @resetError.
  ///
  /// In en, this message translates to:
  /// **'Could not send the email. Check the address and try again.'**
  String get resetError;

  /// No description provided for @stepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String stepOf(int step, int total);

  /// No description provided for @stepAboutYou.
  ///
  /// In en, this message translates to:
  /// **'About you'**
  String get stepAboutYou;

  /// No description provided for @stepContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get stepContact;

  /// No description provided for @stepAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get stepAccount;

  /// No description provided for @addPhotoHint.
  ///
  /// In en, this message translates to:
  /// **'Add a clear photo of your face'**
  String get addPhotoHint;

  /// No description provided for @tapToChange.
  ///
  /// In en, this message translates to:
  /// **'Tap to change'**
  String get tapToChange;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// No description provided for @nationality.
  ///
  /// In en, this message translates to:
  /// **'Nationality'**
  String get nationality;

  /// No description provided for @mobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get mobileNumber;

  /// No description provided for @mobileInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a UAE mobile number (05X XXX XXXX)'**
  String get mobileInvalid;

  /// No description provided for @company.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get company;

  /// No description provided for @homeAddress.
  ///
  /// In en, this message translates to:
  /// **'Home address'**
  String get homeAddress;

  /// No description provided for @passwordHelper.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get passwordHelper;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @passwordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDontMatch;

  /// No description provided for @approvalNotice.
  ///
  /// In en, this message translates to:
  /// **'An admin reviews new accounts. You can sign in once yours is approved.'**
  String get approvalNotice;

  /// No description provided for @photoRequired.
  ///
  /// In en, this message translates to:
  /// **'Add a photo so your supervisor can recognise you.'**
  String get photoRequired;

  /// No description provided for @nationalityRequired.
  ///
  /// In en, this message translates to:
  /// **'Select your nationality.'**
  String get nationalityRequired;

  /// No description provided for @homeRequired.
  ///
  /// In en, this message translates to:
  /// **'Set your home address on the map.'**
  String get homeRequired;

  /// No description provided for @cameraError.
  ///
  /// In en, this message translates to:
  /// **'Could not open the camera or gallery.'**
  String get cameraError;

  /// No description provided for @emailInUse.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists. Try signing in.'**
  String get emailInUse;

  /// No description provided for @registerFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create the account. Check your details and try again.'**
  String get registerFailed;

  /// No description provided for @somethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get somethingWrong;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning, {name}'**
  String greetingMorning(String name);

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon, {name}'**
  String greetingAfternoon(String name);

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening, {name}'**
  String greetingEvening(String name);

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Changes will sync when you reconnect.'**
  String get offlineBanner;

  /// No description provided for @pendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Thanks for signing up'**
  String get pendingTitle;

  /// No description provided for @pendingBody.
  ///
  /// In en, this message translates to:
  /// **'Your account is waiting for approval. You will get access once an admin activates it.'**
  String get pendingBody;

  /// No description provided for @yourSite.
  ///
  /// In en, this message translates to:
  /// **'Your site'**
  String get yourSite;

  /// No description provided for @yourSites.
  ///
  /// In en, this message translates to:
  /// **'Your sites'**
  String get yourSites;

  /// No description provided for @noSiteTitle.
  ///
  /// In en, this message translates to:
  /// **'No site assigned yet'**
  String get noSiteTitle;

  /// No description provided for @noSiteBody.
  ///
  /// In en, this message translates to:
  /// **'Your supervisor will assign you to a project.'**
  String get noSiteBody;

  /// No description provided for @noSitesAssigned.
  ///
  /// In en, this message translates to:
  /// **'No sites assigned.'**
  String get noSitesAssigned;

  /// No description provided for @yourTeam.
  ///
  /// In en, this message translates to:
  /// **'Your team ({count})'**
  String yourTeam(int count);

  /// No description provided for @nobodyYet.
  ///
  /// In en, this message translates to:
  /// **'Nobody yet.'**
  String get nobodyYet;

  /// No description provided for @onSiteAtSince.
  ///
  /// In en, this message translates to:
  /// **'On site at {site} since {time}'**
  String onSiteAtSince(String site, String time);

  /// No description provided for @checkedOut.
  ///
  /// In en, this message translates to:
  /// **'Checked out'**
  String get checkedOut;

  /// No description provided for @notCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'Not checked in'**
  String get notCheckedIn;

  /// No description provided for @durationHm.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String durationHm(int hours, int minutes);

  /// No description provided for @durationM.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String durationM(int minutes);

  /// No description provided for @onSiteSince.
  ///
  /// In en, this message translates to:
  /// **'On site since {time} · {duration}'**
  String onSiteSince(String time, String duration);

  /// No description provided for @checkedInAtSite.
  ///
  /// In en, this message translates to:
  /// **'Checked in at {site}'**
  String checkedInAtSite(String site);

  /// No description provided for @doneToday.
  ///
  /// In en, this message translates to:
  /// **'Done today · {duration}'**
  String doneToday(String duration);

  /// No description provided for @withinSiteArea.
  ///
  /// In en, this message translates to:
  /// **'Within site area'**
  String get withinSiteArea;

  /// No description provided for @kmAway.
  ///
  /// In en, this message translates to:
  /// **'{km} km away'**
  String kmAway(String km);

  /// No description provided for @metersAway.
  ///
  /// In en, this message translates to:
  /// **'{meters} m away'**
  String metersAway(int meters);

  /// No description provided for @gettingGpsFix.
  ///
  /// In en, this message translates to:
  /// **'Getting an accurate GPS fix…'**
  String get gettingGpsFix;

  /// No description provided for @checkIn.
  ///
  /// In en, this message translates to:
  /// **'Check in'**
  String get checkIn;

  /// No description provided for @checkOut.
  ///
  /// In en, this message translates to:
  /// **'Check out'**
  String get checkOut;

  /// No description provided for @workCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Work completed today'**
  String get workCompletedTitle;

  /// No description provided for @workSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get workSystem;

  /// No description provided for @workTiles.
  ///
  /// In en, this message translates to:
  /// **'Tiles'**
  String get workTiles;

  /// No description provided for @workOthers.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get workOthers;

  /// No description provided for @describeWork.
  ///
  /// In en, this message translates to:
  /// **'Describe the work'**
  String get describeWork;

  /// No description provided for @areaCompleted.
  ///
  /// In en, this message translates to:
  /// **'Area completed'**
  String get areaCompleted;

  /// No description provided for @enterNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a number'**
  String get enterNumber;

  /// No description provided for @checkedInAt.
  ///
  /// In en, this message translates to:
  /// **'Checked in at {time}. Have a good day!'**
  String checkedInAt(String time);

  /// No description provided for @checkedOutAt.
  ///
  /// In en, this message translates to:
  /// **'Checked out at {time}. Thank you!'**
  String checkedOutAt(String time);

  /// No description provided for @errLocationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not get your location. Make sure location is turned on and try again.'**
  String get errLocationUnavailable;

  /// No description provided for @errNoServer.
  ///
  /// In en, this message translates to:
  /// **'No connection to the server. Check your internet and try again.'**
  String get errNoServer;

  /// No description provided for @errCheckInFailed.
  ///
  /// In en, this message translates to:
  /// **'Check-in failed ({code}).'**
  String errCheckInFailed(String code);

  /// No description provided for @errSignInAgain.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again.'**
  String get errSignInAgain;

  /// No description provided for @errNotActive.
  ///
  /// In en, this message translates to:
  /// **'Your account is not active.'**
  String get errNotActive;

  /// No description provided for @errMockLocation.
  ///
  /// In en, this message translates to:
  /// **'A fake GPS app was detected. Turn it off to check in.'**
  String get errMockLocation;

  /// No description provided for @errWeakGps.
  ///
  /// In en, this message translates to:
  /// **'GPS signal is too weak (±{meters} m). Step outside or wait a moment and try again.'**
  String errWeakGps(int meters);

  /// No description provided for @errNoSiteLocation.
  ///
  /// In en, this message translates to:
  /// **'This site has no location set. Contact your admin.'**
  String get errNoSiteLocation;

  /// No description provided for @errOutOfRange.
  ///
  /// In en, this message translates to:
  /// **'You are {meters} m outside the site.'**
  String errOutOfRange(int meters);

  /// No description provided for @errAlreadyCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'You are already checked in at {site}.'**
  String errAlreadyCheckedIn(String site);

  /// No description provided for @errNotCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'You are not checked in.'**
  String get errNotCheckedIn;

  /// No description provided for @errCheckedInElsewhere.
  ///
  /// In en, this message translates to:
  /// **'You are checked in at {site}. Check out from there.'**
  String errCheckedInElsewhere(String site);

  /// No description provided for @errNotAssigned.
  ///
  /// In en, this message translates to:
  /// **'You are not assigned to this site.'**
  String get errNotAssigned;

  /// No description provided for @trackingActive.
  ///
  /// In en, this message translates to:
  /// **'Tracking is active'**
  String get trackingActive;

  /// No description provided for @waitingForGps.
  ///
  /// In en, this message translates to:
  /// **'Waiting for GPS…'**
  String get waitingForGps;

  /// No description provided for @gpsAccuracy.
  ///
  /// In en, this message translates to:
  /// **'GPS accuracy ±{meters} m'**
  String gpsAccuracy(int meters);

  /// No description provided for @locationOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Location is turned off'**
  String get locationOffTitle;

  /// No description provided for @locationOffBody.
  ///
  /// In en, this message translates to:
  /// **'Your admin has been notified. Turn it on to continue.'**
  String get locationOffBody;

  /// No description provided for @allowAlwaysTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow location \"All the time\"'**
  String get allowAlwaysTitle;

  /// No description provided for @allowAlwaysBody.
  ///
  /// In en, this message translates to:
  /// **'Needed so check-in works when the app is closed.'**
  String get allowAlwaysBody;

  /// No description provided for @preciseOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Precise location is off'**
  String get preciseOffTitle;

  /// No description provided for @preciseOffBody.
  ///
  /// In en, this message translates to:
  /// **'Turn on \"Use precise location\" for this app.'**
  String get preciseOffBody;

  /// No description provided for @noInternetTitle.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternetTitle;

  /// No description provided for @noInternetBody.
  ///
  /// In en, this message translates to:
  /// **'Location is saved and will upload when you reconnect.'**
  String get noInternetBody;

  /// No description provided for @batterySaverTitle.
  ///
  /// In en, this message translates to:
  /// **'Battery saver is on'**
  String get batterySaverTitle;

  /// No description provided for @batterySaverBody.
  ///
  /// In en, this message translates to:
  /// **'Tracking may be delayed. Turn it off during work hours.'**
  String get batterySaverBody;

  /// No description provided for @batteryOptTitle.
  ///
  /// In en, this message translates to:
  /// **'Battery optimization is on'**
  String get batteryOptTitle;

  /// No description provided for @batteryOptBody.
  ///
  /// In en, this message translates to:
  /// **'Your phone may stop tracking in the background.'**
  String get batteryOptBody;

  /// No description provided for @myPay.
  ///
  /// In en, this message translates to:
  /// **'My pay'**
  String get myPay;

  /// No description provided for @yourPackage.
  ///
  /// In en, this message translates to:
  /// **'Your package'**
  String get yourPackage;

  /// No description provided for @payNotAddedTitle.
  ///
  /// In en, this message translates to:
  /// **'Your pay details haven\'t been added yet.'**
  String get payNotAddedTitle;

  /// No description provided for @payNotAddedBody.
  ///
  /// In en, this message translates to:
  /// **'Ask your admin if you think this is a mistake.'**
  String get payNotAddedBody;

  /// No description provided for @payTypeMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly salary'**
  String get payTypeMonthly;

  /// No description provided for @payTypeDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily rate'**
  String get payTypeDaily;

  /// No description provided for @payTypeHourly.
  ///
  /// In en, this message translates to:
  /// **'Hourly rate'**
  String get payTypeHourly;

  /// No description provided for @perMonth.
  ///
  /// In en, this message translates to:
  /// **'/ month'**
  String get perMonth;

  /// No description provided for @perDay.
  ///
  /// In en, this message translates to:
  /// **'/ day'**
  String get perDay;

  /// No description provided for @perHour.
  ///
  /// In en, this message translates to:
  /// **'/ hour'**
  String get perHour;

  /// No description provided for @basic.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get basic;

  /// No description provided for @housing.
  ///
  /// In en, this message translates to:
  /// **'Housing'**
  String get housing;

  /// No description provided for @transportation.
  ///
  /// In en, this message translates to:
  /// **'Transportation'**
  String get transportation;

  /// No description provided for @food.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get food;

  /// No description provided for @totalPerMonth.
  ///
  /// In en, this message translates to:
  /// **'Total per month'**
  String get totalPerMonth;

  /// No description provided for @allowancesMonthly.
  ///
  /// In en, this message translates to:
  /// **'Allowances are monthly amounts.'**
  String get allowancesMonthly;

  /// No description provided for @effectiveFrom.
  ///
  /// In en, this message translates to:
  /// **'From {date}'**
  String effectiveFrom(String date);

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get myProfile;

  /// No description provided for @sectionTeam.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get sectionTeam;

  /// No description provided for @teamStatusAlerts.
  ///
  /// In en, this message translates to:
  /// **'Team status & alerts'**
  String get teamStatusAlerts;

  /// No description provided for @liveMap.
  ///
  /// In en, this message translates to:
  /// **'Live map'**
  String get liveMap;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @sectionSites.
  ///
  /// In en, this message translates to:
  /// **'Sites'**
  String get sectionSites;

  /// No description provided for @newProject.
  ///
  /// In en, this message translates to:
  /// **'New project'**
  String get newProject;

  /// No description provided for @newMockup.
  ///
  /// In en, this message translates to:
  /// **'New mock-up'**
  String get newMockup;

  /// No description provided for @sectionSales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get sectionSales;

  /// No description provided for @clients.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get clients;

  /// No description provided for @addClient.
  ///
  /// In en, this message translates to:
  /// **'Add client'**
  String get addClient;

  /// No description provided for @newVisit.
  ///
  /// In en, this message translates to:
  /// **'New visit'**
  String get newVisit;

  /// No description provided for @visits.
  ///
  /// In en, this message translates to:
  /// **'Visits'**
  String get visits;

  /// No description provided for @sectionReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get sectionReports;

  /// No description provided for @attendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendance;

  /// No description provided for @salesActivity.
  ///
  /// In en, this message translates to:
  /// **'Sales activity'**
  String get salesActivity;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutTitle;

  /// No description provided for @signOutBody.
  ///
  /// In en, this message translates to:
  /// **'Location tracking stops and you won\'t be able to check in until you sign in again.'**
  String get signOutBody;
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
      <String>['ar', 'en', 'hi', 'ur'].contains(locale.languageCode);

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
    case 'hi':
      return AppLocalizationsHi();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
