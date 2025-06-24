import 'chat_localizations.dart';

/// 英文本地化实现
class ChatLocalizationsEn extends ChatLocalizations {
  ChatLocalizationsEn() : super('en');

  @override
  String get pluginName => 'Chat';

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

  @override
  String get setBackground => 'Set Background';

  // New localizations for UI service
  @override
  String get channelCount => 'Channels';

  @override
  String get totalMessages => 'Messages';

  @override
  String get todayMessages => 'Today';

  @override
  String get profileTitle => 'Profile';

  @override
  String get chatSettings => 'Chat Settings';

  @override
  String get showAvatarInChat => 'Show avatar in chat';

  @override
  String get playSoundOnSend => 'Play sound when sending message';

  @override
  String get showAvatarInTimeline => 'Show avatar in timeline';

  // Message input actions
  @override
  String get advancedEditor => 'Advanced Editor';

  @override
  String get photo => 'Photo';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get recordVideo => 'Record Video';

  @override
  String get video => 'Video';

  @override
  String get pluginAnalysis => 'Plugin Analysis';

  @override
  String get file => 'File';

  @override
  String get audioRecording => 'Audio Recording';

  @override
  String get smartAgent => 'Smart Agent';
}
