import 'webdav_localizations.dart';

class WebDAVLocalizationsZh extends WebDAVLocalizations {
  WebDAVLocalizationsZh() : super('zh');

  @override
  String get settingsTitle => 'WebDAV 设置';

  @override
  String get serverAddressLabel => 'WebDAV 服务器地址';

  @override
  String get serverAddressHint => 'https://example.com/webdav';

  @override
  String get serverAddressEmptyError => '请输入WebDAV服务器地址';

  @override
  String get serverAddressInvalidError => '地址必须以http://或https://开头';

  @override
  String get usernameLabel => '用户名';

  @override
  String get usernameEmptyError => '请输入用户名';

  @override
  String get passwordLabel => '密码';

  @override
  String get passwordEmptyError => '请输入密码';

  @override
  String get dataPathLabel => '数据目录路径';

  @override
  String get dataPathHint => '/app_data';

  @override
  String get dataPathEmptyError => '请输入数据目录路径';

  @override
  String get dataPathInvalidError => '路径必须以/开头';

  @override
  String get autoSyncLabel => '自动同步';

  @override
  String get autoSyncSubtitle => '监控本地文件变化并自动同步到WebDAV (不包含配置文件)';

  @override
  String get testConnectionButton => '测试连接';

  @override
  String get disconnectButton => '断开连接';

  @override
  String get downloadButton => '下载';

  @override
  String get uploadButton => '上传';

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
}