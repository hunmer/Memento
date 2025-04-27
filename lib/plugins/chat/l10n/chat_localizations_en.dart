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

  @override
  String userInitial(String username) => 'Initial letter of $username';

  @override
  String get edit => 'Edit';

  @override
  String get copy => 'Copy';

  @override
  String get delete => 'Delete';

  @override
  String get pin => 'Pin';

  @override
  String get clear => 'Clear';

  @override
  String get info => 'Info';

  @override
  String get multiSelectMode => 'Multi-select Mode';

  @override
  String get clearMessages => 'Clear Messages';

  @override
  String get channelInfo => 'Channel Info';

  @override
  String get selectedMessages => '{count} messages selected';

  @override
  String get edited => 'edited';

  @override
  String get channelsTab => 'Channels';

  @override
  String get timelineTab => 'Timeline';

  @override
  String get timelineComingSoon => 'Timeline - Coming Soon';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  // Advanced filter related implementations
  @override
  String get advancedFilter => 'Advanced Filter';

  @override
  String get searchIn => 'Search in:';

  @override
  String get channelNames => 'Channel names';

  @override
  String get usernames => 'Usernames';

  @override
  String get messageContent => 'Message content';

  @override
  String get dateRange => 'Date range:';

  @override
  String get startDate => 'Start date';

  @override
  String get endDate => 'End date';

  @override
  String get clearDates => 'Clear dates';

  @override
  String get selectChannels => 'Select channels:';

  @override
  String get selectUsers => 'Select users:';

  @override
  String get noChannelsAvailable => 'No channels available';

  @override
  String get noUsersAvailable => 'No users available';

  @override
  String get cancel => 'Cancel';

  @override
  String get reset => 'Reset';

  @override
  String get apply => 'Apply';
}