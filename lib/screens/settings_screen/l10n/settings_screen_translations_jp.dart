/// Settings screen Japanese translations
const Map<String, String> settingsScreenTranslationsJp = {
  // Page title
  'settings_screen_settingsTitle': '設定',

  // Language settings
  'settings_screen_languageTitle': '言語 (日本語)',
  'settings_screen_languageSubtitle': 'タップして中文に切り替え',

  // Theme settings
  'settings_screen_darkModeTitle': 'ダークモード',
  'settings_screen_darkModeSubtitle': 'アプリテーマを切り替え',

  // Data management
  'settings_screen_exportDataTitle': 'アプリデータをエクスポート',
  'settings_screen_exportDataSubtitle': 'プラグインデータをファイルにエクスポート',
  'settings_screen_dataManagementTitle': 'データファイル管理',
  'settings_screen_dataManagementSubtitle': 'アプリデータディレクトリ内のファイルを管理',
  'settings_screen_importDataTitle': 'アプリデータをインポート',
  'settings_screen_importDataSubtitle': 'ファイルからプラグインデータをインポート',
  'settings_screen_fullBackupTitle': '完全バックアップ',
  'settings_screen_fullBackupSubtitle': 'アプリデータディレクトリ全体をバックアップ',
  'settings_screen_fullRestoreTitle': '完全復元',
  'settings_screen_fullRestoreSubtitle': 'バックアップからアプリデータ全体を復元（既存データを上書き）',

  // WebDAV sync
  'settings_screen_webDAVTitle': 'WebDAV同期',
  'settings_screen_webDAVConnected': '接続済み',
  'settings_screen_webDAVDisconnected': '未接続',

  // Server sync
  'settings_screen_serverSyncTitle': 'サーバー同期',
  'settings_screen_serverSyncConnected': 'ログイン済み',
  'settings_screen_serverSyncDisconnected': '未ログイン',

  // Floating ball settings
  'settings_screen_floatingBallTitle': 'フローティングボール設定',
  'settings_screen_floatingBallEnabled': '有効',
  'settings_screen_floatingBallDisabled': '無効',

  // Auto backup settings
  'settings_screen_autoBackupTitle': '自動バックアップ設定',
  'settings_screen_autoBackupSubtitle': '自動バックアップスケジュールを設定',

  // Plugin management
  'settings_screen_pluginManagementTitle': 'プラグイン管理',
  'settings_screen_pluginManagementSubtitle': '起動時に読み込むプラグインを選択',
  'settings_screen_pluginManagementTip': '無効化されたプラグインは次回起動時に初期化をスキップします。再度有効化すると復元されます。',

  // Auto open last plugin
  'settings_screen_autoOpenLastPluginTitle': '最後に使用したプラグインを自動起動',
  'settings_screen_autoOpenLastPluginSubtitle': '起動時に最後に使用したプラグインを自動的に開く',

  // Update check
  'settings_screen_autoCheckUpdateTitle': '自動更新チェック',
  'settings_screen_autoCheckUpdateSubtitle': '定期的にアプリの新しいバージョンをチェック',
  'settings_screen_checkUpdateTitle': '更新をチェック',
  'settings_screen_checkUpdateSubtitle': '今すぐアプリの新しいバージョンをチェック',

  // Update prompts
  'settings_screen_updateAvailableTitle': '新しいバージョンが利用可能です',
  'settings_screen_updateAvailableContent': '現在のバージョン: @currentVersion\n最新バージョン: @latestVersion\nリリースノート:',
  'settings_screen_updateLaterButton': '後で行う',
  'settings_screen_updateViewButton': '更新を確認',
  'settings_screen_alreadyLatestVersion': '最新バージョンをインストール済みです',
  'settings_screen_updateCheckFailed': '更新チェックに失敗しました: @error',
  'settings_screen_checkingForUpdates': '更新をチェック中...',

  // Server sync settings
  'server_sync_title': 'サーバー同期',
  'server_sync_loggedIn': 'ログイン済み',
  'server_sync_serverAddress': 'サーバーアドレス',
  'server_sync_serverAddressRequired': 'サーバーアドレスを入力してください',
  'server_sync_serverAddressInvalid': 'http:// または https:// で始まる有効なサーバーアドレスを入力してください',
  'server_sync_username': 'ユーザー名',
  'server_sync_usernameRequired': 'ユーザー名を入力してください',
  'server_sync_password': 'パスワード',
  'server_sync_passwordRequired': 'パスワードを入力してください',
  'server_sync_deviceName': 'デバイス名',
  'server_sync_login': 'ログイン',
  'server_sync_register': '登録',
  'server_sync_logout': 'ログアウト',
  'server_sync_saveSettings': '設定を保存',
  'server_sync_testConnection': '接続をテスト',
  'server_sync_connectionSuccess': '接続成功',
  'server_sync_connectionFailed': '接続失敗',
  'server_sync_loginSuccess': 'ログイン成功',
  'server_sync_loginFailed': 'ログイン失敗',
  'server_sync_registerSuccess': '登録成功',
  'server_sync_registerFailed': '登録失敗',
  'server_sync_logoutSuccess': 'ログアウト成功',
  'server_sync_logoutFailed': 'ログアウト失敗',
  'server_sync_settingsSaved': '設定を保存しました',
  'server_sync_saveFailed': '保存に失敗しました',
  'server_sync_notLoggedIn': 'まずログインしてください',
  'server_sync_syncSettings': '同期設定',
  'server_sync_autoSync': '自動同期',
  'server_sync_autoSyncSubtitle': '定期的にサーバーにデータを自動同期',
  'server_sync_syncInterval': '同期間隔',
  'server_sync_minutes': '分',
  'server_sync_syncOnChange': 'ファイル変更時に同期',
  'server_sync_syncOnChangeSubtitle': 'ローカルファイルが変更されたときに自動的に同期をトリガー',
  'server_sync_syncOnStart': '起動時に同期',
  'server_sync_syncOnStartSubtitle': 'アプリ起動時にサーバーから最新データを自動的に取得',
  'server_sync_syncDirs': '同期ディレクトリ',
  'server_sync_selected': '選択済み',
  'server_sync_syncNow': '今すぐ同期',
  'server_sync_syncComplete': '同期完了: @success 成功、@conflict 競合、@error エラー',
  'server_sync_syncFailed': '同期失敗',
  'server_sync_encryptionKey': '暗号化キー',
  'server_sync_encryptionKeyHint': '⚠️ このキーは管理パネルAPIアクセスに使用されます。安全に保管し、共有しないでください',
  'server_sync_copyKey': 'キーをコピー',
  'server_sync_keyCopied': 'キーをクリップボードにコピーしました',

  // Language selection dialog
  'settingsScreen_selectLanguage': '言語を選択',
  'settingsScreen_chinese': '中文',
  'settingsScreen_english': 'English',
  'settingsScreen_japanese': '日本語',
};
