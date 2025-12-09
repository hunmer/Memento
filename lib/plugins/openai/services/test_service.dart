import 'package:get/get.dart';
import 'dart:io';
import 'package:Memento/plugins/openai/models/ai_agent.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
// 添加本地化导入
import 'request_service.dart';
import 'package:Memento/core/services/toast_service.dart';

class TestService {
  // 用于存储最后一次输入的文本的键
  static const String _lastInputKey = 'last_test_input';

  /// 保存最后一次输入的文本
  static Future<void> saveLastInput(String input) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastInputKey, input);
      debugPrint('已保存最后一次输入的文本');
    } catch (e) {
      debugPrint('保存最后一次输入的文本失败: $e');
    }
  }

  /// 读取最后一次输入的文本
  static Future<String> getLastInput() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_lastInputKey) ?? '';
    } catch (e) {
      debugPrint('读取最后一次输入的文本失败: $e');
      return '';
    }
  }

  /// 显示长文本输入对话框，支持图片选择，自动加载上次输入的文本
  static Future<Map<String, dynamic>?> showLongTextInputDialog(
    BuildContext context, {
    String? title,
    String? hintText,
    String? initialValue,
    bool enableImagePicker = false,
    AIAgent? testAgent,
    Map<String, dynamic>? formValues,
  }) async {
    // 获取本地化实例

    // 如果没有提供初始值，则尝试加载上次输入的文本
    String loadedInitialValue = initialValue ?? await getLastInput();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false, // 防止点击外部关闭对话框导致控制器过早处置
      builder: (BuildContext dialogContext) {
        return _TextInputDialog(
          title: title ?? 'openai_testInput'.tr,
          hintText: hintText ?? 'openai_enterTestText'.tr,
          initialValue: loadedInitialValue,
          enableImagePicker: enableImagePicker,
          testAgent: testAgent,
          formValues: formValues,
        );
      },
    );

    // 如果用户输入了文本并点击了确定，保存这次输入
    if (result != null && result['text'] != null && result['text'].isNotEmpty) {
      await saveLastInput(result['text']);
    }

    return result;
  }

  /// 发送请求并获取响应
  static Future<String> processTestRequest(
    String input,
    AIAgent agent, {
    File? imageFile,
    Map<String, dynamic>? formValues,
  }) async {
    // 如果有表单值，创建一个新的agent并合并表单值
    if (formValues != null && formValues.isNotEmpty) {
      agent = agent.copyWith(
        name: formValues['name'] ?? agent.name,
        baseUrl: formValues['baseUrl'] ?? agent.baseUrl,
        model: formValues['model'] ?? agent.model,
        temperature: formValues['temperature']?.toDouble() ?? agent.temperature,
        maxLength: formValues['maxLength'] ?? agent.maxLength,
        topP: formValues['topP']?.toDouble() ?? agent.topP,
        frequencyPenalty:
            formValues['frequencyPenalty']?.toDouble() ??
            agent.frequencyPenalty,
        presencePenalty:
            formValues['presencePenalty']?.toDouble() ?? agent.presencePenalty,
        stop: formValues['stop'] ?? agent.stop,
        serviceProviderId:
            formValues['serviceProviderId'] ?? agent.serviceProviderId,
      );
    }
    // 保存这次输入
    await saveLastInput(input);
    try {
      String response;
      // 如果提供了图片文件，使用vision模型处理
      if (imageFile != null) {
        response = await RequestService.chat(
          input,
          agent,
          imageFile: imageFile,
        );
      } else if (input.toLowerCase().startsWith("/image")) {
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
${'openai_errorDetails'.tr}: ${e.toString()}

${'openai_checkItems'.tr}:
1. ${'openai_apiKeyConfig'.tr}
2. ${'openai_networkConnection'.tr}
3. ${'openai_serviceEndpoint'.tr}
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
    // 获取本地化实例

    showDialog(
      context: context,
      barrierDismissible: true,
      useRootNavigator: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('openai_testResponse'.tr),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SelectableText(response),
                if (containsImageUrl) ...[
                  const SizedBox(height: 16),
                  Text(
                    '${'openai_previewImages'.tr}:',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildImagePreview(response, dialogContext),
                ],
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('openai_close'.tr),
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

    // 获取本地化实例

    if (matches.isEmpty) {
      return Text('openai_imageLoadFailed'.tr);
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
                          child: Text('openai_imageLoadFailed'.tr),
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
  final bool enableImagePicker;
  final AIAgent? testAgent;
  final Map<String, dynamic>? formValues;

  const _TextInputDialog({
    required this.title,
    required this.hintText,
    required this.initialValue,
    this.enableImagePicker = false,
    this.testAgent,
    this.formValues,
  });

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  late final TextEditingController _controller;
  bool _isDisposed = false;
  bool _isLoading = false;
  File? _selectedImage;
  String? _testResult; // 测试结果
  bool _isTesting = false; // 是否正在测试

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

  /// 加载上次输入的文本
  Future<void> _loadLastInput() async {
    if (_isDisposed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final lastInput = await TestService.getLastInput();
      if (!_isDisposed && lastInput.isNotEmpty) {
        _controller.text = lastInput;
      }
    } catch (e) {
      debugPrint('加载上次输入失败: $e');
      if (!_isDisposed) {

        toastService.showToast('openai_lastInputLoadFailed'.tr);
      }
    } finally {
      if (!_isDisposed) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 选择图片
  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null &&
        result.files.isNotEmpty &&
        result.files.first.path != null) {
      setState(() {
        _selectedImage = File(result.files.first.path!);
      });
    }
  }

  /// 执行测试
  Future<void> _runTest() async {
    if (_isDisposed || widget.testAgent == null) return;

    final input = _controller.text.trim();
    if (input.isEmpty) {
      if (!_isDisposed) {

        toastService.showToast('openai_enterTestText'.tr);
      }
      return;
    }

    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    try {
      // 保存输入
      await TestService.saveLastInput(input);

      // 执行测试
      final response = await TestService.processTestRequest(
        input,
        widget.testAgent!,
        imageFile: _selectedImage,
        formValues: widget.formValues,
      );

      if (!_isDisposed) {
        setState(() {
          _testResult = response;
        });
      }
    } catch (e) {
      if (!_isDisposed) {
        setState(() {
          _testResult = '测试失败: $e';
        });
      }
    } finally {
      if (!_isDisposed) {
        setState(() {
          _isTesting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Builder(
        builder: (context) {

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.title),
              // 加载上次输入的按钮
              IconButton(
                icon:
                    _isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.refresh, size: 20),
                tooltip: 'openai_loadLastInput'.tr,
                onPressed: _isLoading ? null : _loadLastInput,
              ),
            ],
          );
        },
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _controller,
                maxLines: 10,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  border: const OutlineInputBorder(),
                ),
                enabled: !_isTesting, // 测试时禁用输入
              ),
              if (widget.enableImagePicker) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Builder(
                      builder: (context) {

                        return ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.image),
                          label: Text('openai_selectImage'.tr),
                        );
                      },
                    ),
                    const SizedBox(width: 8),

                    Expanded(
                      child: Builder(
                        builder: (context) {

                          return _selectedImage != null
                              ? Text(
                                '${'openai_selectedImage'.tr}: ${_selectedImage!.path.split('/').last}',
                                overflow: TextOverflow.ellipsis,
                              )
                              : Text('openai_noImageSelected'.tr);
                        },
                      ),
                    ),

                    const SizedBox(width: 8),
                    Builder(
                      builder: (context) {

                        return TextButton(
                          onPressed: () {
                            setState(() {
                              _testResult = null;
                            });
                          },
                          child: Text('openai_clearOutput'.tr),
                        );
                      },
                    ),
                  ],
                ),
                if (_selectedImage != null) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _selectedImage!,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ],
              // 显示测试结果
              if (_testResult != null) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {

                    return Text(
                      'openai_testResponse'.tr,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      _testResult!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ],
              // 显示加载指示器
              if (_isTesting) ...[
                const SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 8),
                      Text('openai_testing'.tr),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: <Widget>[
        Builder(
          builder: (context) {

            return TextButton(
              onPressed:
                  _isTesting
                      ? null
                      : () {
                        if (!_isDisposed) {
                          Navigator.of(context).pop();
                        }
                      },
              child: Text('openai_close'.tr),
            );
          },
        ),
        // 如果提供了测试agent，显示测试按钮；否则显示保存按钮
        if (widget.testAgent != null)
          Builder(
            builder: (context) {

              return ElevatedButton(
                onPressed: _isTesting ? null : _runTest,
                child: Text('openai_testAgent'.tr),
              );
            },
          )
        else
          Builder(
            builder: (context) {

              return TextButton(
                child: Text('openai_save'.tr),
                onPressed: () {
                  if (!_isDisposed) {
                    final text = _controller.text;
                    Navigator.of(
                      context,
                    ).pop({'text': text, 'image': _selectedImage});
                  }
                },
              );
            },
          ),
      ],
    );
  }
}
