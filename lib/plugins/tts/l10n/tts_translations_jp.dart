/// TTS plugin Japanese translations
const Map<String, String> ttsTranslationsJp = {
  // Basic info
  'tts_name': 'テキスト読み上げ',
  'tts_servicesList': 'サービス',
  'tts_addService': 'サービスを追加',
  'tts_editService': 'サービスを編集',
  'tts_deleteService': 'サービスを削除',
  'tts_serviceName': 'サービス名',
  'tts_serviceType': 'サービスタイプ',
  'tts_systemTTS': 'システムTTS',
  'tts_httpService': 'HTTPサービス',
  'tts_minimaxService': 'MiniMax',
  'tts_defaultService': 'デフォルトサービス',

  // Status
  'tts_enabled': '有効',
  'tts_disabled': '無効',

  // Parameters
  'tts_pitch': 'ピッチ',
  'tts_speed': '速度',
  'tts_volume': '音量',
  'tts_voice': '音声',

  // HTTP Config
  'tts_apiUrl': 'API URL',
  'tts_headers': 'ヘッダー',
  'tts_requestBody': 'リクエストボディ',
  'tts_responseType': 'レスポンスタイプ',
  'tts_audioFieldPath': 'オーディオフィールドパス',
  'tts_audioFormat': 'オーディオフォーマット',
  'tts_audioBase64Encoded': 'オーディオBase64エンコード',
  'tts_audioIsBase64Encoded': 'オーディオデータはBase64エンコードですか',
  'tts_directAudioReturn': '直接オーディオ返す',
  'tts_jsonWrapped': 'JSONラップ',

  // Config Groups
  'tts_basicConfig': '基本設定',
  'tts_readingParameters': '読み上げパラメータ',
  'tts_httpConfig': 'HTTP設定',
  'tts_minimaxConfig': 'MiniMax設定',

  // Actions
  'tts_test': 'テスト',
  'tts_save': '保存',
  'tts_cancel': 'キャンセル',
  'tts_refresh': '更新',
  'tts_setAsDefault': 'デフォルトに設定',
  'tts_setAsDefaultTTSService': 'デフォルトTTSサービスに設定',
  'tts_enableThisService': 'このサービスを有効にする',
  'tts_disableThisService': 'このサービスを無効にする',

  // Confirm dialogs
  'tts_confirmDelete': 'このサービスを削除してもよろしいですか？',

  // Queue management
  'tts_queue': 'キュー',
  'tts_currentReading': '現在読み上げ中',
  'tts_waiting': '待機中',
  'tts_clearQueue': 'キューをクリア',

  // Status messages
  'tts_loading': '読み込み中...',
  'tts_loadingVoiceList': '音声リストを読み込み中...',
  'tts_testSuccess': 'テスト成功',
  'tts_testFailed': 'テスト失敗',
  'tts_testFailedPrefix': 'テスト失敗',

  // Success messages
  'tts_serviceAdded': 'サービス追加完了',
  'tts_serviceUpdated': 'サービス更新完了',
  'tts_serviceDeleted': 'サービス削除完了',
  'tts_setAsDefaultService': 'デフォルトサービスに設定',

  // Error messages
  'tts_saveFailed': '保存失敗',
  'tts_addFailed': '追加失敗',
  'tts_updateFailed': '更新失敗',
  'tts_deleteFailed': '削除失敗',
  'tts_setDefaultFailed': 'デフォルト設定失敗',
  'tts_loadServicesFailed': 'サービス読み込み失敗',
  'tts_loadVoiceListFailed': '音声リスト読み込み失敗',

  // Empty states
  'tts_noServicesAvailable': '利用可能なサービスがありません',

  // Form validation
  'tts_pleaseEnterApiUrl': 'API URLを入力してください',
  'tts_pleaseEnterAudioFieldPath': 'オーディオフィールドパスを入力してください',
  'tts_urlMustStartWithHttp': 'URLはhttp://またはhttps://で始まる必要があります',
  'tts_configValidationFailed': '設定検証失敗必須フィールドを確認してください',
  'tts_pleaseEnterApiKey': 'APIキーを入力してください',
  'tts_pleaseEnterVoiceId': '音声IDを入力してください',

  // MiniMax Config
  'tts_apiKey': 'APIキー',
  'tts_voiceId': '音声ID',
  'tts_model': 'モデル',
  'tts_emotion': '感情',
  'tts_emotionHelper': 'モデルはテキストに基づいて適切な感情を自動的にマッチングします',
  'tts_auto': '自動',

  // Voice related
  'tts_voiceTestText': 'こんにちは、これは音声テストです',
  'tts_reloadVoiceList': '音声リストを再読み込み',
  'tts_fillAccordingToApi': 'API要件に従って入力',

  // Parameterized translations - using @name placeholders
  'tts_availableVoiceCount': '@countの音声が利用可能',

  // Widget Home Strings
  'tts_widgetName': 'テキスト読み上げ',
  'tts_widgetDescription': 'TTSへのクイックアクセス',
  'tts_overviewName': 'TTS概要',
  'tts_overviewDescription': 'TTSサービスステータスを表示',
};
