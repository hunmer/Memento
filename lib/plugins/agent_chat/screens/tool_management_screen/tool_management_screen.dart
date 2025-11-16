import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/tool_config.dart';
import '../../services/tool_config_manager.dart';
import 'components/plugin_section.dart';
import 'components/tool_editor_dialog.dart';

/// 工具管理界面
class ToolManagementScreen extends StatefulWidget {
  const ToolManagementScreen({super.key});

  @override
  State<ToolManagementScreen> createState() => _ToolManagementScreenState();
}

class _ToolManagementScreenState extends State<ToolManagementScreen> {
  final _searchController = TextEditingController();
  String _searchKeyword = '';
  bool _isLoading = false;

  Map<String, PluginToolSet> _allPluginTools = {};
  List<String> _filteredToolIds = [];

  @override
  void initState() {
    super.initState();
    _loadTools();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 加载工具配置
  Future<void> _loadTools() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _allPluginTools = ToolConfigManager.instance.getAllPluginTools();
      _applySearch();
    } catch (e) {
      _showError('加载工具配置失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 应用搜索过滤
  void _applySearch() {
    if (_searchKeyword.isEmpty) {
      _filteredToolIds = [];
    } else {
      _filteredToolIds = ToolConfigManager.instance.searchTools(_searchKeyword);
    }
    setState(() {});
  }

  /// 搜索框变化
  void _onSearchChanged(String value) {
    setState(() {
      _searchKeyword = value;
    });
    _applySearch();
  }

  /// 添加新工具
  Future<void> _addTool() async {
    // 获取所有插件 ID
    final pluginIds = _allPluginTools.keys.toList();

    if (pluginIds.isEmpty) {
      _showError('没有可用的插件');
      return;
    }

    // 选择插件
    final selectedPlugin = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择插件'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: pluginIds.length,
            itemBuilder: (context, index) {
              final pluginId = pluginIds[index];
              return ListTile(
                title: Text(pluginId),
                onTap: () => Navigator.pop(context, pluginId),
              );
            },
          ),
        ),
      ),
    );

    if (selectedPlugin == null) return;

    // 打开编辑对话框
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ToolEditorDialog(
        pluginId: selectedPlugin,
        isNew: true,
      ),
    );

    if (result != null) {
      try {
        final toolId = result['toolId'] as String;
        final config = result['config'] as ToolConfig;

        await ToolConfigManager.instance.addTool(
          selectedPlugin,
          toolId,
          config,
        );

        _showSuccess('工具添加成功');
        await _loadTools();
      } catch (e) {
        _showError('添加工具失败: $e');
      }
    }
  }

  /// 导入配置
  Future<void> _importConfig() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.first.path;
      if (filePath == null) return;

      // 确认导入
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认导入'),
          content: const Text('导入配置将覆盖现有配置，是否继续？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('确认'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      setState(() {
        _isLoading = true;
      });

      await ToolConfigManager.instance.importConfig(filePath);
      _showSuccess('配置导入成功');
      await _loadTools();
    } catch (e) {
      _showError('导入配置失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 导出配置
  Future<void> _exportConfig() async {
    try {
      final timestamp = DateTime.now().toIso8601String().split('T')[0];
      final fileName = 'tools_config_$timestamp.json';

      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: '导出工具配置',
        fileName: fileName,
      );

      if (outputPath == null) return;

      setState(() {
        _isLoading = true;
      });

      await ToolConfigManager.instance.exportConfig(outputPath);
      _showSuccess('配置已导出到: $outputPath');
    } catch (e) {
      _showError('导出配置失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 恢复默认配置
  Future<void> _resetToDefault() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认恢复默认'),
        content: const Text('此操作将删除所有自定义配置，恢复到默认配置。是否继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('恢复默认'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() {
        _isLoading = true;
      });

      await ToolConfigManager.instance.resetToDefault();
      _showSuccess('已恢复默认配置');
      await _loadTools();
    } catch (e) {
      _showError('恢复默认配置失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 显示错误消息
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// 显示成功消息
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// 构建插件分组列表
  List<Widget> _buildPluginSections() {
    final sections = <Widget>[];

    _allPluginTools.forEach((pluginId, toolSet) {
      // 如果有搜索关键词，只显示匹配的工具
      List<String> toolIds;
      if (_searchKeyword.isNotEmpty) {
        toolIds = toolSet.tools.keys
            .where((toolId) => _filteredToolIds.contains(toolId))
            .toList();
        if (toolIds.isEmpty) return; // 跳过没有匹配工具的插件
      } else {
        toolIds = toolSet.tools.keys.toList();
      }

      sections.add(
        PluginSection(
          pluginId: pluginId,
          toolSet: toolSet,
          visibleToolIds: toolIds,
          onRefresh: _loadTools,
        ),
      );
    });

    return sections;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('工具管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '添加工具',
            onPressed: _isLoading ? null : _addTool,
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: '导入配置',
            onPressed: _isLoading ? null : _importConfig,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 搜索栏
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: '搜索工具...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),

                // 统计信息
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildStatistics(),
                ),

                const Divider(),

                // 工具列表
                Expanded(
                  child: _allPluginTools.isEmpty
                      ? const Center(child: Text('暂无工具配置'))
                      : ListView(
                          children: _buildPluginSections(),
                        ),
                ),

                // 底部按钮
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _resetToDefault,
                          icon: const Icon(Icons.restore),
                          label: const Text('恢复默认'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _exportConfig,
                          icon: const Icon(Icons.file_upload),
                          label: const Text('导出配置'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  /// 构建统计信息卡片
  Widget _buildStatistics() {
    final stats = ToolConfigManager.instance.getStatistics();
    final totalTools = stats['total_tools'] as int;
    final enabledTools = stats['enabled_tools'] as int;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('总工具数', totalTools.toString(), Icons.build),
            _buildStatItem('已启用', enabledTools.toString(), Icons.check_circle,
                color: Colors.green),
            _buildStatItem(
                '已禁用', (totalTools - enabledTools).toString(), Icons.block,
                color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon,
      {Color? color}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
