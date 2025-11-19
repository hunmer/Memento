import 'tts_localizations.dart';

/// TTS插件中文本地化
class TTSLocalizationsZh extends TTSLocalizations {
  TTSLocalizationsZh(super.locale);
  @override
  String get name => '语音朗读';

  @override
  String get servicesList => '服务列表';

  @override
  String get addService => '添加服务';

  @override
  String get editService => '编辑服务';

  @override
  String get deleteService => '删除服务';

  @override
  String get serviceName => '服务名称';

  @override
  String get serviceType => '服务类型';

  @override
  String get systemTts => '系统TTS';

  @override
  String get httpService => 'HTTP服务';

  @override
  String get defaultService => '默认服务';

  @override
  String get enabled => '已启用';

  @override
  String get disabled => '已禁用';

  @override
  String get pitch => '音调';

  @override
  String get speed => '语速';

  @override
  String get volume => '音量';

  @override
  String get voice => '语音';

  @override
  String get apiUrl => 'API URL';

  @override
  String get headers => '请求头';

  @override
  String get requestBody => '请求体';

  @override
  String get test => '测试';

  @override
  String get testSuccess => '测试成功';

  @override
  String get testFailed => '测试失败';

  @override
  String get save => '保存';

  @override
  String get cancel => '取消';

  @override
  String get confirmDelete => '确定要删除这个服务吗？';

  @override
  String get queue => '队列';

  @override
  String get currentReading => '当前朗读';

  @override
  String get waiting => '等待中';

  @override
  String get clearQueue => '清空队列';
}
