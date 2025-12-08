import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:openai_dart/openai_dart.dart';
import 'package:Memento/plugins/openai/models/ai_agent.dart';
import 'request_service.dart';
import 'dart:developer' as developer;

/// 文件处理服务
///
/// 支持两种模式：
/// 1. Assistants API 模式（OpenAI 官方服务）
/// 2. 文件内容读取模式（其他服务商或降级方案）
class FileProcessingService {
  /// 上传文件到 OpenAI
  static Future<String?> _uploadFileToOpenAI(
    String apiKey,
    String baseUrl,
    String filePath,
    String purpose,
  ) async {
    final file = File(filePath);
    if (!await file.exists()) return null;

    try {
      final uri = Uri.parse('$baseUrl/files');
      final request =
          http.MultipartRequest('POST', uri)
            ..headers['Authorization'] = 'Bearer $apiKey'
            ..files.add(await http.MultipartFile.fromPath('file', filePath))
            ..fields['purpose'] = purpose;

      final response = await request.send();
      if (response.statusCode == 200) {
        final body = await response.stream.bytesToString();
        final json = jsonDecode(body);
        return json['id'] as String?;
      }
      developer.log(
        '文件上传失败，状态码: ${response.statusCode}',
        name: 'FileProcessingService',
      );
      return null;
    } catch (e) {
      developer.log('文件上传异常: $e', name: 'FileProcessingService', error: e);
      return null;
    }
  }

  /// 删除 OpenAI 文件
  static Future<void> _deleteFileFromOpenAI(
    String apiKey,
    String baseUrl,
    String fileId,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/files/$fileId');
      final response = await http.delete(
        uri,
        headers: {'Authorization': 'Bearer $apiKey'},
      );
      if (response.statusCode == 200) {
        developer.log('文件已删除: $fileId', name: 'FileProcessingService');
      }
    } catch (e) {
      developer.log('删除文件失败: $e', name: 'FileProcessingService');
    }
  }

  /// 判断是否支持 Assistants API
  static bool supportsAssistantsAPI(AIAgent agent) {
    // 检查 baseUrl 是否包含 openai.com
    final isOpenAI =
        agent.baseUrl.contains('openai.com') ||
        agent.baseUrl.contains('api.openai.com');

    // 也可以通过 serviceProviderId 判断
    final isOpenAIProvider = agent.serviceProviderId.toLowerCase() == 'openai';

    return isOpenAI || isOpenAIProvider;
  }

  /// 使用 Assistants API 处理文件
  static Future<String> processWithAssistantsAPI({
    required AIAgent agent,
    required String prompt,
    required List<File> files,
  }) async {
    developer.log('使用 Assistants API 处理文件', name: 'FileProcessingService');

    try {
      // 获取 API Key 和 BaseUrl
      final apiKey =
          agent.headers['Authorization']?.replaceAll('Bearer ', '') ??
          agent.headers['api-key'] ??
          '';
      final baseUrl = agent.baseUrl;

      // 获取 OpenAI 客户端
      final client = RequestService.getClient(agent);

      // 1. 上传文件
      final fileIds = <String>[];
      for (final file in files) {
        if (!await file.exists()) {
          developer.log('文件不存在: ${file.path}', name: 'FileProcessingService');
          continue;
        }

        final fileName = file.path.split(Platform.pathSeparator).last;
        developer.log('上传文件: $fileName', name: 'FileProcessingService');

        final fileId = await _uploadFileToOpenAI(
          apiKey,
          baseUrl,
          file.path,
          'assistants',
        );

        if (fileId != null) {
          fileIds.add(fileId);
          developer.log('文件已上传，ID: $fileId', name: 'FileProcessingService');
        }
      }

      if (fileIds.isEmpty) {
        throw Exception('没有成功上传任何文件');
      }

      // 2. 创建 vector store
      developer.log('创建 vector store', name: 'FileProcessingService');
      final vectorStore = await client.createVectorStore(
        request: CreateVectorStoreRequest(),
      );
      final vectorStoreId = vectorStore.id;
      developer.log(
        'Vector store 已创建: $vectorStoreId',
        name: 'FileProcessingService',
      );

      // 添加文件到 vector store
      for (final fileId in fileIds) {
        await client.createVectorStoreFile(
          vectorStoreId: vectorStoreId,
          request: CreateVectorStoreFileRequest(fileId: fileId),
        );
      }
      developer.log('文件已添加到 vector store', name: 'FileProcessingService');

      // 3. 创建 assistant
      developer.log('创建 assistant', name: 'FileProcessingService');
      final assistant = await client.createAssistant(
        request: CreateAssistantRequest(
          model: AssistantModel.modelId(agent.model),
          instructions: agent.systemPrompt,
          tools: [AssistantTools.fileSearch(type: 'file_search')],
          toolResources: ToolResources(
            fileSearch: ToolResourcesFileSearch(
              vectorStoreIds: [vectorStoreId],
            ),
          ),
        ),
      );
      final assistantId = assistant.id;
      developer.log(
        'Assistant 已创建: $assistantId',
        name: 'FileProcessingService',
      );

      // 4. 创建 thread
      developer.log('创建 thread', name: 'FileProcessingService');
      final thread = await client.createThread(request: CreateThreadRequest());
      final threadId = thread.id;

      // 5. 添加消息
      await client.createThreadMessage(
        threadId: threadId,
        request: CreateMessageRequest(
          role: MessageRole.user,
          content: CreateMessageRequestContent.text(prompt),
        ),
      );

      // 6. 创建 run
      developer.log('创建 run', name: 'FileProcessingService');
      final run = await client.createThreadRun(
        threadId: threadId,
        request: CreateRunRequest(assistantId: assistantId),
      );

      // 7. 等待完成
      RunObject runStatus = run;
      while (runStatus.status == RunStatus.queued ||
          runStatus.status == RunStatus.inProgress) {
        await Future.delayed(const Duration(seconds: 2));
        runStatus = await client.getThreadRun(
          threadId: threadId,
          runId: run.id,
        );
        developer.log(
          'Run 状态: ${runStatus.status}',
          name: 'FileProcessingService',
        );
      }

      if (runStatus.status != RunStatus.completed) {
        throw Exception('Run 失败，状态: ${runStatus.status}');
      }

      // 8. 获取响应
      final messages = await client.listThreadMessages(threadId: threadId);

      if (messages.data.isEmpty) {
        throw Exception('未收到响应消息');
      }

      developer.log(
        '收到 ${messages.data.length} 条消息',
        name: 'FileProcessingService',
      );

      // 提取所有助手消息的文本内容（合并所有文本片段）
      final textParts = <String>[];

      for (final message in messages.data) {
        developer.log(
          '消息角色: ${message.role}, 内容数量: ${message.content.length}',
          name: 'FileProcessingService',
        );

        if (message.role == MessageRole.assistant) {
          for (final content in message.content) {
            developer.log(
              '内容类型: ${content.runtimeType}',
              name: 'FileProcessingService',
            );

            // 尝试多种方式提取文本
            String? text;

            // 方式1: 如果是 MessageContent.text 类型
            if (content.mapOrNull(
                  text: (textContent) {
                    text = textContent.text.value;
                    return true;
                  },
                ) ==
                true) {
              // 已通过 mapOrNull 提取
            }
            // 方式2: 直接类型检查（降级方案）
            else {
              try {
                final dynamic dynContent = content;
                if (dynContent.text != null && dynContent.text.value != null) {
                  text = dynContent.text.value as String;
                }
              } catch (e) {
                developer.log('提取文本失败: $e', name: 'FileProcessingService');
              }
            }

            if (text != null && text!.isNotEmpty) {
              textParts.add(text!);
              developer.log(
                '提取文本: ${text?.substring(0, text!.length > 50 ? 50 : text!.length)}...',
                name: 'FileProcessingService',
              );
            }
          }
        }
      }

      if (textParts.isEmpty) {
        developer.log('警告：未找到助手响应文本，尝试获取第一条消息', name: 'FileProcessingService');

        // 降级方案：尝试获取第一条消息的所有内容
        if (messages.data.isNotEmpty) {
          final firstMessage = messages.data.first;
          for (final content in firstMessage.content) {
            String? text;

            // 使用 mapOrNull 提取文本
            content.mapOrNull(
              text: (textContent) {
                text = textContent.text.value;
                return true;
              },
            );

            if (text != null && text!.isNotEmpty) {
              textParts.add(text!);
            }
          }
        }
      }

      if (textParts.isEmpty) {
        throw Exception('未找到任何文本响应');
      }

      final textContent = textParts.join('\n\n');
      developer.log(
        '最终文本长度: ${textContent.length}',
        name: 'FileProcessingService',
      );

      // 9. 清理资源（可选）
      try {
        await client.deleteAssistant(assistantId: assistantId);
        await client.deleteVectorStore(vectorStoreId: vectorStoreId);
        for (final fileId in fileIds) {
          await _deleteFileFromOpenAI(apiKey, baseUrl, fileId);
        }
        developer.log('已清理资源', name: 'FileProcessingService');
      } catch (e) {
        developer.log('清理资源失败: $e', name: 'FileProcessingService');
      }

      return textContent;
    } catch (e) {
      developer.log(
        'Assistants API 处理失败: $e',
        name: 'FileProcessingService',
        error: e,
      );
      rethrow;
    }
  }

  /// 读取文件内容并添加到提示词（降级方案）
  static Future<String> processWithContentReading({
    required String prompt,
    required List<File> files,
  }) async {
    developer.log('使用文件内容读取模式处理文件', name: 'FileProcessingService');

    final buffer = StringBuffer();
    buffer.writeln(prompt);
    buffer.writeln();
    buffer.writeln('--- 附件内容 ---');
    buffer.writeln();

    for (final file in files) {
      final fileName = file.path.split(Platform.pathSeparator).last;

      if (!await file.exists()) {
        buffer.writeln('[$fileName]: 文件不存在');
        continue;
      }

      try {
        final extension = fileName.split('.').last.toLowerCase();

        // 判断文件类型并读取内容
        if (_isTextFile(extension)) {
          // 文本文件直接读取
          final content = await file.readAsString();
          buffer.writeln('=== $fileName ===');
          buffer.writeln(content);
          buffer.writeln();
        } else if (_isImageFile(extension)) {
          // 图片文件转 base64（仅提供路径信息）
          buffer.writeln('=== $fileName ===');
          buffer.writeln('[图片文件，路径: ${file.path}]');
          buffer.writeln('注意：此模式不支持直接处理图片，请使用支持 vision 的服务商');
          buffer.writeln();
        } else {
          // 其他二进制文件
          final fileSize = await file.length();
          buffer.writeln('=== $fileName ===');
          buffer.writeln('[二进制文件，大小: ${_formatFileSize(fileSize)}]');
          buffer.writeln('注意：此模式不支持处理二进制文件');
          buffer.writeln();
        }
      } catch (e) {
        buffer.writeln('[$fileName]: 读取失败 - $e');
      }
    }

    return buffer.toString();
  }

  /// 判断是否为文本文件
  static bool _isTextFile(String extension) {
    return [
      'txt',
      'md',
      'json',
      'xml',
      'html',
      'css',
      'js',
      'ts',
      'dart',
      'java',
      'py',
      'cpp',
      'c',
      'h',
      'cs',
      'go',
      'yaml',
      'yml',
      'toml',
      'ini',
      'conf',
      'log',
      'csv',
    ].contains(extension);
  }

  /// 判断是否为图片文件
  static bool _isImageFile(String extension) {
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }

  /// 格式化文件大小
  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
