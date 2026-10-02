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
  String get detailsAssignWorkers => 'تفصیلات اور کارکن مقرر کریں';

  @override
  String get details => 'تفصیلات';

  @override
  String get workersCurrentState => 'کارکنوں کی موجودہ صورتحال';

  @override
  String get changeStatus => 'صورتحال تبدیل کریں';

  @override
  String get myVisits => 'میرے وزٹس';

  @override
  String get site => 'سائٹ';
}
