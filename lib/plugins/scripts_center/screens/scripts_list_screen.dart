import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/script_manager.dart';
import '../models/script_info.dart';
import '../widgets/script_card.dart';

/// 脚本列表界面
///
/// 展示所有脚本，支持启用/禁用切换、搜索、刷新
class ScriptsListScreen extends StatefulWidget {
  final ScriptManager scriptManager;

  const ScriptsListScreen({
    super.key,
    required this.scriptManager,
  });

  @override
  State<ScriptsListScreen> createState() => _ScriptsListScreenState();
}

class _ScriptsListScreenState extends State<ScriptsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showOnlyEnabled = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 获取筛选后的脚本列表
  List<ScriptInfo> _getFilteredScripts() {
    var scripts = widget.scriptManager.scripts;

    // 按启用状态筛选
    if (_showOnlyEnabled) {
      scripts = scripts.where((s) => s.enabled).toList();
    }

    // 按搜索关键词筛选
    if (_searchQuery.isNotEmpty) {
      scripts = widget.scriptManager.searchScripts(_searchQuery);
    }

    return scripts;
  }

  /// 刷新脚本列表
  Future<void> _refreshScripts() async {
    await widget.scriptManager.loadScripts();
  }

  /// 切换脚本启用状态
  Future<void> _toggleScript(ScriptInfo script) async {
    try {
      await widget.scriptManager.toggleScript(script.id, !script.enabled);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              script.enabled
                  ? '已启用脚本: ${script.name}'
                  : '已禁用脚本: ${script.name}',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 创建新脚本对话框
  Future<void> _showCreateScriptDialog() async {
    final nameController = TextEditingController();
    final idController = TextEditingController();
    final descController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建新脚本'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '脚本名称',
                  hintText: '例如：自动备份助手',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: idController,
                decoration: const InputDecoration(
                  labelText: '脚本ID',
                  hintText: '例如：auto_backup（仅小写字母、数字、下划线）',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: '描述',
                  hintText: '简短描述脚本功能',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty || idController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请填写脚本名称和ID')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      try {
        await widget.scriptManager.createScript(
          scriptId: idController.text.trim(),
          name: nameController.text.trim(),
          description: descController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('脚本创建成功！')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('创建失败: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.scriptManager,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('脚本中心'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          actions: [
            // 筛选按钮
            IconButton(
              icon: Icon(
                _showOnlyEnabled
                    ? Icons.filter_alt
                    : Icons.filter_alt_outlined,
              ),
              tooltip: '仅显示已启用',
              onPressed: () {
                setState(() {
                  _showOnlyEnabled = !_showOnlyEnabled;
                });
              },
            ),

            // 刷新按钮
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: '刷新',
              onPressed: _refreshScripts,
            ),
          ],
        ),
        body: Column(
          children: [
            // 搜索栏
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '搜索脚本...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
            ),

            // 脚本列表
            Expanded(
              child: Consumer<ScriptManager>(
                builder: (context, manager, child) {
                  if (manager.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final scripts = _getFilteredScripts();

                  if (scripts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.code_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? '未找到匹配的脚本'
                                : '暂无脚本\n点击右下角按钮创建新脚本',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _refreshScripts,
                    child: ListView.builder(
                      itemCount: scripts.length,
                      itemBuilder: (context, index) {
                        final script = scripts[index];
                        return ScriptCard(
                          script: script,
                          onTap: () {
                            // TODO: 打开脚本详情页
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('详情页面开发中: ${script.name}'),
                              ),
                            );
                          },
                          onToggle: (enabled) => _toggleScript(script),
                        );
                      },
                    ),
                  );
                },
              ),
            ),

            // 底部统计信息
            Consumer<ScriptManager>(
              builder: (context, manager, child) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border(
                      top: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatChip(
                        '总数',
                        manager.scriptCount.toString(),
                        Colors.blue,
                      ),
                      _buildStatChip(
                        '已启用',
                        manager.enabledScriptCount.toString(),
                        Colors.green,
                      ),
                      _buildStatChip(
                        '已禁用',
                        (manager.scriptCount - manager.enabledScriptCount)
                            .toString(),
                        Colors.grey,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),

        // FAB - 创建新脚本
        floatingActionButton: FloatingActionButton(
          onPressed: _showCreateScriptDialog,
          backgroundColor: Colors.deepPurple,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
