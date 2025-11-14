import 'dart:convert';
import 'dart:io';
import 'package:json_dynamic_widget/json_dynamic_widget.dart';
import 'package:path/path.dart' as path;

/// JSON 动态 UI 测试页面
/// 用于快速测试和预览 json_dynamic_widget 配置
class JsonDynamicTestScreen extends StatefulWidget {
  const JsonDynamicTestScreen({super.key});

  @override
  State<JsonDynamicTestScreen> createState() => _JsonDynamicTestScreenState();
}

class _JsonDynamicTestScreenState extends State<JsonDynamicTestScreen> {
  final TextEditingController _jsonController = TextEditingController();
  final JsonWidgetRegistry _registry = JsonWidgetRegistry.instance;
  String? _errorMessage;
  List<JsonFileInfo> _jsonFiles = [];
  bool _isLoadingFiles = false;

  // JSON 文件目录路径
  static const String _jsonPagesPath = 'lib/screens/pages';

  @override
  void initState() {
    super.initState();
    _loadJsonFiles();
  }

  // 从文件系统加载 JSON 文件列表
  Future<void> _loadJsonFiles() async {
    setState(() {
      _isLoadingFiles = true;
    });

    try {
      final directory = Directory(_jsonPagesPath);
      if (!await directory.exists()) {
        _showErrorSnackBar('目录不存在: $_jsonPagesPath');
        setState(() {
          _isLoadingFiles = false;
        });
        return;
      }

      final files =
          await directory
              .list()
              .where(
                (entity) =>
                    entity is File &&
                    (entity.path.endsWith('.json') ||
                        entity.path.endsWith('.yaml')),
              )
              .asyncMap((entity) async {
                final file = entity as File;
                final fileName = path.basename(file.path);
                final stats = await file.stat();
                return JsonFileInfo(
                  name: fileName,
                  path: file.path,
                  size: stats.size,
                  modified: stats.modified,
                );
              })
              .toList();

      setState(() {
        _jsonFiles = files;
        _jsonFiles.sort((a, b) => a.name.compareTo(b.name));
        _isLoadingFiles = false;
      });
    } catch (e) {
      _showErrorSnackBar('加载文件失败: $e');
      setState(() {
        _isLoadingFiles = false;
      });
    }
  }

  // 从文件加载 JSON 内容
  Future<void> _loadJsonFromFile(JsonFileInfo fileInfo) async {
    try {
      final file = File(fileInfo.path);
      final content = await file.readAsString();

      setState(() {
        _jsonController.text = content;
        _errorMessage = null;
      });
    } catch (e) {
      _showErrorSnackBar('读取文件失败: $e');
    }
  }

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  // 解析 JSON 并构建 Widget
  JsonWidgetData? _buildJsonWidget(String jsonString) {
    try {
      final dynamic jsonData = json.decode(jsonString);
      setState(() {
        _errorMessage = null;
      });
      return JsonWidgetData.fromDynamic(jsonData, registry: _registry);
    } catch (e) {
      setState(() {
        _errorMessage = '解析错误: $e';
      });
      return null;
    }
  }

  // 显示预览页面
  void _showPreviewDialog() {
    final jsonString = _jsonController.text.trim();
    if (jsonString.isEmpty) {
      _showErrorSnackBar('请输入 JSON 配置');
      return;
    }

    final widgetData = _buildJsonWidget(jsonString);
    if (widgetData == null) {
      _showErrorSnackBar(_errorMessage ?? '解析失败');
      return;
    }

    // 导航到预览页面
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => JsonDynamicPreviewScreen(
          widgetData: widgetData,
        ),
      ),
    );
  }

  // 显示文件选择对话框
  void _showTemplateDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
              constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
                  // 标题栏
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                          Icons.folder_open,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '选择 JSON 文件',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '共 ${_jsonFiles.length} 个文件',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await _loadJsonFiles();
                            _showTemplateDialog();
                          },
                          icon: const Icon(Icons.refresh),
                          tooltip: '刷新列表',
                    ),
                  ],
                ),
              ),
                  // 文件列表
                  Expanded(
                    child:
                        _isLoadingFiles
                            ? const Center(child: CircularProgressIndicator())
                            : _jsonFiles.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.folder_off,
                                    size: 64,
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    '未找到 JSON 文件',
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '目录: $_jsonPagesPath',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              itemCount: _jsonFiles.length,
                              itemBuilder: (context, index) {
                                final fileInfo = _jsonFiles[index];
                                return ListTile(
                                  leading: Icon(
                                    fileInfo.name.endsWith('.json')
                                        ? Icons.description
                                        : Icons.code,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  title: Text(fileInfo.name),
                                  subtitle: Text(
                                    '${_formatFileSize(fileInfo.size)} • ${_formatDateTime(fileInfo.modified)}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                  ),
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    _loadJsonFromFile(fileInfo);
                                  },
                                );
                              },
                            ),
              ),
              // 关闭按钮
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 格式化文件大小
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '今天 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return '昨天';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} 天前';
    } else {
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    }
  }

  // 清空编辑器
  void _clearEditor() {
    setState(() {
      _jsonController.clear();
      _errorMessage = null;
    });
  }

  // 格式化 JSON
  void _formatJson() {
    try {
      final jsonString = _jsonController.text.trim();
      if (jsonString.isEmpty) {
        _showErrorSnackBar('请输入 JSON 配置');
        return;
      }

      final dynamic jsonData = json.decode(jsonString);
      const encoder = JsonEncoder.withIndent('  ');
      final formatted = encoder.convert(jsonData);

      setState(() {
        _jsonController.text = formatted;
        _errorMessage = null;
      });
      _showSuccessSnackBar('格式化成功');
    } catch (e) {
      _showErrorSnackBar('格式化失败: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JSON 动态 UI 测试'),
        actions: [
          IconButton(
            onPressed: _showTemplateDialog,
            icon: const Icon(Icons.folder_open),
            tooltip: '加载文件',
          ),
          IconButton(
            onPressed: _formatJson,
            icon: const Icon(Icons.format_align_left),
            tooltip: '格式化',
          ),
          IconButton(
            onPressed: _clearEditor,
            icon: const Icon(Icons.clear),
            tooltip: '清空',
          ),
        ],
      ),
      body: Column(
        children: [
          // JSON 编辑器
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _errorMessage != null
                      ? Colors.red
                      : Theme.of(context).colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // 编辑器标题
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.code,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'JSON 配置编辑器',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 编辑器内容
                  Expanded(
                    child: TextField(
                      controller: _jsonController,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                      decoration: const InputDecoration(
                        hintText: '在此输入或粘贴 JSON 配置...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                      onChanged: (value) {
                        // 实时验证
                        if (value.trim().isNotEmpty) {
                          _buildJsonWidget(value);
                        }
                      },
                    ),
                  ),
                  // 错误信息
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          // 操作按钮
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _showTemplateDialog,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('加载文件'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: _showPreviewDialog,
                  icon: const Icon(Icons.visibility),
                  label: const Text('预览效果'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
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
}

/// JSON 文件信息
class JsonFileInfo {
  final String name;
  final String path;
  final int size;
  final DateTime modified;

  const JsonFileInfo({
    required this.name,
    required this.path,
    required this.size,
    required this.modified,
  });
}

/// JSON 动态 UI 预览页面
class JsonDynamicPreviewScreen extends StatefulWidget {
  final JsonWidgetData widgetData;

  const JsonDynamicPreviewScreen({
    super.key,
    required this.widgetData,
  });

  @override
  State<JsonDynamicPreviewScreen> createState() =>
      _JsonDynamicPreviewScreenState();
}

class _JsonDynamicPreviewScreenState extends State<JsonDynamicPreviewScreen> {
  Widget? _builtWidget;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _buildWidget();
  }

  void _buildWidget() {
    try {
      // 延迟构建，确保上下文准备好
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            try {
              _builtWidget = widget.widgetData.build(context: context);
              _errorMessage = null;
            } catch (e) {
              _errorMessage = '构建失败: $e';
            }
          });
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = '初始化失败: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
          tooltip: '返回',
        ),
        title: const Text('UI 预览'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            tooltip: '关闭',
          ),
        ],
      ),
      body: _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '预览失败',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : _builtWidget == null
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _builtWidget,
                  ),
                ),
    );
  }
}
