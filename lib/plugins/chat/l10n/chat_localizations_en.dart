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

  // Message options dialog
  @override
  String get messageOptions => 'Message Options';
  @override
  String get addEmoji => 'Add Emoji';
  @override
  String get settings => 'Settings';
  @override
  String get editMessage => 'Edit Message';
  @override
  String get save => 'Save';
  @override
  String get deleteMessage => 'Delete Message';
  @override
  String get deleteMessageConfirmation =>
      'Are you sure you want to delete this message? This action cannot be undone.';
  @override
  String get copiedToClipboard => 'Copied to clipboard';
  @override
  String get createChannelFailed => 'Failed to create channel: \$e';
  @override
  String get noMessagesYet => 'No messages yet';
  @override
  String get noMessagesFound => 'No messages found for';

  // New strings implementations
  @override
  String get copiedSelectedMessages => 'Selected messages copied';
  @override
  String get aiAssistantNotFound => 'Corresponding AI assistant not found';
  @override
  String get aiMessages => 'AI Messages';
  @override
  String get filterAiMessages => 'Filter messages created by AI';
  @override
  String get favoriteMessages => 'Favorite Messages';
  @override
  String get showOnlyFavorites => 'Show only favorited messages';
  @override
  String get recordingFailed => 'Recording failed';
  @override
  String get gotIt => 'Got it';
  @override
  String get recordingStopError =>
      'An error occurred while stopping recording. The recording may not have been saved.';
  @override
  String get selectDate => 'Select Date';
  @override
  String get invalidAudioMessage => 'Invalid audio message';
  @override
  String get fileNotAccessible => 'File does not exist or is not accessible';
  @override
  String get fileProcessingFailed =>
      'File processing failed: \$processingError';
  @override
  String get fileSelectionFailed => 'File selection failed: \$e';
  @override
  String get fileSelected => 'File selected: \${fileMessage.originalFileName}';
  @override
  String get imageNotExist => 'Image file does not exist';
  @override
  String get imageProcessingFailed => 'Image processing failed: \$e';
  @override
  String get imageSelectionFailed => 'Image selection failed: \$e';
  @override
  String get clearAllMessages => 'Clear All Messages';
  @override
  String get confirmClearAllMessages =>
      'Are you sure you want to clear all messages? This action cannot be undone.';
  @override
  String get videoNotSupportedOnWeb =>
      'Video recording is not supported on Web platform';
  @override
  String get videoNotExist => 'Video file does not exist';
  @override
  String get videoProcessingFailed =>
      'Video processing failed: \$processingError';
  @override
  String get videoSelectionFailed => 'Video selection failed: \$e';
  @override
  String get videoSent => 'Video sent: \${path.basename(video.path)}';
  @override
  String get videoRecordingFailed => 'Video recording failed: \$e';
  @override
  String get channelCreationFailed => 'Failed to create channel: \$e';

  // New translations
  @override
  String get usernameCannotBeEmpty => 'Username cannot be empty';
  @override
  String get updateFailed => 'Update failed: \$e';
  @override
  String get showAll => 'Show all';

  @override
  String get singleFile => '1 file';
  @override
  String get contextRange => 'Context: \$contextRange';
  @override
  String get setContextRange => 'Set Context Range';
  @override
  String get currentRange => 'Current range: \${currentValue.round()}';

  @override
  String get titleCannotBeEmpty => 'Title cannot be empty';

  @override
  String get metadataFilters => 'Metadata filters';

  @override
  String get deleteChannelConfirmation =>
      'Are you sure you want to delete channel "\${channel.title}"? This action cannot be undone.';

  @override
  String get fileOpenFailed => 'Failed to open file: \$e';

  @override
  String get audioMessageBubbleErrorText => 'Failed to load audio message: \$e';

  @override
  String get editMessageTitle => 'Edit Message Title';

  @override
  String get errorFilePreviewFailed => 'Failed to preview file: \$e';

  @override
  get messageHintText => 'Type your message here...';

  @override
  String get stopRecordingHint => 'Tap to stop recording...';

  @override
  String get rangeHint => 'Context Range: ';
}
