import 'package:Memento/screens/settings_screen/widgets/webdav_localizations.dart';
import 'package:flutter/material.dart';

class WebDAVLocalizationsZh implements WebDAVLocalizations {
  const WebDAVLocalizationsZh();

  @override
  String get title => 'WebDAV同步';

  @override
  String get serverAddress => 'WebDAV服务器地址';

  @override
  String get serverAddressHint => 'https://your-webdav-server.com/dav';

  @override
  String get serverAddressEmptyError => '请输入WebDAV服务器地址';

  @override
  String get serverAddressInvalidError => '服务器地址必须以http://或https://开头';

  @override
  String get username => '用户名';

  @override
  String get usernameEmptyError => '请输入用户名';

  @override
  String get password => '密码';

  @override
  String get passwordEmptyError => '请输入密码';

  @override
  String get saveSettings => '保存设置';

  @override
  String get dataSync => '数据同步';

  @override
  String get uploadAllData => '上传所有数据';

  @override
  String get downloadAllData => '下载所有数据';

  @override
  String get settingsSaved => 'WebDAV设置已保存';

  @override
  String get saveFailed => '保存失败';

  @override
  String get autoSyncDisabledStatus => '自动同步已禁用';

  @override
  String get autoSyncEnabledStatus => '自动同步已启用';

  @override
  String get autoSyncLabel => '自动同步';

  @override
  String get autoSyncSubtitle => '定期自动同步数据';

  @override
  String get connectingStatus => '连接中...';

  @override
  String get connectionErrorStatus => '连接错误';

  @override
  String get connectionFailedStatus => '连接失败';

  @override
  String get connectionSuccessStatus => '连接成功';

  @override
  String get dataPathEmptyError => '请输入数据路径';

  @override
  String get dataPathHint => '/path/to/data';

  @override
  String get dataPathInvalidError => '数据路径无效';

  @override
  String get dataPathLabel => '数据路径';

  @override
  String get disconnectButton => '断开连接';

  @override
  String get disconnectedStatus => '已断开连接';

  @override
  String get disconnectingStatus => '正在断开连接...';

  @override
  String get downloadButton => '下载';

  @override
  String get downloadFailedStatus => '下载失败';

  @override
  String get downloadSuccessStatus => '下载成功';

  @override
  String get downloadingStatus => '下载中...';

  @override
  String get localeName => '中文';

  @override
  String get passwordLabel => '密码';

  @override
  String get serverAddressLabel => '服务器地址';

  @override
  String get settingsSavedMessage => '设置已保存';

  @override
  String get settingsTitle => '设置';

  @override
  String get testConnectionButton => '测试连接';

  @override
  String get uploadButton => '上传';

  @override
  String get uploadFailedStatus => '上传失败';

  @override
  String get uploadSuccessStatus => '上传成功';

  @override
  String get uploadingStatus => '上传中...';

  @override
  String get usernameLabel => '用户名';
}
