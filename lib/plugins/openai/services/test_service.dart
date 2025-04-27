import 'package:flutter/material.dart';
import '../models/ai_agent.dart';
import 'request_service.dart';

class TestService {
  /// 显示长文本输入对话框
  static Future<String?> showLongTextInputDialog(
    BuildContext context, {
    String title = '测试输入',
    String hintText = '请输入测试文本',
    String initialValue = '',
  }) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false, // 防止点击外部关闭对话框导致控制器过早处置
      builder: (BuildContext dialogContext) {
        return _TextInputDialog(
          title: title,
          hintText: hintText,
          initialValue: initialValue,
        );
      },
    );
  }

  /// 发送请求并获取响应
  static Future<String> processTestRequest(String input, AIAgent agent) async {
    try {
      if (input.trim().isEmpty) {
        return "请提供输入内容。";
      }

      String response;
      if (input.toLowerCase().startsWith("/image")) {
        // 处理图片生成请求
        final prompt = input.substring(6).trim(); // 移除 "/image "
        if (prompt.isEmpty) {
          return "请在 /image 命令后提供图片描述。";
        }

        final imageUrls = await RequestService.generateImages(prompt, agent);
        response = '''
生成的图片链接:
${imageUrls.map((url) => "- $url").join('\n')}

提示词: $prompt
''';
      } else {
        // 处理聊天请求
        response = await RequestService.chat(input, agent);
      }

      return '''
输入: "${input.length > 50 ? '${input.substring(0, 50)}...' : input}"
    
回应:
$response

---
智能体: ${agent.name} (${agent.serviceProviderId})
API端点: ${agent.baseUrl}
''';
    } catch (e) {
      return '''
错误: 请求处理失败
详细信息: ${e.toString()}

请检查:
1. API密钥是否正确配置
2. 网络连接是否正常
3. 服务端点是否可访问
''';
    }
  }

  /// 显示响应结果对话框
  static void showResponseDialog(BuildContext context, String response) {
    // 检查响应是否包含图片URL
    final containsImageUrl =
        response.contains('生成的图片链接:') &&
        (response.contains('http://') || response.contains('https://'));

    // 使用独立的context避免MediaQuery依赖问题
    showDialog(
      context: context,
      barrierDismissible: true,
      useRootNavigator: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('测试响应'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SelectableText(response),
                if (containsImageUrl) ...[
                  const SizedBox(height: 16),
                  const Text(
                    '预览图片:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildImagePreview(response, dialogContext),
                ],
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('关闭'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// 从响应中提取并显示图片
  static Widget _buildImagePreview(String response, BuildContext context) {
    // 提取URL
    final RegExp urlRegex = RegExp(r'https?://\S+');
    final matches = urlRegex.allMatches(response);

    if (matches.isEmpty) {
      return const Text('无法加载图片预览');
    }

    // 使用ValueKey生成唯一键以避免重复键问题
    return Column(
      key: ValueKey('image_preview_${DateTime.now().millisecondsSinceEpoch}'),
      children:
          matches.map((match) {
            final url = match.group(0)!;
            // 移除URL末尾可能的标点符号
            final cleanUrl = url.replaceAll(RegExp(r'[,.\s;]$'), '');

            // 为每个图片容器生成唯一键
            final uniqueKey = ValueKey(
              'img_${cleanUrl.hashCode}_${DateTime.now().millisecondsSinceEpoch}',
            );

            return Container(
              key: uniqueKey,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      cleanUrl,
                      // 设置合理的宽度限制
                      width: MediaQuery.of(context).size.width * 0.7,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 300,
                          height: 200,
                          alignment: Alignment.center,
                          child: CircularProgressIndicator(
                            value:
                                loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        (loadingProgress.expectedTotalBytes ??
                                            1)
                                    : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 300,
                          height: 100,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('图片加载失败'),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    cleanUrl,
                    style: const TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }
}

/// 文本输入对话框组件
class _TextInputDialog extends StatefulWidget {
  final String title;
  final String hintText;
  final String initialValue;

  const _TextInputDialog({
    required this.title,
    required this.hintText,
    required this.initialValue,
  });

  @override
  _TextInputDialogState createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  late final TextEditingController _controller;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _controller,
                maxLines: 10,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('取消'),
          onPressed: () {
            if (!_isDisposed) {
              Navigator.of(context).pop();
            }
          },
        ),
        TextButton(
          child: const Text('确定'),
          onPressed: () {
            if (!_isDisposed) {
              final text = _controller.text;
              Navigator.of(context).pop(text);
            }
          },
        ),
      ],
    );
  }
}
