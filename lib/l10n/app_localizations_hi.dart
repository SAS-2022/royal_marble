// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get languageName => 'हिन्दी';

  @override
  String get language => 'भाषा';

  @override
  String get chooseLanguage => 'भाषा चुनें';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get save => 'सेव करें';

  @override
  String get back => 'वापस';

  @override
  String get continueLabel => 'आगे बढ़ें';

  @override
  String get required => 'ज़रूरी';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get allow => 'अनुमति दें';

  @override
  String get fix => 'ठीक करें';

  @override
  String get turnOn => 'चालू करें';

  @override
  String get roleAdmin => 'एडमिन';

  @override
  String get roleSupervisor => 'सुपरवाइज़र';

  @override
  String get roleSales => 'सेल्स';

  @override
  String get roleSiteEngineer => 'साइट इंजीनियर';

  @override
  String get roleMason => 'मिस्त्री';

  @override
  String get welcomeBack => 'फिर से स्वागत है';

  @override
  String get signInToContinue => 'आगे बढ़ने के लिए साइन इन करें';

  @override
  String get email => 'ईमेल';

  @override
  String get password => 'पासवर्ड';

  @override
  String get enterValidEmail => 'सही ईमेल डालें';

  @override
  String get enterPassword => 'अपना पासवर्ड डालें';

  @override
  String get forgotPassword => 'पासवर्ड भूल गए?';

  @override
  String get signIn => 'साइन इन';

  @override
  String get newToApp => 'रॉयल मार्बल पर नए हैं?';

  @override
  String get createAccount => 'खाता बनाएँ';

  @override
  String get errInvalidEmail => 'यह ईमेल पता सही नहीं लग रहा।';

  @override
  String get errUserDisabled =>
      'यह खाता बंद कर दिया गया है। अपने एडमिन से संपर्क करें।';

  @override
  String get errTooManyRequests =>
      'बहुत ज़्यादा कोशिशें। कुछ मिनट रुककर फिर कोशिश करें।';

  @override
  String get errNoInternet => 'इंटरनेट कनेक्शन नहीं है।';

  @override
  String get errWrongCredentials => 'ईमेल या पासवर्ड गलत है।';

  @override
  String get errSignInGeneric => 'साइन इन नहीं हो सका। फिर कोशिश करें।';

  @override
  String get resetPassword => 'पासवर्ड रीसेट करें';

  @override
  String get resetIntro =>
      'जिस ईमेल से आप साइन इन करते हैं वह डालें, हम नया पासवर्ड चुनने का लिंक भेजेंगे।';

  @override
  String get sendResetLink => 'लिंक भेजें';

  @override
  String get checkYourEmail => 'अपना ईमेल देखें';

  @override
  String resetSent(String email) {
    return 'हमने $email पर रीसेट लिंक भेजा है।';
  }

  @override
  String get backToSignIn => 'साइन इन पर वापस जाएँ';

  @override
  String get resetError =>
      'ईमेल नहीं भेजा जा सका। पता जाँचें और फिर कोशिश करें।';

  @override
  String stepOf(int step, int total) {
    return 'चरण $step / $total';
  }

  @override
  String get stepAboutYou => 'आपके बारे में';

  @override
  String get stepContact => 'संपर्क';

  @override
  String get stepAccount => 'खाता';

  @override
  String get addPhotoHint => 'अपने चेहरे की साफ़ फ़ोटो लगाएँ';

  @override
  String get tapToChange => 'बदलने के लिए टैप करें';

  @override
  String get takePhoto => 'फ़ोटो लें';

  @override
  String get chooseFromGallery => 'गैलरी से चुनें';

  @override
  String get firstName => 'पहला नाम';

  @override
  String get lastName => 'उपनाम';

  @override
  String get nationality => 'राष्ट्रीयता';

  @override
  String get mobileNumber => 'मोबाइल नंबर';

  @override
  String get mobileInvalid => 'UAE मोबाइल नंबर डालें (05X XXX XXXX)';

  @override
  String get company => 'कंपनी';

  @override
  String get homeAddress => 'घर का पता';

  @override
  String get passwordHelper => 'कम से कम 6 अक्षर';

  @override
  String get passwordTooShort => 'कम से कम 6 अक्षर रखें';

  @override
  String get confirmPassword => 'पासवर्ड दोबारा डालें';

  @override
  String get passwordsDontMatch => 'पासवर्ड मेल नहीं खाते';

  @override
  String get approvalNotice =>
      'एडमिन नए खातों की जाँच करता है। मंज़ूरी मिलने के बाद आप साइन इन कर सकेंगे।';

  @override
  String get photoRequired =>
      'फ़ोटो लगाएँ ताकि आपका सुपरवाइज़र आपको पहचान सके।';

  @override
  String get nationalityRequired => 'अपनी राष्ट्रीयता चुनें।';

  @override
  String get homeRequired => 'नक्शे पर अपना घर का पता चुनें।';

  @override
  String get cameraError => 'कैमरा या गैलरी नहीं खुल सकी।';

  @override
  String get emailInUse => 'इस ईमेल से पहले से खाता है। साइन इन करके देखें।';

  @override
  String get registerFailed =>
      'खाता नहीं बन सका। अपनी जानकारी जाँचें और फिर कोशिश करें।';

  @override
  String get somethingWrong => 'कुछ गड़बड़ हो गई। फिर कोशिश करें।';

  @override
  String greetingMorning(String name) {
    return 'सुप्रभात, $name';
  }

  @override
  String greetingAfternoon(String name) {
    return 'नमस्ते, $name';
  }

  @override
  String greetingEvening(String name) {
    return 'शुभ संध्या, $name';
  }

  @override
  String get offlineBanner =>
      'आप ऑफ़लाइन हैं। कनेक्शन आने पर बदलाव अपने-आप भेज दिए जाएँगे।';

  @override
  String get pendingTitle => 'रजिस्टर करने के लिए धन्यवाद';

  @override
  String get pendingBody =>
      'आपका खाता मंज़ूरी का इंतज़ार कर रहा है। एडमिन के चालू करने के बाद आप ऐप इस्तेमाल कर सकेंगे।';

  @override
  String get yourSite => 'आपकी साइट';

  @override
  String get yourSites => 'आपकी साइटें';

  @override
  String get noSiteTitle => 'अभी कोई साइट नहीं दी गई';

  @override
  String get noSiteBody => 'आपका सुपरवाइज़र आपको किसी प्रोजेक्ट पर लगाएगा।';

  @override
  String get noSitesAssigned => 'कोई साइट नहीं दी गई।';

  @override
  String yourTeam(int count) {
    return 'आपकी टीम ($count)';
  }

  @override
  String get nobodyYet => 'अभी कोई नहीं।';

  @override
  String onSiteAtSince(String site, String time) {
    return '$site पर $time से मौजूद';
  }

  @override
  String get checkedOut => 'चेक आउट किया';

  @override
  String get notCheckedIn => 'चेक इन नहीं किया';

  @override
  String durationHm(int hours, int minutes) {
    return '$hours घं $minutes मि';
  }

  @override
  String durationM(int minutes) {
    return '$minutes मि';
  }

  @override
  String onSiteSince(String time, String duration) {
    return '$time से साइट पर · $duration';
  }

  @override
  String checkedInAtSite(String site) {
    return '$site पर चेक इन';
  }

  @override
  String doneToday(String duration) {
    return 'आज का काम पूरा · $duration';
  }

  @override
  String get withinSiteArea => 'साइट के दायरे में';

  @override
  String kmAway(String km) {
    return '$km किमी दूर';
  }

  @override
  String metersAway(int meters) {
    return '$meters मीटर दूर';
  }

  @override
  String get gettingGpsFix => 'सटीक GPS लोकेशन ली जा रही है…';

  @override
  String get checkIn => 'चेक इन';

  @override
  String get checkOut => 'चेक आउट';

  @override
  String get workCompletedTitle => 'आज किया गया काम';

  @override
  String get workSystem => 'सिस्टम';

  @override
  String get workTiles => 'टाइल्स';

  @override
  String get workOthers => 'अन्य';

  @override
  String get describeWork => 'काम के बारे में लिखें';

  @override
  String get areaCompleted => 'पूरा किया गया क्षेत्र';

  @override
  String get enterNumber => 'संख्या डालें';

  @override
  String checkedInAt(String time) {
    return '$time पर चेक इन हो गया। आपका दिन अच्छा हो!';
  }

  @override
  String checkedOutAt(String time) {
    return '$time पर चेक आउट हो गया। धन्यवाद!';
  }

  @override
  String get errLocationUnavailable =>
      'आपकी लोकेशन नहीं मिल सकी। लोकेशन चालू करके फिर कोशिश करें।';

  @override
  String get errNoServer =>
      'सर्वर से कनेक्शन नहीं है। इंटरनेट जाँचें और फिर कोशिश करें।';

  @override
  String errCheckInFailed(String code) {
    return 'चेक इन नहीं हो सका ($code)।';
  }

  @override
  String get errSignInAgain => 'कृपया फिर से साइन इन करें।';

  @override
  String get errNotActive => 'आपका खाता चालू नहीं है।';

  @override
  String get errMockLocation =>
      'नकली GPS ऐप मिला है। चेक इन के लिए उसे बंद करें।';

  @override
  String errWeakGps(int meters) {
    return 'GPS सिग्नल कमज़ोर है (±$meters मी)। बाहर खुली जगह जाएँ या थोड़ा रुककर फिर कोशिश करें।';
  }

  @override
  String get errNoSiteLocation =>
      'इस साइट की लोकेशन सेट नहीं है। एडमिन से संपर्क करें।';

  @override
  String errOutOfRange(int meters) {
    return 'आप साइट से $meters मीटर बाहर हैं।';
  }

  @override
  String errAlreadyCheckedIn(String site) {
    return 'आप पहले से $site पर चेक इन हैं।';
  }

  @override
  String get errNotCheckedIn => 'आपने चेक इन नहीं किया है।';

  @override
  String errCheckedInElsewhere(String site) {
    return 'आप $site पर चेक इन हैं। पहले वहाँ से चेक आउट करें।';
  }

  @override
  String get errNotAssigned => 'आप इस साइट पर नियुक्त नहीं हैं।';

  @override
  String get trackingActive => 'ट्रैकिंग चालू है';

  @override
  String get waitingForGps => 'GPS का इंतज़ार…';

  @override
  String gpsAccuracy(int meters) {
    return 'GPS सटीकता ±$meters मी';
  }

  @override
  String get locationOffTitle => 'लोकेशन बंद है';

  @override
  String get locationOffBody =>
      'आपके एडमिन को सूचना दे दी गई है। आगे बढ़ने के लिए इसे चालू करें।';

  @override
  String get allowAlwaysTitle => 'लोकेशन \"हर समय\" की अनुमति दें';

  @override
  String get allowAlwaysBody =>
      'ऐप बंद होने पर भी चेक इन काम करे, इसके लिए ज़रूरी है।';

  @override
  String get preciseOffTitle => 'सटीक लोकेशन बंद है';

  @override
  String get preciseOffBody => 'इस ऐप के लिए \"सटीक लोकेशन\" चालू करें।';

  @override
  String get noInternetTitle => 'इंटरनेट कनेक्शन नहीं है';

  @override
  String get noInternetBody =>
      'लोकेशन सेव हो रही है और कनेक्शन आने पर भेज दी जाएगी।';

  @override
  String get batterySaverTitle => 'बैटरी सेवर चालू है';

  @override
  String get batterySaverBody =>
      'ट्रैकिंग में देरी हो सकती है। काम के समय इसे बंद रखें।';

  @override
  String get batteryOptTitle => 'बैटरी ऑप्टिमाइज़ेशन चालू है';

  @override
  String get batteryOptBody => 'आपका फ़ोन बैकग्राउंड में ट्रैकिंग रोक सकता है।';

  @override
  String get myPay => 'मेरा वेतन';

  @override
  String get yourPackage => 'आपका वेतन विवरण';

  @override
  String get payNotAddedTitle => 'आपका वेतन विवरण अभी नहीं जोड़ा गया है।';

  @override
  String get payNotAddedBody =>
      'अगर आपको लगता है कि यह गलती है तो अपने एडमिन से पूछें।';

  @override
  String get payTypeMonthly => 'मासिक वेतन';

  @override
  String get payTypeDaily => 'दैनिक मज़दूरी';

  @override
  String get payTypeHourly => 'घंटे के हिसाब से';

  @override
  String get perMonth => '/ महीना';

  @override
  String get perDay => '/ दिन';

  @override
  String get perHour => '/ घंटा';

  @override
  String get basic => 'मूल वेतन';

  @override
  String get housing => 'आवास भत्ता';

  @override
  String get transportation => 'यातायात भत्ता';

  @override
  String get food => 'भोजन भत्ता';

  @override
  String get totalPerMonth => 'कुल मासिक';

  @override
  String get allowancesMonthly => 'भत्ते मासिक राशि हैं।';

  @override
  String effectiveFrom(String date) {
    return '$date से';
  }

  @override
  String get myProfile => 'मेरी प्रोफ़ाइल';

  @override
  String get sectionTeam => 'टीम';

  @override
  String get teamStatusAlerts => 'टीम की स्थिति और अलर्ट';

  @override
  String get liveMap => 'लाइव मैप';

  @override
  String get users => 'यूज़र';

  @override
  String get sectionSites => 'साइटें';

  @override
  String get newProject => 'नया प्रोजेक्ट';

  @override
  String get newMockup => 'नया मॉक-अप';

  @override
  String get sectionSales => 'सेल्स';

  @override
  String get clients => 'क्लाइंट';

  @override
  String get addClient => 'क्लाइंट जोड़ें';

  @override
  String get newVisit => 'नई विज़िट';

  @override
  String get visits => 'विज़िट';

  @override
  String get sectionReports => 'रिपोर्ट';

  @override
  String get attendance => 'हाज़िरी';

  @override
  String get salesActivity => 'सेल्स गतिविधि';

  @override
  String get signOut => 'साइन आउट';

  @override
  String get signOutTitle => 'साइन आउट करें?';

  @override
  String get signOutBody =>
      'लोकेशन ट्रैकिंग बंद हो जाएगी और दोबारा साइन इन करने तक आप चेक इन नहीं कर पाएँगे।';

  @override
  String get teamStatus => 'टीम की स्थिति';

  @override
  String get onSiteNow => 'अभी साइट पर';

  @override
  String get phoneAlerts => 'फ़ोन अलर्ट';

  @override
  String get pendingLabel => 'लंबित';

  @override
  String get needsAttention => 'ध्यान देने की ज़रूरत';

  @override
  String get seeAll => 'सब देखें';

  @override
  String get todaysAttendance => 'आज की हाज़िरी';

  @override
  String get alertLog => 'अलर्ट लॉग';

  @override
  String activeProjects(int count) {
    return 'चालू प्रोजेक्ट ($count)';
  }

  @override
  String activeMockups(int count) {
    return 'चालू मॉक-अप ($count)';
  }

  @override
  String potentialProjects(int count) {
    return 'संभावित प्रोजेक्ट ($count)';
  }

  @override
  String get nobodyCheckedInToday => 'आज अभी तक किसी ने चेक इन नहीं किया।';

  @override
  String get details => 'विवरण';

  @override
  String get changeStatus => 'स्थिति बदलें';

  @override
  String get myVisits => 'मेरी विज़िट';

  @override
  String get site => 'साइट';

  @override
  String get problemSilent => 'रिपोर्ट नहीं कर रहा';

  @override
  String get problemLocationOff => 'लोकेशन बंद';

  @override
  String problemPermission(String value) {
    return 'अनुमति: $value';
  }

  @override
  String get problemTrackingStopped => 'ट्रैकिंग बंद';

  @override
  String get problemOffline => 'ऑफ़लाइन';

  @override
  String get problemApproximate => 'अनुमानित लोकेशन';

  @override
  String get problemBatterySaver => 'बैटरी सेवर चालू';

  @override
  String problemBattery(int percent) {
    return 'बैटरी $percent%';
  }

  @override
  String get permWhenInUse => 'उपयोग के दौरान';

  @override
  String get permDenied => 'अस्वीकृत';

  @override
  String get permRestricted => 'प्रतिबंधित';

  @override
  String get permNotDetermined => 'तय नहीं';

  @override
  String get permAlways => 'हर समय';

  @override
  String get unknownUser => 'अज्ञात';

  @override
  String get timeNever => 'कभी नहीं';

  @override
  String get timeJustNow => 'अभी-अभी';

  @override
  String timeMinAgo(int n) {
    return '$n मिनट पहले';
  }

  @override
  String timeHoursAgo(int n) {
    return '$n घंटे पहले';
  }

  @override
  String seenAgo(String when) {
    return 'देखा गया $when';
  }

  @override
  String lastSeen(String when) {
    return 'आख़िरी बार $when';
  }

  @override
  String get phonesTab => 'फ़ोन';

  @override
  String get alertsTab => 'अलर्ट';

  @override
  String get noActiveWorkers => 'कोई सक्रिय कामगार नहीं';

  @override
  String get notOnNewApp => 'अभी नए ऐप पर नहीं';

  @override
  String get allGood => 'सब ठीक';

  @override
  String gpsShort(int meters) {
    return 'GPS ±$meters मी';
  }

  @override
  String get alertsNotEnabled => 'सर्वर पर अलर्ट अभी चालू नहीं हैं।';

  @override
  String get alertsLoadError => 'अलर्ट लोड नहीं हो सके। कनेक्शन जाँचें।';

  @override
  String get noAlertsYet => 'अभी कोई अलर्ट नहीं';

  @override
  String get evLocationOff => 'लोकेशन सेवा बंद की गई';

  @override
  String get evLocationOn => 'लोकेशन सेवा फिर चालू की गई';

  @override
  String get evGpsOff => 'GPS बंद (सिर्फ़ नेटवर्क लोकेशन)';

  @override
  String get evGpsOn => 'GPS फिर चालू';

  @override
  String get evPreciseOff => 'सटीक लोकेशन बंद की गई';

  @override
  String get evPreciseOn => 'सटीक लोकेशन फिर चालू';

  @override
  String evPermission(String value) {
    return 'लोकेशन अनुमति बदलकर \"$value\" हुई';
  }

  @override
  String get evOffline => 'फ़ोन का इंटरनेट कनेक्शन टूट गया';

  @override
  String get evOnline => 'फ़ोन फिर ऑनलाइन है';

  @override
  String get evPowerSaveOn => 'बैटरी सेवर चालू (ट्रैकिंग में देरी हो सकती है)';

  @override
  String get evPowerSaveOff => 'बैटरी सेवर बंद';

  @override
  String get evTrackingStopped => 'लोकेशन ट्रैकिंग रुक गई';

  @override
  String get evTrackingStarted => 'लोकेशन ट्रैकिंग शुरू हुई';

  @override
  String get evAppClosed => 'ऐप बंद किया गया (ट्रैकिंग जारी है)';

  @override
  String get evDeviceBoot => 'फ़ोन रीस्टार्ट हुआ';

  @override
  String get evMock => 'नकली GPS लोकेशन पकड़ी गई';

  @override
  String get evMockCleared => 'असली GPS वापस आया';

  @override
  String evBatteryLow(int percent) {
    return 'बैटरी कम ($percent%)';
  }

  @override
  String get evBatteryOk => 'बैटरी ठीक हुई';

  @override
  String get evSilent =>
      'फ़ोन ने रिपोर्ट करना बंद कर दिया। फ़ोन बंद, ऑफ़लाइन, या ऐप ज़बरदस्ती बंद हो सकता है।';

  @override
  String get usersAll => 'सभी';

  @override
  String activeTab(int count) {
    return 'सक्रिय ($count)';
  }

  @override
  String pendingTab(int count) {
    return 'लंबित ($count)';
  }

  @override
  String get searchUsers => 'नाम, ईमेल या फ़ोन से खोजें';

  @override
  String get noActiveUsersMatch => 'कोई सक्रिय यूज़र नहीं मिला।';

  @override
  String get nobodyWaiting => 'कोई मंज़ूरी का इंतज़ार नहीं कर रहा।';

  @override
  String get review => 'समीक्षा';

  @override
  String roleChangedTo(String role) {
    return 'भूमिका बदलकर $role की गई';
  }

  @override
  String get roleChangeFailed => 'भूमिका नहीं बदली जा सकी।';

  @override
  String get accountActivated => 'खाता चालू किया गया';

  @override
  String get accountDeactivated => 'खाता बंद किया गया';

  @override
  String get accessUpdateFailed => 'पहुँच अपडेट नहीं हो सकी।';

  @override
  String deleteUserTitle(String name) {
    return '$name को हटाएँ?';
  }

  @override
  String get deleteUserBody =>
      'प्रोफ़ाइल स्थायी रूप से हट जाएगी। पुरानी हाज़िरी बनी रहेगी।';

  @override
  String get delete => 'हटाएँ';

  @override
  String get statusActive => 'सक्रिय';

  @override
  String get statusPendingInactive => 'लंबित / निष्क्रिय';

  @override
  String get waitingForAccess => 'यह खाता पहुँच का इंतज़ार कर रहा है।';

  @override
  String get approve => 'मंज़ूर करें';

  @override
  String get sectionContact => 'संपर्क';

  @override
  String get sectionWork => 'काम';

  @override
  String get noSiteAssigned => 'कोई साइट नहीं दी गई';

  @override
  String get assignedSite => 'नियुक्त साइट';

  @override
  String get phoneReportingNormally => 'फ़ोन सामान्य रूप से रिपोर्ट कर रहा है';

  @override
  String get recentAlerts => 'हाल के अलर्ट';

  @override
  String get sectionPay => 'वेतन';

  @override
  String get sectionRole => 'भूमिका';

  @override
  String get sectionAccess => 'पहुँच';

  @override
  String get deactivateAccount => 'खाता बंद करें';

  @override
  String get activateAccount => 'खाता चालू करें';

  @override
  String get deactivateBeforeDeleting => 'हटाने से पहले खाता बंद करें';

  @override
  String get deletePermanently => 'खाता स्थायी रूप से हटाएँ';

  @override
  String get userTitle => 'यूज़र';

  @override
  String get project => 'प्रोजेक्ट';

  @override
  String get mockup => 'मॉक-अप';

  @override
  String get edit => 'बदलें';

  @override
  String checkInRadius(int meters) {
    return 'चेक इन दायरा $meters मी';
  }

  @override
  String get directions => 'रास्ता';

  @override
  String get today => 'आज';

  @override
  String get contractor => 'ठेकेदार';

  @override
  String teamCount(int count) {
    return 'टीम ($count)';
  }

  @override
  String get manage => 'प्रबंधन';

  @override
  String get nobodyAssigned => 'अभी कोई नियुक्त नहीं।';

  @override
  String peopleAssigned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count लोग नियुक्त।',
      one: '1 व्यक्ति नियुक्त।',
    );
    return '$_temp0';
  }

  @override
  String get onSite => 'साइट पर';

  @override
  String get away => 'बाहर';

  @override
  String get teamUpdated => 'टीम अपडेट हुई';

  @override
  String get teamUpdateFailed => 'टीम अपडेट नहीं हो सकी।';

  @override
  String teamOf(String site) {
    return 'टीम · $site';
  }

  @override
  String selectedCount(int count) {
    return '$count चुने गए';
  }

  @override
  String get searchPeople => 'लोग खोजें';

  @override
  String get saveTeam => 'टीम सेव करें';

  @override
  String currentlyAt(String site) {
    return '$site पर भी';
  }

  @override
  String get payUnavailable => 'वेतन विवरण अभी उपलब्ध नहीं।';

  @override
  String get noPayDetails => 'अभी कोई वेतन विवरण नहीं।';

  @override
  String get setPayDetails => 'वेतन विवरण जोड़ें';

  @override
  String get editPayDetails => 'वेतन विवरण बदलें';

  @override
  String get paySaved => 'वेतन विवरण सेव हुआ';

  @override
  String get enterValidAmount => 'सही राशि डालें';

  @override
  String payFor(String name) {
    return 'वेतन · $name';
  }

  @override
  String get monthly => 'मासिक';

  @override
  String get daily => 'दैनिक';

  @override
  String get hourly => 'घंटे के हिसाब';

  @override
  String get monthlyAllowances => 'मासिक भत्ते';

  @override
  String get allowance => 'भत्ता';

  @override
  String get nameIt => 'नाम लिखें';

  @override
  String get amount => 'राशि';

  @override
  String get addAllowance => 'एक और भत्ता जोड़ें';

  @override
  String get effectiveFromLabel => 'किस तारीख़ से लागू';

  @override
  String get notesOptional => 'नोट्स (वैकल्पिक)';

  @override
  String get summary => 'सारांश';

  @override
  String get savePayDetails => 'वेतन विवरण सेव करें';

  @override
  String get yesterday => 'कल';

  @override
  String get thisWeek => 'इस हफ़्ते';

  @override
  String get lastWeek => 'पिछले हफ़्ते';

  @override
  String get thisMonth => 'इस महीने';

  @override
  String get lastMonth => 'पिछले महीने';

  @override
  String get customRange => 'कस्टम…';

  @override
  String get reportLoadError => 'रिपोर्ट लोड नहीं हो सकी। कनेक्शन जाँचें।';

  @override
  String get nothingToExport => 'इस अवधि के लिए निर्यात करने को कुछ नहीं।';

  @override
  String get pdfSubtitle => 'देखें, प्रिंट करें या शेयर करें';

  @override
  String get excelSubtitle => 'दैनिक प्रविष्टियाँ और सारांश शीट';

  @override
  String get export => 'निर्यात';

  @override
  String get everyone => 'सभी';

  @override
  String get rolesMasons => 'मिस्त्री';

  @override
  String get rolesSiteEngineers => 'साइट इंजीनियर';

  @override
  String get rolesSupervisors => 'सुपरवाइज़र';

  @override
  String get people => 'लोग';

  @override
  String get hours => 'घंटे';

  @override
  String get areaM2 => 'क्षेत्र मी²';

  @override
  String missingCheckouts(int count) {
    return 'बिना चेक आउट की प्रविष्टियाँ: $count। उनके घंटे नहीं गिने गए।';
  }

  @override
  String get viewBy => 'इसके अनुसार देखें';

  @override
  String get person => 'व्यक्ति';

  @override
  String get day => 'दिन';

  @override
  String get noAttendance => 'इस अवधि में कोई हाज़िरी नहीं।';

  @override
  String get noSalesTeam => 'सेल्स टीम में कोई नहीं।';

  @override
  String get salespeople => 'सेल्सपर्सन';

  @override
  String get noVisits => 'इस अवधि में कोई विज़िट नहीं।';

  @override
  String get client => 'क्लाइंट';

  @override
  String get noOut => 'चेक आउट नहीं';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count दिन',
    );
    return '$_temp0';
  }

  @override
  String salesSummary(int days, int client, int project) {
    return '$days कार्य दिवस · $client क्लाइंट · $project प्रोजेक्ट विज़िट';
  }

  @override
  String peopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count लोग',
      one: '1 व्यक्ति',
    );
    return '$_temp0';
  }

  @override
  String get nowLabel => 'अभी';

  @override
  String get switchHere => 'इस साइट पर जाएँ';

  @override
  String get switchSiteTitle => 'साइट बदलें?';

  @override
  String switchSiteBody(String from, String to) {
    return 'आपको $from से चेक-आउट और $to पर चेक-इन किया जाएगा।';
  }

  @override
  String outsideSiteSince(String time) {
    return '$time से साइट के बाहर';
  }

  @override
  String get autoCheckedOut => 'अपने-आप चेक-आउट हुआ';

  @override
  String evLeftSite(String site) {
    return 'चेक-इन रहते हुए $site से बाहर गया';
  }

  @override
  String evReturnedToSite(String site) {
    return '$site पर वापस आया';
  }

  @override
  String evAutoCheckout(String site) {
    return '$site से अपने-आप चेक-आउट हुआ';
  }

  @override
  String get allSites => 'सभी साइटें';

  @override
  String autoCheckoutsToReview(int count) {
    return 'समीक्षा के लिए अपने-आप हुए चेक-आउट: $count।';
  }

  @override
  String autoCheckoutsToReviewTap(int count) {
    return 'समीक्षा के लिए अपने-आप हुए चेक-आउट: $count। ठीक करने या मंज़ूर करने के लिए किसी प्रविष्टि पर टैप करें।';
  }

  @override
  String awayFor(String duration) {
    return '$duration बाहर';
  }

  @override
  String get autoLeftSiteShort => 'अपने-आप: साइट छोड़ी';

  @override
  String get autoEndOfDayShort => 'अपने-आप: दिन का अंत';

  @override
  String get editedByAdmin => 'संपादित';

  @override
  String noOutCount(int count) {
    return '$count बिना चेक-आउट';
  }

  @override
  String get errEndBeforeStart => 'चेक-आउट, चेक-इन के बाद होना चाहिए।';

  @override
  String get errOnlyLastOpen =>
      'केवल आख़िरी प्रविष्टि बिना चेक-आउट के छोड़ी जा सकती है।';

  @override
  String get errSessionsOverlap =>
      'दो प्रविष्टियों का समय टकरा रहा है। समय ठीक करें।';

  @override
  String get attendanceSaved => 'हाज़िरी सहेजी गई';

  @override
  String get errNotAdmin => 'केवल एडमिन हाज़िरी सुधार सकते हैं।';

  @override
  String get reviewHint =>
      'सिस्टम ने यह दिन अपने-आप बंद किया। ज़रूरत हो तो समय ठीक करें, या जैसा है वैसा मंज़ूर करें।';

  @override
  String get addSession => 'प्रविष्टि जोड़ें';

  @override
  String get correctionNote => 'कारण';

  @override
  String get correctionNoteHint =>
      'जैसे: चेक-आउट भूल गया, सुपरवाइज़र ने पुष्टि की';

  @override
  String get saveChanges => 'बदलाव सहेजें';

  @override
  String get approveAsIs => 'जैसा है वैसा मंज़ूर करें';

  @override
  String get correctionHistory => 'बदलाव का इतिहास';

  @override
  String previously(String sessions) {
    return 'पहले: $sessions';
  }

  @override
  String get removeSession => 'यह प्रविष्टि हटाएँ';

  @override
  String get inLabel => 'इन';

  @override
  String get outLabel => 'आउट';

  @override
  String get setCheckOut => 'चेक-आउट समय डालें';

  @override
  String get leaveOpen => 'खुला छोड़ें (अभी साइट पर है)';

  @override
  String get leftAt => 'बाहर गया';

  @override
  String get returnedAt => 'वापस आया';

  @override
  String get siteStatusActive => 'चालू';

  @override
  String get siteStatusPotential => 'संभावित';

  @override
  String get siteStatusClosed => 'बंद';

  @override
  String get siteStatus => 'स्थिति';

  @override
  String get siteName => 'साइट का नाम';

  @override
  String get siteDetails => 'विवरण (वैकल्पिक)';

  @override
  String get siteLocation => 'लोकेशन';

  @override
  String get noPinYet => 'अभी लोकेशन तय नहीं है';

  @override
  String get pinRequired => 'नक्शे पर साइट की जगह तय करें।';

  @override
  String get setPin => 'नक्शे पर तय करें';

  @override
  String get movePin => 'बदलें';

  @override
  String get checkInRadiusLabel => 'चेक-इन दायरा';

  @override
  String metersShort(int meters) {
    return '$meters मी';
  }

  @override
  String get radiusHint =>
      'कर्मचारी पिन से इतनी दूरी के भीतर चेक-इन कर सकते हैं। साइट छोड़ने का सही पता चले, इसके लिए कम से कम 150 मी रखें।';

  @override
  String get contractorCompany => 'ठेकेदार कंपनी';

  @override
  String get contactPerson => 'संपर्क व्यक्ति';

  @override
  String get contactPhone => 'फ़ोन';

  @override
  String get enterValidPhone => 'सही फ़ोन नंबर डालें';

  @override
  String get createSite => 'साइट बनाएँ';

  @override
  String get editProject => 'प्रोजेक्ट संपादित करें';

  @override
  String get editMockup => 'मॉक-अप संपादित करें';

  @override
  String get siteSaved => 'साइट सहेजी गई';

  @override
  String get siteSaveFailed =>
      'साइट सहेजी नहीं जा सकी। कनेक्शन जाँचें और फिर कोशिश करें।';

  @override
  String get deleteSite => 'साइट हटाएँ';

  @override
  String deleteSiteTitle(String name) {
    return '$name हटाएँ?';
  }

  @override
  String deleteSiteBody(int count) {
    return 'साइट हमेशा के लिए हट जाएगी और $count लोगों की सूची से निकल जाएगी। पुरानी हाज़िरी बनी रहेगी।';
  }

  @override
  String get placePin => 'साइट की जगह तय करें';

  @override
  String get searchAddress => 'पता या इलाका खोजें';

  @override
  String get addressNotFound => 'पता नहीं मिला। कुछ और खोजें या नक्शा खिसकाएँ।';

  @override
  String get myLocation => 'मेरी लोकेशन';

  @override
  String get usePinHere => 'यह लोकेशन चुनें';

  @override
  String get siteNotFound => 'यह साइट अब मौजूद नहीं है।';

  @override
  String get newSite => 'नई साइट';

  @override
  String get searchSites => 'नाम, पता या ठेकेदार खोजें';

  @override
  String get everything => 'सभी';

  @override
  String get projectsLabel => 'प्रोजेक्ट';

  @override
  String get mockupsLabel => 'मॉक-अप';

  @override
  String get noSitesFound => 'कोई मेल खाती साइट नहीं।';

  @override
  String get siteAddress => 'पता';

  @override
  String get callAction => 'कॉल करें';

  @override
  String helpersCount(int count) {
    return 'सहायक ($count)';
  }

  @override
  String get noHelpers => 'कोई सहायक नियुक्त नहीं।';

  @override
  String get noHelpersYet => 'अभी कोई सहायक नहीं। ऊपर के बटन से जोड़ें।';

  @override
  String helpersMax(int count) {
    return 'एक मिस्त्री के अधिकतम $count सहायक हो सकते हैं।';
  }

  @override
  String helpersOf(String name) {
    return 'सहायक · $name';
  }

  @override
  String get addHelper => 'सहायक जोड़ें';

  @override
  String get editHelper => 'सहायक संपादित करें';

  @override
  String get saveHelpers => 'सहायक सहेजें';

  @override
  String get helpersSaved => 'सहायक अपडेट हुए';

  @override
  String get helpersSaveFailed => 'सहायक अपडेट नहीं हो सके।';

  @override
  String deleteHelperTitle(String name) {
    return '$name हटाएँ?';
  }

  @override
  String get deleteHelperBody =>
      'उन्हें सहायक सूची से और हर उस मिस्त्री से हटा दिया जाएगा जिसके साथ वे काम करते हैं।';

  @override
  String get profileSaved => 'प्रोफ़ाइल सहेजी गई';

  @override
  String get profileSaveFailed =>
      'प्रोफ़ाइल सहेजी नहीं जा सकी। कनेक्शन जाँचें और फिर कोशिश करें।';

  @override
  String get sectionAccount => 'खाता';

  @override
  String get deleteMyAccount => 'मेरा खाता हटाएँ';

  @override
  String get deleteMyAccountTitle => 'अपना खाता हटाएँ?';

  @override
  String get deleteMyAccountBody =>
      'आपकी प्रोफ़ाइल और लॉगिन हमेशा के लिए हट जाएँगे और आप फिर साइन इन नहीं कर पाएँगे। हाज़िरी और वेतन रिकॉर्ड कंपनी के पास रहेंगे। पुष्टि के लिए पासवर्ड डालें।';

  @override
  String get errWrongPassword => 'गलत पासवर्ड।';

  @override
  String get deleteAccountFailed =>
      'खाता हटाया नहीं जा सका। कनेक्शन जाँचें और फिर कोशिश करें।';

  @override
  String get clientName => 'क्लाइंट का नाम';

  @override
  String get editClient => 'क्लाइंट बदलें';

  @override
  String get deleteClient => 'क्लाइंट हटाएँ';

  @override
  String deleteClientTitle(String name) {
    return '$name को हटाएँ?';
  }

  @override
  String get deleteClientBody =>
      'क्लाइंट सूची से हट जाएगा। पिछली विज़िट में क्लाइंट का नाम बना रहेगा।';

  @override
  String get clientSaved => 'क्लाइंट सेव हो गया';

  @override
  String get clientSaveFailed =>
      'क्लाइंट सेव नहीं हो सका। कनेक्शन जाँचें और फिर कोशिश करें।';

  @override
  String get clientLocation => 'जगह';

  @override
  String get clientLocationHint =>
      'वैकल्पिक। नक्शे पर पिन से बाद में रास्ता खोल सकते हैं।';

  @override
  String get placeClient => 'क्लाइंट की जगह चुनें';

  @override
  String get clientNotFound => 'यह क्लाइंट हटा दिया गया है।';

  @override
  String get searchClients => 'नाम, संपर्क, फ़ोन या इलाका खोजें';

  @override
  String clientsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count क्लाइंट',
      one: '1 क्लाइंट',
      zero: 'कोई क्लाइंट नहीं',
    );
    return '$_temp0';
  }

  @override
  String get noClientsYet =>
      'अभी कोई क्लाइंट नहीं। नीचे के बटन से पहला जोड़ें।';

  @override
  String get noClientsFound => 'कोई क्लाइंट नहीं मिला';

  @override
  String get pinOnly => 'नक्शे पर पिन किया गया';

  @override
  String visitsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count विज़िट',
      one: '1 विज़िट',
      zero: 'विज़िट',
    );
    return '$_temp0';
  }

  @override
  String get noVisitsYet => 'अभी कोई विज़िट दर्ज नहीं।';

  @override
  String get noVisitsToday => 'आज कोई विज़िट दर्ज नहीं।';

  @override
  String get noVisitsInPeriod => 'इस अवधि में कोई विज़िट नहीं।';

  @override
  String todaysVisits(int count) {
    return 'आज की विज़िट ($count)';
  }

  @override
  String visitsSummary(int total, int clients, int projects) {
    return '$total विज़िट · $clients क्लाइंट · $projects प्रोजेक्ट';
  }

  @override
  String get salesperson => 'सेल्सपर्सन';

  @override
  String get meLabel => 'मैं';

  @override
  String get last7Days => 'पिछले 7 दिन';

  @override
  String get clientWord => 'क्लाइंट';

  @override
  String get projectWord => 'प्रोजेक्ट';

  @override
  String get chooseClient => 'क्लाइंट चुनें';

  @override
  String get chooseProject => 'प्रोजेक्ट चुनें';

  @override
  String get visitStepWho => 'आप किससे मिले?';

  @override
  String get visitStepWhat => 'क्या हुआ';

  @override
  String get metWith => 'किससे मिले';

  @override
  String get visitPurpose => 'उद्देश्य';

  @override
  String get choosePurpose => 'उद्देश्य चुनें';

  @override
  String get visitNotes => 'नोट्स';

  @override
  String get visitNotesHint => 'क्या बात हुई, क्या तय हुआ या क्या वादा हुआ?';

  @override
  String notesTooShort(int min, int count) {
    return 'कम से कम $min अक्षर लिखें (अभी $count)';
  }

  @override
  String get visitTime => 'विज़िट का समय';

  @override
  String get rightNow => 'अभी';

  @override
  String get change => 'बदलें';

  @override
  String get saveVisit => 'विज़िट सेव करें';

  @override
  String get visitSaved => 'विज़िट सेव हो गई';

  @override
  String get visitSaveFailed =>
      'विज़िट सेव नहीं हो सकी। कनेक्शन जाँचें और फिर कोशिश करें।';

  @override
  String get visitDetails => 'विज़िट';

  @override
  String get managerComment => 'मैनेजर की टिप्पणी';

  @override
  String get managerCommentHint => 'सेल्सपर्सन के लिए फ़ीडबैक या अगले कदम';

  @override
  String get noManagerComment => 'अभी मैनेजर की कोई टिप्पणी नहीं।';

  @override
  String get saveComment => 'टिप्पणी सेव करें';

  @override
  String get purposeCollectPayment => 'भुगतान लेना';

  @override
  String get purposeRequestPayment => 'भुगतान माँगना';

  @override
  String get purposeNewOrder => 'नया ऑर्डर';

  @override
  String get purposeOrderFollowUp => 'ऑर्डर फ़ॉलो-अप';

  @override
  String get purposeQuotationFollowUp => 'कोटेशन फ़ॉलो-अप';

  @override
  String get purposeSamples => 'सैंपल देना';

  @override
  String get purposeComplaint => 'शिकायत निपटाना';

  @override
  String get purposeNewProduct => 'नया प्रोडक्ट दिखाना';

  @override
  String get purposeProjectDiscussion => 'प्रोजेक्ट पर चर्चा';

  @override
  String get purposeNewClient => 'नया क्लाइंट';

  @override
  String get purposeReestablish => 'कारोबार फिर शुरू करना';

  @override
  String get purposeCatchUp => 'मुलाक़ात';

  @override
  String get purposeOther => 'अन्य';
}
