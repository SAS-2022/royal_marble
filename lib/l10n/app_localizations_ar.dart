// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get languageName => 'العربية';

  @override
  String get language => 'اللغة';

  @override
  String get chooseLanguage => 'اختر اللغة';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get back => 'رجوع';

  @override
  String get continueLabel => 'متابعة';

  @override
  String get required => 'مطلوب';

  @override
  String get settings => 'الإعدادات';

  @override
  String get allow => 'سماح';

  @override
  String get fix => 'إصلاح';

  @override
  String get turnOn => 'تشغيل';

  @override
  String get roleAdmin => 'مدير';

  @override
  String get roleSupervisor => 'مشرف';

  @override
  String get roleSales => 'مبيعات';

  @override
  String get roleSiteEngineer => 'مهندس موقع';

  @override
  String get roleMason => 'عامل بناء';

  @override
  String get welcomeBack => 'مرحباً بعودتك';

  @override
  String get signInToContinue => 'سجّل الدخول للمتابعة';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get enterValidEmail => 'أدخل بريداً إلكترونياً صحيحاً';

  @override
  String get enterPassword => 'أدخل كلمة المرور';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get newToApp => 'جديد في رويال ماربل؟';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get errInvalidEmail => 'يبدو أن البريد الإلكتروني غير صحيح.';

  @override
  String get errUserDisabled => 'تم إيقاف هذا الحساب. تواصل مع المدير.';

  @override
  String get errTooManyRequests =>
      'محاولات كثيرة. انتظر بضع دقائق ثم حاول مرة أخرى.';

  @override
  String get errNoInternet => 'لا يوجد اتصال بالإنترنت.';

  @override
  String get errWrongCredentials =>
      'البريد الإلكتروني أو كلمة المرور غير صحيحة.';

  @override
  String get errSignInGeneric => 'تعذّر تسجيل الدخول. حاول مرة أخرى.';

  @override
  String get resetPassword => 'إعادة تعيين كلمة المرور';

  @override
  String get resetIntro =>
      'أدخل البريد الإلكتروني الذي تسجّل به وسنرسل لك رابطاً لاختيار كلمة مرور جديدة.';

  @override
  String get sendResetLink => 'إرسال الرابط';

  @override
  String get checkYourEmail => 'تحقق من بريدك الإلكتروني';

  @override
  String resetSent(String email) {
    return 'أرسلنا رابط إعادة التعيين إلى $email.';
  }

  @override
  String get backToSignIn => 'العودة لتسجيل الدخول';

  @override
  String get resetError =>
      'تعذّر إرسال البريد. تحقق من العنوان وحاول مرة أخرى.';

  @override
  String stepOf(int step, int total) {
    return 'الخطوة $step من $total';
  }

  @override
  String get stepAboutYou => 'معلوماتك';

  @override
  String get stepContact => 'التواصل';

  @override
  String get stepAccount => 'الحساب';

  @override
  String get addPhotoHint => 'أضف صورة واضحة لوجهك';

  @override
  String get tapToChange => 'اضغط للتغيير';

  @override
  String get takePhoto => 'التقاط صورة';

  @override
  String get chooseFromGallery => 'اختيار من المعرض';

  @override
  String get firstName => 'الاسم الأول';

  @override
  String get lastName => 'اسم العائلة';

  @override
  String get nationality => 'الجنسية';

  @override
  String get mobileNumber => 'رقم الجوال';

  @override
  String get mobileInvalid => 'أدخل رقم جوال إماراتي (05X XXX XXXX)';

  @override
  String get company => 'الشركة';

  @override
  String get homeAddress => 'عنوان السكن';

  @override
  String get passwordHelper => '6 أحرف على الأقل';

  @override
  String get passwordTooShort => 'استخدم 6 أحرف على الأقل';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get passwordsDontMatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get approvalNotice =>
      'يراجع المدير الحسابات الجديدة. يمكنك تسجيل الدخول بعد الموافقة على حسابك.';

  @override
  String get photoRequired => 'أضف صورة ليتعرّف عليك المشرف.';

  @override
  String get nationalityRequired => 'اختر جنسيتك.';

  @override
  String get homeRequired => 'حدّد عنوان سكنك على الخريطة.';

  @override
  String get cameraError => 'تعذّر فتح الكاميرا أو المعرض.';

  @override
  String get emailInUse =>
      'يوجد حساب بهذا البريد الإلكتروني. جرّب تسجيل الدخول.';

  @override
  String get registerFailed =>
      'تعذّر إنشاء الحساب. تحقق من بياناتك وحاول مرة أخرى.';

  @override
  String get somethingWrong => 'حدث خطأ ما. حاول مرة أخرى.';

  @override
  String greetingMorning(String name) {
    return 'صباح الخير، $name';
  }

  @override
  String greetingAfternoon(String name) {
    return 'مساء الخير، $name';
  }

  @override
  String greetingEvening(String name) {
    return 'مساء الخير، $name';
  }

  @override
  String get offlineBanner =>
      'أنت غير متصل. ستتم مزامنة التغييرات عند عودة الاتصال.';

  @override
  String get pendingTitle => 'شكراً لتسجيلك';

  @override
  String get pendingBody =>
      'حسابك بانتظار الموافقة. ستتمكن من الدخول بعد أن يفعّله المدير.';

  @override
  String get yourSite => 'موقع عملك';

  @override
  String get yourSites => 'مواقع عملك';

  @override
  String get noSiteTitle => 'لم يتم تعيين موقع بعد';

  @override
  String get noSiteBody => 'سيعيّنك المشرف على أحد المشاريع.';

  @override
  String get noSitesAssigned => 'لا توجد مواقع معيّنة.';

  @override
  String yourTeam(int count) {
    return 'فريقك ($count)';
  }

  @override
  String get nobodyYet => 'لا أحد بعد.';

  @override
  String onSiteAtSince(String site, String time) {
    return 'في الموقع $site منذ $time';
  }

  @override
  String get checkedOut => 'سجّل الخروج';

  @override
  String get notCheckedIn => 'لم يسجّل الحضور';

  @override
  String durationHm(int hours, int minutes) {
    return '$hours س $minutes د';
  }

  @override
  String durationM(int minutes) {
    return '$minutes د';
  }

  @override
  String onSiteSince(String time, String duration) {
    return 'في الموقع منذ $time · $duration';
  }

  @override
  String checkedInAtSite(String site) {
    return 'مسجّل الحضور في $site';
  }

  @override
  String doneToday(String duration) {
    return 'انتهى اليوم · $duration';
  }

  @override
  String get withinSiteArea => 'داخل نطاق الموقع';

  @override
  String kmAway(String km) {
    return 'على بعد $km كم';
  }

  @override
  String metersAway(int meters) {
    return 'على بعد $meters م';
  }

  @override
  String get gettingGpsFix => 'جارٍ تحديد موقعك بدقة…';

  @override
  String get checkIn => 'تسجيل الحضور';

  @override
  String get checkOut => 'تسجيل الخروج';

  @override
  String get workCompletedTitle => 'العمل المنجز اليوم';

  @override
  String get workSystem => 'نظام';

  @override
  String get workTiles => 'بلاط';

  @override
  String get workOthers => 'أخرى';

  @override
  String get describeWork => 'صف العمل';

  @override
  String get areaCompleted => 'المساحة المنجزة';

  @override
  String get enterNumber => 'أدخل رقماً';

  @override
  String checkedInAt(String time) {
    return 'تم تسجيل الحضور الساعة $time. يوماً موفقاً!';
  }

  @override
  String checkedOutAt(String time) {
    return 'تم تسجيل الخروج الساعة $time. شكراً لك!';
  }

  @override
  String get errLocationUnavailable =>
      'تعذّر تحديد موقعك. تأكد من تشغيل خدمة الموقع وحاول مرة أخرى.';

  @override
  String get errNoServer =>
      'لا يوجد اتصال بالخادم. تحقق من الإنترنت وحاول مرة أخرى.';

  @override
  String errCheckInFailed(String code) {
    return 'فشل تسجيل الحضور ($code).';
  }

  @override
  String get errSignInAgain => 'يرجى تسجيل الدخول مرة أخرى.';

  @override
  String get errNotActive => 'حسابك غير مفعّل.';

  @override
  String get errMockLocation =>
      'تم اكتشاف تطبيق لتزييف الموقع. أوقفه لتتمكن من تسجيل الحضور.';

  @override
  String errWeakGps(int meters) {
    return 'إشارة GPS ضعيفة (±$meters م). اخرج إلى مكان مفتوح أو انتظر قليلاً وحاول مرة أخرى.';
  }

  @override
  String get errNoSiteLocation =>
      'لم يتم تحديد موقع لهذا المشروع. تواصل مع المدير.';

  @override
  String errOutOfRange(int meters) {
    return 'أنت على بعد $meters م خارج الموقع.';
  }

  @override
  String errAlreadyCheckedIn(String site) {
    return 'أنت مسجّل الحضور بالفعل في $site.';
  }

  @override
  String get errNotCheckedIn => 'لم تسجّل الحضور.';

  @override
  String errCheckedInElsewhere(String site) {
    return 'أنت مسجّل الحضور في $site. سجّل الخروج من هناك أولاً.';
  }

  @override
  String get errNotAssigned => 'أنت غير معيّن على هذا الموقع.';

  @override
  String get trackingActive => 'التتبع يعمل';

  @override
  String get waitingForGps => 'بانتظار إشارة GPS…';

  @override
  String gpsAccuracy(int meters) {
    return 'دقة GPS ±$meters م';
  }

  @override
  String get locationOffTitle => 'خدمة الموقع متوقفة';

  @override
  String get locationOffBody => 'تم إبلاغ المدير. شغّلها للمتابعة.';

  @override
  String get allowAlwaysTitle => 'اسمح بالموقع \"طوال الوقت\"';

  @override
  String get allowAlwaysBody => 'مطلوب ليعمل تسجيل الحضور والتطبيق مغلق.';

  @override
  String get preciseOffTitle => 'الموقع الدقيق متوقف';

  @override
  String get preciseOffBody => 'فعّل \"استخدام الموقع الدقيق\" لهذا التطبيق.';

  @override
  String get noInternetTitle => 'لا يوجد اتصال بالإنترنت';

  @override
  String get noInternetBody => 'يتم حفظ موقعك وسيُرسل عند عودة الاتصال.';

  @override
  String get batterySaverTitle => 'وضع توفير البطارية مفعّل';

  @override
  String get batterySaverBody => 'قد يتأخر التتبع. أوقفه خلال ساعات العمل.';

  @override
  String get batteryOptTitle => 'تحسين البطارية مفعّل';

  @override
  String get batteryOptBody => 'قد يتوقف هاتفك عن التتبع في الخلفية.';

  @override
  String get myPay => 'راتبي';

  @override
  String get yourPackage => 'تفاصيل راتبك';

  @override
  String get payNotAddedTitle => 'لم تتم إضافة تفاصيل راتبك بعد.';

  @override
  String get payNotAddedBody => 'اسأل المدير إذا كنت تعتقد أن هناك خطأ.';

  @override
  String get payTypeMonthly => 'راتب شهري';

  @override
  String get payTypeDaily => 'أجر يومي';

  @override
  String get payTypeHourly => 'أجر بالساعة';

  @override
  String get perMonth => '/ شهرياً';

  @override
  String get perDay => '/ يومياً';

  @override
  String get perHour => '/ للساعة';

  @override
  String get basic => 'الراتب الأساسي';

  @override
  String get housing => 'بدل السكن';

  @override
  String get transportation => 'بدل المواصلات';

  @override
  String get food => 'بدل الطعام';

  @override
  String get totalPerMonth => 'الإجمالي الشهري';

  @override
  String get allowancesMonthly => 'البدلات مبالغ شهرية.';

  @override
  String effectiveFrom(String date) {
    return 'اعتباراً من $date';
  }

  @override
  String get myProfile => 'ملفي الشخصي';

  @override
  String get sectionTeam => 'الفريق';

  @override
  String get teamStatusAlerts => 'حالة الفريق والتنبيهات';

  @override
  String get liveMap => 'الخريطة المباشرة';

  @override
  String get users => 'المستخدمون';

  @override
  String get sectionSites => 'المواقع';

  @override
  String get newProject => 'مشروع جديد';

  @override
  String get newMockup => 'عيّنة جديدة';

  @override
  String get sectionSales => 'المبيعات';

  @override
  String get clients => 'العملاء';

  @override
  String get addClient => 'إضافة عميل';

  @override
  String get newVisit => 'زيارة جديدة';

  @override
  String get visits => 'الزيارات';

  @override
  String get sectionReports => 'التقارير';

  @override
  String get attendance => 'الحضور';

  @override
  String get salesActivity => 'نشاط المبيعات';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get signOutTitle => 'تسجيل الخروج؟';

  @override
  String get signOutBody =>
      'سيتوقف تتبع الموقع ولن تتمكن من تسجيل الحضور حتى تسجّل الدخول مرة أخرى.';
}
