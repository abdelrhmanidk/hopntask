// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get chat => 'Chat';

  @override
  String get error => 'Error';

  @override
  String get ok => 'OK';

  @override
  String get clearChatHistory => 'Clear Chat History';

  @override
  String get clearChatHistoryConfirmation =>
      'Are you sure you want to clear all chat history?';

  @override
  String get clear => 'Clear';

  @override
  String get cancel => 'Cancel';

  @override
  String failedToClearChat(String error) {
    return 'Failed to clear chat history: $error';
  }

  @override
  String failedToSendMessage(String error) {
    return 'Failed to send message: $error';
  }

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String get startConversation => 'Start a conversation with your AI assistant';

  @override
  String get typeMessage => 'Type a message...';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';
}
