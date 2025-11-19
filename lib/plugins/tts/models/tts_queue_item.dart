import 'package:uuid/uuid.dart';

/// TTS队列项状态
enum TTSQueueItemStatus {
  /// 等待中
  pending,

  /// 正在朗读
  playing,

  /// 已完成
  completed,

  /// 出错
  error,
}

/// TTS朗读队列项
class TTSQueueItem {
  /// 唯一标识
  final String id;

  /// 要朗读的文本
  final String text;

  /// 指定的服务ID (如果为null则使用默认服务)
  final String? serviceId;

  /// 状态
  TTSQueueItemStatus status;

  /// 错误信息
  String? error;

  /// 创建时间
  final DateTime createdAt;

  TTSQueueItem({
    String? id,
    required this.text,
    this.serviceId,
    this.status = TTSQueueItemStatus.pending,
    this.error,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  /// 从JSON创建
  factory TTSQueueItem.fromJson(Map<String, dynamic> json) {
    return TTSQueueItem(
      id: json['id'] as String,
      text: json['text'] as String,
      serviceId: json['serviceId'] as String?,
      status: TTSQueueItemStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TTSQueueItemStatus.pending,
      ),
      error: json['error'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      if (serviceId != null) 'serviceId': serviceId,
      'status': status.name,
      if (error != null) 'error': error,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// 复制并修改
  TTSQueueItem copyWith({
    String? text,
    String? serviceId,
    TTSQueueItemStatus? status,
    String? error,
  }) {
    return TTSQueueItem(
      id: id,
      text: text ?? this.text,
      serviceId: serviceId ?? this.serviceId,
      status: status ?? this.status,
      error: error ?? this.error,
      createdAt: createdAt,
    );
  }

  @override
  String toString() =>
      'TTSQueueItem(id: $id, text: ${text.substring(0, text.length > 20 ? 20 : text.length)}..., status: ${status.name})';
}
