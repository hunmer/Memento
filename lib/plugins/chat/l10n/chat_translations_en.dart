/// 聊天插件英文翻译
class ChatTranslationsEn {
  static const Map<String, String> keys = {
    // Basic translations
    'chat_name': 'Chat',
    'chat_all': 'All',
    'chat_ungrouped': 'Ungrouped',
    'chat_showAvatarInChannelList': 'Show avatars in channel list',
    'chat_channelList': 'Channel List',
    'chat_newChannel': 'New Channel',
    'chat_deleteChannel': 'Delete Channel',
    'chat_deleteMessages': 'Delete Messages',
    'chat_draft': 'Draft',
    'chat_chatRoom': 'Chat Room',
    'chat_enterMessage': 'Type a message...',
    'chat_justNow': 'Just now',
    'chat_edit': 'Edit',
    'chat_copy': 'Copy',
    'chat_delete': 'Delete',
    'chat_pin': 'Pin',
    'chat_clear': 'Clear',
    'chat_info': 'Info',
    'chat_multiSelectMode': 'Multi-select Mode',
    'chat_clearMessages': 'Clear Messages',
    'chat_channelInfo': 'Channel Info',
    'chat_selectedMessages': '@count messages selected',
    'chat_edited': 'edited',
    'chat_channelsTab': 'Channels',
    'chat_timelineTab': 'Timeline',
    'chat_timelineComingSoon': 'Timeline - Coming Soon',
    'chat_editProfile': 'Edit Profile',
    'chat_today': 'Today',
    'chat_yesterday': 'Yesterday',

    // Time related
    'chat_minutesAgo': '@minutes minutes ago',
    'chat_hoursAgo': '@hours hours ago',
    'chat_daysAgo': '@days days ago',
    'chat_userInitial': 'Initial letter of @username',

    // Advanced filter
    'chat_advancedFilter': 'Advanced Filter',
    'chat_searchIn': 'Search in:',
    'chat_channelNames': 'Channel names',
    'chat_usernames': 'Usernames',
    'chat_messageContent': 'Message content',
    'chat_dateRange': 'Date range:',
    'chat_startDate': 'Start date',
    'chat_endDate': 'End date',
    'chat_clearDates': 'Clear dates',
    'chat_selectChannels': 'Select channels:',
    'chat_selectUsers': 'Select users:',
    'chat_noChannelsAvailable': 'No channels available',
    'chat_noUsersAvailable': 'No users available',
    'chat_setBackground': 'Set Background',

    // Message options dialog
    'chat_messageOptions': 'Message Options',
    'chat_addEmoji': 'Add Emoji',
    'chat_settings': 'Settings',
    'chat_editMessage': 'Edit Message',
    'chat_deleteMessage': 'Delete Message',
    'chat_deleteMessageConfirmation':
        'Are you sure you want to delete this message? This action cannot be undone.',
    'chat_copiedToClipboard': 'Copied to clipboard',
    'chat_createChannelFailed': 'Failed to create channel: @e',
    'chat_noMessagesYet': 'No messages yet',
    'chat_noMessagesFound': 'No messages found for',

    // Chat functionality related
    'chat_copiedSelectedMessages': 'Selected messages copied',
    'chat_aiAssistantNotFound': 'Corresponding AI assistant not found',
    'chat_aiMessages': 'AI Messages',
    'chat_filterAiMessages': 'Filter messages created by AI',
    'chat_favoriteMessages': 'Favorite Messages',
    'chat_showOnlyFavorites': 'Show only favorited messages',

    // Recording and file related
    'chat_recordingFailed': 'Recording failed',
    'chat_gotIt': 'Got it',
    'chat_recordingStopError':
        'An error occurred while stopping recording. The recording may not have been saved.',
    'chat_selectDate': 'Select Date',
    'chat_invalidAudioMessage': 'Invalid audio message',
    'chat_fileNotAccessible': 'File does not exist or is not accessible',
    'chat_fileProcessingFailed': 'File processing failed: @processingError',
    'chat_fileSelectionFailed': 'File selection failed: @e',
    'chat_fileSelected': 'File selected: @originalFileName',
    'chat_imageNotExist': 'Image file does not exist',
    'chat_imageProcessingFailed': 'Image processing failed: @e',
    'chat_imageSelectionFailed': 'Image selection failed: @e',
    'chat_clearAllMessages': 'Clear All Messages',
    'chat_confirmClearAllMessages':
        'Are you sure you want to clear all messages? This action cannot be undone.',
    'chat_videoNotSupportedOnWeb':
        'Video recording is not supported on Web platform',
    'chat_videoNotExist': 'Video file does not exist',
    'chat_videoProcessingFailed': 'Video processing failed: @processingError',
    'chat_videoSelectionFailed': 'Video selection failed: @e',
    'chat_videoSent': 'Video sent: @basename',
    'chat_videoRecordingFailed': 'Video recording failed: @e',
    'chat_channelCreationFailed': 'Failed to create channel: @e',

    // New translations
    'chat_usernameCannotBeEmpty': 'Username cannot be empty',
    'chat_updateFailed': 'Update failed: @e',
    'chat_showAll': 'Show all',
    'chat_singleFile': '1 file',
    'chat_contextRange': 'Context: @contextRange',
    'chat_setContextRange': 'Set Context Range',
    'chat_currentRange': 'Current range: @currentValue',
    'chat_titleCannotBeEmpty': 'Title cannot be empty',
    'chat_deleteChannelConfirmation':
        'Are you sure you want to delete channel "@title"? This action cannot be undone.',

    // UI service related
    'chat_channelCount': 'Channels',
    'chat_totalMessagesCount': 'Messages',
    'chat_todayMessages': 'Today',
    'chat_profileTitle': 'Profile',
    'chat_chatSettings': 'Chat Settings',
    'chat_showAvatarInChat': 'Show avatar in chat',
    'chat_playSoundOnSend': 'Play sound when sending message',
    'chat_showAvatarInTimeline': 'Show avatar in timeline',

    // Message input actions
    'chat_advancedEditor': 'Advanced Editor',
    'chat_photo': 'Photo',
    'chat_takePhoto': 'Take Photo',
    'chat_recordVideo': 'Record Video',
    'chat_video': 'Video',
    'chat_pluginAnalysis': 'Plugin Analysis',
    'chat_file': 'File',
    'chat_audioRecording': 'Audio Recording',
    'chat_smartAgent': 'Smart Agent',

    // Widget related
    'chat_widgetName': 'Chat',
    'chat_widgetDescription': 'Quick access to chat',
    'chat_chatWidgetIcon': 'Chat',
    'chat_overviewName': 'Chat Overview',
    'chat_overviewDescription': 'Display channel and message statistics',
    'chat_communicationCategory': 'Communication',
    'chat_loadFailed': 'Load Failed',
    'chat_channelQuickAccess': 'Channel Quick Access',
    'chat_channelQuickAccessDesc': 'Quickly open a specific channel',
    'chat_clickToEnter': 'Click to enter',
    'chat_untitled': 'Untitled Channel',
    'chat_noMessages': 'No messages',

    // Selector related
    'chat_channelSelectorName': 'Select Channel',
    'chat_channelSelectorDesc': 'Choose a chat channel',
    'chat_selectChannel': 'Select Channel',
    'chat_noChannels': 'No channels, please create one first',

    // Other UI elements
    'chat_editMessageTitle': 'Edit Message Title',
    'chat_messageHintText': 'Type your message here...',
    'chat_errorFilePreviewFailed': 'Failed to preview file: @e',
    'chat_audioMessageBubbleErrorText': 'Failed to load audio message: @e',
    'chat_stopRecordingHint': 'Tap to stop recording...',
    'chat_rangeHint': 'Context Range: ',
    'chat_metadataFilters': 'Metadata filters',

    // Channel related
    'chat_channelName': 'Channel Name',
    'chat_tag': 'Tag',
    'chat_tagHint': 'Add tags to categorize messages',
    'chat_username': 'Username',
    'chat_channelGroupLabel': 'Channel Groups',
    'chat_channelGroupHint': 'Optional, leave empty for default group',

    // Bottom bar buttons
    'chat_createChannel': 'Create Channel',
    'chat_create': 'Create',
    'chat_cancel': 'Cancel',
    'chat_channelCreated': 'Channel Created',

    // Other
    'chat_save': 'Save',
    'chat_reset': 'Reset',
    'chat_apply': 'Apply',
    'chat_fileOpenFailed': 'Failed to open file: @e',

    // Interface search
    'chat_channelListTitle': 'Channel List',
    'chat_searchPlaceholder': 'Search channel name',

    // Tags feature
    'chat_tagsTab': 'Tags',
    'chat_tagList': 'Tag List',
    'chat_messageCount': '@count messages',
    'chat_searchTags': 'Search tags',
    'chat_sortByTime': 'Sort by Time',
    'chat_sortByCount': 'Sort by Count',
    'chat_noTagsFound': 'No Tags Found',
    'chat_noMatchingTags': 'No Matching Tags',
    'chat_totalMessages': 'Total @count messages',
    'chat_unknownChannel': 'Unknown Channel',
    'chat_error': 'Error',
    'chat_messageNoChannel': 'Message has no associated channel',
    'chat_channelNotFound': 'Channel not found',
    'chat_searchMessages': 'Search messages',
    'chat_noMatchingMessages': 'No matching messages',
    'chat_refresh': 'Refresh',
  };
}
