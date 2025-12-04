import 'memento_nfc_platform_interface.dart';

/// NFC数据读取结果
class NfcReadResult {
  final bool success;
  final String? data;
  final String? error;

  NfcReadResult({required this.success, this.data, this.error});

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'data': data,
      'error': error,
    };
  }

  factory NfcReadResult.fromMap(Map<String, dynamic> map) {
    return NfcReadResult(
      success: map['success'] ?? false,
      data: map['data'],
      error: map['error'],
    );
  }
}

/// NFC数据写入结果
class NfcWriteResult {
  final bool success;
  final String? error;

  NfcWriteResult({required this.success, this.error});

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'error': error,
    };
  }

  factory NfcWriteResult.fromMap(Map<String, dynamic> map) {
    return NfcWriteResult(
      success: map['success'] ?? false,
      error: map['error'],
    );
  }
}

class MementoNfc {
  /// 获取平台版本
  Future<String?> getPlatformVersion() {
    return MementoNfcPlatform.instance.getPlatformVersion();
  }

  /// 检查设备是否支持NFC
  Future<bool> isNfcSupported() {
    return MementoNfcPlatform.instance.isNfcSupported();
  }

  /// 检查NFC是否已启用
  Future<bool> isNfcEnabled() {
    return MementoNfcPlatform.instance.isNfcEnabled();
  }

  /// 读取NFC标签数据
  /// 返回包含读取结果的Future
  Future<NfcReadResult> readNfc() {
    return MementoNfcPlatform.instance.readNfc();
  }

  /// 写入数据到NFC标签
  /// [data] 要写入的数据
  /// [formatType] NFC格式类型，默认为'NDEF'
  Future<NfcWriteResult> writeNfc(String data, {String formatType = 'NDEF'}) {
    return MementoNfcPlatform.instance.writeNfc(data, formatType: formatType);
  }

  /// 写入NDEF格式的URL
  /// [url] 要写入的URL
  Future<NfcWriteResult> writeNdefUrl(String url) {
    return MementoNfcPlatform.instance.writeNdefUrl(url);
  }

  /// 写入NDEF格式的文本
  /// [text] 要写入的文本
  Future<NfcWriteResult> writeNdefText(String text) {
    return MementoNfcPlatform.instance.writeNdefText(text);
  }
}
