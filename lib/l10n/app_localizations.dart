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

  /// No description provided for @teamStatus.
  ///
  /// In en, this message translates to:
  /// **'Team status'**
  String get teamStatus;

  /// No description provided for @onSiteNow.
  ///
  /// In en, this message translates to:
  /// **'On site now'**
  String get onSiteNow;

  /// No description provided for @phoneAlerts.
  ///
  /// In en, this message translates to:
  /// **'Phone alerts'**
  String get phoneAlerts;

  /// No description provided for @pendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingLabel;

  /// No description provided for @needsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get needsAttention;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @todaysAttendance.
  ///
  /// In en, this message translates to:
  /// **'Today\'s attendance'**
  String get todaysAttendance;

  /// No description provided for @alertLog.
  ///
  /// In en, this message translates to:
  /// **'Alert log'**
  String get alertLog;

  /// No description provided for @activeProjects.
  ///
  /// In en, this message translates to:
  /// **'Active projects ({count})'**
  String activeProjects(int count);

  /// No description provided for @activeMockups.
  ///
  /// In en, this message translates to:
  /// **'Active mock-ups ({count})'**
  String activeMockups(int count);

  /// No description provided for @potentialProjects.
  ///
  /// In en, this message translates to:
  /// **'Potential projects ({count})'**
  String potentialProjects(int count);

  /// No description provided for @nobodyCheckedInToday.
  ///
  /// In en, this message translates to:
  /// **'Nobody has checked in yet today.'**
  String get nobodyCheckedInToday;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @changeStatus.
  ///
  /// In en, this message translates to:
  /// **'Change status'**
  String get changeStatus;

  /// No description provided for @myVisits.
  ///
  /// In en, this message translates to:
  /// **'My visits'**
  String get myVisits;

  /// No description provided for @site.
  ///
  /// In en, this message translates to:
  /// **'Site'**
  String get site;

  /// No description provided for @problemSilent.
  ///
  /// In en, this message translates to:
  /// **'Not reporting'**
  String get problemSilent;

  /// No description provided for @problemLocationOff.
  ///
  /// In en, this message translates to:
  /// **'Location off'**
  String get problemLocationOff;

  /// No description provided for @problemPermission.
  ///
  /// In en, this message translates to:
  /// **'Permission: {value}'**
  String problemPermission(String value);

  /// No description provided for @problemTrackingStopped.
  ///
  /// In en, this message translates to:
  /// **'Tracking stopped'**
  String get problemTrackingStopped;

  /// No description provided for @problemOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get problemOffline;

  /// No description provided for @problemApproximate.
  ///
  /// In en, this message translates to:
  /// **'Approximate location'**
  String get problemApproximate;

  /// No description provided for @problemBatterySaver.
  ///
  /// In en, this message translates to:
  /// **'Battery saver on'**
  String get problemBatterySaver;

  /// No description provided for @problemBattery.
  ///
  /// In en, this message translates to:
  /// **'Battery {percent}%'**
  String problemBattery(int percent);

  /// No description provided for @permWhenInUse.
  ///
  /// In en, this message translates to:
  /// **'while in use'**
  String get permWhenInUse;

  /// No description provided for @permDenied.
  ///
  /// In en, this message translates to:
  /// **'denied'**
  String get permDenied;

  /// No description provided for @permRestricted.
  ///
  /// In en, this message translates to:
  /// **'restricted'**
  String get permRestricted;

  /// No description provided for @permNotDetermined.
  ///
  /// In en, this message translates to:
  /// **'not set'**
  String get permNotDetermined;

  /// No description provided for @permAlways.
  ///
  /// In en, this message translates to:
  /// **'all the time'**
  String get permAlways;

  /// No description provided for @unknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownUser;

  /// No description provided for @timeNever.
  ///
  /// In en, this message translates to:
  /// **'never'**
  String get timeNever;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get timeJustNow;

  /// No description provided for @timeMinAgo.
  ///
  /// In en, this message translates to:
  /// **'{n} min ago'**
  String timeMinAgo(int n);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{n} h ago'**
  String timeHoursAgo(int n);

  /// No description provided for @seenAgo.
  ///
  /// In en, this message translates to:
  /// **'seen {when}'**
  String seenAgo(String when);

  /// No description provided for @lastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last seen {when}'**
  String lastSeen(String when);

  /// No description provided for @phonesTab.
  ///
  /// In en, this message translates to:
  /// **'Phones'**
  String get phonesTab;

  /// No description provided for @alertsTab.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alertsTab;

  /// No description provided for @noActiveWorkers.
  ///
  /// In en, this message translates to:
  /// **'No active workers'**
  String get noActiveWorkers;

  /// No description provided for @notOnNewApp.
  ///
  /// In en, this message translates to:
  /// **'Not on the new app version yet'**
  String get notOnNewApp;

  /// No description provided for @allGood.
  ///
  /// In en, this message translates to:
  /// **'All good'**
  String get allGood;

  /// No description provided for @gpsShort.
  ///
  /// In en, this message translates to:
  /// **'GPS ±{meters} m'**
  String gpsShort(int meters);

  /// No description provided for @alertsNotEnabled.
  ///
  /// In en, this message translates to:
  /// **'Alerts are not enabled on the server yet.'**
  String get alertsNotEnabled;

  /// No description provided for @alertsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load alerts. Check your connection.'**
  String get alertsLoadError;

  /// No description provided for @noAlertsYet.
  ///
  /// In en, this message translates to:
  /// **'No alerts yet'**
  String get noAlertsYet;

  /// No description provided for @evLocationOff.
  ///
  /// In en, this message translates to:
  /// **'Location services turned OFF'**
  String get evLocationOff;

  /// No description provided for @evLocationOn.
  ///
  /// In en, this message translates to:
  /// **'Location services turned back on'**
  String get evLocationOn;

  /// No description provided for @evGpsOff.
  ///
  /// In en, this message translates to:
  /// **'GPS turned off (only network location)'**
  String get evGpsOff;

  /// No description provided for @evGpsOn.
  ///
  /// In en, this message translates to:
  /// **'GPS turned back on'**
  String get evGpsOn;

  /// No description provided for @evPreciseOff.
  ///
  /// In en, this message translates to:
  /// **'Precise location turned off'**
  String get evPreciseOff;

  /// No description provided for @evPreciseOn.
  ///
  /// In en, this message translates to:
  /// **'Precise location turned back on'**
  String get evPreciseOn;

  /// No description provided for @evPermission.
  ///
  /// In en, this message translates to:
  /// **'Location permission changed to \"{value}\"'**
  String evPermission(String value);

  /// No description provided for @evOffline.
  ///
  /// In en, this message translates to:
  /// **'Phone lost internet connection'**
  String get evOffline;

  /// No description provided for @evOnline.
  ///
  /// In en, this message translates to:
  /// **'Phone is back online'**
  String get evOnline;

  /// No description provided for @evPowerSaveOn.
  ///
  /// In en, this message translates to:
  /// **'Battery saver turned on (tracking may be delayed)'**
  String get evPowerSaveOn;

  /// No description provided for @evPowerSaveOff.
  ///
  /// In en, this message translates to:
  /// **'Battery saver turned off'**
  String get evPowerSaveOff;

  /// No description provided for @evTrackingStopped.
  ///
  /// In en, this message translates to:
  /// **'Location tracking stopped'**
  String get evTrackingStopped;

  /// No description provided for @evTrackingStarted.
  ///
  /// In en, this message translates to:
  /// **'Location tracking started'**
  String get evTrackingStarted;

  /// No description provided for @evAppClosed.
  ///
  /// In en, this message translates to:
  /// **'App was closed (tracking continues)'**
  String get evAppClosed;

  /// No description provided for @evDeviceBoot.
  ///
  /// In en, this message translates to:
  /// **'Phone restarted'**
  String get evDeviceBoot;

  /// No description provided for @evMock.
  ///
  /// In en, this message translates to:
  /// **'Fake GPS / mock location detected'**
  String get evMock;

  /// No description provided for @evMockCleared.
  ///
  /// In en, this message translates to:
  /// **'Real GPS restored'**
  String get evMockCleared;

  /// No description provided for @evBatteryLow.
  ///
  /// In en, this message translates to:
  /// **'Battery low ({percent}%)'**
  String evBatteryLow(int percent);

  /// No description provided for @evBatteryOk.
  ///
  /// In en, this message translates to:
  /// **'Battery recovered'**
  String get evBatteryOk;

  /// No description provided for @evSilent.
  ///
  /// In en, this message translates to:
  /// **'Phone stopped reporting. It may be switched off, offline, or the app was force-stopped.'**
  String get evSilent;

  /// No description provided for @usersAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get usersAll;

  /// No description provided for @activeTab.
  ///
  /// In en, this message translates to:
  /// **'Active ({count})'**
  String activeTab(int count);

  /// No description provided for @pendingTab.
  ///
  /// In en, this message translates to:
  /// **'Pending ({count})'**
  String pendingTab(int count);

  /// No description provided for @searchUsers.
  ///
  /// In en, this message translates to:
  /// **'Search name, email or phone'**
  String get searchUsers;

  /// No description provided for @noActiveUsersMatch.
  ///
  /// In en, this message translates to:
  /// **'No active users match.'**
  String get noActiveUsersMatch;

  /// No description provided for @nobodyWaiting.
  ///
  /// In en, this message translates to:
  /// **'Nobody is waiting for approval.'**
  String get nobodyWaiting;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @roleChangedTo.
  ///
  /// In en, this message translates to:
  /// **'Role changed to {role}'**
  String roleChangedTo(String role);

  /// No description provided for @roleChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not change the role.'**
  String get roleChangeFailed;

  /// No description provided for @accountActivated.
  ///
  /// In en, this message translates to:
  /// **'Account activated'**
  String get accountActivated;

  /// No description provided for @accountDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Account deactivated'**
  String get accountDeactivated;

  /// No description provided for @accessUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update access.'**
  String get accessUpdateFailed;

  /// No description provided for @deleteUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteUserTitle(String name);

  /// No description provided for @deleteUserBody.
  ///
  /// In en, this message translates to:
  /// **'Their profile is removed permanently. Past timesheets are kept.'**
  String get deleteUserBody;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusPendingInactive.
  ///
  /// In en, this message translates to:
  /// **'Pending / inactive'**
  String get statusPendingInactive;

  /// No description provided for @waitingForAccess.
  ///
  /// In en, this message translates to:
  /// **'This account is waiting for access.'**
  String get waitingForAccess;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @sectionContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get sectionContact;

  /// No description provided for @sectionWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get sectionWork;

  /// No description provided for @noSiteAssigned.
  ///
  /// In en, this message translates to:
  /// **'No site assigned'**
  String get noSiteAssigned;

  /// No description provided for @assignedSite.
  ///
  /// In en, this message translates to:
  /// **'Assigned site'**
  String get assignedSite;

  /// No description provided for @phoneReportingNormally.
  ///
  /// In en, this message translates to:
  /// **'Phone is reporting normally'**
  String get phoneReportingNormally;

  /// No description provided for @recentAlerts.
  ///
  /// In en, this message translates to:
  /// **'Recent alerts'**
  String get recentAlerts;

  /// No description provided for @sectionPay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get sectionPay;

  /// No description provided for @sectionRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get sectionRole;

  /// No description provided for @sectionAccess.
  ///
  /// In en, this message translates to:
  /// **'Access'**
  String get sectionAccess;

  /// No description provided for @deactivateAccount.
  ///
  /// In en, this message translates to:
  /// **'Deactivate account'**
  String get deactivateAccount;

  /// No description provided for @activateAccount.
  ///
  /// In en, this message translates to:
  /// **'Activate account'**
  String get activateAccount;

  /// No description provided for @deactivateBeforeDeleting.
  ///
  /// In en, this message translates to:
  /// **'Deactivate before deleting'**
  String get deactivateBeforeDeleting;

  /// No description provided for @deletePermanently.
  ///
  /// In en, this message translates to:
  /// **'Delete account permanently'**
  String get deletePermanently;

  /// No description provided for @userTitle.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get userTitle;

  /// No description provided for @project.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get project;

  /// No description provided for @mockup.
  ///
  /// In en, this message translates to:
  /// **'Mock-up'**
  String get mockup;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @checkInRadius.
  ///
  /// In en, this message translates to:
  /// **'Check-in radius {meters} m'**
  String checkInRadius(int meters);

  /// No description provided for @directions.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get directions;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @contractor.
  ///
  /// In en, this message translates to:
  /// **'Contractor'**
  String get contractor;

  /// No description provided for @teamCount.
  ///
  /// In en, this message translates to:
  /// **'Team ({count})'**
  String teamCount(int count);

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// No description provided for @nobodyAssigned.
  ///
  /// In en, this message translates to:
  /// **'Nobody is assigned yet.'**
  String get nobodyAssigned;

  /// No description provided for @peopleAssigned.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person assigned.} other{{count} people assigned.}}'**
  String peopleAssigned(int count);

  /// No description provided for @onSite.
  ///
  /// In en, this message translates to:
  /// **'On site'**
  String get onSite;

  /// No description provided for @away.
  ///
  /// In en, this message translates to:
  /// **'Away'**
  String get away;

  /// No description provided for @teamUpdated.
  ///
  /// In en, this message translates to:
  /// **'Team updated'**
  String get teamUpdated;

  /// No description provided for @teamUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update the team.'**
  String get teamUpdateFailed;

  /// No description provided for @teamOf.
  ///
  /// In en, this message translates to:
  /// **'Team · {site}'**
  String teamOf(String site);

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(int count);

  /// No description provided for @searchPeople.
  ///
  /// In en, this message translates to:
  /// **'Search people'**
  String get searchPeople;

  /// No description provided for @saveTeam.
  ///
  /// In en, this message translates to:
  /// **'Save team'**
  String get saveTeam;

  /// No description provided for @currentlyAt.
  ///
  /// In en, this message translates to:
  /// **'also at {site}'**
  String currentlyAt(String site);

  /// No description provided for @payUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Pay details are not available yet.'**
  String get payUnavailable;

  /// No description provided for @noPayDetails.
  ///
  /// In en, this message translates to:
  /// **'No pay details yet.'**
  String get noPayDetails;

  /// No description provided for @setPayDetails.
  ///
  /// In en, this message translates to:
  /// **'Set pay details'**
  String get setPayDetails;

  /// No description provided for @editPayDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit pay details'**
  String get editPayDetails;

  /// No description provided for @paySaved.
  ///
  /// In en, this message translates to:
  /// **'Pay details saved'**
  String get paySaved;

  /// No description provided for @enterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get enterValidAmount;

  /// No description provided for @payFor.
  ///
  /// In en, this message translates to:
  /// **'Pay · {name}'**
  String payFor(String name);

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @hourly.
  ///
  /// In en, this message translates to:
  /// **'Hourly'**
  String get hourly;

  /// No description provided for @monthlyAllowances.
  ///
  /// In en, this message translates to:
  /// **'Monthly allowances'**
  String get monthlyAllowances;

  /// No description provided for @allowance.
  ///
  /// In en, this message translates to:
  /// **'Allowance'**
  String get allowance;

  /// No description provided for @nameIt.
  ///
  /// In en, this message translates to:
  /// **'Name it'**
  String get nameIt;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @addAllowance.
  ///
  /// In en, this message translates to:
  /// **'Add another allowance'**
  String get addAllowance;

  /// No description provided for @effectiveFromLabel.
  ///
  /// In en, this message translates to:
  /// **'Effective from'**
  String get effectiveFromLabel;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptional;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// No description provided for @savePayDetails.
  ///
  /// In en, this message translates to:
  /// **'Save pay details'**
  String get savePayDetails;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// No description provided for @lastWeek.
  ///
  /// In en, this message translates to:
  /// **'Last week'**
  String get lastWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @lastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get lastMonth;

  /// No description provided for @customRange.
  ///
  /// In en, this message translates to:
  /// **'Custom…'**
  String get customRange;

  /// No description provided for @reportLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the report. Check your connection.'**
  String get reportLoadError;

  /// No description provided for @nothingToExport.
  ///
  /// In en, this message translates to:
  /// **'Nothing to export for this period.'**
  String get nothingToExport;

  /// No description provided for @pdfSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Preview, print or share'**
  String get pdfSubtitle;

  /// No description provided for @excelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Daily entries and a summary sheet'**
  String get excelSubtitle;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @everyone.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get everyone;

  /// No description provided for @rolesMasons.
  ///
  /// In en, this message translates to:
  /// **'Masons'**
  String get rolesMasons;

  /// No description provided for @rolesSiteEngineers.
  ///
  /// In en, this message translates to:
  /// **'Site Engineers'**
  String get rolesSiteEngineers;

  /// No description provided for @rolesSupervisors.
  ///
  /// In en, this message translates to:
  /// **'Supervisors'**
  String get rolesSupervisors;

  /// No description provided for @people.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get people;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hours;

  /// No description provided for @areaM2.
  ///
  /// In en, this message translates to:
  /// **'Area m²'**
  String get areaM2;

  /// No description provided for @missingCheckouts.
  ///
  /// In en, this message translates to:
  /// **'Entries without check-out: {count}. Those hours are not counted.'**
  String missingCheckouts(int count);

  /// No description provided for @viewBy.
  ///
  /// In en, this message translates to:
  /// **'View by'**
  String get viewBy;

  /// No description provided for @person.
  ///
  /// In en, this message translates to:
  /// **'Person'**
  String get person;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get day;

  /// No description provided for @noAttendance.
  ///
  /// In en, this message translates to:
  /// **'No attendance in this period.'**
  String get noAttendance;

  /// No description provided for @noSalesTeam.
  ///
  /// In en, this message translates to:
  /// **'No sales team members.'**
  String get noSalesTeam;

  /// No description provided for @salespeople.
  ///
  /// In en, this message translates to:
  /// **'Salespeople'**
  String get salespeople;

  /// No description provided for @noVisits.
  ///
  /// In en, this message translates to:
  /// **'No visits in this period.'**
  String get noVisits;

  /// No description provided for @client.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get client;

  /// No description provided for @noOut.
  ///
  /// In en, this message translates to:
  /// **'No out'**
  String get noOut;

  /// No description provided for @daysCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String daysCount(int count);

  /// No description provided for @salesSummary.
  ///
  /// In en, this message translates to:
  /// **'{days} working days · {client} client · {project} project visits'**
  String salesSummary(int days, int client, int project);

  /// No description provided for @peopleCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person} other{{count} people}}'**
  String peopleCount(int count);

  /// No description provided for @nowLabel.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get nowLabel;

  /// No description provided for @switchHere.
  ///
  /// In en, this message translates to:
  /// **'Switch to this site'**
  String get switchHere;

  /// No description provided for @switchSiteTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch site?'**
  String get switchSiteTitle;

  /// No description provided for @switchSiteBody.
  ///
  /// In en, this message translates to:
  /// **'You will be checked out of {from} and checked in at {to}.'**
  String switchSiteBody(String from, String to);

  /// No description provided for @outsideSiteSince.
  ///
  /// In en, this message translates to:
  /// **'Outside the site since {time}'**
  String outsideSiteSince(String time);

  /// No description provided for @autoCheckedOut.
  ///
  /// In en, this message translates to:
  /// **'Checked out automatically'**
  String get autoCheckedOut;

  /// No description provided for @evLeftSite.
  ///
  /// In en, this message translates to:
  /// **'Left {site} while checked in'**
  String evLeftSite(String site);

  /// No description provided for @evReturnedToSite.
  ///
  /// In en, this message translates to:
  /// **'Returned to {site}'**
  String evReturnedToSite(String site);

  /// No description provided for @evAutoCheckout.
  ///
  /// In en, this message translates to:
  /// **'Checked out automatically from {site}'**
  String evAutoCheckout(String site);

  /// No description provided for @allSites.
  ///
  /// In en, this message translates to:
  /// **'All sites'**
  String get allSites;

  /// No description provided for @autoCheckoutsToReview.
  ///
  /// In en, this message translates to:
  /// **'Automatic check-outs to review: {count}.'**
  String autoCheckoutsToReview(int count);

  /// No description provided for @autoCheckoutsToReviewTap.
  ///
  /// In en, this message translates to:
  /// **'Automatic check-outs to review: {count}. Tap an entry to fix or approve it.'**
  String autoCheckoutsToReviewTap(int count);

  /// No description provided for @awayFor.
  ///
  /// In en, this message translates to:
  /// **'away {duration}'**
  String awayFor(String duration);

  /// No description provided for @autoLeftSiteShort.
  ///
  /// In en, this message translates to:
  /// **'Auto: left site'**
  String get autoLeftSiteShort;

  /// No description provided for @autoEndOfDayShort.
  ///
  /// In en, this message translates to:
  /// **'Auto: end of day'**
  String get autoEndOfDayShort;

  /// No description provided for @editedByAdmin.
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get editedByAdmin;

  /// No description provided for @noOutCount.
  ///
  /// In en, this message translates to:
  /// **'{count} no out'**
  String noOutCount(int count);

  /// No description provided for @errEndBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'Check-out must be after check-in.'**
  String get errEndBeforeStart;

  /// No description provided for @errOnlyLastOpen.
  ///
  /// In en, this message translates to:
  /// **'Only the last stay can be left without a check-out.'**
  String get errOnlyLastOpen;

  /// No description provided for @errSessionsOverlap.
  ///
  /// In en, this message translates to:
  /// **'Two stays overlap. Adjust the times.'**
  String get errSessionsOverlap;

  /// No description provided for @attendanceSaved.
  ///
  /// In en, this message translates to:
  /// **'Attendance saved'**
  String get attendanceSaved;

  /// No description provided for @errNotAdmin.
  ///
  /// In en, this message translates to:
  /// **'Only admins can correct attendance.'**
  String get errNotAdmin;

  /// No description provided for @reviewHint.
  ///
  /// In en, this message translates to:
  /// **'The system closed this day automatically. Fix the times if needed, or approve them as they are.'**
  String get reviewHint;

  /// No description provided for @addSession.
  ///
  /// In en, this message translates to:
  /// **'Add a stay'**
  String get addSession;

  /// No description provided for @correctionNote.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get correctionNote;

  /// No description provided for @correctionNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Forgot to check out, confirmed by supervisor'**
  String get correctionNoteHint;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @approveAsIs.
  ///
  /// In en, this message translates to:
  /// **'Approve as is'**
  String get approveAsIs;

  /// No description provided for @correctionHistory.
  ///
  /// In en, this message translates to:
  /// **'Change history'**
  String get correctionHistory;

  /// No description provided for @previously.
  ///
  /// In en, this message translates to:
  /// **'Before: {sessions}'**
  String previously(String sessions);

  /// No description provided for @removeSession.
  ///
  /// In en, this message translates to:
  /// **'Remove this stay'**
  String get removeSession;

  /// No description provided for @inLabel.
  ///
  /// In en, this message translates to:
  /// **'In'**
  String get inLabel;

  /// No description provided for @outLabel.
  ///
  /// In en, this message translates to:
  /// **'Out'**
  String get outLabel;

  /// No description provided for @setCheckOut.
  ///
  /// In en, this message translates to:
  /// **'Set check-out'**
  String get setCheckOut;

  /// No description provided for @leaveOpen.
  ///
  /// In en, this message translates to:
  /// **'Leave open (still on site)'**
  String get leaveOpen;

  /// No description provided for @leftAt.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get leftAt;

  /// No description provided for @returnedAt.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get returnedAt;

  /// No description provided for @siteStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get siteStatusActive;

  /// No description provided for @siteStatusPotential.
  ///
  /// In en, this message translates to:
  /// **'Potential'**
  String get siteStatusPotential;

  /// No description provided for @siteStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get siteStatusClosed;

  /// No description provided for @siteStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get siteStatus;

  /// No description provided for @siteName.
  ///
  /// In en, this message translates to:
  /// **'Site name'**
  String get siteName;

  /// No description provided for @siteDetails.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get siteDetails;

  /// No description provided for @siteLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get siteLocation;

  /// No description provided for @noPinYet.
  ///
  /// In en, this message translates to:
  /// **'No location set yet'**
  String get noPinYet;

  /// No description provided for @pinRequired.
  ///
  /// In en, this message translates to:
  /// **'Place the site on the map.'**
  String get pinRequired;

  /// No description provided for @setPin.
  ///
  /// In en, this message translates to:
  /// **'Set on map'**
  String get setPin;

  /// No description provided for @movePin.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get movePin;

  /// No description provided for @checkInRadiusLabel.
  ///
  /// In en, this message translates to:
  /// **'Check-in radius'**
  String get checkInRadiusLabel;

  /// No description provided for @metersShort.
  ///
  /// In en, this message translates to:
  /// **'{meters} m'**
  String metersShort(int meters);

  /// No description provided for @radiusHint.
  ///
  /// In en, this message translates to:
  /// **'Workers can check in within this distance of the pin. Use at least 150 m so leaving the site is detected reliably.'**
  String get radiusHint;

  /// No description provided for @contractorCompany.
  ///
  /// In en, this message translates to:
  /// **'Contractor company'**
  String get contractorCompany;

  /// No description provided for @contactPerson.
  ///
  /// In en, this message translates to:
  /// **'Contact person'**
  String get contactPerson;

  /// No description provided for @contactPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get contactPhone;

  /// No description provided for @enterValidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number'**
  String get enterValidPhone;

  /// No description provided for @createSite.
  ///
  /// In en, this message translates to:
  /// **'Create site'**
  String get createSite;

  /// No description provided for @editProject.
  ///
  /// In en, this message translates to:
  /// **'Edit project'**
  String get editProject;

  /// No description provided for @editMockup.
  ///
  /// In en, this message translates to:
  /// **'Edit mock-up'**
  String get editMockup;

  /// No description provided for @siteSaved.
  ///
  /// In en, this message translates to:
  /// **'Site saved'**
  String get siteSaved;

  /// No description provided for @siteSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the site. Check your connection and try again.'**
  String get siteSaveFailed;

  /// No description provided for @deleteSite.
  ///
  /// In en, this message translates to:
  /// **'Delete site'**
  String get deleteSite;

  /// No description provided for @deleteSiteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteSiteTitle(String name);

  /// No description provided for @deleteSiteBody.
  ///
  /// In en, this message translates to:
  /// **'The site is removed for good and {count} assigned people lose it from their list. Past attendance is kept.'**
  String deleteSiteBody(int count);

  /// No description provided for @placePin.
  ///
  /// In en, this message translates to:
  /// **'Place the site'**
  String get placePin;

  /// No description provided for @searchAddress.
  ///
  /// In en, this message translates to:
  /// **'Search an address or area'**
  String get searchAddress;

  /// No description provided for @addressNotFound.
  ///
  /// In en, this message translates to:
  /// **'Address not found. Try another search or move the map.'**
  String get addressNotFound;

  /// No description provided for @myLocation.
  ///
  /// In en, this message translates to:
  /// **'My location'**
  String get myLocation;

  /// No description provided for @usePinHere.
  ///
  /// In en, this message translates to:
  /// **'Use this location'**
  String get usePinHere;

  /// No description provided for @siteNotFound.
  ///
  /// In en, this message translates to:
  /// **'This site no longer exists.'**
  String get siteNotFound;

  /// No description provided for @newSite.
  ///
  /// In en, this message translates to:
  /// **'New site'**
  String get newSite;

  /// No description provided for @searchSites.
  ///
  /// In en, this message translates to:
  /// **'Search name, address or contractor'**
  String get searchSites;

  /// No description provided for @everything.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get everything;

  /// No description provided for @projectsLabel.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projectsLabel;

  /// No description provided for @mockupsLabel.
  ///
  /// In en, this message translates to:
  /// **'Mock-ups'**
  String get mockupsLabel;

  /// No description provided for @noSitesFound.
  ///
  /// In en, this message translates to:
  /// **'No sites match.'**
  String get noSitesFound;

  /// No description provided for @siteAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get siteAddress;

  /// No description provided for @callAction.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get callAction;

  /// No description provided for @helpersCount.
  ///
  /// In en, this message translates to:
  /// **'Helpers ({count})'**
  String helpersCount(int count);

  /// No description provided for @noHelpers.
  ///
  /// In en, this message translates to:
  /// **'No helpers assigned.'**
  String get noHelpers;

  /// No description provided for @noHelpersYet.
  ///
  /// In en, this message translates to:
  /// **'No helpers yet. Add one with the button above.'**
  String get noHelpersYet;

  /// No description provided for @helpersMax.
  ///
  /// In en, this message translates to:
  /// **'A mason can have at most {count} helpers.'**
  String helpersMax(int count);

  /// No description provided for @helpersOf.
  ///
  /// In en, this message translates to:
  /// **'Helpers · {name}'**
  String helpersOf(String name);

  /// No description provided for @addHelper.
  ///
  /// In en, this message translates to:
  /// **'Add helper'**
  String get addHelper;

  /// No description provided for @editHelper.
  ///
  /// In en, this message translates to:
  /// **'Edit helper'**
  String get editHelper;

  /// No description provided for @saveHelpers.
  ///
  /// In en, this message translates to:
  /// **'Save helpers'**
  String get saveHelpers;

  /// No description provided for @helpersSaved.
  ///
  /// In en, this message translates to:
  /// **'Helpers updated'**
  String get helpersSaved;

  /// No description provided for @helpersSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update the helpers.'**
  String get helpersSaveFailed;

  /// No description provided for @deleteHelperTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteHelperTitle(String name);

  /// No description provided for @deleteHelperBody.
  ///
  /// In en, this message translates to:
  /// **'They are removed from the helper list and from every mason they work with.'**
  String get deleteHelperBody;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get profileSaved;

  /// No description provided for @profileSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save your profile. Check your connection and try again.'**
  String get profileSaveFailed;

  /// No description provided for @sectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get sectionAccount;

  /// No description provided for @deleteMyAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get deleteMyAccount;

  /// No description provided for @deleteMyAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteMyAccountTitle;

  /// No description provided for @deleteMyAccountBody.
  ///
  /// In en, this message translates to:
  /// **'Your profile and login are deleted for good and you can no longer sign in. Attendance and pay records stay with the company. Enter your password to confirm.'**
  String get deleteMyAccountBody;

  /// No description provided for @errWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong password.'**
  String get errWrongPassword;

  /// No description provided for @deleteAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the account. Check your connection and try again.'**
  String get deleteAccountFailed;

  /// No description provided for @clientName.
  ///
  /// In en, this message translates to:
  /// **'Client name'**
  String get clientName;

  /// No description provided for @editClient.
  ///
  /// In en, this message translates to:
  /// **'Edit client'**
  String get editClient;

  /// No description provided for @deleteClient.
  ///
  /// In en, this message translates to:
  /// **'Delete client'**
  String get deleteClient;

  /// No description provided for @deleteClientTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteClientTitle(String name);

  /// No description provided for @deleteClientBody.
  ///
  /// In en, this message translates to:
  /// **'The client is removed from the list. Past visits keep the client\'s name.'**
  String get deleteClientBody;

  /// No description provided for @clientSaved.
  ///
  /// In en, this message translates to:
  /// **'Client saved'**
  String get clientSaved;

  /// No description provided for @clientSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the client. Check your connection and try again.'**
  String get clientSaveFailed;

  /// No description provided for @clientLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get clientLocation;

  /// No description provided for @clientLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Optional. A pin on the map lets you open directions later.'**
  String get clientLocationHint;

  /// No description provided for @placeClient.
  ///
  /// In en, this message translates to:
  /// **'Place the client'**
  String get placeClient;

  /// No description provided for @clientNotFound.
  ///
  /// In en, this message translates to:
  /// **'This client was deleted.'**
  String get clientNotFound;

  /// No description provided for @searchClients.
  ///
  /// In en, this message translates to:
  /// **'Search name, contact, phone or area'**
  String get searchClients;

  /// No description provided for @clientsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No clients} =1{1 client} other{{count} clients}}'**
  String clientsCount(int count);

  /// No description provided for @noClientsYet.
  ///
  /// In en, this message translates to:
  /// **'No clients yet. Add your first one with the button below.'**
  String get noClientsYet;

  /// No description provided for @noClientsFound.
  ///
  /// In en, this message translates to:
  /// **'No clients found'**
  String get noClientsFound;

  /// No description provided for @pinOnly.
  ///
  /// In en, this message translates to:
  /// **'Pinned on the map'**
  String get pinOnly;

  /// No description provided for @visitsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Visits} =1{1 visit} other{{count} visits}}'**
  String visitsCount(int count);

  /// No description provided for @noVisitsYet.
  ///
  /// In en, this message translates to:
  /// **'No visits recorded yet.'**
  String get noVisitsYet;

  /// No description provided for @noVisitsToday.
  ///
  /// In en, this message translates to:
  /// **'No visits recorded today.'**
  String get noVisitsToday;

  /// No description provided for @noVisitsInPeriod.
  ///
  /// In en, this message translates to:
  /// **'No visits in this period.'**
  String get noVisitsInPeriod;

  /// No description provided for @todaysVisits.
  ///
  /// In en, this message translates to:
  /// **'Today\'s visits ({count})'**
  String todaysVisits(int count);

  /// No description provided for @visitsSummary.
  ///
  /// In en, this message translates to:
  /// **'{total} visits · {clients} clients · {projects} projects'**
  String visitsSummary(int total, int clients, int projects);

  /// No description provided for @salesperson.
  ///
  /// In en, this message translates to:
  /// **'Salesperson'**
  String get salesperson;

  /// No description provided for @meLabel.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get meLabel;

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get last7Days;

  /// No description provided for @clientWord.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get clientWord;

  /// No description provided for @projectWord.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get projectWord;

  /// No description provided for @chooseClient.
  ///
  /// In en, this message translates to:
  /// **'Choose a client'**
  String get chooseClient;

  /// No description provided for @chooseProject.
  ///
  /// In en, this message translates to:
  /// **'Choose a project'**
  String get chooseProject;

  /// No description provided for @visitStepWho.
  ///
  /// In en, this message translates to:
  /// **'Who did you visit?'**
  String get visitStepWho;

  /// No description provided for @visitStepWhat.
  ///
  /// In en, this message translates to:
  /// **'What happened'**
  String get visitStepWhat;

  /// No description provided for @metWith.
  ///
  /// In en, this message translates to:
  /// **'Met with'**
  String get metWith;

  /// No description provided for @visitPurpose.
  ///
  /// In en, this message translates to:
  /// **'Purpose'**
  String get visitPurpose;

  /// No description provided for @choosePurpose.
  ///
  /// In en, this message translates to:
  /// **'Choose a purpose'**
  String get choosePurpose;

  /// No description provided for @visitNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get visitNotes;

  /// No description provided for @visitNotesHint.
  ///
  /// In en, this message translates to:
  /// **'What was discussed, agreed or promised?'**
  String get visitNotesHint;

  /// No description provided for @notesTooShort.
  ///
  /// In en, this message translates to:
  /// **'Write at least {min} characters ({count} so far)'**
  String notesTooShort(int min, int count);

  /// No description provided for @visitTime.
  ///
  /// In en, this message translates to:
  /// **'Visit time'**
  String get visitTime;

  /// No description provided for @rightNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get rightNow;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @saveVisit.
  ///
  /// In en, this message translates to:
  /// **'Save visit'**
  String get saveVisit;

  /// No description provided for @visitSaved.
  ///
  /// In en, this message translates to:
  /// **'Visit saved'**
  String get visitSaved;

  /// No description provided for @visitSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the visit. Check your connection and try again.'**
  String get visitSaveFailed;

  /// No description provided for @visitDetails.
  ///
  /// In en, this message translates to:
  /// **'Visit'**
  String get visitDetails;

  /// No description provided for @managerComment.
  ///
  /// In en, this message translates to:
  /// **'Manager\'s comment'**
  String get managerComment;

  /// No description provided for @managerCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Feedback or next steps for the salesperson'**
  String get managerCommentHint;

  /// No description provided for @noManagerComment.
  ///
  /// In en, this message translates to:
  /// **'No comment from your manager yet.'**
  String get noManagerComment;

  /// No description provided for @saveComment.
  ///
  /// In en, this message translates to:
  /// **'Save comment'**
  String get saveComment;

  /// No description provided for @purposeCollectPayment.
  ///
  /// In en, this message translates to:
  /// **'Collecting payment'**
  String get purposeCollectPayment;

  /// No description provided for @purposeRequestPayment.
  ///
  /// In en, this message translates to:
  /// **'Requesting payment'**
  String get purposeRequestPayment;

  /// No description provided for @purposeNewOrder.
  ///
  /// In en, this message translates to:
  /// **'New order'**
  String get purposeNewOrder;

  /// No description provided for @purposeOrderFollowUp.
  ///
  /// In en, this message translates to:
  /// **'Order follow-up'**
  String get purposeOrderFollowUp;

  /// No description provided for @purposeQuotationFollowUp.
  ///
  /// In en, this message translates to:
  /// **'Quotation follow-up'**
  String get purposeQuotationFollowUp;

  /// No description provided for @purposeSamples.
  ///
  /// In en, this message translates to:
  /// **'Sample submission'**
  String get purposeSamples;

  /// No description provided for @purposeComplaint.
  ///
  /// In en, this message translates to:
  /// **'Handling a complaint'**
  String get purposeComplaint;

  /// No description provided for @purposeNewProduct.
  ///
  /// In en, this message translates to:
  /// **'Presenting a new product'**
  String get purposeNewProduct;

  /// No description provided for @purposeProjectDiscussion.
  ///
  /// In en, this message translates to:
  /// **'Project discussion'**
  String get purposeProjectDiscussion;

  /// No description provided for @purposeNewClient.
  ///
  /// In en, this message translates to:
  /// **'New client'**
  String get purposeNewClient;

  /// No description provided for @purposeReestablish.
  ///
  /// In en, this message translates to:
  /// **'Re-establishing business'**
  String get purposeReestablish;

  /// No description provided for @purposeCatchUp.
  ///
  /// In en, this message translates to:
  /// **'Catch-up visit'**
  String get purposeCatchUp;

  /// No description provided for @purposeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get purposeOther;

  /// No description provided for @phoneProblems.
  ///
  /// In en, this message translates to:
  /// **'Phone problems'**
  String get phoneProblems;

  /// No description provided for @outsideSite.
  ///
  /// In en, this message translates to:
  /// **'Outside the site'**
  String get outsideSite;

  /// No description provided for @noLocationYet.
  ///
  /// In en, this message translates to:
  /// **'No location yet'**
  String get noLocationYet;

  /// No description provided for @locationUpdated.
  ///
  /// In en, this message translates to:
  /// **'Location updated {time}'**
  String locationUpdated(String time);

  /// No description provided for @distanceFromSite.
  ///
  /// In en, this message translates to:
  /// **'{distance} from {site}'**
  String distanceFromSite(String distance, String site);

  /// No description provided for @kilometersShort.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String kilometersShort(String km);

  /// No description provided for @showEveryone.
  ///
  /// In en, this message translates to:
  /// **'Show everyone'**
  String get showEveryone;

  /// No description provided for @peopleOnMap.
  ///
  /// In en, this message translates to:
  /// **'{located} of {total} on the map'**
  String peopleOnMap(int located, int total);

  /// No description provided for @newProjectHere.
  ///
  /// In en, this message translates to:
  /// **'New project here'**
  String get newProjectHere;

  /// No description provided for @newMockupHere.
  ///
  /// In en, this message translates to:
  /// **'New mock-up here'**
  String get newMockupHere;

  /// No description provided for @mapLegendTitle.
  ///
  /// In en, this message translates to:
  /// **'What the pins mean'**
  String get mapLegendTitle;

  /// No description provided for @legendOnSite.
  ///
  /// In en, this message translates to:
  /// **'On site, checked in'**
  String get legendOnSite;

  /// No description provided for @legendOutside.
  ///
  /// In en, this message translates to:
  /// **'Checked in, but outside the site'**
  String get legendOutside;

  /// No description provided for @legendProblem.
  ///
  /// In en, this message translates to:
  /// **'Phone problem (location off, battery saver…)'**
  String get legendProblem;

  /// No description provided for @legendNotCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'Not checked in today'**
  String get legendNotCheckedIn;

  /// No description provided for @legendStale.
  ///
  /// In en, this message translates to:
  /// **'Faded: location is over 2 hours old'**
  String get legendStale;

  /// No description provided for @legendSite.
  ///
  /// In en, this message translates to:
  /// **'Site and its check-in area'**
  String get legendSite;

  /// No description provided for @zoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get zoomIn;

  /// No description provided for @zoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get zoomOut;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orDivider;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @errAccountExists.
  ///
  /// In en, this message translates to:
  /// **'This email already has an account with a different sign-in method. Sign in with your email and password.'**
  String get errAccountExists;

  /// No description provided for @finishSignUp.
  ///
  /// In en, this message translates to:
  /// **'Finish signing up'**
  String get finishSignUp;

  /// No description provided for @signedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String signedInAs(String email);

  /// No description provided for @deleteMyAccountBodyProvider.
  ///
  /// In en, this message translates to:
  /// **'Your profile and login are deleted for good and you can no longer sign in. Attendance and pay records stay with the company. You\'ll confirm with your Google or Apple account.'**
  String get deleteMyAccountBodyProvider;

  /// No description provided for @waitingApproval.
  ///
  /// In en, this message translates to:
  /// **'Waiting for approval'**
  String get waitingApproval;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose which alerts send a notification to this phone. Every alert still shows in the app.'**
  String get notificationsIntro;

  /// No description provided for @notifyNewUsers.
  ///
  /// In en, this message translates to:
  /// **'New sign-ups'**
  String get notifyNewUsers;

  /// No description provided for @notifyLeftSite.
  ///
  /// In en, this message translates to:
  /// **'Worker left the site'**
  String get notifyLeftSite;

  /// No description provided for @notifyAutoCheckout.
  ///
  /// In en, this message translates to:
  /// **'Automatic check-outs'**
  String get notifyAutoCheckout;

  /// No description provided for @notifyPhoneProblemsHint.
  ///
  /// In en, this message translates to:
  /// **'Location off, not reporting, tracking stopped, fake GPS'**
  String get notifyPhoneProblemsHint;

  /// No description provided for @notificationsBlocked.
  ///
  /// In en, this message translates to:
  /// **'Notifications are blocked for Royal Marble in your phone settings.'**
  String get notificationsBlocked;
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
