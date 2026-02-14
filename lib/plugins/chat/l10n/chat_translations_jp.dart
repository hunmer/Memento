/// Chat plugin Japanese translations
class ChatTranslationsJp {
  static const Map<String, String> keys = {
    // Basic translations
    'chat_name': 'チャット',
    'chat_all': 'すべて',
    'chat_ungrouped': 'グループなし',
    'chat_showAvatarInChannelList': 'チャンネルリストにアバターを表示',
    'chat_channelList': 'チャンネルリスト',
    'chat_newChannel': '新規チャンネル',
    'chat_deleteChannel': 'チャンネルを削除',
    'chat_deleteMessages': 'メッセージを削除',
    'chat_draft': '下書き',
    'chat_chatRoom': 'チャットルーム',
    'chat_enterMessage': 'メッセージを入力...',
    'chat_justNow': '今しがた',
    'chat_edit': '編集',
    'chat_copy': 'コピー',
    'chat_delete': '削除',
    'chat_pin': 'ピン留め',
    'chat_clear': 'クリア',
    'chat_info': '情報',
    'chat_multiSelectMode': '複数選択モード',
    'chat_clearMessages': 'メッセージをクリア',
    'chat_channelInfo': 'チャンネル情報',
    'chat_selectedMessages': '@count 件のメッセージを選択',
    'chat_edited': '編集済み',
    'chat_channelsTab': 'チャンネル',
    'chat_timelineTab': 'タイムライン',
    'chat_timelineComingSoon': 'タイムライン - 近日公開',
    'chat_editProfile': 'プロフィールを編集',
    'chat_today': '今日',
    'chat_yesterday': '昨日',

    // Time related
    'chat_minutesAgo': '@minutes 分前',
    'chat_hoursAgo': '@hours 時間前',
    'chat_daysAgo': '@days 日前',
    'chat_userInitial': '@username のイニシャル',

    // Advanced filter
    'chat_advancedFilter': '詳細フィルター',
    'chat_searchIn': '検索範囲:',
    'chat_channelNames': 'チャンネル名',
    'chat_usernames': 'ユーザー名',
    'chat_messageContent': 'メッセージ内容',
    'chat_dateRange': '日付範囲:',
    'chat_startDate': '開始日',
    'chat_endDate': '終了日',
    'chat_clearDates': '日付をクリア',
    'chat_selectChannels': 'チャンネルを選択:',
    'chat_selectUsers': 'ユーザーを選択:',
    'chat_noChannelsAvailable': '利用可能なチャンネルがありません',
    'chat_noUsersAvailable': '利用可能なユーザーがいません',
    'chat_setBackground': '背景を設定',

    // Message options dialog
    'chat_messageOptions': 'メッセージオプション',
    'chat_addEmoji': '絵文字を追加',
    'chat_settings': '設定',
    'chat_editMessage': 'メッセージを編集',
    'chat_deleteMessage': 'メッセージを削除',
    'chat_deleteMessageConfirmation':
        'このメッセージを削除してもよろしいですか？この操作は取り消せません。',
    'chat_copiedToClipboard': 'クリップボードにコピーしました',
    'chat_createChannelFailed': 'チャンネルの作成に失敗しました: @e',
    'chat_noMessagesYet': 'メッセージがありません',
    'chat_noMessagesFound': '一致するメッセージがありません',

    // Chat functionality related
    'chat_copiedSelectedMessages': '選択したメッセージをコピーしました',
    'chat_aiAssistantNotFound': '対応するAIアシスタントが見つかりません',
    'chat_aiMessages': 'AIメッセージ',
    'chat_filterAiMessages': 'AIが作成したメッセージをフィルター',
    'chat_favoriteMessages': 'お気に入りメッセージ',
    'chat_showOnlyFavorites': 'お気に入りのメッセージのみ表示',

    // Recording and file related
    'chat_recordingFailed': '録音に失敗しました',
    'chat_gotIt': '了解',
    'chat_recordingStopError':
        '録音を停止中にエラーが発生しました。録音が保存されていない可能性があります。',
    'chat_selectDate': '日付を選択',
    'chat_invalidAudioMessage': '無効な音声メッセージ',
    'chat_fileNotAccessible': 'ファイルが存在しないか、アクセスできません',
    'chat_fileProcessingFailed': 'ファイルの処理に失敗しました: @processingError',
    'chat_fileSelectionFailed': 'ファイルの選択に失敗しました: @e',
    'chat_fileSelected': 'ファイルを選択しました: @originalFileName',
    'chat_imageNotExist': '画像ファイルが存在しません',
    'chat_imageProcessingFailed': '画像の処理に失敗しました: @e',
    'chat_imageSelectionFailed': '画像の選択に失敗しました: @e',
    'chat_clearAllMessages': 'すべてのメッセージをクリア',
    'chat_confirmClearAllMessages':
        'すべてのメッセージをクリアしてもよろしいですか？この操作は取り消せません。',
    'chat_videoNotSupportedOnWeb':
        'Webプラットフォームでは動画録画はサポートされていません',
    'chat_videoNotExist': '動画ファイルが存在しません',
    'chat_videoProcessingFailed': '動画の処理に失敗しました: @processingError',
    'chat_videoSelectionFailed': '動画の選択に失敗しました: @e',
    'chat_videoSent': '動画を送信しました: @basename',
    'chat_videoRecordingFailed': '動画録画に失敗しました: @e',
    'chat_channelCreationFailed': 'チャンネルの作成に失敗しました: @e',

    // New translations
    'chat_usernameCannotBeEmpty': 'ユーザー名は入力必須です',
    'chat_updateFailed': '更新に失敗しました: @e',
    'chat_showAll': 'すべて表示',
    'chat_singleFile': '1ファイル',
    'chat_contextRange': 'コンテキスト: @contextRange',
    'chat_setContextRange': 'コンテキスト範囲を設定',
    'chat_currentRange': '現在の範囲: @currentValue',
    'chat_titleCannotBeEmpty': 'タイトルを入力必須です',
    'chat_deleteChannelConfirmation':
        'チャンネル「@title」を削除してもよろしいですか？この操作は取り消せません。',

    // UI service related
    'chat_channelCount': 'チャンネル',
    'chat_totalMessagesCount': 'メッセージ',
    'chat_todayMessages': '今日',
    'chat_profileTitle': 'プロフィール',
    'chat_chatSettings': 'チャット設定',
    'chat_showAvatarInChat': 'チャットにアバターを表示',
    'chat_playSoundOnSend': 'メッセージ送信時に音を鳴らす',
    'chat_showAvatarInTimeline': 'タイムラインにアバターを表示',

    // Message input actions
    'chat_advancedEditor': '詳細エディター',
    'chat_photo': '写真',
    'chat_takePhoto': '写真を撮影',
    'chat_recordVideo': '動画を録画',
    'chat_video': '動画',
    'chat_pluginAnalysis': 'プラグイン分析',
    'chat_file': 'ファイル',
    'chat_audioRecording': '音声録音',
    'chat_smartAgent': 'スマートエージェント',

    // Widget related
    'chat_widgetName': 'チャット',
    'chat_widgetDescription': 'チャットへのクイックアクセス',
    'chat_chatWidgetIcon': 'チャット',
    'chat_overviewName': 'チャット概要',
    'chat_overviewDescription': 'チャンネルとメッセージの統計を表示',
    'chat_communicationCategory': 'コミュニケーション',
    'chat_loadFailed': '読み込み失敗',
    'chat_channelQuickAccess': 'チャンネルクイックアクセス',
    'chat_channelQuickAccessDesc': '特定のチャンネルを素早く開く',
    'chat_clickToEnter': 'タップして入力',
    'chat_untitled': '無題のチャンネル',
    'chat_noMessages': 'メッセージがありません',

    // Selector related
    'chat_channelSelectorName': 'チャンネルを選択',
    'chat_channelSelectorDesc': 'チャットチャンネルを選択',
    'chat_selectChannel': 'チャンネルを選択',
    'chat_noChannels': 'チャンネルがありません。まず作成してください',

    // Other UI elements
    'chat_editMessageTitle': 'メッセージタイトルを編集',
    'chat_messageHintText': 'ここにメッセージを入力...',
    'chat_errorFilePreviewFailed': 'ファイルのプレビューに失敗しました: @e',
    'chat_audioMessageBubbleErrorText': '音声メッセージの読み込みに失敗しました: @e',
    'chat_stopRecordingHint': 'タップして録音を停止...',
    'chat_rangeHint': 'コンテキスト範囲: ',
    'chat_metadataFilters': 'メタデータフィルター',

    // Channel related
    'chat_channelName': 'チャンネル名',
    'chat_tag': 'タグ',
    'chat_tagHint': 'メッセージを分類するためにタグを追加',
    'chat_username': 'ユーザー名',
    'chat_channelGroupLabel': 'チャンネルグループ',
    'chat_channelGroupHint': 'オプションです。空のままにするとデフォルトグループになります',

    // Bottom bar buttons
    'chat_createChannel': 'チャンネルを作成',
    'chat_create': '作成',
    'chat_cancel': 'キャンセル',
    'chat_channelCreated': 'チャンネルを作成しました',

    // Other
    'chat_save': '保存',
    'chat_reset': 'リセット',
    'chat_apply': '適用',
    'chat_fileOpenFailed': 'ファイルを開けませんでした: @e',

    // Interface search
    'chat_channelListTitle': 'チャンネルリスト',
    'chat_searchPlaceholder': 'チャンネル名を検索',

    // Tags feature
    'chat_tagsPlaceholder': 'タグを追加',
    'chat_tagList': 'タグリスト',
    'chat_messageCount': '@count 件のメッセージ',
    'chat_searchTags': 'タグを検索',
    'chat_sortByTime': '時間で並べ替え',
    'chat_sortByCount': '数で並べ替え',
    'chat_noTagsFound': 'タグが見つかりません',
    'chat_noMatchingTags': '一致するタグがありません',
    'chat_totalMessages': '合計 @count 件のメッセージ',
    'chat_unknownChannel': '不明なチャンネル',
    'chat_error': 'エラー',
    'chat_messageNoChannel': 'メッセージにチャンネルが関連付けられていません',
    'chat_channelNotFound': 'チャンネルが見つかりません',
    'chat_searchMessages': 'メッセージを検索',
    'chat_noMatchingMessages': '一致するメッセージがありません',
    'chat_refresh': '更新',
  };
}
