import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/widgets/quill_viewer/index.dart';
import '../models/analysis_preset.dart';
import '../models/ai_agent.dart';
import '../models/execution_history.dart';
import '../controllers/analysis_preset_controller.dart';
import '../controllers/execution_history_controller.dart';
import '../l10n/openai_localizations.dart';
import '../openai_plugin.dart';
import '../services/request_service.dart';
import '../services/file_processing_service.dart';
import '../widgets/agent_list_drawer.dart';
import '../widgets/plugin_method_selection_dialog.dart';
import '../controllers/prompt_replacement_controller.dart';

/// 预设运行页面
///
/// 用于运行分析预设并查看执行历史
class PresetRunScreen extends StatefulWidget {
  final AnalysisPreset preset;

  const PresetRunScreen({super.key, required this.preset});

  @override
  State<PresetRunScreen> createState() => _PresetRunScreenState();
}

class _PresetRunScreenState extends State<PresetRunScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ExecutionHistoryController _historyController;
  late AnalysisPresetController _presetController;
  final PromptReplacementController _promptReplacementController =
      PromptReplacementController();

  // 表单相关
  final TextEditingController _promptController = TextEditingController();
  AIAgent? _selectedAgent;
  final List<File> _selectedImages = [];
  bool _isLoading = false;
  String _responseMessage = '';

  // 当前预设
  late AnalysisPreset _currentPreset;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _historyController = ExecutionHistoryController();
    _presetController = AnalysisPresetController();
    _currentPreset = widget.preset;

    // 初始化表单
    _promptController.text = _currentPreset.prompt;

    // 加载智能体和执行历史
    _loadAgent();
    _historyController.loadHistories(_currentPreset.id);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  // 加载智能体
  Future<void> _loadAgent() async {
    if (_currentPreset.agentId != null) {
      try {
        final plugin =
            PluginManager.instance.getPlugin('openai') as OpenAIPlugin;
        final agentController = plugin.controller;
        final agent = await agentController.getAgent(_currentPreset.agentId!);
        if (agent != null && mounted) {
          setState(() {
            _selectedAgent = agent;
          });
        }
      } catch (e) {
        debugPrint('加载智能体失败: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = OpenAILocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentPreset.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _historyController.loadHistories(_currentPreset.id);
            },
            tooltip: '刷新',
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab标签
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: '运行', icon: Icon(Icons.play_arrow)),
              Tab(text: '执行历史', icon: Icon(Icons.history)),
            ],
          ),

          // Tab内容
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 运行Tab
                _buildRunTab(localizations),

                // 执行历史Tab
                _buildHistoryTab(localizations),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建运行Tab
  Widget _buildRunTab(OpenAILocalizations localizations) {
    return Column(
      children: [
        // 表单部分（上）
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 智能体选择器
                _buildAgentSelector(localizations),
                const SizedBox(height: 16),

                // 提示词输入
                TextField(
                  controller: _promptController,
                  decoration: InputDecoration(
                    labelText: localizations.prompt,
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 6,
                  minLines: 3,
                ),

                const SizedBox(height: 16),

                // 图片选择按钮
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.image),
                      label: const Text('添加图片'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _pickFiles,
                      icon: const Icon(Icons.attach_file),
                      label: const Text('添加文件'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final result =
                            await showDialog<Map<String, String>>(
                          context: context,
                          builder: (context) =>
                              const PluginMethodSelectionDialog(),
                        );

                        if (result != null && mounted) {
                          setState(() {
                            final currentText = _promptController.text;
                            final jsonString = result['jsonString'] ?? '';
                            final newText = currentText.isEmpty
                                ? jsonString
                                : '$currentText\n$jsonString';
                            _promptController.text = newText;
                          });
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: Text(localizations.addAnalysisMethod),
                    ),
                  ],
                ),

                // 显示已选择的图片
                if (_selectedImages.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildSelectedImages(),
                ],

                const SizedBox(height: 16),

                // 运行按钮
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _runPreset,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send),
                    label: Text(_isLoading ? '运行中...' : '运行'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const Divider(height: 1),

        // 输出部分（下）
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.blue.shade50,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.agentResponse,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: _responseMessage.isEmpty
                        ? Center(
                            child: Text(
                              '暂无输出\n点击上方"运行"按钮开始',
                              style: TextStyle(color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : QuillViewer(
                            data: _responseMessage,
                            selectable: true,
                          ),
                  ),
                ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: LinearProgressIndicator(),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 构建智能体选择器
  Widget _buildAgentSelector(OpenAILocalizations localizations) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (_selectedAgent != null) ...[
            _buildAgentIcon(_selectedAgent!),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedAgent!.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedAgent!.description,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ] else
            Expanded(
              child: Text(
                localizations.noAgentSelected,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _openAgentSelector,
            tooltip: localizations.selectAgentTooltip,
          ),
        ],
      ),
    );
  }

  // 构建智能体图标（复用之前的代码）
  Widget _buildAgentIcon(AIAgent agent) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getColorForServiceProvider(agent.serviceProviderId),
      ),
      child: const Icon(Icons.smart_toy, size: 24, color: Colors.white),
    );
  }

  Color _getColorForServiceProvider(String providerId) {
    switch (providerId) {
      case 'openai':
        return Colors.green;
      case 'azure':
        return Colors.blue;
      case 'ollama':
        return Colors.orange;
      case 'deepseek':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  /// 打开智能体选择器
  void _openAgentSelector() {
    OpenAILocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AgentListDrawer(
        selectedAgents: _selectedAgent != null
            ? [
                {'id': _selectedAgent!.id, 'name': _selectedAgent!.name},
              ]
            : const [],
        onAgentSelected: (selectedAgents) async {
          if (selectedAgents.isNotEmpty) {
            try {
              final plugin =
                  PluginManager.instance.getPlugin('openai') as OpenAIPlugin;
              final agentController = plugin.controller;
              final selectedAgent =
                  await agentController.getAgent(selectedAgents.first['id']!);
              if (selectedAgent != null && mounted) {
                setState(() {
                  _selectedAgent = selectedAgent;
                });

                // 更新预设的智能体ID
                _currentPreset = _currentPreset.copyWith(
                  agentId: selectedAgent.id,
                );
                await _presetController.savePreset(_currentPreset);
              }
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('加载智能体失败: $e')),
              );
            }
          }
        },
        allowMultipleSelection: false,
      ),
    );
  }

  /// 选择图片
  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(
          result.files
              .where((file) => file.path != null)
              .map((file) => File(file.path!)),
        );
      });
    }
  }

  /// 选择文件（任意类型）
  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(
          result.files
              .where((file) => file.path != null)
              .map((file) => File(file.path!)),
        );
      });
    }
  }

  /// 显示已选择的图片/文件
  Widget _buildSelectedImages() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '已选择 ${_selectedImages.length} 个文件：',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _selectedImages.asMap().entries.map((entry) {
            final index = entry.key;
            final file = entry.value;
            final isImage = _isImageFile(file);

            return Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: isImage
                        ? Image.file(
                            file,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _getFileIcon(file),
                                size: 32,
                                color: Colors.grey[700],
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  _getFileName(file),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[700],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      padding: EdgeInsets.zero,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedImages.removeAt(index);
                      });
                    },
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 判断文件是否为图片
  bool _isImageFile(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }

  /// 获取文件图标
  IconData _getFileIcon(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'txt':
        return Icons.text_snippet;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  /// 获取文件名
  String _getFileName(File file) {
    return file.path.split('/').last.split('\\').last;
  }

  /// 运行预设
  Future<void> _runPreset() async {
    final localizations = OpenAILocalizations.of(context);

    // 验证输入
    if (_selectedAgent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.noAgentSelected)),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _responseMessage = '';
    });

    // 创建执行历史记录
    final startTime = DateTime.now();
    final history = ExecutionHistory(
      presetId: _currentPreset.id,
      agentId: _selectedAgent!.id,
      prompt: _promptController.text,
      imagePaths: _selectedImages.map((img) => img.path).toList(),
      status: 'running',
    );

    await _historyController.addHistory(history);

    try {
      // 处理提示词替换
      final processedReplacements =
          await _promptReplacementController.preprocessPromptReplacements(
        _promptController.text,
      );

      final processedPrompt =
          PromptReplacementController.applyProcessedReplacements(
        _promptController.text,
        processedReplacements,
      );

      // 判断文件处理模式
      if (_selectedImages.isEmpty) {
        // 模式1: 无文件，使用普通流式响应
        await _runWithoutFiles(
          processedPrompt,
          history,
          startTime,
        );
      } else {
        // 分析文件类型
        final imageFiles = <File>[];
        final otherFiles = <File>[];

        for (final file in _selectedImages) {
          if (_isImageFile(file)) {
            imageFiles.add(file);
          } else {
            otherFiles.add(file);
          }
        }

        if (otherFiles.isEmpty && imageFiles.isNotEmpty) {
          // 模式2: 只有图片文件，使用 vision 模式
          await _runWithVision(
            processedPrompt,
            imageFiles,
            history,
            startTime,
          );
        } else if (FileProcessingService.supportsAssistantsAPI(_selectedAgent!)) {
          // 模式3: 包含非图片文件且支持 Assistants API
          await _runWithAssistantsAPI(
            processedPrompt,
            _selectedImages,
            history,
            startTime,
          );
        } else {
          // 模式4: 包含非图片文件但不支持 Assistants API，使用文件内容读取
          await _runWithFileContent(
            processedPrompt,
            _selectedImages,
            history,
            startTime,
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _responseMessage += "\nERROR: $e";
        _isLoading = false;
      });

      // 更新历史记录为失败
      _historyController.updateHistory(
        history.copyWith(
          status: 'error',
          errorMessage: e.toString(),
          response: _responseMessage,
          durationMs: DateTime.now().difference(startTime).inMilliseconds,
        ),
      );
    }
  }

  /// 构建执行历史Tab
  Widget _buildHistoryTab(OpenAILocalizations localizations) {
    return AnimatedBuilder(
      animation: _historyController,
      builder: (context, child) {
        if (_historyController.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_historyController.histories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  '暂无执行历史',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  '在"运行"标签页中执行预设后将显示历史记录',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _historyController.histories.length,
          itemBuilder: (context, index) {
            final history = _historyController.histories[index];
            return _buildHistoryCard(history);
          },
        );
      },
    );
  }

  /// 构建历史记录卡片
  Widget _buildHistoryCard(ExecutionHistory history) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    Color statusColor;
    IconData statusIcon;

    switch (history.status) {
      case 'success':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'error':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(statusIcon, color: statusColor),
        title: Text(
          dateFormat.format(history.createdAt),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            if (history.durationMs != null)
              Text('耗时: ${history.durationMs}ms'),
            if (history.imagePaths.isNotEmpty) ...[
              const SizedBox(width: 12),
              Icon(Icons.image, size: 16, color: Colors.grey[600]),
              Text(' ${history.imagePaths.length}'),
            ],
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 输入
                Text(
                  '输入:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(history.prompt),
                ),

                // 附件（如果有）
                if (history.imagePaths.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    '附件 (${history.imagePaths.length}):',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: history.imagePaths.map((filePath) {
                      final file = File(filePath);
                      final isImage = _isImageFile(file);
                      return Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[200],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: isImage
                              ? Image.file(
                                  file,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.broken_image,
                                            size: 24, color: Colors.grey[600]),
                                        Text(
                                          '无法加载',
                                          style: TextStyle(
                                            fontSize: 8,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _getFileIcon(file),
                                      size: 24,
                                      color: Colors.grey[700],
                                    ),
                                    const SizedBox(height: 2),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 2),
                                      child: Text(
                                        _getFileName(file),
                                        style: TextStyle(
                                          fontSize: 8,
                                          color: Colors.grey[700],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 16),

                // 输出
                Text(
                  '输出:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: history.response.isEmpty
                      ? Text(
                          history.errorMessage ?? '无响应',
                          style: TextStyle(color: Colors.grey[600]),
                        )
                      : QuillViewer(data: history.response, selectable: true),
                ),

                // 删除按钮
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _deleteHistory(history.id),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text(
                      '删除',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 模式1: 无文件流式响应
  Future<void> _runWithoutFiles(
    String prompt,
    ExecutionHistory history,
    DateTime startTime,
  ) async {
    String raw = '';

    await RequestService.streamResponse(
      agent: _selectedAgent!,
      prompt: prompt,
      onToken: (token) {
        if (!mounted) return;
        setState(() {
          raw += token;
          _responseMessage = RequestService.processThinkingContent(raw);
        });
      },
      onError: (error) => _handleError(error, history, startTime),
      onComplete: () => _handleComplete(history, startTime),
      replacePrompt: false, // 已经处理过替换
    );
  }

  /// 模式2: Vision 模式（仅图片）
  Future<void> _runWithVision(
    String prompt,
    List<File> imageFiles,
    ExecutionHistory history,
    DateTime startTime,
  ) async {
    String raw = '';

    // 只使用第一张图片（当前 RequestService 限制）
    await RequestService.streamResponse(
      agent: _selectedAgent!,
      prompt: prompt,
      vision: true,
      filePath: imageFiles.first.path,
      onToken: (token) {
        if (!mounted) return;
        setState(() {
          raw += token;
          _responseMessage = RequestService.processThinkingContent(raw);
        });
      },
      onError: (error) => _handleError(error, history, startTime),
      onComplete: () => _handleComplete(history, startTime),
      replacePrompt: false,
    );

    // 如果有多张图片，显示警告
    if (imageFiles.length > 1 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('注意：当前仅使用了第一张图片，其他 ${imageFiles.length - 1} 张已忽略'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  /// 模式3: Assistants API 模式
  Future<void> _runWithAssistantsAPI(
    String prompt,
    List<File> files,
    ExecutionHistory history,
    DateTime startTime,
  ) async {
    setState(() {
      _responseMessage = '正在使用 Assistants API 处理文件...\n';
    });

    try {
      final response = await FileProcessingService.processWithAssistantsAPI(
        agent: _selectedAgent!,
        prompt: prompt,
        files: files,
      );

      if (!mounted) return;
      setState(() {
        _responseMessage = response;
        _isLoading = false;
      });

      // 更新历史记录为成功
      _historyController.updateHistory(
        history.copyWith(
          status: 'success',
          response: response,
          durationMs: DateTime.now().difference(startTime).inMilliseconds,
        ),
      );
    } catch (e) {
      _handleError('Assistants API 错误: $e', history, startTime);
    }
  }

  /// 模式4: 文件内容读取模式（降级方案）
  Future<void> _runWithFileContent(
    String prompt,
    List<File> files,
    ExecutionHistory history,
    DateTime startTime,
  ) async {
    setState(() {
      _responseMessage = '正在读取文件内容...\n';
    });

    try {
      // 读取文件内容并合并到提示词
      final enhancedPrompt = await FileProcessingService.processWithContentReading(
        prompt: prompt,
        files: files,
      );

      setState(() {
        _responseMessage = '文件内容已加载，开始处理...\n';
      });

      // 使用普通流式响应
      String raw = '';
      await RequestService.streamResponse(
        agent: _selectedAgent!,
        prompt: enhancedPrompt,
        onToken: (token) {
          if (!mounted) return;
          setState(() {
            raw += token;
            _responseMessage = RequestService.processThinkingContent(raw);
          });
        },
        onError: (error) => _handleError(error, history, startTime),
        onComplete: () => _handleComplete(history, startTime),
        replacePrompt: false,
      );

      // 显示提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('注意：当前服务商不支持 Assistants API，已使用文件内容读取模式'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      _handleError('文件内容读取错误: $e', history, startTime);
    }
  }

  /// 处理错误
  void _handleError(String error, ExecutionHistory history, DateTime startTime) {
    if (!mounted) return;
    setState(() {
      _responseMessage += "\nERROR: $error";
      _isLoading = false;
    });

    _historyController.updateHistory(
      history.copyWith(
        status: 'error',
        errorMessage: error,
        response: _responseMessage,
        durationMs: DateTime.now().difference(startTime).inMilliseconds,
      ),
    );
  }

  /// 处理完成
  void _handleComplete(ExecutionHistory history, DateTime startTime) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    _historyController.updateHistory(
      history.copyWith(
        status: 'success',
        response: _responseMessage,
        durationMs: DateTime.now().difference(startTime).inMilliseconds,
      ),
    );
  }

  /// 删除历史记录
  Future<void> _deleteHistory(String historyId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条执行历史吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _historyController.deleteHistory(historyId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已删除历史记录')),
        );
      }
    }
  }
}
