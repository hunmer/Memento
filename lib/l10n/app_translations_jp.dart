/// Japanese translations for app-level strings
///
/// All keys are prefixed with 'app_' to avoid conflicts with plugin translations.
/// Parameterized translations use @paramName format for GetX.
const Map<String, String> appTranslationsJp = {
  // App basics
  'app_appTitle': 'memento',
  'app_pluginManager': 'プラグイン管理',
  'app_home': 'ホーム',
  'app_settings': '設定',
  'app_version': 'バージョン',

  // Common actions
  'app_ok': 'OK',
  'app_select': '選択',
  'app_no': 'いいえ',
  'app_yes': 'はい',
  'app_cancel': 'キャンセル',
  'app_save': '保存',
  'app_close': '閉じる',
  'app_delete': '削除',
  'app_reset': 'リセット',
  'app_apply': '適用',
  'app_edit': '編集',
  'app_retry': '再試行',
  'app_rename': '名前変更',
  'app_copy': 'コピー',
  'app_done': '完了',
  'app_create': '新規作成',
  'app_confirm': '確認',
  'app_import': 'インポート',

  // Delete confirmation
  'app_confirmDelete': '削除してよろしいですか？',

  // Date and time
  'app_selectDate': '日付を選択',
  'app_startTime': '開始時間',
  'app_endTime': '終了時間',
  'app_interval': '間隔',
  'app_minutes': '分',
  'app_week': '週',
  'app_month': '月',
  'app_date': '日付',
  'app_day': '@day日目',

  // Display options
  'app_showAll': 'すべて表示',
  'app_adjustCardSize': 'カードサイズを調整',
  'app_width': '幅',
  'app_height': '高さ',

  // Tags and categories
  'app_tags': 'タグ',
  'app_selectGroup': 'グループを選択',
  'app_selectLocation': '場所を選択',

  // Backup and export
  'app_backupOptions': 'バックアップオプション',
  'app_selectBackupMethod': 'バックアップ方法を選択してください',
  'app_exportAppData': 'アプリデータをエクスポート',
  'app_fullBackup': '完全バックアップ',
  'app_webdavSync': 'WebDAV同期',
  'app_setBackupSchedule': 'バックアップスケジュールを設定',

  // Backup progress
  'app_backupInProgress': 'バックアップ中',
  'app_completed': '完了: @percentage%',
  'app_exportingData': 'データをエクスポート中',
  'app_importingData': 'データをインポート中',
  'app_pleaseWait': 'お待ちください',

  // Export messages
  'app_exportCancelled': 'エクスポートがキャンセルされました',
  'app_exportSuccess': 'データのエクスポートに成功しました',
  'app_exportFailed': 'エクスポート失敗: @error',
  'app_dataExportedTo': 'データを以下にエクスポートしました: @path',
  'app_exportFailedWithError': 'エクスポート失敗: @error',
  'app_exportSuccessTo': 'エクスポート成功: @path',

  // Import messages
  'app_warning': '警告',
  'app_importWarning':
      'インポートすると現在のアプリデータが完全に上書きされます。\nインポート前に既存のデータのバックアップをお勧めします。\n\n続行しますか？',
  'app_stillContinue': '続行',
  'app_importCancelled': 'インポートがキャンセルされました',
  'app_selectBackupFile': 'バックアップファイルを選択してください',
  'app_noFileSelected': 'ファイルが選択されていません',
  'app_importInProgress': 'インポート中',
  'app_processingBackupFile': 'バックアップファイルを処理中...',
  'app_importSuccess': 'データのインポートに成功しました、アプリを再起動してください',
  'app_restartRequired': '再起動が必要です',
  'app_restartMessage':
      'データのインポートが完了しました。適用にはアプリの再起動が必要です。',
  'app_fileSelectionFailed': 'ファイル選択失敗: @error',
  'app_importFailed': 'インポート失敗',
  'app_importTimeout': 'インポートタイムアウト: ファイルが大きすぎるか、アクセスできません',
  'app_filesystemError': 'ファイルシステムエラー: ファイルの読み書きができません',
  'app_invalidBackupFile': '無効なバックアップファイル: ファイルが破損している可能性があります',
  'app_noPluginDataFound': 'インポートするプラグインのデータが見つかりません',
  'app_importFailedWithError': 'インポート失敗: @error',

  // Plugin management
  'app_noPluginsAvailable': '利用可能なプラグインがありません',
  'app_failedToLoadPlugins': 'プラグインの読み込みに失敗しました: @error',
  'app_selectPluginToExport': 'エクスポートするプラグインを選択',
  'app_selectPluginToImport': 'インポートするプラグインを選択 (@mode)',
  'app_selectPluginsToImport': 'インポートするプラグインを選択',
  'app_selectFolderToImport': 'インポートするフォルダを選択',
  'app_dataSize': 'データサイズ: @size',
  'app_mergeMode': 'マージモード',
  'app_overwriteMode': '上書きモード',

  // Permissions
  'app_permissionRequired': '@permission権限が必要です',
  'app_permissionRequiredForApp': 'アプリを正常に動作させるには@permission権限が必要です。権限を付与しますか？',
  'app_notNow': '後で行う',
  'app_grantPermission': '権限を付与',
  'app_permissionRequiredInSettings': '続けるには@permission権限が必要です。システム設定で権限を付与してください。',
  'app_storagePermissionRequired': '続けるにはストレージ権限が必要です。システム設定で権限を付与してください。',
  'app_permissionsTitle': '権限アクセス',
  'app_permissionsDescription':
      'バックアップ、インポート、リマインダーが正常に機能するために、以下の権限を付与してください。',
  'app_permissionsGrantAll': 'すべての権限を一度に付与',
  'app_permissionsGranted': '付与済み',
  'app_permissionsRequest': '許可',
  'app_permissionsOpenSettings': '設定を開く',
  'app_permissionsManageDescription':
      'メディアと通知の権限を確認・管理します。',
  'app_permission_photosTitle': '写真',
  'app_permission_photosDescription':
      '日記、チェックインなどのプラグインで画像を選択・バックアップするために必要です。',
  'app_permission_videosTitle': '動画',
  'app_permission_videosDescription':
      '録画した動画を添付・エクスポートするために必要です。',
  'app_permission_audioTitle': 'オーディオ',
  'app_permission_audioDescription':
      '音声メモの録音やオーディオファイルを添付するために必要です。',
  'app_permission_notificationsTitle': '通知',
  'app_permission_notificationsDescription':
      'リマインダーやスケジュールされたアラートを送信するために必要です。',
  'app_permission_storageTitle': 'ストレージ',
  'app_permission_storageDescription':
      'デバイス上のバックアップファイルを読み書きするために必要です。',
  'app_permission_calendarTitle': 'カレンダー',
  'app_permission_calendarDescription':
      'システムカレンダーと同期し、カレンダーイベントを管理するために必要です。',

  // File operations
  'app_downloadCancelled': 'ダウンロードがキャンセルされました',
  'app_moveSuccess': '移動成功',
  'app_moveFailed': '移動失敗: @error',
  'app_renameFailed': '名前変更失敗: @error',

  // Media selection
  'app_selectImage': '画像を選択',
  'app_selectFromGallery': 'ギャラリーから選択',
  'app_takePhoto': '写真を撮影',
  'app_loadingVideo': '動画を読み込み中...',
  'app_videoLoadFailed': '動画の読み込み失敗: @error',

  // Form validation
  'app_pleaseEnterTitle': 'タイトルを入力してください',
  'app_titleRequired': 'タイトルは必須です',

  // Colors
  'app_selectBackgroundColor': '背景色を選択',
  'app_nodeColor': 'ノードカラー',

  // Testing
  'app_testForegroundTask': 'フォアグラウンドタスクをテスト',

  // About
  'app_aboutTitle': 'アプリについて',
  'app_aboutDescription':
      'Mementoは、大切なことを整理・記憶するための生産性向上アプリです。',
  'app_projectLinkTitle': 'プロジェクトリンク',
  'app_projectLink': 'https://github.com/hunmer/memento',
  'app_feedbackTitle': 'フィードバック・問題報告',
  'app_feedbackLink': 'https://github.com/hunmer/Memento/issues',
  'app_documentationTitle': 'ドキュメント',
  'app_documentationLink': 'https://github.com/hunmer/Memento#readme',

  // Home Widget Categories
  'home_categoryRecord': '記録',
  'home_categoryTools': 'ツール',
  'home_categoryCommunication': 'コミュニケーション',
  'home_categoryFinance': 'ファイナンス',
  'home_categoryLife': '生活',
  'home_loadFailed': '読み込み失敗',
};
