import 'dart:io';
import 'package:flutter/material.dart';
import 'package:Memento/core/services/log_service.dart';

/// 日志查看界面
class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  final LogService _logService = LogService.instance;
  bool _isEnabled = false;
  String _selectedFileContent = '';
  String _currentLogText = '';
  List<File> _logFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _isEnabled = _logService.isEnabled;
    _currentLogText = _formatSessionLogs();
    _loadLogFiles();

    // 监听日志流，实时更新
    _logService.logStream.listen((_) {
      if (mounted) {
        setState(() {
          _currentLogText = _formatSessionLogs();
        });
      }
    });
  }

  Future<void> _loadLogFiles() async {
    setState(() => _isLoading = true);
    try {
      final files = await _logService.getLogFiles();
      if (mounted) {
        setState(() {
          _logFiles = files;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载日志文件失败: $e')),
        );
      }
    }
  }

  String _formatSessionLogs() {
    if (_logService.currentSessionLogs.isEmpty) {
      return '暂无日志记录';
    }
    return _logService.currentSessionLogs.join('\n');
  }

  Future<void> _toggleEnabled(bool value) async {
    try {
      await _logService.setEnabled(value);
      setState(() {
        _isEnabled = value;
        _currentLogText = _formatSessionLogs();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(value ? '日志已启用' : '日志已禁用')),
        );
      }
      // 重新加载日志文件列表
      await _loadLogFiles();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    }
  }

  Future<void> _loadLogFile(File file) async {
    try {
      final content = await _logService.readLogFile(file);
      setState(() {
        _selectedFileContent = content;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('读取日志文件失败: $e')),
        );
      }
    }
  }

  Future<void> _deleteAllLogs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除所有日志文件吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _logService.deleteAllLogs();
        setState(() {
          _selectedFileContent = '';
          _currentLogText = _formatSessionLogs();
        });
        await _loadLogFiles();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('所有日志已删除')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败: $e')),
          );
        }
      }
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedFileContent = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('日志系统'),
        actions: [
          if (_logFiles.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '删除所有日志',
              onPressed: _deleteAllLogs,
            ),
        ],
      ),
      body: Column(
        children: [
          // 设置区域
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surface,
            child: Row(
              children: [
                const Icon(Icons.storage, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('启用日志记录', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        '每次启动应用创建新日志文件，最多保存10个文件',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isEnabled,
                  onChanged: _toggleEnabled,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 内容区域
          Expanded(
            child: Row(
              children: [
                // 左侧：日志文件列表
                SizedBox(
                  width: 200,
                  child: _buildFileList(),
                ),

                const VerticalDivider(width: 1),

                // 右侧：日志内容
                Expanded(
                  child: _buildLogContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 当前会话日志
        ListTile(
          leading: const Icon(Icons.live_help, size: 20),
          title: const Text('当前会话', style: TextStyle(fontSize: 13)),
          selected: _selectedFileContent.isEmpty,
          selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
          onTap: _clearSelection,
          dense: true,
        ),
        const Divider(height: 1),

        // 历史日志文件列表
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _logFiles.isEmpty
                  ? const Center(child: Text('暂无历史日志'))
                  : ListView.builder(
                      itemCount: _logFiles.length,
                      itemBuilder: (context, index) {
                        final file = _logFiles[index];
                        final fileName = file.path.split(Platform.pathSeparator).last;
                        final isSelected = _selectedFileContent.isNotEmpty &&
                            file.path == _logFiles.firstWhere(
                              (f) => _selectedFileContent.contains(fileName),
                              orElse: () => File(''),
                            ).path;

                        return ListTile(
                          leading: const Icon(Icons.insert_drive_file, size: 18),
                          title: Text(
                            fileName,
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          selected: isSelected,
                          selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                          onTap: () => _loadLogFile(file),
                          dense: true,
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildLogContent() {
    final content = _selectedFileContent.isEmpty ? _currentLogText : _selectedFileContent;

    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: SelectableText(
          content.isEmpty ? '暂无日志内容' : content,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
