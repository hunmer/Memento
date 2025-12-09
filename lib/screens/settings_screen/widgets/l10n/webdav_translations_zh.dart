/// WebDAV设置中文翻译
const Map<String, String> webdavTranslationsZh = {
  // 基础信息
  'webdav_name': 'WebDAV同步',
  'webdav_title': 'WebDAV设置',

  // 表单字段
  'webdav_serverAddress': '服务器地址',
  'webdav_serverAddressHint': 'https://example.com/webdav',
  'webdav_serverUrl': '服务器URL',
  'webdav_serverUrlHint': 'https://example.com/webdav',
  'webdav_username': '用户名',
  'webdav_usernameHint': '请输入用户名',
  'webdav_password': '密码',
  'webdav_passwordHint': '请输入密码',
  'webdav_rootPath': '根路径',
  'webdav_rootPathHint': '/webdav',

  // 高级设置
  'webdav_advancedSettings': '高级设置',
  'webdav_connectionTimeout': '连接超时',
  'webdav_connectionTimeoutHint': '连接超时时间(秒)',
  'webdav_useHTTPS': '使用HTTPS',
  'webdav_verifyCertificate': '验证证书',
  'webdav_maxRetries': '最大重试次数',
  'webdav_maxRetriesHint': '连接失败时的最大重试次数',
  'webdav_retryInterval': '重试间隔',
  'webdav_retryIntervalHint': '重试间隔时间(秒)',

  // 同步设置
  'webdav_syncInterval': '同步间隔',
  'webdav_syncIntervalHint': '自动同步间隔时间(分钟)',
  'webdav_enableAutoSync': '启用自动同步',
  'webdav_lastSyncTime': '上次同步时间',

  // 数据同步
  'webdav_dataSync': '数据同步',
  'webdav_uploadAllData': '上传所有数据',
  'webdav_downloadAllData': '下载所有数据',
  'webdav_syncNow': '立即同步',

  // 操作按钮
  'webdav_testConnection': '测试连接',
  'webdav_disconnect': '断开连接',
  'webdav_saveSettings': '保存设置',

  // 表单验证错误
  'webdav_serverAddressEmptyError': '请输入WebDAV服务器地址',
  'webdav_serverAddressInvalidError': '地址必须以http://或https://开头',
  'webdav_usernameEmptyError': '请输入用户名',
  'webdav_passwordEmptyError': '请输入密码',
  'webdav_rootPathEmptyError': '请输入根路径',
  'webdav_rootPathInvalidError': '路径必须以/开头',

  // 连接状态
  'webdav_connectingStatus': '正在连接...',
  'webdav_connectionSuccessStatus': '连接成功!',
  'webdav_connectionFailedStatus': '连接失败,请检查设置',
  'webdav_connectionErrorStatus': '连接错误: ',
  'webdav_disconnectingStatus': '正在断开连接...',
  'webdav_disconnectedStatus': '已断开连接',

  // 同步状态
  'webdav_uploadingStatus': '正在上传数据到WebDAV...',
  'webdav_uploadSuccessStatus': '上传成功!',
  'webdav_uploadFailedStatus': '上传失败,请检查连接',
  'webdav_downloadingStatus': '正在从WebDAV下载数据...',
  'webdav_downloadSuccessStatus': '下载成功!',
  'webdav_downloadFailedStatus': '下载失败,请检查连接',
  'webdav_syncInProgress': '正在同步...',
  'webdav_syncCompleted': '同步完成',
  'webdav_syncFailed': '同步失败',

  // 自动同步状态
  'webdav_autoSyncEnabledStatus': '自动同步已开启,点击完成后生效',
  'webdav_autoSyncDisabledStatus': '自动同步已关闭,点击完成后生效',

  // 成功提示
  'webdav_connectionSuccess': '连接成功',
  'webdav_settingsSaved': '设置已保存',
  'webdav_settingsSavedMessage': '设置已保存',

  // 失败提示
  'webdav_connectionFailed': '连接失败',
  'webdav_settingsSaveFailed': '设置保存失败',
  'webdav_saveFailed': '保存失败',
  'webdav_invalidUrl': '无效的URL',
  'webdav_invalidCredentials': '无效的凭据',
  'webdav_serverUnreachable': '无法访问服务器',
  'webdav_permissionDenied': '权限不足',
  'webdav_sslCertificateError': 'SSL证书错误',
};
