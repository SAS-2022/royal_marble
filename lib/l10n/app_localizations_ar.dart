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

  @override
  String get teamStatus => 'حالة الفريق';

  @override
  String get onSiteNow => 'في الموقع الآن';

  @override
  String get phoneAlerts => 'تنبيهات الهواتف';

  @override
  String get pendingLabel => 'قيد الانتظار';

  @override
  String get needsAttention => 'يحتاج إلى متابعة';

  @override
  String get seeAll => 'عرض الكل';

  @override
  String get todaysAttendance => 'حضور اليوم';

  @override
  String get alertLog => 'سجل التنبيهات';

  @override
  String activeProjects(int count) {
    return 'المشاريع النشطة ($count)';
  }

  @override
  String activeMockups(int count) {
    return 'العيّنات النشطة ($count)';
  }

  @override
  String potentialProjects(int count) {
    return 'مشاريع محتملة ($count)';
  }

  @override
  String get nobodyCheckedInToday => 'لم يسجّل أحد الحضور اليوم بعد.';

  @override
  String get detailsAssignWorkers => 'التفاصيل وتعيين العمال';

  @override
  String get details => 'التفاصيل';

  @override
  String get workersCurrentState => 'الحالة الحالية للعمال';

  @override
  String get changeStatus => 'تغيير الحالة';

  @override
  String get myVisits => 'زياراتي';

  @override
  String get site => 'موقع';

  @override
  String get problemSilent => 'لا يرسل بيانات';

  @override
  String get problemLocationOff => 'الموقع متوقف';

  @override
  String problemPermission(String value) {
    return 'الإذن: $value';
  }

  @override
  String get problemTrackingStopped => 'التتبع متوقف';

  @override
  String get problemOffline => 'غير متصل';

  @override
  String get problemApproximate => 'موقع تقريبي';

  @override
  String get problemBatterySaver => 'توفير البطارية مفعّل';

  @override
  String problemBattery(int percent) {
    return 'البطارية $percent%';
  }

  @override
  String get permWhenInUse => 'أثناء الاستخدام';

  @override
  String get permDenied => 'مرفوض';

  @override
  String get permRestricted => 'مقيّد';

  @override
  String get permNotDetermined => 'غير محدد';

  @override
  String get permAlways => 'طوال الوقت';

  @override
  String get unknownUser => 'غير معروف';

  @override
  String get timeNever => 'أبداً';

  @override
  String get timeJustNow => 'الآن';

  @override
  String timeMinAgo(int n) {
    return 'منذ $n د';
  }

  @override
  String timeHoursAgo(int n) {
    return 'منذ $n س';
  }

  @override
  String seenAgo(String when) {
    return 'آخر ظهور $when';
  }

  @override
  String lastSeen(String when) {
    return 'آخر ظهور $when';
  }

  @override
  String get phonesTab => 'الهواتف';

  @override
  String get alertsTab => 'التنبيهات';

  @override
  String get noActiveWorkers => 'لا يوجد عمال نشطون';

  @override
  String get notOnNewApp => 'لم يحدّث التطبيق بعد';

  @override
  String get allGood => 'كل شيء جيد';

  @override
  String gpsShort(int meters) {
    return 'GPS ±$meters م';
  }

  @override
  String get alertsNotEnabled => 'التنبيهات غير مفعّلة على الخادم بعد.';

  @override
  String get alertsLoadError => 'تعذّر تحميل التنبيهات. تحقق من اتصالك.';

  @override
  String get noAlertsYet => 'لا توجد تنبيهات بعد';

  @override
  String get evLocationOff => 'تم إيقاف خدمة الموقع';

  @override
  String get evLocationOn => 'تم تشغيل خدمة الموقع مجدداً';

  @override
  String get evGpsOff => 'تم إيقاف GPS (موقع الشبكة فقط)';

  @override
  String get evGpsOn => 'تم تشغيل GPS مجدداً';

  @override
  String get evPreciseOff => 'تم إيقاف الموقع الدقيق';

  @override
  String get evPreciseOn => 'تم تشغيل الموقع الدقيق مجدداً';

  @override
  String evPermission(String value) {
    return 'تم تغيير إذن الموقع إلى \"$value\"';
  }

  @override
  String get evOffline => 'انقطع اتصال الهاتف بالإنترنت';

  @override
  String get evOnline => 'عاد الهاتف للاتصال';

  @override
  String get evPowerSaveOn => 'تم تشغيل توفير البطارية (قد يتأخر التتبع)';

  @override
  String get evPowerSaveOff => 'تم إيقاف توفير البطارية';

  @override
  String get evTrackingStopped => 'توقف تتبع الموقع';

  @override
  String get evTrackingStarted => 'بدأ تتبع الموقع';

  @override
  String get evAppClosed => 'تم إغلاق التطبيق (يستمر التتبع)';

  @override
  String get evDeviceBoot => 'تمت إعادة تشغيل الهاتف';

  @override
  String get evMock => 'تم اكتشاف موقع مزيّف';

  @override
  String get evMockCleared => 'عاد الموقع الحقيقي';

  @override
  String evBatteryLow(int percent) {
    return 'البطارية منخفضة ($percent%)';
  }

  @override
  String get evBatteryOk => 'تعافت البطارية';

  @override
  String get evSilent =>
      'توقف الهاتف عن الإرسال. قد يكون مغلقاً أو غير متصل أو تم إيقاف التطبيق.';

  @override
  String get usersAll => 'الكل';

  @override
  String activeTab(int count) {
    return 'نشط ($count)';
  }

  @override
  String pendingTab(int count) {
    return 'قيد الانتظار ($count)';
  }

  @override
  String get searchUsers => 'ابحث بالاسم أو البريد أو الهاتف';

  @override
  String get noActiveUsersMatch => 'لا يوجد مستخدمون نشطون مطابقون.';

  @override
  String get nobodyWaiting => 'لا أحد بانتظار الموافقة.';

  @override
  String get review => 'مراجعة';

  @override
  String roleChangedTo(String role) {
    return 'تم تغيير الدور إلى $role';
  }

  @override
  String get roleChangeFailed => 'تعذّر تغيير الدور.';

  @override
  String get accountActivated => 'تم تفعيل الحساب';

  @override
  String get accountDeactivated => 'تم إيقاف الحساب';

  @override
  String get accessUpdateFailed => 'تعذّر تحديث الصلاحية.';

  @override
  String deleteUserTitle(String name) {
    return 'حذف $name؟';
  }

  @override
  String get deleteUserBody =>
      'سيتم حذف الملف نهائياً. يتم الاحتفاظ بسجلات الحضور السابقة.';

  @override
  String get delete => 'حذف';

  @override
  String get statusActive => 'نشط';

  @override
  String get statusPendingInactive => 'قيد الانتظار / غير نشط';

  @override
  String get waitingForAccess => 'هذا الحساب بانتظار الصلاحية.';

  @override
  String get approve => 'موافقة';

  @override
  String get sectionContact => 'التواصل';

  @override
  String get sectionWork => 'العمل';

  @override
  String get noSiteAssigned => 'لا يوجد موقع معيّن';

  @override
  String get assignedSite => 'الموقع المعيّن';

  @override
  String get phoneReportingNormally => 'الهاتف يرسل بشكل طبيعي';

  @override
  String get recentAlerts => 'أحدث التنبيهات';

  @override
  String get sectionPay => 'الراتب';

  @override
  String get sectionRole => 'الدور';

  @override
  String get sectionAccess => 'الصلاحية';

  @override
  String get deactivateAccount => 'إيقاف الحساب';

  @override
  String get activateAccount => 'تفعيل الحساب';

  @override
  String get deactivateBeforeDeleting => 'أوقف الحساب قبل الحذف';

  @override
  String get deletePermanently => 'حذف الحساب نهائياً';

  @override
  String get userTitle => 'المستخدم';

  @override
  String get project => 'مشروع';

  @override
  String get mockup => 'عيّنة';

  @override
  String get edit => 'تعديل';

  @override
  String checkInRadius(int meters) {
    return 'نطاق تسجيل الحضور $meters م';
  }

  @override
  String get directions => 'الاتجاهات';

  @override
  String get today => 'اليوم';

  @override
  String get contractor => 'المقاول';

  @override
  String teamCount(int count) {
    return 'الفريق ($count)';
  }

  @override
  String get manage => 'إدارة';

  @override
  String get nobodyAssigned => 'لم يتم تعيين أحد بعد.';

  @override
  String peopleAssigned(int count) {
    return '$count أشخاص معيّنون.';
  }

  @override
  String get onSite => 'في الموقع';

  @override
  String get away => 'خارج الموقع';

  @override
  String get teamUpdated => 'تم تحديث الفريق';

  @override
  String get teamUpdateFailed => 'تعذّر تحديث الفريق.';

  @override
  String teamOf(String site) {
    return 'الفريق · $site';
  }

  @override
  String selectedCount(int count) {
    return '$count محدد';
  }

  @override
  String get searchPeople => 'ابحث عن أشخاص';

  @override
  String get saveTeam => 'حفظ الفريق';

  @override
  String currentlyAt(String site) {
    return 'أيضاً في $site';
  }

  @override
  String get payUnavailable => 'تفاصيل الراتب غير متاحة بعد.';

  @override
  String get noPayDetails => 'لا توجد تفاصيل راتب بعد.';

  @override
  String get setPayDetails => 'إضافة تفاصيل الراتب';

  @override
  String get editPayDetails => 'تعديل تفاصيل الراتب';

  @override
  String get paySaved => 'تم حفظ تفاصيل الراتب';

  @override
  String get enterValidAmount => 'أدخل مبلغاً صحيحاً';

  @override
  String payFor(String name) {
    return 'الراتب · $name';
  }

  @override
  String get monthly => 'شهري';

  @override
  String get daily => 'يومي';

  @override
  String get hourly => 'بالساعة';

  @override
  String get monthlyAllowances => 'البدلات الشهرية';

  @override
  String get allowance => 'البدل';

  @override
  String get nameIt => 'أدخل الاسم';

  @override
  String get amount => 'المبلغ';

  @override
  String get addAllowance => 'إضافة بدل آخر';

  @override
  String get effectiveFromLabel => 'ساري من';

  @override
  String get notesOptional => 'ملاحظات (اختياري)';

  @override
  String get summary => 'الملخص';

  @override
  String get savePayDetails => 'حفظ تفاصيل الراتب';

  @override
  String get yesterday => 'أمس';

  @override
  String get thisWeek => 'هذا الأسبوع';

  @override
  String get lastWeek => 'الأسبوع الماضي';

  @override
  String get thisMonth => 'هذا الشهر';

  @override
  String get lastMonth => 'الشهر الماضي';

  @override
  String get customRange => 'مخصص…';

  @override
  String get reportLoadError => 'تعذّر تحميل التقرير. تحقق من اتصالك.';

  @override
  String get nothingToExport => 'لا يوجد ما يُصدَّر لهذه الفترة.';

  @override
  String get pdfSubtitle => 'معاينة أو طباعة أو مشاركة';

  @override
  String get excelSubtitle => 'السجلات اليومية وورقة ملخص';

  @override
  String get export => 'تصدير';

  @override
  String get everyone => 'الجميع';

  @override
  String get rolesMasons => 'عمال البناء';

  @override
  String get rolesSiteEngineers => 'مهندسو المواقع';

  @override
  String get rolesSupervisors => 'المشرفون';

  @override
  String get people => 'الأشخاص';

  @override
  String get hours => 'الساعات';

  @override
  String get areaM2 => 'المساحة م²';

  @override
  String missingCheckouts(int count) {
    return 'سجلات بدون تسجيل خروج: $count. لا تُحتسب ساعاتها.';
  }

  @override
  String get viewBy => 'عرض حسب';

  @override
  String get person => 'الشخص';

  @override
  String get day => 'اليوم';

  @override
  String get noAttendance => 'لا يوجد حضور في هذه الفترة.';

  @override
  String get noSalesTeam => 'لا يوجد أعضاء في فريق المبيعات.';

  @override
  String get salespeople => 'مندوبو المبيعات';

  @override
  String get noVisits => 'لا توجد زيارات في هذه الفترة.';

  @override
  String get client => 'عميل';

  @override
  String get noOut => 'بدون خروج';

  @override
  String daysCount(int count) {
    return '$count يوم';
  }

  @override
  String salesSummary(int days, int client, int project) {
    return '$days أيام عمل · $client زيارة عميل · $project زيارة مشروع';
  }

  @override
  String peopleCount(int count) {
    return '$count أشخاص';
  }

  @override
  String get nowLabel => 'الآن';

  @override
  String get switchHere => 'الانتقال إلى هذا الموقع';

  @override
  String get switchSiteTitle => 'تغيير الموقع؟';

  @override
  String switchSiteBody(String from, String to) {
    return 'سيتم تسجيل خروجك من $from وتسجيل دخولك في $to.';
  }

  @override
  String outsideSiteSince(String time) {
    return 'خارج الموقع منذ $time';
  }

  @override
  String get autoCheckedOut => 'تم تسجيل الخروج تلقائياً';

  @override
  String evLeftSite(String site) {
    return 'غادر $site أثناء تسجيل الدخول';
  }

  @override
  String evReturnedToSite(String site) {
    return 'عاد إلى $site';
  }

  @override
  String evAutoCheckout(String site) {
    return 'تم تسجيل خروجه تلقائياً من $site';
  }

  @override
  String get allSites => 'كل المواقع';

  @override
  String autoCheckoutsToReview(int count) {
    return 'عمليات خروج تلقائية بانتظار المراجعة: $count.';
  }

  @override
  String autoCheckoutsToReviewTap(int count) {
    return 'عمليات خروج تلقائية بانتظار المراجعة: $count. اضغط على أي سجل لتصحيحه أو اعتماده.';
  }

  @override
  String awayFor(String duration) {
    return 'خارج الموقع $duration';
  }

  @override
  String get autoLeftSiteShort => 'تلقائي: غادر الموقع';

  @override
  String get autoEndOfDayShort => 'تلقائي: نهاية اليوم';

  @override
  String get editedByAdmin => 'معدّل';

  @override
  String noOutCount(int count) {
    return '$count بدون خروج';
  }

  @override
  String get errEndBeforeStart => 'يجب أن يكون الخروج بعد الدخول.';

  @override
  String get errOnlyLastOpen => 'يمكن ترك آخر فترة فقط بدون خروج.';

  @override
  String get errSessionsOverlap => 'فترتان متداخلتان. عدّل الأوقات.';

  @override
  String get attendanceSaved => 'تم حفظ الحضور';

  @override
  String get errNotAdmin => 'يمكن للمسؤولين فقط تصحيح الحضور.';

  @override
  String get reviewHint =>
      'أغلق النظام هذا اليوم تلقائياً. صحّح الأوقات إذا لزم، أو اعتمدها كما هي.';

  @override
  String get addSession => 'إضافة فترة';

  @override
  String get correctionNote => 'السبب';

  @override
  String get correctionNoteHint => 'مثال: نسي تسجيل الخروج، أكده المشرف';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get approveAsIs => 'اعتماد كما هو';

  @override
  String get correctionHistory => 'سجل التغييرات';

  @override
  String previously(String sessions) {
    return 'سابقاً: $sessions';
  }

  @override
  String get removeSession => 'حذف هذه الفترة';

  @override
  String get inLabel => 'دخول';

  @override
  String get outLabel => 'خروج';

  @override
  String get setCheckOut => 'تحديد الخروج';

  @override
  String get leaveOpen => 'إبقاؤها مفتوحة (ما زال في الموقع)';

  @override
  String get leftAt => 'غادر';

  @override
  String get returnedAt => 'عاد';
}
