// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'استوديو آب إيمج';

  @override
  String get appSubtitle =>
      'حوّل أي مجلد تطبيق مجمّع (Flutter, Rust, Go, C++, etc.) إلى حزمة AppImage مستقلة بنقرة واحدة';

  @override
  String get switchLanguage => 'تغيير اللغة';

  @override
  String get appVersion => 'v1.0.0';

  @override
  String get developedBy => 'تطوير بكل ❤️ بواسطة علي الخضر والمساهمين';

  @override
  String get sourceCardTitle => '1. مسار مجلد التطبيق والملف التنفيذي';

  @override
  String get bundleDirLabel => 'مجلد التطبيق (Bundle Directory)';

  @override
  String get bundleDirHint => 'اختر مجلد الـ bundle أو مجلد المشروع المجمّع...';

  @override
  String get executableLabel => 'اسم الملف التنفيذي (Executable Binary)';

  @override
  String get executableHint => 'مثال: my_app أو runner';

  @override
  String get autoDetectedExecutables => 'الملفات المكتشفة تلقائياً';

  @override
  String get browseButton => 'استعراض...';

  @override
  String get metadataCardTitle => '2. بيانات وتفاصيل التطبيق (Metadata)';

  @override
  String get appNameLabel => 'اسم التطبيق (App Name)';

  @override
  String get appNameHint => 'مثال: My Awesome App';

  @override
  String get versionLabel => 'الإصدار (Version)';

  @override
  String get versionHint => '1.0.0';

  @override
  String get categoryLabel => 'الفئة (Category)';

  @override
  String get iconLabel => 'أيقونة التطبيق (Icon - PNG أو SVG)';

  @override
  String get iconHint => 'اختر صورة بصيغة PNG أو SVG...';

  @override
  String get descriptionLabel => 'وصف مختصر للتطبيق (Description)';

  @override
  String get descriptionHint =>
      'وصف قصير يظهر في نظام التشغيل عند البحث عن البرنامج...';

  @override
  String get outputCardTitle => '3. مجلد الإخراج وخيارات التثبيت';

  @override
  String get outputDirLabel => 'مجلد حفظ ملف الـ AppImage';

  @override
  String get outputDirHint => 'اختر مجلد الحفظ...';

  @override
  String get integrateMenuTitle =>
      'تثبيت التطبيق في قائمة البرامج (ابدأ) فور انتهاء البناء';

  @override
  String get integrateMenuSubtitle =>
      'ينشئ اختصاراً نظامياً في جهازك لتتمكن من فتح التطبيق من قائمة البحث وشريط المهام فوراً';

  @override
  String get buildButton => 'توليد وبناء حزمة AppImage الآن';

  @override
  String get validationError =>
      'يرجى تعبئة كافة الحقول الإلزامية واختيار مسار التطبيق والملف التنفيذي';

  @override
  String filePickError(String error) {
    return 'خطأ أثناء اختيار المسار: $error';
  }

  @override
  String get buildingTitle => 'جاري تجهيز وبناء حزمة AppImage...';

  @override
  String get buildingSubtitle => 'يرجى الانتظار أثناء ضغط وتوليد الملف';

  @override
  String get buildSuccessTitle => 'اكتمل بناء الحزمة بنجاح!';

  @override
  String get buildFailedTitle => 'فشلت عملية البناء';

  @override
  String get openFolder => 'فتح مجلد الملف';

  @override
  String get testRunApp => 'تجربة وتشغيل التطبيق الآن';

  @override
  String get close => 'إغلاق';

  @override
  String failedToRun(String error) {
    return 'فشل تشغيل الملف: $error';
  }

  @override
  String get catUtility => 'أدوات مساعدة';

  @override
  String get catDevelopment => 'تطوير وبرمجة';

  @override
  String get catGame => 'ألعاب';

  @override
  String get catGraphics => 'تصميم ورسوميات';

  @override
  String get catAudioVideo => 'صوتيات ومرئيات';

  @override
  String get catOffice => 'مكتب وأعمال';

  @override
  String get catNetwork => 'إنترنت وشبكات';

  @override
  String get catEducation => 'تعليم';

  @override
  String get aboutTooltip => 'حول التطبيق';

  @override
  String get aboutAppTitle => 'حول استوديو آب إيمج';

  @override
  String get aboutAppDescription =>
      'أداة ديسكتوب عصرية ومفتوحة المصدر لتغليف وتوزيع تطبيقات لينكس كحزم AppImage مستقلة بنقرة زر واحدة وبدون الحاجة لإنترنت.';

  @override
  String get developerLabel => 'المطور والمؤسس:';

  @override
  String get developerName => 'علي الخضر (Ali El Khedr)';

  @override
  String get websiteTooltip => 'زيارة الموقع الشخصي للمطور';

  @override
  String get blogPostButton => 'مقال الشرح الكامل على المدونة';

  @override
  String get contributorsSectionTitle => 'المساهمون والمجتمع';

  @override
  String get contributorsPrompt =>
      'المشروع مفتوح المصدر بالكامل.. نرحب بمساهمتك وتطويرك معنا عبر GitHub!';

  @override
  String get githubRepoButton => 'مستودع المشروع على GitHub';

  @override
  String get contributorsButton => 'قائمة المساهمين على GitHub';

  @override
  String get licenseNotice => 'الترخيص: مفتوح المصدر بموجب رخصة GNU GPLv3';
}
