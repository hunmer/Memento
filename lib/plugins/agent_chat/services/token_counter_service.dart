/// Token计数服务
///
/// 提供简单的token估算功能
/// 注意：这是估算值，实际token数可能有所不同
class TokenCounterService {
  /// 估算文本的token数量
  ///
  /// 使用简单的规则：
  /// - 英文：约4个字符 = 1 token
  /// - 中文：约1.5个字符 = 1 token
  /// - 混合文本：取平均值约2个字符 = 1 token
  ///
  /// 这是一个粗略估算，实际应用可以考虑集成tiktoken库
  static int estimateTokenCount(String text) {
    if (text.isEmpty) return 0;

    // 统计中文字符数
    final chinesePattern = RegExp(r'[\u4e00-\u9fa5]');
    final chineseMatches = chinesePattern.allMatches(text);
    final chineseCount = chineseMatches.length;

    // 统计英文单词数（简化处理）
    final englishWords = text
        .replaceAll(chinesePattern, ' ') // 移除中文
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;

    // 中文：1.5字符/token，英文：4字符/token
    // 简化计算：中文约0.7 token/字，英文约1 token/单词
    final chineseTokens = (chineseCount * 0.7).ceil();
    final englishTokens = englishWords;

    return chineseTokens + englishTokens;
  }

  /// 计算图片的token数
  ///
  /// Vision模型中，一张图片大约消耗85-170 tokens
  /// 这里使用保守估计：100 tokens/图片
  static int estimateImageTokens({int imageCount = 1}) {
    return imageCount * 100;
  }

  /// 计算文档的token数（基于文件大小估算）
  ///
  /// 1KB 文本 ≈ 250 tokens（粗略估算）
  static int estimateDocumentTokens(int fileSizeBytes) {
    final fileSizeKB = fileSizeBytes / 1024;
    return (fileSizeKB * 250).ceil();
  }

  /// 格式化token数显示
  ///
  /// 例如：1234 -> "1.2K tokens"
  static String formatTokenCount(int tokenCount) {
    if (tokenCount < 1000) {
      return '$tokenCount tokens';
    } else if (tokenCount < 1000000) {
      final k = (tokenCount / 1000).toStringAsFixed(1);
      return '${k}K tokens';
    } else {
      final m = (tokenCount / 1000000).toStringAsFixed(1);
      return '${m}M tokens';
    }
  }

  /// 简短格式化（用于UI紧凑显示）
  ///
  /// 例如：~123
  static String formatTokenCountShort(int tokenCount) {
    if (tokenCount < 1000) {
      return '~$tokenCount';
    } else if (tokenCount < 1000000) {
      final k = (tokenCount / 1000).toStringAsFixed(1);
      return '~${k}K';
    } else {
      final m = (tokenCount / 1000000).toStringAsFixed(1);
      return '~${m}M';
    }
  }
}
