import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// 文件附件模型
class FileAttachment {
  /// 附件ID
  final String id;

  /// 文件路径（绝对路径）
  final String filePath;

  /// 文件名
  final String fileName;

  /// 文件类型（'image' | 'document'）
  final String fileType;

  /// 文件大小（字节）
  final int fileSize;

  /// 缩略图路径（仅图片）
  final String? thumbnailPath;

  FileAttachment({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    this.thumbnailPath,
  });

  /// 创建图片附件
  factory FileAttachment.image({
    required String filePath,
    required String fileName,
    required int fileSize,
    String? thumbnailPath,
  }) {
    return FileAttachment(
      id: _uuid.v4(),
      filePath: filePath,
      fileName: fileName,
      fileType: 'image',
      fileSize: fileSize,
      thumbnailPath: thumbnailPath,
    );
  }

  /// 创建文档附件
  factory FileAttachment.document({
    required String filePath,
    required String fileName,
    required int fileSize,
  }) {
    return FileAttachment(
      id: _uuid.v4(),
      filePath: filePath,
      fileName: fileName,
      fileType: 'document',
      fileSize: fileSize,
    );
  }

  /// 从JSON反序列化
  factory FileAttachment.fromJson(Map<String, dynamic> json) {
    return FileAttachment(
      id: json['id'] as String,
      filePath: json['filePath'] as String,
      fileName: json['fileName'] as String,
      fileType: json['fileType'] as String,
      fileSize: json['fileSize'] as int,
      thumbnailPath: json['thumbnailPath'] as String?,
    );
  }

  /// 序列化为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filePath': filePath,
      'fileName': fileName,
      'fileType': fileType,
      'fileSize': fileSize,
      'thumbnailPath': thumbnailPath,
    };
  }

  /// 是否为图片
  bool get isImage => fileType == 'image';

  /// 是否为文档
  bool get isDocument => fileType == 'document';

  /// 获取格式化的文件大小
  String get formattedSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}
