// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get languageName => 'اردو';

  @override
  String get language => 'زبان';

  @override
  String get chooseLanguage => 'زبان منتخب کریں';

  @override
  String get cancel => 'منسوخ کریں';

  @override
  String get save => 'محفوظ کریں';

  @override
  String get back => 'واپس';

  @override
  String get continueLabel => 'جاری رکھیں';

  @override
  String get required => 'ضروری';

  @override
  String get settings => 'سیٹنگز';

  @override
  String get allow => 'اجازت دیں';

  @override
  String get fix => 'ٹھیک کریں';

  @override
  String get turnOn => 'آن کریں';

  @override
  String get roleAdmin => 'ایڈمن';

  @override
  String get roleSupervisor => 'سپروائزر';

  @override
  String get roleSales => 'سیلز';

  @override
  String get roleSiteEngineer => 'سائٹ انجینئر';

  @override
  String get roleMason => 'مستری';

  @override
  String get welcomeBack => 'خوش آمدید';

  @override
  String get signInToContinue => 'جاری رکھنے کے لیے سائن اِن کریں';

  @override
  String get email => 'ای میل';

  @override
  String get password => 'پاس ورڈ';

  @override
  String get enterValidEmail => 'درست ای میل درج کریں';

  @override
  String get enterPassword => 'اپنا پاس ورڈ درج کریں';

  @override
  String get forgotPassword => 'پاس ورڈ بھول گئے؟';

  @override
  String get signIn => 'سائن اِن';

  @override
  String get newToApp => 'رائل ماربل پر نئے ہیں؟';

  @override
  String get createAccount => 'اکاؤنٹ بنائیں';

  @override
  String get errInvalidEmail => 'یہ ای میل درست نہیں لگتی۔';

  @override
  String get errUserDisabled =>
      'یہ اکاؤنٹ بند کر دیا گیا ہے۔ اپنے ایڈمن سے رابطہ کریں۔';

  @override
  String get errTooManyRequests =>
      'بہت زیادہ کوششیں۔ چند منٹ انتظار کر کے دوبارہ کوشش کریں۔';

  @override
  String get errNoInternet => 'انٹرنیٹ کنکشن نہیں ہے۔';

  @override
  String get errWrongCredentials => 'ای میل یا پاس ورڈ غلط ہے۔';

  @override
  String get errSignInGeneric => 'سائن اِن نہیں ہو سکا۔ دوبارہ کوشش کریں۔';

  @override
  String get resetPassword => 'پاس ورڈ ری سیٹ کریں';

  @override
  String get resetIntro =>
      'جس ای میل سے آپ سائن اِن کرتے ہیں وہ درج کریں، ہم نیا پاس ورڈ منتخب کرنے کا لنک بھیجیں گے۔';

  @override
  String get sendResetLink => 'لنک بھیجیں';

  @override
  String get checkYourEmail => 'اپنی ای میل دیکھیں';

  @override
  String resetSent(String email) {
    return 'ہم نے $email پر ری سیٹ لنک بھیج دیا ہے۔';
  }

  @override
  String get backToSignIn => 'سائن اِن پر واپس جائیں';

  @override
  String get resetError =>
      'ای میل نہیں بھیجی جا سکی۔ پتہ چیک کر کے دوبارہ کوشش کریں۔';

  @override
  String stepOf(int step, int total) {
    return 'مرحلہ $step از $total';
  }

  @override
  String get stepAboutYou => 'آپ کے بارے میں';

  @override
  String get stepContact => 'رابطہ';

  @override
  String get stepAccount => 'اکاؤنٹ';

  @override
  String get addPhotoHint => 'اپنے چہرے کی واضح تصویر لگائیں';

  @override
  String get tapToChange => 'تبدیل کرنے کے لیے ٹیپ کریں';

  @override
  String get takePhoto => 'تصویر لیں';

  @override
  String get chooseFromGallery => 'گیلری سے منتخب کریں';

  @override
  String get firstName => 'پہلا نام';

  @override
  String get lastName => 'خاندانی نام';

  @override
  String get nationality => 'قومیت';

  @override
  String get mobileNumber => 'موبائل نمبر';

  @override
  String get mobileInvalid =>
      'متحدہ عرب امارات کا موبائل نمبر درج کریں (05X XXX XXXX)';

  @override
  String get company => 'کمپنی';

  @override
  String get homeAddress => 'گھر کا پتہ';

  @override
  String get passwordHelper => 'کم از کم 6 حروف';

  @override
  String get passwordTooShort => 'کم از کم 6 حروف استعمال کریں';

  @override
  String get confirmPassword => 'پاس ورڈ کی تصدیق کریں';

  @override
  String get passwordsDontMatch => 'پاس ورڈ ایک جیسے نہیں ہیں';

  @override
  String get approvalNotice =>
      'ایڈمن نئے اکاؤنٹس کا جائزہ لیتا ہے۔ منظوری کے بعد آپ سائن اِن کر سکیں گے۔';

  @override
  String get photoRequired =>
      'تصویر لگائیں تاکہ آپ کا سپروائزر آپ کو پہچان سکے۔';

  @override
  String get nationalityRequired => 'اپنی قومیت منتخب کریں۔';

  @override
  String get homeRequired => 'نقشے پر اپنے گھر کا پتہ منتخب کریں۔';

  @override
  String get cameraError => 'کیمرہ یا گیلری نہیں کھل سکی۔';

  @override
  String get emailInUse =>
      'اس ای میل سے پہلے ہی اکاؤنٹ موجود ہے۔ سائن اِن کر کے دیکھیں۔';

  @override
  String get registerFailed =>
      'اکاؤنٹ نہیں بن سکا۔ اپنی معلومات چیک کر کے دوبارہ کوشش کریں۔';

  @override
  String get somethingWrong => 'کچھ غلط ہو گیا۔ دوبارہ کوشش کریں۔';

  @override
  String greetingMorning(String name) {
    return 'صبح بخیر، $name';
  }

  @override
  String greetingAfternoon(String name) {
    return 'سلام، $name';
  }

  @override
  String greetingEvening(String name) {
    return 'شام بخیر، $name';
  }

  @override
  String get offlineBanner =>
      'آپ آف لائن ہیں۔ کنکشن بحال ہونے پر تبدیلیاں بھیج دی جائیں گی۔';

  @override
  String get pendingTitle => 'رجسٹر کرنے کا شکریہ';

  @override
  String get pendingBody =>
      'آپ کا اکاؤنٹ منظوری کا منتظر ہے۔ ایڈمن کے فعال کرنے کے بعد آپ ایپ استعمال کر سکیں گے۔';

  @override
  String get yourSite => 'آپ کی سائٹ';

  @override
  String get yourSites => 'آپ کی سائٹس';

  @override
  String get noSiteTitle => 'ابھی کوئی سائٹ نہیں دی گئی';

  @override
  String get noSiteBody => 'آپ کا سپروائزر آپ کو کسی پروجیکٹ پر لگائے گا۔';

  @override
  String get noSitesAssigned => 'کوئی سائٹ نہیں دی گئی۔';

  @override
  String yourTeam(int count) {
    return 'آپ کی ٹیم ($count)';
  }

  @override
  String get nobodyYet => 'ابھی کوئی نہیں۔';

  @override
  String onSiteAtSince(String site, String time) {
    return '$site پر $time سے موجود';
  }

  @override
  String get checkedOut => 'چیک آؤٹ کر لیا';

  @override
  String get notCheckedIn => 'چیک اِن نہیں کیا';

  @override
  String durationHm(int hours, int minutes) {
    return '$hours گھنٹے $minutes منٹ';
  }

  @override
  String durationM(int minutes) {
    return '$minutes منٹ';
  }

  @override
  String onSiteSince(String time, String duration) {
    return '$time سے سائٹ پر · $duration';
  }

  @override
  String checkedInAtSite(String site) {
    return '$site پر چیک اِن';
  }

  @override
  String doneToday(String duration) {
    return 'آج کا کام مکمل · $duration';
  }

  @override
  String get withinSiteArea => 'سائٹ کی حدود میں';

  @override
  String kmAway(String km) {
    return '$km کلومیٹر دور';
  }

  @override
  String metersAway(int meters) {
    return '$meters میٹر دور';
  }

  @override
  String get gettingGpsFix => 'درست GPS مقام حاصل کیا جا رہا ہے…';

  @override
  String get checkIn => 'چیک اِن';

  @override
  String get checkOut => 'چیک آؤٹ';

  @override
  String get workCompletedTitle => 'آج کیا گیا کام';

  @override
  String get workSystem => 'سسٹم';

  @override
  String get workTiles => 'ٹائلز';

  @override
  String get workOthers => 'دیگر';

  @override
  String get describeWork => 'کام کی تفصیل لکھیں';

  @override
  String get areaCompleted => 'مکمل کیا گیا رقبہ';

  @override
  String get enterNumber => 'عدد درج کریں';

  @override
  String checkedInAt(String time) {
    return '$time پر چیک اِن ہو گیا۔ آپ کا دن اچھا گزرے!';
  }

  @override
  String checkedOutAt(String time) {
    return '$time پر چیک آؤٹ ہو گیا۔ شکریہ!';
  }

  @override
  String get errLocationUnavailable =>
      'آپ کا مقام معلوم نہیں ہو سکا۔ لوکیشن آن کر کے دوبارہ کوشش کریں۔';

  @override
  String get errNoServer =>
      'سرور سے رابطہ نہیں ہے۔ انٹرنیٹ چیک کر کے دوبارہ کوشش کریں۔';

  @override
  String errCheckInFailed(String code) {
    return 'چیک اِن نہیں ہو سکا ($code)۔';
  }

  @override
  String get errSignInAgain => 'براہ کرم دوبارہ سائن اِن کریں۔';

  @override
  String get errNotActive => 'آپ کا اکاؤنٹ فعال نہیں ہے۔';

  @override
  String get errMockLocation =>
      'جعلی GPS ایپ کا پتہ چلا ہے۔ چیک اِن کے لیے اسے بند کریں۔';

  @override
  String errWeakGps(int meters) {
    return 'GPS سگنل کمزور ہے (±$meters میٹر)۔ کھلی جگہ پر جائیں یا تھوڑا انتظار کر کے دوبارہ کوشش کریں۔';
  }

  @override
  String get errNoSiteLocation =>
      'اس سائٹ کا مقام سیٹ نہیں ہے۔ ایڈمن سے رابطہ کریں۔';

  @override
  String errOutOfRange(int meters) {
    return 'آپ سائٹ سے $meters میٹر باہر ہیں۔';
  }

  @override
  String errAlreadyCheckedIn(String site) {
    return 'آپ پہلے ہی $site پر چیک اِن ہیں۔';
  }

  @override
  String get errNotCheckedIn => 'آپ نے چیک اِن نہیں کیا۔';

  @override
  String errCheckedInElsewhere(String site) {
    return 'آپ $site پر چیک اِن ہیں۔ پہلے وہاں سے چیک آؤٹ کریں۔';
  }

  @override
  String get errNotAssigned => 'آپ اس سائٹ پر مقرر نہیں ہیں۔';

  @override
  String get trackingActive => 'ٹریکنگ فعال ہے';

  @override
  String get waitingForGps => 'GPS کا انتظار…';

  @override
  String gpsAccuracy(int meters) {
    return 'GPS درستگی ±$meters میٹر';
  }

  @override
  String get locationOffTitle => 'لوکیشن بند ہے';

  @override
  String get locationOffBody =>
      'آپ کے ایڈمن کو اطلاع دے دی گئی ہے۔ جاری رکھنے کے لیے اسے آن کریں۔';

  @override
  String get allowAlwaysTitle => 'لوکیشن \"ہر وقت\" کی اجازت دیں';

  @override
  String get allowAlwaysBody =>
      'ضروری ہے تاکہ ایپ بند ہونے پر بھی چیک اِن کام کرے۔';

  @override
  String get preciseOffTitle => 'درست لوکیشن بند ہے';

  @override
  String get preciseOffBody => 'اس ایپ کے لیے \"درست لوکیشن\" آن کریں۔';

  @override
  String get noInternetTitle => 'انٹرنیٹ کنکشن نہیں ہے';

  @override
  String get noInternetBody =>
      'لوکیشن محفوظ ہو رہی ہے اور کنکشن بحال ہونے پر بھیج دی جائے گی۔';

  @override
  String get batterySaverTitle => 'بیٹری سیور آن ہے';

  @override
  String get batterySaverBody =>
      'ٹریکنگ میں تاخیر ہو سکتی ہے۔ کام کے اوقات میں اسے بند رکھیں۔';

  @override
  String get batteryOptTitle => 'بیٹری آپٹیمائزیشن آن ہے';

  @override
  String get batteryOptBody => 'آپ کا فون پس منظر میں ٹریکنگ روک سکتا ہے۔';

  @override
  String get myPay => 'میری تنخواہ';

  @override
  String get yourPackage => 'آپ کی تنخواہ کی تفصیل';

  @override
  String get payNotAddedTitle =>
      'آپ کی تنخواہ کی تفصیلات ابھی شامل نہیں کی گئیں۔';

  @override
  String get payNotAddedBody =>
      'اگر آپ کو لگتا ہے کہ یہ غلطی ہے تو اپنے ایڈمن سے پوچھیں۔';

  @override
  String get payTypeMonthly => 'ماہانہ تنخواہ';

  @override
  String get payTypeDaily => 'یومیہ اجرت';

  @override
  String get payTypeHourly => 'فی گھنٹہ اجرت';

  @override
  String get perMonth => '/ ماہانہ';

  @override
  String get perDay => '/ یومیہ';

  @override
  String get perHour => '/ فی گھنٹہ';

  @override
  String get basic => 'بنیادی تنخواہ';

  @override
  String get housing => 'رہائش الاؤنس';

  @override
  String get transportation => 'ٹرانسپورٹ الاؤنس';

  @override
  String get food => 'کھانے کا الاؤنس';

  @override
  String get totalPerMonth => 'کل ماہانہ';

  @override
  String get allowancesMonthly => 'الاؤنس ماہانہ رقم ہیں۔';

  @override
  String effectiveFrom(String date) {
    return '$date سے';
  }

  @override
  String get myProfile => 'میری پروفائل';

  @override
  String get sectionTeam => 'ٹیم';

  @override
  String get teamStatusAlerts => 'ٹیم کی صورتحال اور الرٹس';

  @override
  String get liveMap => 'لائیو نقشہ';

  @override
  String get users => 'صارفین';

  @override
  String get sectionSites => 'سائٹس';

  @override
  String get newProject => 'نیا پروجیکٹ';

  @override
  String get newMockup => 'نیا موک اپ';

  @override
  String get sectionSales => 'سیلز';

  @override
  String get clients => 'کلائنٹس';

  @override
  String get addClient => 'کلائنٹ شامل کریں';

  @override
  String get newVisit => 'نیا وزٹ';

  @override
  String get visits => 'وزٹس';

  @override
  String get sectionReports => 'رپورٹس';

  @override
  String get attendance => 'حاضری';

  @override
  String get salesActivity => 'سیلز سرگرمی';

  @override
  String get signOut => 'سائن آؤٹ';

  @override
  String get signOutTitle => 'سائن آؤٹ کریں؟';

  @override
  String get signOutBody =>
      'لوکیشن ٹریکنگ بند ہو جائے گی اور دوبارہ سائن اِن کرنے تک آپ چیک اِن نہیں کر سکیں گے۔';

  @override
  String get teamStatus => 'ٹیم کی صورتحال';

  @override
  String get onSiteNow => 'ابھی سائٹ پر';

  @override
  String get phoneAlerts => 'فون الرٹس';

  @override
  String get pendingLabel => 'زیرِ التوا';

  @override
  String get needsAttention => 'توجہ درکار';

  @override
  String get seeAll => 'سب دیکھیں';

  @override
  String get todaysAttendance => 'آج کی حاضری';

  @override
  String get alertLog => 'الرٹ لاگ';

  @override
  String activeProjects(int count) {
    return 'فعال پروجیکٹس ($count)';
  }

  @override
  String activeMockups(int count) {
    return 'فعال موک اپس ($count)';
  }

  @override
  String potentialProjects(int count) {
    return 'ممکنہ پروجیکٹس ($count)';
  }

  @override
  String get nobodyCheckedInToday => 'آج ابھی تک کسی نے چیک اِن نہیں کیا۔';

  @override
  String get details => 'تفصیلات';

  @override
  String get changeStatus => 'صورتحال تبدیل کریں';

  @override
  String get myVisits => 'میرے وزٹس';

  @override
  String get site => 'سائٹ';

  @override
  String get problemSilent => 'رپورٹ نہیں کر رہا';

  @override
  String get problemLocationOff => 'لوکیشن بند';

  @override
  String problemPermission(String value) {
    return 'اجازت: $value';
  }

  @override
  String get problemTrackingStopped => 'ٹریکنگ بند';

  @override
  String get problemOffline => 'آف لائن';

  @override
  String get problemApproximate => 'تخمینی لوکیشن';

  @override
  String get problemBatterySaver => 'بیٹری سیور آن';

  @override
  String problemBattery(int percent) {
    return 'بیٹری $percent%';
  }

  @override
  String get permWhenInUse => 'استعمال کے دوران';

  @override
  String get permDenied => 'مسترد';

  @override
  String get permRestricted => 'محدود';

  @override
  String get permNotDetermined => 'طے نہیں';

  @override
  String get permAlways => 'ہر وقت';

  @override
  String get unknownUser => 'نامعلوم';

  @override
  String get timeNever => 'کبھی نہیں';

  @override
  String get timeJustNow => 'ابھی ابھی';

  @override
  String timeMinAgo(int n) {
    return '$n منٹ پہلے';
  }

  @override
  String timeHoursAgo(int n) {
    return '$n گھنٹے پہلے';
  }

  @override
  String seenAgo(String when) {
    return 'آخری بار $when';
  }

  @override
  String lastSeen(String when) {
    return 'آخری بار دیکھا گیا $when';
  }

  @override
  String get phonesTab => 'فونز';

  @override
  String get alertsTab => 'الرٹس';

  @override
  String get noActiveWorkers => 'کوئی فعال کارکن نہیں';

  @override
  String get notOnNewApp => 'ابھی نئی ایپ پر نہیں';

  @override
  String get allGood => 'سب ٹھیک';

  @override
  String gpsShort(int meters) {
    return 'GPS ±$meters میٹر';
  }

  @override
  String get alertsNotEnabled => 'سرور پر الرٹس ابھی فعال نہیں ہیں۔';

  @override
  String get alertsLoadError => 'الرٹس لوڈ نہیں ہو سکے۔ کنکشن چیک کریں۔';

  @override
  String get noAlertsYet => 'ابھی کوئی الرٹ نہیں';

  @override
  String get evLocationOff => 'لوکیشن سروس بند کر دی گئی';

  @override
  String get evLocationOn => 'لوکیشن سروس دوبارہ آن کی گئی';

  @override
  String get evGpsOff => 'GPS بند (صرف نیٹ ورک لوکیشن)';

  @override
  String get evGpsOn => 'GPS دوبارہ آن';

  @override
  String get evPreciseOff => 'درست لوکیشن بند کر دی گئی';

  @override
  String get evPreciseOn => 'درست لوکیشن دوبارہ آن';

  @override
  String evPermission(String value) {
    return 'لوکیشن کی اجازت \"$value\" میں تبدیل ہو گئی';
  }

  @override
  String get evOffline => 'فون کا انٹرنیٹ کنکشن منقطع ہو گیا';

  @override
  String get evOnline => 'فون دوبارہ آن لائن ہے';

  @override
  String get evPowerSaveOn => 'بیٹری سیور آن (ٹریکنگ میں تاخیر ہو سکتی ہے)';

  @override
  String get evPowerSaveOff => 'بیٹری سیور بند';

  @override
  String get evTrackingStopped => 'لوکیشن ٹریکنگ رک گئی';

  @override
  String get evTrackingStarted => 'لوکیشن ٹریکنگ شروع ہو گئی';

  @override
  String get evAppClosed => 'ایپ بند کی گئی (ٹریکنگ جاری ہے)';

  @override
  String get evDeviceBoot => 'فون ری اسٹارٹ ہوا';

  @override
  String get evMock => 'جعلی GPS لوکیشن کا پتہ چلا';

  @override
  String get evMockCleared => 'اصل GPS بحال ہو گیا';

  @override
  String evBatteryLow(int percent) {
    return 'بیٹری کم ($percent%)';
  }

  @override
  String get evBatteryOk => 'بیٹری بحال ہو گئی';

  @override
  String get evSilent =>
      'فون نے رپورٹ کرنا بند کر دیا۔ ہو سکتا ہے فون بند ہو، آف لائن ہو یا ایپ زبردستی بند کی گئی ہو۔';

  @override
  String get usersAll => 'سب';

  @override
  String activeTab(int count) {
    return 'فعال ($count)';
  }

  @override
  String pendingTab(int count) {
    return 'زیرِ التوا ($count)';
  }

  @override
  String get searchUsers => 'نام، ای میل یا فون سے تلاش کریں';

  @override
  String get noActiveUsersMatch => 'کوئی فعال صارف نہیں ملا۔';

  @override
  String get nobodyWaiting => 'کوئی منظوری کا منتظر نہیں۔';

  @override
  String get review => 'جائزہ';

  @override
  String roleChangedTo(String role) {
    return 'کردار $role میں تبدیل کر دیا گیا';
  }

  @override
  String get roleChangeFailed => 'کردار تبدیل نہیں ہو سکا۔';

  @override
  String get accountActivated => 'اکاؤنٹ فعال کر دیا گیا';

  @override
  String get accountDeactivated => 'اکاؤنٹ غیر فعال کر دیا گیا';

  @override
  String get accessUpdateFailed => 'رسائی اپ ڈیٹ نہیں ہو سکی۔';

  @override
  String deleteUserTitle(String name) {
    return '$name کو حذف کریں؟';
  }

  @override
  String get deleteUserBody =>
      'پروفائل مستقل طور پر حذف ہو جائے گی۔ پرانی حاضری محفوظ رہے گی۔';

  @override
  String get delete => 'حذف کریں';

  @override
  String get statusActive => 'فعال';

  @override
  String get statusPendingInactive => 'زیرِ التوا / غیر فعال';

  @override
  String get waitingForAccess => 'یہ اکاؤنٹ رسائی کا منتظر ہے۔';

  @override
  String get approve => 'منظور کریں';

  @override
  String get sectionContact => 'رابطہ';

  @override
  String get sectionWork => 'کام';

  @override
  String get noSiteAssigned => 'کوئی سائٹ نہیں دی گئی';

  @override
  String get assignedSite => 'مقرر سائٹ';

  @override
  String get phoneReportingNormally => 'فون معمول کے مطابق رپورٹ کر رہا ہے';

  @override
  String get recentAlerts => 'حالیہ الرٹس';

  @override
  String get sectionPay => 'تنخواہ';

  @override
  String get sectionRole => 'کردار';

  @override
  String get sectionAccess => 'رسائی';

  @override
  String get deactivateAccount => 'اکاؤنٹ غیر فعال کریں';

  @override
  String get activateAccount => 'اکاؤنٹ فعال کریں';

  @override
  String get deactivateBeforeDeleting => 'حذف کرنے سے پہلے غیر فعال کریں';

  @override
  String get deletePermanently => 'اکاؤنٹ مستقل طور پر حذف کریں';

  @override
  String get userTitle => 'صارف';

  @override
  String get project => 'پروجیکٹ';

  @override
  String get mockup => 'موک اپ';

  @override
  String get edit => 'ترمیم';

  @override
  String checkInRadius(int meters) {
    return 'چیک اِن دائرہ $meters میٹر';
  }

  @override
  String get directions => 'راستہ';

  @override
  String get today => 'آج';

  @override
  String get contractor => 'ٹھیکیدار';

  @override
  String teamCount(int count) {
    return 'ٹیم ($count)';
  }

  @override
  String get manage => 'انتظام';

  @override
  String get nobodyAssigned => 'ابھی کوئی مقرر نہیں۔';

  @override
  String peopleAssigned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count افراد مقرر۔',
      one: '1 فرد مقرر۔',
    );
    return '$_temp0';
  }

  @override
  String get onSite => 'سائٹ پر';

  @override
  String get away => 'باہر';

  @override
  String get teamUpdated => 'ٹیم اپ ڈیٹ ہو گئی';

  @override
  String get teamUpdateFailed => 'ٹیم اپ ڈیٹ نہیں ہو سکی۔';

  @override
  String teamOf(String site) {
    return 'ٹیم · $site';
  }

  @override
  String selectedCount(int count) {
    return '$count منتخب';
  }

  @override
  String get searchPeople => 'لوگ تلاش کریں';

  @override
  String get saveTeam => 'ٹیم محفوظ کریں';

  @override
  String currentlyAt(String site) {
    return '$site پر بھی';
  }

  @override
  String get payUnavailable => 'تنخواہ کی تفصیلات ابھی دستیاب نہیں۔';

  @override
  String get noPayDetails => 'ابھی کوئی تنخواہ کی تفصیل نہیں۔';

  @override
  String get setPayDetails => 'تنخواہ کی تفصیل شامل کریں';

  @override
  String get editPayDetails => 'تنخواہ کی تفصیل میں ترمیم';

  @override
  String get paySaved => 'تنخواہ کی تفصیل محفوظ ہو گئی';

  @override
  String get enterValidAmount => 'درست رقم درج کریں';

  @override
  String payFor(String name) {
    return 'تنخواہ · $name';
  }

  @override
  String get monthly => 'ماہانہ';

  @override
  String get daily => 'یومیہ';

  @override
  String get hourly => 'فی گھنٹہ';

  @override
  String get monthlyAllowances => 'ماہانہ الاؤنس';

  @override
  String get allowance => 'الاؤنس';

  @override
  String get nameIt => 'نام لکھیں';

  @override
  String get amount => 'رقم';

  @override
  String get addAllowance => 'ایک اور الاؤنس شامل کریں';

  @override
  String get effectiveFromLabel => 'مؤثر از';

  @override
  String get notesOptional => 'نوٹس (اختیاری)';

  @override
  String get summary => 'خلاصہ';

  @override
  String get savePayDetails => 'تنخواہ کی تفصیل محفوظ کریں';

  @override
  String get yesterday => 'کل';

  @override
  String get thisWeek => 'اس ہفتے';

  @override
  String get lastWeek => 'پچھلے ہفتے';

  @override
  String get thisMonth => 'اس مہینے';

  @override
  String get lastMonth => 'پچھلے مہینے';

  @override
  String get customRange => 'اپنی مرضی…';

  @override
  String get reportLoadError => 'رپورٹ لوڈ نہیں ہو سکی۔ کنکشن چیک کریں۔';

  @override
  String get nothingToExport => 'اس مدت کے لیے برآمد کرنے کو کچھ نہیں۔';

  @override
  String get pdfSubtitle => 'دیکھیں، پرنٹ کریں یا شیئر کریں';

  @override
  String get excelSubtitle => 'روزانہ اندراجات اور خلاصہ شیٹ';

  @override
  String get export => 'برآمد';

  @override
  String get everyone => 'سب';

  @override
  String get rolesMasons => 'مستری';

  @override
  String get rolesSiteEngineers => 'سائٹ انجینئرز';

  @override
  String get rolesSupervisors => 'سپروائزرز';

  @override
  String get people => 'افراد';

  @override
  String get hours => 'گھنٹے';

  @override
  String get areaM2 => 'رقبہ م²';

  @override
  String missingCheckouts(int count) {
    return 'بغیر چیک آؤٹ اندراجات: $count۔ ان کے گھنٹے شمار نہیں ہوئے۔';
  }

  @override
  String get viewBy => 'اس کے مطابق دیکھیں';

  @override
  String get person => 'فرد';

  @override
  String get day => 'دن';

  @override
  String get noAttendance => 'اس مدت میں کوئی حاضری نہیں۔';

  @override
  String get noSalesTeam => 'سیلز ٹیم میں کوئی نہیں۔';

  @override
  String get salespeople => 'سیلز پرسنز';

  @override
  String get noVisits => 'اس مدت میں کوئی وزٹ نہیں۔';

  @override
  String get client => 'کلائنٹ';

  @override
  String get noOut => 'چیک آؤٹ نہیں';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count دن',
    );
    return '$_temp0';
  }

  @override
  String salesSummary(int days, int client, int project) {
    return '$days کام کے دن · $client کلائنٹ · $project پروجیکٹ وزٹس';
  }

  @override
  String peopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count افراد',
      one: '1 فرد',
    );
    return '$_temp0';
  }

  @override
  String get nowLabel => 'ابھی';

  @override
  String get switchHere => 'اس سائٹ پر جائیں';

  @override
  String get switchSiteTitle => 'سائٹ بدلیں؟';

  @override
  String switchSiteBody(String from, String to) {
    return 'آپ کو $from سے چیک آؤٹ اور $to پر چیک اِن کیا جائے گا۔';
  }

  @override
  String outsideSiteSince(String time) {
    return '$time سے سائٹ سے باہر';
  }

  @override
  String get autoCheckedOut => 'خودکار طور پر چیک آؤٹ ہوا';

  @override
  String evLeftSite(String site) {
    return 'چیک اِن کے دوران $site سے باہر گیا';
  }

  @override
  String evReturnedToSite(String site) {
    return '$site پر واپس آیا';
  }

  @override
  String evAutoCheckout(String site) {
    return '$site سے خودکار طور پر چیک آؤٹ ہوا';
  }

  @override
  String get allSites => 'تمام سائٹیں';

  @override
  String autoCheckoutsToReview(int count) {
    return 'جائزے کے لیے خودکار چیک آؤٹ: $count۔';
  }

  @override
  String autoCheckoutsToReviewTap(int count) {
    return 'جائزے کے لیے خودکار چیک آؤٹ: $count۔ درست یا منظور کرنے کے لیے کسی اندراج پر ٹیپ کریں۔';
  }

  @override
  String awayFor(String duration) {
    return '$duration باہر';
  }

  @override
  String get autoLeftSiteShort => 'خودکار: سائٹ چھوڑی';

  @override
  String get autoEndOfDayShort => 'خودکار: دن کا اختتام';

  @override
  String get editedByAdmin => 'ترمیم شدہ';

  @override
  String noOutCount(int count) {
    return '$count بغیر چیک آؤٹ';
  }

  @override
  String get errEndBeforeStart => 'چیک آؤٹ، چیک اِن کے بعد ہونا چاہیے۔';

  @override
  String get errOnlyLastOpen =>
      'صرف آخری اندراج بغیر چیک آؤٹ کے چھوڑا جا سکتا ہے۔';

  @override
  String get errSessionsOverlap =>
      'دو اندراجات کا وقت آپس میں ٹکرا رہا ہے۔ وقت درست کریں۔';

  @override
  String get attendanceSaved => 'حاضری محفوظ ہو گئی';

  @override
  String get errNotAdmin => 'صرف ایڈمن حاضری درست کر سکتے ہیں۔';

  @override
  String get reviewHint =>
      'سسٹم نے یہ دن خودکار طور پر بند کیا۔ ضرورت ہو تو وقت درست کریں، یا جیسا ہے ویسا منظور کریں۔';

  @override
  String get addSession => 'اندراج شامل کریں';

  @override
  String get correctionNote => 'وجہ';

  @override
  String get correctionNoteHint =>
      'مثلاً: چیک آؤٹ بھول گیا، سپروائزر نے تصدیق کی';

  @override
  String get saveChanges => 'تبدیلیاں محفوظ کریں';

  @override
  String get approveAsIs => 'جیسا ہے ویسا منظور کریں';

  @override
  String get correctionHistory => 'تبدیلیوں کی تاریخ';

  @override
  String previously(String sessions) {
    return 'پہلے: $sessions';
  }

  @override
  String get removeSession => 'یہ اندراج ہٹائیں';

  @override
  String get inLabel => 'اِن';

  @override
  String get outLabel => 'آؤٹ';

  @override
  String get setCheckOut => 'چیک آؤٹ کا وقت ڈالیں';

  @override
  String get leaveOpen => 'کھلا چھوڑیں (ابھی سائٹ پر ہے)';

  @override
  String get leftAt => 'باہر گیا';

  @override
  String get returnedAt => 'واپس آیا';

  @override
  String get siteStatusActive => 'فعال';

  @override
  String get siteStatusPotential => 'ممکنہ';

  @override
  String get siteStatusClosed => 'بند';

  @override
  String get siteStatus => 'حیثیت';

  @override
  String get siteName => 'سائٹ کا نام';

  @override
  String get siteDetails => 'تفصیل (اختیاری)';

  @override
  String get siteLocation => 'مقام';

  @override
  String get noPinYet => 'ابھی مقام طے نہیں ہوا';

  @override
  String get pinRequired => 'نقشے پر سائٹ کی جگہ طے کریں۔';

  @override
  String get setPin => 'نقشے پر طے کریں';

  @override
  String get movePin => 'بدلیں';

  @override
  String get checkInRadiusLabel => 'چیک اِن کا دائرہ';

  @override
  String metersShort(int meters) {
    return '$meters میٹر';
  }

  @override
  String get radiusHint =>
      'کارکن پن سے اتنے فاصلے کے اندر چیک اِن کر سکتے ہیں۔ سائٹ چھوڑنے کا درست پتا چلے، اس کے لیے کم از کم 150 میٹر رکھیں۔';

  @override
  String get contractorCompany => 'ٹھیکیدار کمپنی';

  @override
  String get contactPerson => 'رابطہ شخص';

  @override
  String get contactPhone => 'فون';

  @override
  String get enterValidPhone => 'درست فون نمبر درج کریں';

  @override
  String get createSite => 'سائٹ بنائیں';

  @override
  String get editProject => 'پروجیکٹ میں ترمیم';

  @override
  String get editMockup => 'ماک اپ میں ترمیم';

  @override
  String get siteSaved => 'سائٹ محفوظ ہو گئی';

  @override
  String get siteSaveFailed =>
      'سائٹ محفوظ نہیں ہو سکی۔ کنکشن چیک کریں اور دوبارہ کوشش کریں۔';

  @override
  String get deleteSite => 'سائٹ حذف کریں';

  @override
  String deleteSiteTitle(String name) {
    return '$name حذف کریں؟';
  }

  @override
  String deleteSiteBody(int count) {
    return 'سائٹ ہمیشہ کے لیے حذف ہو جائے گی اور $count افراد کی فہرست سے نکل جائے گی۔ پرانی حاضری محفوظ رہے گی۔';
  }

  @override
  String get placePin => 'سائٹ کی جگہ طے کریں';

  @override
  String get searchAddress => 'پتہ یا علاقہ تلاش کریں';

  @override
  String get addressNotFound =>
      'پتہ نہیں ملا۔ کچھ اور تلاش کریں یا نقشہ ہلائیں۔';

  @override
  String get myLocation => 'میرا مقام';

  @override
  String get usePinHere => 'یہ مقام استعمال کریں';

  @override
  String get siteNotFound => 'یہ سائٹ اب موجود نہیں۔';

  @override
  String get newSite => 'نئی سائٹ';

  @override
  String get searchSites => 'نام، پتہ یا ٹھیکیدار تلاش کریں';

  @override
  String get everything => 'تمام';

  @override
  String get projectsLabel => 'پروجیکٹس';

  @override
  String get mockupsLabel => 'ماک اپس';

  @override
  String get noSitesFound => 'کوئی مماثل سائٹ نہیں۔';

  @override
  String get siteAddress => 'پتہ';

  @override
  String get callAction => 'کال کریں';

  @override
  String helpersCount(int count) {
    return 'مددگار ($count)';
  }

  @override
  String get noHelpers => 'کوئی مددگار مقرر نہیں۔';

  @override
  String get noHelpersYet =>
      'ابھی کوئی مددگار نہیں۔ اوپر والے بٹن سے شامل کریں۔';

  @override
  String helpersMax(int count) {
    return 'ایک مستری کے زیادہ سے زیادہ $count مددگار ہو سکتے ہیں۔';
  }

  @override
  String helpersOf(String name) {
    return 'مددگار · $name';
  }

  @override
  String get addHelper => 'مددگار شامل کریں';

  @override
  String get editHelper => 'مددگار میں ترمیم';

  @override
  String get saveHelpers => 'مددگار محفوظ کریں';

  @override
  String get helpersSaved => 'مددگار اپ ڈیٹ ہو گئے';

  @override
  String get helpersSaveFailed => 'مددگار اپ ڈیٹ نہیں ہو سکے۔';

  @override
  String deleteHelperTitle(String name) {
    return '$name حذف کریں؟';
  }

  @override
  String get deleteHelperBody =>
      'انہیں مددگاروں کی فہرست اور ہر اس مستری سے ہٹا دیا جائے گا جس کے ساتھ وہ کام کرتے ہیں۔';

  @override
  String get profileSaved => 'پروفائل محفوظ ہو گیا';

  @override
  String get profileSaveFailed =>
      'پروفائل محفوظ نہیں ہو سکا۔ کنکشن چیک کریں اور دوبارہ کوشش کریں۔';

  @override
  String get sectionAccount => 'اکاؤنٹ';

  @override
  String get deleteMyAccount => 'میرا اکاؤنٹ حذف کریں';

  @override
  String get deleteMyAccountTitle => 'اپنا اکاؤنٹ حذف کریں؟';

  @override
  String get deleteMyAccountBody =>
      'آپ کا پروفائل اور لاگ اِن ہمیشہ کے لیے حذف ہو جائے گا اور آپ دوبارہ سائن اِن نہیں کر سکیں گے۔ حاضری اور تنخواہ کا ریکارڈ کمپنی کے پاس رہے گا۔ تصدیق کے لیے پاس ورڈ درج کریں۔';

  @override
  String get errWrongPassword => 'غلط پاس ورڈ۔';

  @override
  String get deleteAccountFailed =>
      'اکاؤنٹ حذف نہیں ہو سکا۔ کنکشن چیک کریں اور دوبارہ کوشش کریں۔';

  @override
  String get clientName => 'کلائنٹ کا نام';

  @override
  String get editClient => 'کلائنٹ میں ترمیم';

  @override
  String get deleteClient => 'کلائنٹ حذف کریں';

  @override
  String deleteClientTitle(String name) {
    return '$name کو حذف کریں؟';
  }

  @override
  String get deleteClientBody =>
      'کلائنٹ فہرست سے ہٹا دیا جائے گا۔ پچھلے وزٹس میں کلائنٹ کا نام رہے گا۔';

  @override
  String get clientSaved => 'کلائنٹ محفوظ ہو گیا';

  @override
  String get clientSaveFailed =>
      'کلائنٹ محفوظ نہیں ہو سکا۔ کنکشن چیک کریں اور دوبارہ کوشش کریں۔';

  @override
  String get clientLocation => 'مقام';

  @override
  String get clientLocationHint =>
      'اختیاری۔ نقشے پر پن سے بعد میں راستہ کھول سکتے ہیں۔';

  @override
  String get placeClient => 'کلائنٹ کا مقام منتخب کریں';

  @override
  String get clientNotFound => 'یہ کلائنٹ حذف ہو چکا ہے۔';

  @override
  String get searchClients => 'نام، رابطہ، فون یا علاقہ تلاش کریں';

  @override
  String clientsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count کلائنٹس',
      one: '1 کلائنٹ',
      zero: 'کوئی کلائنٹ نہیں',
    );
    return '$_temp0';
  }

  @override
  String get noClientsYet =>
      'ابھی کوئی کلائنٹ نہیں۔ نیچے والے بٹن سے پہلا شامل کریں۔';

  @override
  String get noClientsFound => 'کوئی کلائنٹ نہیں ملا';

  @override
  String get pinOnly => 'نقشے پر پن کیا گیا';

  @override
  String visitsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count وزٹس',
      one: '1 وزٹ',
      zero: 'وزٹس',
    );
    return '$_temp0';
  }

  @override
  String get noVisitsYet => 'ابھی کوئی وزٹ درج نہیں۔';

  @override
  String get noVisitsToday => 'آج کوئی وزٹ درج نہیں۔';

  @override
  String get noVisitsInPeriod => 'اس مدت میں کوئی وزٹ نہیں۔';

  @override
  String todaysVisits(int count) {
    return 'آج کے وزٹس ($count)';
  }

  @override
  String visitsSummary(int total, int clients, int projects) {
    return '$total وزٹس · $clients کلائنٹ · $projects پروجیکٹ';
  }

  @override
  String get salesperson => 'سیلز پرسن';

  @override
  String get meLabel => 'میں';

  @override
  String get last7Days => 'پچھلے 7 دن';

  @override
  String get clientWord => 'کلائنٹ';

  @override
  String get projectWord => 'پروجیکٹ';

  @override
  String get chooseClient => 'کلائنٹ منتخب کریں';

  @override
  String get chooseProject => 'پروجیکٹ منتخب کریں';

  @override
  String get visitStepWho => 'آپ نے کس کا وزٹ کیا؟';

  @override
  String get visitStepWhat => 'کیا ہوا';

  @override
  String get metWith => 'کس سے ملے';

  @override
  String get visitPurpose => 'مقصد';

  @override
  String get choosePurpose => 'مقصد منتخب کریں';

  @override
  String get visitNotes => 'نوٹس';

  @override
  String get visitNotesHint => 'کیا بات ہوئی، کیا طے ہوا یا کیا وعدہ ہوا؟';

  @override
  String notesTooShort(int min, int count) {
    return 'کم از کم $min حروف لکھیں (ابھی $count)';
  }

  @override
  String get visitTime => 'وزٹ کا وقت';

  @override
  String get rightNow => 'ابھی';

  @override
  String get change => 'تبدیل کریں';

  @override
  String get saveVisit => 'وزٹ محفوظ کریں';

  @override
  String get visitSaved => 'وزٹ محفوظ ہو گیا';

  @override
  String get visitSaveFailed =>
      'وزٹ محفوظ نہیں ہو سکا۔ کنکشن چیک کریں اور دوبارہ کوشش کریں۔';

  @override
  String get visitDetails => 'وزٹ';

  @override
  String get managerComment => 'مینیجر کا تبصرہ';

  @override
  String get managerCommentHint => 'سیلز پرسن کے لیے رائے یا اگلے اقدامات';

  @override
  String get noManagerComment => 'ابھی مینیجر کا کوئی تبصرہ نہیں۔';

  @override
  String get saveComment => 'تبصرہ محفوظ کریں';

  @override
  String get purposeCollectPayment => 'ادائیگی وصول کرنا';

  @override
  String get purposeRequestPayment => 'ادائیگی کا مطالبہ';

  @override
  String get purposeNewOrder => 'نیا آرڈر';

  @override
  String get purposeOrderFollowUp => 'آرڈر کی پیروی';

  @override
  String get purposeQuotationFollowUp => 'کوٹیشن کی پیروی';

  @override
  String get purposeSamples => 'نمونے جمع کرانا';

  @override
  String get purposeComplaint => 'شکایت نمٹانا';

  @override
  String get purposeNewProduct => 'نئی پروڈکٹ پیش کرنا';

  @override
  String get purposeProjectDiscussion => 'پروجیکٹ پر گفتگو';

  @override
  String get purposeNewClient => 'نیا کلائنٹ';

  @override
  String get purposeReestablish => 'کاروبار دوبارہ شروع کرنا';

  @override
  String get purposeCatchUp => 'ملاقات';

  @override
  String get purposeOther => 'دیگر';

  @override
  String get phoneProblems => 'فون کے مسائل';

  @override
  String get outsideSite => 'سائٹ سے باہر';

  @override
  String get noLocationYet => 'ابھی کوئی مقام نہیں';

  @override
  String locationUpdated(String time) {
    return 'مقام اپ ڈیٹ: $time';
  }

  @override
  String distanceFromSite(String distance, String site) {
    return '$site سے $distance دور';
  }

  @override
  String kilometersShort(String km) {
    return '$km کلومیٹر';
  }

  @override
  String get showEveryone => 'سب کو دکھائیں';

  @override
  String peopleOnMap(int located, int total) {
    return 'نقشے پر $total میں سے $located';
  }

  @override
  String get newProjectHere => 'یہاں نیا پروجیکٹ';

  @override
  String get newMockupHere => 'یہاں نیا ماک اپ';
}
