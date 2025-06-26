import 'package:Memento/screens/settings_screen/widgets/l10n/webdav_localizations.dart';
import 'package:flutter/widgets.dart';

class WebDAVLocalizationsZh extends WebDAVLocalizations {
  WebDAVLocalizationsZh() : super('zh');

  @override
  String get pluginName => 'WebDAV设置';

  @override
  String get serverUrl => '服务器地址';

  @override
  String get serverUrlHint => '输入WebDAV服务器地址';

  @override
  String get username => '用户名';

  @override
  String get usernameHint => '输入您的用户名';

  @override
  String get password => '密码';

  @override
  String get passwordHint => '输入您的密码';

  @override
  String get testConnection => '测试连接';

  @override
  String get connectionSuccess => '连接成功';

  @override
  String get connectionFailed => '连接失败';

  @override
  String get saveSettings => '保存设置';

  @override
  String get settingsSaved => '设置保存成功';

  @override
  String get settingsSaveFailed => '设置保存失败';

  @override
  String get rootPath => '根路径';

  @override
  String get rootPathHint => '输入服务器上的根路径';

  @override
  String get syncInterval => '同步间隔';

  @override
  String get syncIntervalHint => '设置同步间隔(分钟)';

  @override
  String get enableAutoSync => '启用自动同步';

  @override
  String get lastSyncTime => '上次同步时间';

  @override
  String get syncNow => '立即同步';

  @override
  String get syncInProgress => '正在同步...';

  @override
  String get syncCompleted => '同步完成';

  @override
  String get syncFailed => '同步失败';

  @override
  String get invalidUrl => '无效的URL';

  @override
  String get invalidCredentials => '无效的凭证';

  @override
  String get serverUnreachable => '无法连接到服务器';

  @override
  String get permissionDenied => '权限被拒绝';

  @override
  String get sslCertificateError => 'SSL证书错误';

  @override
  String get advancedSettings => '高级设置';

  @override
  String get connectionTimeout => '连接超时';

  @override
  String get connectionTimeoutHint => '设置超时时间(秒)';

  @override
  String get useHTTPS => '使用HTTPS';

  @override
  String get verifyCertificate => '验证证书';

  @override
  String get maxRetries => '最大重试次数';

  @override
  String get maxRetriesHint => '设置最大重试次数';

  @override
  String get retryInterval => '重试间隔';

  @override
  String get retryIntervalHint => '设置重试间隔(秒)';

  @override
  String get dataSync => '数据同步';

  @override
  String get downloadAllData => '下载所有数据';

  @override
  String get passwordEmptyError => '密码不能为空';

  @override
  String get saveFailed => '保存失败';

  @override
  String get serverAddress => '服务器地址';

  @override
  String get serverAddressEmptyError => '服务器地址不能为空';

  @override
  String get serverAddressHint => '输入服务器地址';

  @override
  String? get serverAddressInvalidError => '无效的服务器地址';

  @override
  String get title => 'WebDAV设置';

  @override
  String get uploadAllData => '上传所有数据';

  @override
  String get usernameEmptyError => '用户名不能为空';
}
