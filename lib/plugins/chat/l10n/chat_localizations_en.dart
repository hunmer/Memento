import 'chat_localizations.dart';

/// 英文本地化实现
class ChatLocalizationsEn extends ChatLocalizations {
  ChatLocalizationsEn() : super('en');

  @override
  String get chatPluginName => 'Chat';

  @override
  String get chatPluginDescription => 'Basic chat functionality plugin';

  @override
  String get showAvatarInChannelList => 'Show avatars in channel list';

  @override
  String get channelList => 'Channel List';

  @override
  String get newChannel => 'New Channel';

  @override
  String get deleteChannel => 'Delete Channel';

  @override
  String get deleteMessages => 'Delete Messages';

  @override
  String get draft => 'Draft';

  @override
  String get chatRoom => 'Chat Room';

  @override
  String get enterMessage => 'Type a message...';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int minutes) => '$minutes minutes ago';

  @override
  String hoursAgo(int hours) => '$hours hours ago';

  @override
  String daysAgo(int days) => '$days days ago';
}