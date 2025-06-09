// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get chat => 'المحادثة';

  @override
  String get error => 'خطأ';

  @override
  String get ok => 'موافق';

  @override
  String get clearChatHistory => 'مسح سجل المحادثة';

  @override
  String get clearChatHistoryConfirmation =>
      'هل أنت متأكد أنك تريد مسح كل سجل المحادثة؟';

  @override
  String get clear => 'مسح';

  @override
  String get cancel => 'إلغاء';

  @override
  String failedToClearChat(String error) {
    return 'فشل في مسح سجل المحادثة: $error';
  }

  @override
  String failedToSendMessage(String error) {
    return 'فشل في إرسال الرسالة: $error';
  }

  @override
  String get noMessagesYet => 'لا توجد رسائل بعد';

  @override
  String get startConversation => 'ابدأ محادثة مع المساعد الذكي';

  @override
  String get typeMessage => 'اكتب رسالة...';

  @override
  String get today => 'اليوم';

  @override
  String get yesterday => 'الأمس';
}
