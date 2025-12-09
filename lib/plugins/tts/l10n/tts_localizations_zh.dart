import 'tts_localizations.dart';

/// TTS插件中文本地化
class TTSLocalizationsZh extends {
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

  @override
  String get loading => '加载中...';

  @override
  String get setAsDefaultTTSService => '设为默认朗读服务';

  @override
  String get audioBase64Encoded => '音频Base64编码';

  @override
  String get audioIsBase64Encoded => '音频数据是否为Base64编码';

  @override
  String get enableThisService => '启用此服务';

  @override
  String get disableThisService => '禁用此服务';

  @override
  String get basicConfig => '基础配置';

  @override
  String get readingParameters => '朗读参数';

  @override
  String get httpConfig => 'HTTP 配置';

  @override
  String get directAudioReturn => '直接返回音频';

  @override
  String get jsonWrapped => 'JSON 包裹';

  @override
  String get loadVoiceListFailed => '加载语音列表失败';

  @override
  String get pleaseEnterApiUrl => '请输入API URL';

  @override
  String get urlMustStartWithHttp => 'URL 必须以 http:// 或 https:// 开头';

  @override
  String get configValidationFailed => '配置验证失败，请检查必填项';

  @override
  String get saveFailed => '保存失败';

  @override
  String get pleaseEnterAudioFieldPath => '请输入音频字段路径';

  @override
  String get noServicesAvailable => '暂无服务';

  @override
  String get setAsDefault => '设为默认';

  @override
  String get loadServicesFailed => '加载服务失败';

  @override
  String get serviceDeleted => '服务已删除';

  @override
  String get deleteFailed => '删除失败';

  @override
  String get updateFailed => '更新失败';

  @override
  String get setAsDefaultService => '已设置为默认服务';

  @override
  String get setDefaultFailed => '设置失败';

  @override
  String get serviceAdded => '服务已添加';

  @override
  String get addFailed => '添加失败';

  @override
  String get serviceUpdated => '服务已更新';

  @override
  String get voiceTestText => '你好，这是语音测试';

  @override
  String get testFailedPrefix => '测试失败';

  @override
  String get refresh => '刷新';

  @override
  String get loadingVoiceList => '正在加载语音列表...';

  @override
  String availableVoiceCount(int count) => '共 $count 个可用语音';

  @override
  String get reloadVoiceList => '重新加载语音列表';

  @override
  String get fillAccordingToApi => '根据API要求填写';

  @override
  String get responseType => '响应类型';

  @override
  String get audioFieldPath => '音频字段路径';

  @override
  String get audioFormat => '音频格式';
}
