import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logging/logging.dart';
import 'tts_base_service.dart';
import 'package:Memento/plugins/tts/models/tts_voice.dart';

/// MiniMax TTS服务实现
class MiniMaxTTSService extends TTSBaseService {
  static final _log = Logger('MiniMaxTTSService');
  static const String _baseUrl = 'https://api.minimaxi.com/v1/t2a_v2';

  final Dio _dio = Dio();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isPlaying = false;
  bool _isPaused = false;

  /// MiniMax 可用模型列表
  static const List<String> _availableModels = [
    'speech-2.8-hd',
    'speech-2.8-turbo',
    'speech-2.6-hd',
    'speech-2.6-turbo',
    'speech-02-hd',
    'speech-02-turbo',
    'speech-01-hd',
    'speech-01-turbo',
  ];

  /// MiniMax 可用情绪列表
  static const List<String> _availableEmotions = [
    'happy',
    'sad',
    'angry',
    'fearful',
    'disgusted',
    'surprised',
    'calm',
    'fluent',
    'whisper',
  ];

  MiniMaxTTSService(super.config);

  @override
  Future<void> initialize() async {
    try {
      // 验证配置
      if (config.apiKey == null || config.apiKey!.isEmpty) {
        throw Exception('MiniMax API Key 不能为空');
      }
      if (config.voiceId == null || config.voiceId!.isEmpty) {
        throw Exception('MiniMax 语音ID 不能为空');
      }

      // 配置 Dio
      _dio.options.headers['Authorization'] = 'Bearer ${config.apiKey}';
      _dio.options.headers['Content-Type'] = 'application/json';
      _dio.options.connectTimeout = const Duration(seconds: 30);
      _dio.options.receiveTimeout = const Duration(seconds: 30);

      // 配置音频播放器回调
      _audioPlayer.onPlayerStateChanged.listen((state) {
        if (state == PlayerState.completed) {
          _isPlaying = false;
          _isPaused = false;
        }
      });

      _log.info('MiniMax TTS服务初始化成功: ${config.name}');
    } catch (e) {
      _log.severe('MiniMax TTS服务初始化失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> speak(
    String text, {
    TTSCallback? onStart,
    TTSCallback? onComplete,
    TTSErrorCallback? onError,
  }) async {
    try {
      onStart?.call();
      _isPlaying = true;
      _isPaused = false;

      _log.info('MiniMax TTS 朗读: ${text.substring(0, text.length > 50 ? 50 : text.length)}...');

      // 构建请求体
      final requestBody = _buildRequestBody(text);

      _log.info('MiniMax 请求: model=${requestBody['model']}, voiceId=${config.voiceId}');

      // 发送请求
      final response = await _dio.post(
        _baseUrl,
        data: requestBody,
        options: Options(
          responseType: ResponseType.json,
        ),
      );

      // 解析响应
      final responseData = response.data as Map<String, dynamic>;

      // 检查响应状态
      final baseResp = responseData['base_resp'] as Map<String, dynamic>?;
      if (baseResp != null) {
        final statusCode = baseResp['status_code'] as int?;
        final statusMsg = baseResp['status_msg'] as String?;
        if (statusCode != 0) {
          throw Exception('MiniMax API 错误: $statusCode - $statusMsg');
        }
      }

      // 提取音频数据
      final data = responseData['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('MiniMax 响应数据为空');
      }

      final audioHex = data['audio'] as String?;
      if (audioHex == null || audioHex.isEmpty) {
        throw Exception('MiniMax 音频数据为空');
      }

      // Hex 解码为字节
      final audioBytes = _hexToBytes(audioHex);
      _log.info('收到音频字节: ${audioBytes.length} bytes');

      // 播放音频
      await _playAudioFromBytes(audioBytes);

      onComplete?.call();
      _isPlaying = false;
      _isPaused = false;
    } catch (e) {
      _log.severe('MiniMax TTS朗读失败: $e');
      onError?.call(e.toString());
      _isPlaying = false;
      _isPaused = false;
    }
  }

  /// 构建请求体
  Map<String, dynamic> _buildRequestBody(String text) {
    return {
      'model': config.model ?? 'speech-2.8-hd',
      'text': text,
      'stream': false,
      'voice_setting': {
        'voice_id': config.voiceId,
        'speed': config.speed,
        'vol': ((config.volume * 10).clamp(1, 10)).toInt(), // MiniMax vol 范围 (0,10]，我们的 volume 是 0-1
        'pitch': ((config.pitch - 1) * 12).clamp(-12, 12).toInt(), // MiniMax pitch 范围 [-12,12]，我们的 pitch 是 0.5-2.0
        if (config.emotion != null && config.emotion!.isNotEmpty)
          'emotion': config.emotion,
      },
      'audio_setting': {
        'sample_rate': 32000,
        'bitrate': 128000,
        'format': config.audioFormat ?? 'mp3',
        'channel': 1,
      },
      'output_format': 'hex',
    };
  }

  /// Hex 字符串转字节数组
  List<int> _hexToBytes(String hexString) {
    final buffer = StringBuffer();
    for (int i = 0; i < hexString.length; i += 2) {
      buffer.write(String.fromCharCode(
        int.parse(hexString.substring(i, i + 2), radix: 16),
      ));
    }
    return latin1.encode(buffer.toString());
  }

  /// 从字节数组播放音频
  Future<void> _playAudioFromBytes(List<int> audioBytes) async {
    try {
      // 保存到临时文件
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/minimax_tts_${DateTime.now().millisecondsSinceEpoch}.${config.audioFormat ?? 'mp3'}');

      await tempFile.writeAsBytes(audioBytes);
      _log.info('音频临时文件: ${tempFile.path}');

      // 播放音频
      await _audioPlayer.play(DeviceFileSource(tempFile.path));

      // 等待播放完成
      await _audioPlayer.onPlayerComplete.first;

      // 删除临时文件
      try {
        await tempFile.delete();
      } catch (e) {
        _log.warning('删除临时文件失败: $e');
      }
    } catch (e) {
      _log.severe('播放音频失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
      _isPaused = false;
      _log.info('停止 MiniMax TTS 播放');
    } catch (e) {
      _log.warning('停止 MiniMax TTS 播放失败: $e');
    }
  }

  @override
  Future<void> pause() async {
    try {
      if (_isPlaying && !_isPaused) {
        await _audioPlayer.pause();
        _isPaused = true;
        _log.info('暂停 MiniMax TTS 播放');
      }
    } catch (e) {
      _log.warning('暂停 MiniMax TTS 播放失败: $e');
    }
  }

  @override
  Future<void> resume() async {
    try {
      if (_isPlaying && _isPaused) {
        await _audioPlayer.resume();
        _isPaused = false;
        _log.info('继续 MiniMax TTS 播放');
      }
    } catch (e) {
      _log.warning('继续 MiniMax TTS 播放失败: $e');
    }
  }

  @override
  Future<List<TTSVoice>> getAvailableVoices() async {
    // MiniMax 需要用户手动配置语音 ID
    // 这里返回一些常用的系统音色示例
    return [
      TTSVoice(
        id: 'female-tianmei',
        name: '甜美女生',
        language: 'Chinese',
        gender: 'female',
      ),
      TTSVoice(
        id: 'male-qn-qingse',
        name: '青涩男生',
        language: 'Chinese',
        gender: 'male',
      ),
      TTSVoice(
        id: 'presenter_male',
        name: '男主持',
        language: 'Chinese',
        gender: 'male',
      ),
      TTSVoice(
        id: 'presenter_female',
        name: '女主持',
        language: 'Chinese',
        gender: 'female',
      ),
    ];
  }

  /// 获取可用模型列表
  static List<String> getAvailableModels() => List.unmodifiable(_availableModels);

  /// 获取可用情绪列表
  static List<String> getAvailableEmotions() => List.unmodifiable(_availableEmotions);

  @override
  Future<bool> testConnection() async {
    try {
      _log.info('测试 MiniMax TTS 连接');

      // 发送测试请求
      await speak(
        '测试',
        onError: (error) {
          throw Exception(error);
        },
      );

      return true;
    } catch (e) {
      _log.warning('MiniMax TTS 连接测试失败: $e');
      return false;
    }
  }

  @override
  Future<void> dispose() async {
    try {
      await _audioPlayer.dispose();
      _dio.close();
      _log.info('MiniMax TTS 服务已释放');
    } catch (e) {
      _log.warning('释放 MiniMax TTS 服务失败: $e');
    }
  }
}
