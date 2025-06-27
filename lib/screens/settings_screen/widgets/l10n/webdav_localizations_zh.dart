import 'webdav_localizations.dart';

class WebDAVLocalizationsZh extends WebDAVLocalizations {
  WebDAVLocalizationsZh() : super('zh');

  @override
  String get serverAddressHint => 'https://example.com/webdav';

  @override
  String get serverAddressEmptyError => '请输入WebDAV服务器地址';

  @override
  String get serverAddressInvalidError => '地址必须以http://或https://开头';

  @override
  String get usernameEmptyError => '请输入用户名';

  @override
  String get passwordEmptyError => '请输入密码';

  @override
  String get connectingStatus => '正在连接...';

  @override
  String get connectionSuccessStatus => '连接成功!';

  @override
  String get connectionFailedStatus => '连接失败，请检查设置';

  @override
  String get connectionErrorStatus => '连接错误: ';

  @override
  String get disconnectingStatus => '正在断开连接...';

  @override
  String get disconnectedStatus => '已断开连接';

  @override
  String get uploadingStatus => '正在上传数据到WebDAV...';

  @override
  String get uploadSuccessStatus => '上传成功!';

  @override
  String get uploadFailedStatus => '上传失败，请检查连接';

  @override
  String get downloadingStatus => '正在从WebDAV下载数据...';

  @override
  String get downloadSuccessStatus => '下载成功!';

  @override
  String get downloadFailedStatus => '下载失败，请检查连接';

  @override
  String get autoSyncEnabledStatus => '自动同步已开启，点击完成后生效';

  @override
  String get autoSyncDisabledStatus => '自动同步已关闭，点击完成后生效';

  @override
  String get settingsSavedMessage => '设置已保存';

  @override
  String get advancedSettings => '高级设置';

  @override
  String get connectionFailed => '连接失败';

  @override
  String get connectionSuccess => '连接成功';

  @override
  String get connectionTimeout => '连接超时';

  @override
  String get connectionTimeoutHint => '连接超时时间(秒)';

  @override
  String get dataSync => '数据同步';

  @override
  String get disconnect => '断开连接';

  @override
  String get downloadAllData => '下载所有数据';

  @override
  String get enableAutoSync => '启用自动同步';

  @override
  String get invalidCredentials => '无效的凭据';

  @override
  String get invalidUrl => '无效的URL';

  @override
  String get lastSyncTime => '上次同步时间';

  @override
  String get maxRetries => '最大重试次数';

  @override
  String get maxRetriesHint => '连接失败时的最大重试次数';

  @override
  String get password => '密码';

  @override
  String get passwordHint => '请输入密码';

  @override
  String get permissionDenied => '权限不足';

  @override
  String get name => 'WebDAV同步';

  @override
  String get retryInterval => '重试间隔';

  @override
  String get retryIntervalHint => '重试间隔时间(秒)';

  @override
  String get rootPath => '根路径';

  @override
  String get rootPathEmptyError => '请输入根路径';

  @override
  String get rootPathHint => '/webdav';

  @override
  String? get rootPathInvalidError => '路径必须以/开头';

  @override
  String get saveFailed => '保存失败';

  @override
  String get saveSettings => '保存设置';

  @override
  String get serverAddress => '服务器地址';

  @override
  String get serverUnreachable => '无法访问服务器';

  @override
  String get serverUrl => '服务器URL';

  @override
  String get serverUrlHint => 'https://example.com/webdav';

  @override
  String get settingsSaveFailed => '设置保存失败';

  @override
  String get settingsSaved => '设置已保存';

  @override
  String get sslCertificateError => 'SSL证书错误';

  @override
  String get syncCompleted => '同步完成';

  @override
  String get syncFailed => '同步失败';

  @override
  String get syncInProgress => '正在同步...';

  @override
  String get syncInterval => '同步间隔';

  @override
  String get syncIntervalHint => '自动同步间隔时间(分钟)';

  @override
  String get syncNow => '立即同步';

  @override
  String get testConnection => '测试连接';

  @override
  String get title => 'WebDAV设置';

  @override
  String get uploadAllData => '上传所有数据';

  @override
  String get useHTTPS => '使用HTTPS';

  @override
  String get username => '用户名';

  @override
  String get usernameHint => '请输入用户名';

  @override
  String get verifyCertificate => '验证证书';
}
