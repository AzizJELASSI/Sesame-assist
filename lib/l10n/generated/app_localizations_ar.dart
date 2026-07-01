// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'سيسامي أسيست برو';

  @override
  String get tagline => 'نظام تذاكر جامعي ذكي';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get noAccount => 'ليس لديك حساب؟';

  @override
  String get haveAccount => 'لديك حساب بالفعل؟';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get role => 'الدور';

  @override
  String get roleStudent => 'طالب';

  @override
  String get roleTeacher => 'أستاذ';

  @override
  String get roleAgent => 'وكيل الدعم';

  @override
  String get roleAdmin => 'مدير';

  @override
  String get department => 'القسم';

  @override
  String get filiere => 'التخصص';

  @override
  String get selectDepartment => 'اختر القسم';

  @override
  String get selectFiliere => 'اختر التخصص';

  @override
  String get dashboard => 'لوحة التحكم';

  @override
  String get myTickets => 'تذاكري';

  @override
  String get newTicket => 'تذكرة جديدة';

  @override
  String get allTickets => 'جميع التذاكر';

  @override
  String get queue => 'قائمة الانتظار';

  @override
  String get reports => 'التقارير';

  @override
  String get users => 'المستخدمون';

  @override
  String get settings => 'الإعدادات';

  @override
  String get ticketTitle => 'العنوان';

  @override
  String get ticketDescription => 'الوصف';

  @override
  String get ticketType => 'النوع';

  @override
  String get ticketPriority => 'الأولوية';

  @override
  String get ticketStatus => 'الحالة';

  @override
  String get ticketDepartment => 'القسم';

  @override
  String get ticketCreatedBy => 'أُنشئت بواسطة';

  @override
  String get ticketAssignedTo => 'مُسندة إلى';

  @override
  String get ticketCreatedAt => 'تاريخ الإنشاء';

  @override
  String get ticketUpdatedAt => 'آخر تحديث';

  @override
  String get priorityLow => 'منخفضة';

  @override
  String get priorityMedium => 'متوسطة';

  @override
  String get priorityHigh => 'عالية';

  @override
  String get statusOpen => 'مفتوحة';

  @override
  String get statusInProgress => 'قيد المعالجة';

  @override
  String get statusWaitingOnUser => 'بانتظارك';

  @override
  String get statusResolved => 'محلولة';

  @override
  String get statusClosed => 'مغلقة';

  @override
  String get ticketTypeAcademic => 'أكاديمي';

  @override
  String get ticketTypeIT => 'مشكلة تقنية';

  @override
  String get ticketTypeHR => 'شؤون موارد بشرية';

  @override
  String get ticketTypeFacility => 'البنية التحتية';

  @override
  String get ticketTypeClassroomIT => 'تقنية قاعة الدراسة';

  @override
  String get comments => 'التعليقات';

  @override
  String get addComment => 'أضف تعليقاً…';

  @override
  String get internalNote => 'ملاحظة داخلية';

  @override
  String get submitComment => 'إرسال';

  @override
  String get aiAssistant => 'المساعد الذكي';

  @override
  String get aiHint => 'صف مشكلتك وسأساعدك في إنشاء تذكرة…';

  @override
  String get aiDraftReady => 'المسودة جاهزة — راجع وأكد';

  @override
  String get aiConfirm => 'إنشاء التذكرة';

  @override
  String get aiEdit => 'تعديل المسودة';

  @override
  String get aiDiscard => 'تجاهل';

  @override
  String get noTickets => 'لا توجد تذاكر بعد';

  @override
  String get noTicketsHint => 'اضغط + لإنشاء أول تذكرة';

  @override
  String get search => 'ابحث في التذاكر…';

  @override
  String get filter => 'تصفية';

  @override
  String get sortBy => 'ترتيب حسب';

  @override
  String get sortNewest => 'الأحدث أولاً';

  @override
  String get sortOldest => 'الأقدم أولاً';

  @override
  String get sortPriority => 'حسب الأولوية';

  @override
  String get save => 'حفظ';

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get edit => 'تعديل';

  @override
  String get confirm => 'تأكيد';

  @override
  String get loading => 'جاري التحميل…';

  @override
  String get error => 'حدث خطأ ما';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get success => 'نجاح';

  @override
  String get validationRequired => 'هذا الحقل مطلوب';

  @override
  String get validationEmail => 'أدخل بريداً إلكترونياً صحيحاً';

  @override
  String get validationPasswordLength =>
      'يجب أن تتكون كلمة المرور من 8 أحرف على الأقل';

  @override
  String get validationPasswordMatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get language => 'اللغة';

  @override
  String get langEn => 'English';

  @override
  String get langFr => 'Français';

  @override
  String get langAr => 'العربية';

  @override
  String get totalTickets => 'إجمالي التذاكر';

  @override
  String get openTickets => 'مفتوحة';

  @override
  String get resolvedTickets => 'محلولة';

  @override
  String get avgResolutionTime => 'متوسط وقت الحل';

  @override
  String get attachments => 'المرفقات';

  @override
  String get addAttachment => 'إضافة ملف';

  @override
  String get noAttachments => 'لا توجد مرفقات';

  @override
  String get attachmentUploading => 'جاري الرفع…';

  @override
  String get attachmentDownload => 'تحميل';

  @override
  String get updateStatus => 'تحديث الحالة';

  @override
  String get deleteTicket => 'حذف التذكرة';

  @override
  String get deleteTicketConfirm =>
      'هل أنت متأكد أنك تريد حذف هذه التذكرة؟ لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get deleteConfirmBtn => 'نعم، احذف';

  @override
  String get ticketDeleted => 'تم حذف التذكرة بنجاح';

  @override
  String get agentQueue => 'قائمة انتظار الوكيل';

  @override
  String get adminPanel => 'لوحة الإدارة';

  @override
  String get userManagement => 'إدارة المستخدمين';

  @override
  String get departmentManagement => 'إدارة الأقسام';

  @override
  String get systemStats => 'إحصائيات النظام';

  @override
  String get bulkUpdate => 'تحديث جماعي';

  @override
  String get bulkUpdateStatus => 'تحديث حالة المحددين';

  @override
  String selectedCount(int count) {
    return '$count محدد';
  }

  @override
  String get clearSelection => 'مسح التحديد';

  @override
  String get selectAll => 'تحديد الكل';

  @override
  String get noUsersFound => 'لم يتم العثور على مستخدمين';

  @override
  String get createUser => 'إنشاء مستخدم';

  @override
  String get editUser => 'تعديل المستخدم';

  @override
  String get deleteUser => 'حذف المستخدم';

  @override
  String get deleteUserConfirm =>
      'هل أنت متأكد من حذف هذا المستخدم؟ سيتم إزالة حسابه نهائياً.';

  @override
  String get userSaved => 'تم حفظ المستخدم بنجاح';

  @override
  String get userDeleted => 'تم حذف المستخدم بنجاح';

  @override
  String get assignRole => 'تعيين دور';

  @override
  String get assignDepartment => 'تعيين قسم';

  @override
  String get totalUsers => 'إجمالي المستخدمين';

  @override
  String get totalAgents => 'إجمالي الوكلاء';

  @override
  String get closedTickets => 'مغلقة';

  @override
  String get activeTickets => 'نشطة';

  @override
  String get systemOverview => 'نظرة عامة على النظام';

  @override
  String get departmentBreakdown => 'توزيع الأقسام';

  @override
  String get filterByDepartment => 'تصفية حسب القسم';

  @override
  String get filterByStatus => 'تصفية حسب الحالة';

  @override
  String get filterByPriority => 'تصفية حسب الأولوية';

  @override
  String get allDepartments => 'جميع الأقسام';

  @override
  String get allStatuses => 'جميع الحالات';

  @override
  String get allPriorities => 'جميع الأولويات';

  @override
  String get sortNewestFirst => 'الأحدث أولاً';

  @override
  String get sortOldestFirst => 'الأقدم أولاً';

  @override
  String get sortByPriority => 'حسب الأولوية';

  @override
  String get completeYourProfile => 'أكمل ملفك الشخصي';

  @override
  String get completeProfileHint => 'حسابك جاهز. يرجى إضافة معلوماتك للبدء.';

  @override
  String get saveAndContinue => 'حفظ ومتابعة';
}
