import 'dart:convert';
import 'package:crypto/crypto.dart';

/// 腾讯云 ASR 配置
class TencentASRConfig {
  /// 应用 ID
  final String appId;

  /// 密钥 ID
  final String secretId;

  /// 密钥 Key
  final String secretKey;

  /// 采样率（默认 16000Hz）
  final int sampleRate;

  /// 引擎模型类型
  /// - 16k_zh: 16k 中文普通话通用
  /// - 8k_zh: 8k 中文普通话通用
  /// - 16k_zh_large: 16k 中文普通话大模型
  final String engineModelType;

  /// 是否需要 VAD（人声检测）
  final bool needVad;

  /// 是否过滤脏词���0-2）
  /// - 0: 不过滤
  /// - 1: 过滤
  /// - 2: 替换为 *
  final int filterDirty;

  /// 是否显示词级别时间戳
  final bool wordInfo;

  TencentASRConfig({
    required this.appId,
    required this.secretId,
    required this.secretKey,
    this.sampleRate = 16000,
    this.engineModelType = '16k_zh',
    this.needVad = false,
    this.filterDirty = 0,
    this.wordInfo = false,
  });

  /// 从 JSON 创建配置
  factory TencentASRConfig.fromJson(Map<String, dynamic> json) {
    return TencentASRConfig(
      appId: json['appId'] as String,
      secretId: json['secretId'] as String,
      secretKey: json['secretKey'] as String,
      sampleRate: json['sampleRate'] as int? ?? 16000,
      engineModelType: json['engineModelType'] as String? ?? '16k_zh',
      needVad: json['needVad'] as bool? ?? false,
      filterDirty: json['filterDirty'] as int? ?? 0,
      wordInfo: json['wordInfo'] as bool? ?? false,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'appId': appId,
      'secretId': secretId,
      'secretKey': secretKey,
      'sampleRate': sampleRate,
      'engineModelType': engineModelType,
      'needVad': needVad,
      'filterDirty': filterDirty,
      'wordInfo': wordInfo,
    };
  }

  /// 生成请求签名
  ///
  /// 签名算法：
  /// 1. 将所有参数（除 signature）按字典序排序并拼接为 URL 参数
  /// 2. 使用 SecretKey ��行 HMAC-SHA1 加密
  /// 3. Base64 编码
  /// 4. URL 编码
  String generateSignature({
    required int timestamp,
    required int expired,
    required int nonce,
    String? voiceId,
  }) {
    // 构建参数 Map
    final params = <String, String>{
      'secretid': secretId,
      'timestamp': timestamp.toString(),
      'expired': expired.toString(),
      'nonce': nonce.toString(),
      'engine_model_type': engineModelType,
      'voice_format': '1', // PCM 格式
    };

    if (voiceId != null) {
      params['voice_id'] = voiceId;
    }

    if (needVad) {
      params['needvad'] = '1';
    }

    if (filterDirty > 0) {
      params['filter_dirty'] = filterDirty.toString();
    }

    if (wordInfo) {
      params['word_info'] = '1';
    }

    // 按字典序排序参数
    final sortedKeys = params.keys.toList()..sort();

    // 拼接参数字符串
    final queryString = sortedKeys
        .map((key) => '$key=${params[key]}')
        .join('&');

    // HMAC-SHA1 加密
    final key = utf8.encode(secretKey);
    final bytes = utf8.encode(queryString);
    final hmacSha1 = Hmac(sha1, key);
    final digest = hmacSha1.convert(bytes);

    // Base64 编码
    final signature = base64.encode(digest.bytes);

    // URL 编码
    return Uri.encodeComponent(signature);
  }

  /// 生成 WebSocket 连接 URL
  String generateWebSocketUrl({
    required String voiceId,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final expired = timestamp + 3600; // 1 小时后过期
    final nonce = DateTime.now().millisecondsSinceEpoch % 1000000000;

    final signature = generateSignature(
      timestamp: timestamp,
      expired: expired,
      nonce: nonce,
      voiceId: voiceId,
    );

    // 构建查询参数
    final queryParams = <String, String>{
      'secretid': secretId,
      'timestamp': timestamp.toString(),
      'expired': expired.toString(),
      'nonce': nonce.toString(),
      'voice_id': voiceId,
      'engine_model_type': engineModelType,
      'voice_format': '1', // PCM
      'signature': signature,
    };

    if (needVad) {
      queryParams['needvad'] = '1';
    }

    if (filterDirty > 0) {
      queryParams['filter_dirty'] = filterDirty.toString();
    }

    if (wordInfo) {
      queryParams['word_info'] = '1';
    }

    // 构建查询字符串
    final queryString = queryParams.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');

    return 'wss://asr.cloud.tencent.com/asr/v2/$appId?$queryString';
  }

  /// 验证配置是否有效
  bool isValid() {
    return appId.isNotEmpty &&
        secretId.isNotEmpty &&
        secretKey.isNotEmpty &&
        (sampleRate == 8000 || sampleRate == 16000);
  }

  @override
  String toString() {
    return 'TencentASRConfig{appId: $appId, engineModelType: $engineModelType, sampleRate: $sampleRate}';
  }
}
