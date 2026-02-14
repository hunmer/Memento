import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'tts_manager_service.dart';

/// 后台播报服务
///
/// 用于定期播报文本，支持时间占位符替换
class BackgroundAnnouncementService extends ChangeNotifier {
  static final BackgroundAnnouncementService _instance =
      BackgroundAnnouncementService._internal();

  factory BackgroundAnnouncementService() => _instance;

  BackgroundAnnouncementService._internal();

  /// TTS管理器服务
  TTSManagerService? _ttsManager;

  /// 播报计时器
  Timer? _announcementTimer;

  /// 是否正在播报
  bool _isActive = false;

  /// 播报间隔（秒）
  int _intervalSeconds = 60;

  /// 播报文本
  String _textTemplate = '现在是 {yyyy-MM-dd HH:mm:ss}';

  /// 使用的TTS服务ID
  String? _serviceId;

  /// 最后一次播报的时间
  DateTime? _lastAnnouncementTime;

  /// 播报次数
  int _announcementCount = 0;

  /// 是否正在播报
  bool get isActive => _isActive;

  /// 播报间隔（秒）
  int get intervalSeconds => _intervalSeconds;

  /// 播报文本模板
  String get textTemplate => _textTemplate;

  /// 使用的TTS服务ID
  String? get serviceId => _serviceId;

  /// 最后一次播报的时间
  DateTime? get lastAnnouncementTime => _lastAnnouncementTime;

  /// 播报次数
  int get announcementCount => _announcementCount;

  /// 下一次播报时间
  DateTime? get nextAnnouncementTime {
    if (_lastAnnouncementTime == null || !_isActive) {
      return null;
    }
    return _lastAnnouncementTime!.add(Duration(seconds: _intervalSeconds));
  }

  /// 初始化服务
  void initialize(TTSManagerService ttsManager) {
    _ttsManager = ttsManager;
  }

  /// 启动播报
  Future<void> start({
    required int intervalSeconds,
    required String textTemplate,
    String? serviceId,
  }) async {
    if (_ttsManager == null) {
      throw StateError('TTS管理器未初始化');
    }

    // 如果已在运行，先停止
    if (_isActive) {
      await stop();
    }

    // 检查服务是否存在
    if (serviceId != null) {
      final service = await _ttsManager!.getServiceById(serviceId);
      if (service == null) {
        throw Exception('指定的TTS服务不存在');
      }
    }

    _intervalSeconds = intervalSeconds;
    _textTemplate = textTemplate;
    _serviceId = serviceId;
    _isActive = true;
    _announcementCount = 0;

    // 立即播报一次
    await _speak();

    // 启动定时器
    _announcementTimer = Timer.periodic(
      Duration(seconds: _intervalSeconds),
      (_) => _speak(),
    );

    notifyListeners();
  }

  /// 停止播报
  Future<void> stop() async {
    _isActive = false;
    _announcementTimer?.cancel();
    _announcementTimer = null;

    // 停止当前的TTS播放
    await _ttsManager?.stop();

    notifyListeners();
  }

  /// 执行播报
  Future<void> _speak() async {
    if (!_isActive) return;

    try {
      // 替换时间占位符
      final text = _replacePlaceholders(_textTemplate);

      await _ttsManager!.speak(
        text,
        serviceId: _serviceId,
        onComplete: () {
          _lastAnnouncementTime = DateTime.now();
          _announcementCount++;
          notifyListeners();
        },
        onError: (error) {
          debugPrint('播报失败: $error');
        },
      );
    } catch (e) {
      debugPrint('播报异常: $e');
    }
  }

  /// 替换文本中的时间占位符
  String _replacePlaceholders(String template) {
    final now = DateTime.now();
    String result = template;

    // 日期占位符
    result = result.replaceAll(
      '{yyyy}',
      DateFormat('yyyy').format(now),
    );
    result = result.replaceAll(
      '{yy}',
      DateFormat('yy').format(now),
    );
    result = result.replaceAll(
      '{MM}',
      DateFormat('MM').format(now),
    );
    result = result.replaceAll(
      '{dd}',
      DateFormat('dd').format(now),
    );

    // 时间占位符
    result = result.replaceAll(
      '{HH}',
      DateFormat('HH').format(now),
    );
    result = result.replaceAll(
      '{mm}',
      DateFormat('mm').format(now),
    );
    result = result.replaceAll(
      '{ss}',
      DateFormat('ss').format(now),
    );

    // 组合占位符
    result = result.replaceAll(
      '{yyyy-MM-dd}',
      DateFormat('yyyy-MM-dd').format(now),
    );
    result = result.replaceAll(
      '{HH:mm:ss}',
      DateFormat('HH:mm:ss').format(now),
    );
    result = result.replaceAll(
      '{HH:mm}',
      DateFormat('HH:mm').format(now),
    );
    result = result.replaceAll(
      '{yyyy-MM-dd HH:mm:ss}',
      DateFormat('yyyy-MM-dd HH:mm:ss').format(now),
    );

    // 中文格式需要手动构建（Intl DateFormat 不支持中文分隔符）
    result = result.replaceAll(
      '{yyyy年MM月dd日}',
      '${DateFormat('yyyy').format(now)}年${DateFormat('MM').format(now)}月${DateFormat('dd').format(now)}日',
    );
    result = result.replaceAll(
      '{HH时mm分}',
      '${DateFormat('HH').format(now)}时${DateFormat('mm').format(now)}分',
    );
    result = result.replaceAll(
      '{HH时mm分ss秒}',
      '${DateFormat('HH').format(now)}时${DateFormat('mm').format(now)}分${DateFormat('ss').format(now)}秒',
    );
    result = result.replaceAll(
      '{HH时mm}',
      '${DateFormat('HH').format(now)}时${DateFormat('mm').format(now)}',
    );

    // 星期
    final weekDays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    result = result.replaceAll(
      '{weekday}',
      weekDays[now.weekday - 1],
    );

    return result;
  }

  /// 手动播报一次
  Future<void> speakOnce({String? textTemplate}) async {
    if (_ttsManager == null) {
      throw StateError('TTS管理器未初始化');
    }

    final template = textTemplate ?? _textTemplate;
    final text = _replacePlaceholders(template);

    await _ttsManager!.speak(
      text,
      serviceId: _serviceId,
    );
  }

  /// 更新配置（如果正在运行）
  void updateConfig({
    int? intervalSeconds,
    String? textTemplate,
    String? serviceId,
  }) {
    bool needRestart = false;

    if (intervalSeconds != null && intervalSeconds != _intervalSeconds) {
      _intervalSeconds = intervalSeconds;
      needRestart = true;
    }

    if (textTemplate != null && textTemplate != _textTemplate) {
      _textTemplate = textTemplate;
    }

    if (serviceId != null && serviceId != _serviceId) {
      _serviceId = serviceId;
      needRestart = true;
    }

    if (needRestart && _isActive) {
      // 重启播报
      start(
        intervalSeconds: _intervalSeconds,
        textTemplate: _textTemplate,
        serviceId: _serviceId,
      );
    }

    notifyListeners();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
