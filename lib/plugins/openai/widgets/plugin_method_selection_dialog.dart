import 'dart:convert';
import 'package:Memento/plugins/openai/l10n/openai_localizations.dart';
import 'package:flutter/material.dart';
import '../models/plugin_analysis_method.dart';

class PluginMethodSelectionDialog extends StatefulWidget {
  const PluginMethodSelectionDialog({super.key});

  @override
  State<PluginMethodSelectionDialog> createState() =>
      _PluginMethodSelectionDialogState();
}

class _PluginMethodSelectionDialogState
    extends State<PluginMethodSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedPluginId;
  String _searchQuery = '';

  // 获取所有插件ID列表
  List<String> get _allPluginIds {
    final pluginIds = PluginAnalysisMethod.predefinedMethods
        .map((m) => m.pluginId)
        .whereType<String>()
        .toSet()
        .toList();
    pluginIds.sort();
    return pluginIds;
  }

  // 插件显示名称映射
  Map<String, String> get _pluginDisplayNames => {
        'system': '系统',
        'activity': '活动',
        'bill': '账单',
        'calendar': '日历',
        'calendar_album': '日记相册',
        'chat': '聊天',
        'checkin': '签到',
        'contact': '联系人',
        'database': '数据库',
        'day': '纪念日',
        'diary': '日记',
        'goods': '物品',
        'habits': '习惯',
        'nodes': '节点',
        'notes': '笔记',
        'store': '商店',
        'timer': '计时器',
        'todo': '任务',
        'tracker': '目标',
        'ui': '界面',
      };

  // 过滤方法列表
  List<PluginAnalysisMethod> get _filteredMethods {
    var methods = PluginAnalysisMethod.predefinedMethods;

    // 按插件ID过滤
    if (_selectedPluginId != null) {
      methods = methods.where((m) => m.pluginId == _selectedPluginId).toList();
    }

    // 按搜索关键词过滤
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      methods = methods.where((m) {
        return m.name.toLowerCase().contains(query) ||
            m.title.toLowerCase().contains(query);
      }).toList();
    }

    return methods;
  }

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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                const Icon(Icons.category),
                const SizedBox(width: 8),
                Text(
                  OpenAILocalizations.of(context).selectAnalysisMethod,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                Text(
                  '共 ${_filteredMethods.length} 个方法',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const Divider(),

            // 搜索框
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索方法...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 插件过滤按钮
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // "全部" 按钮
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('全部'),
                      selected: _selectedPluginId == null,
                      onSelected: (selected) {
                        setState(() {
                          _selectedPluginId = null;
                        });
                      },
                    ),
                  ),
                  // 各插件按钮
                  for (final pluginId in _allPluginIds)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(_pluginDisplayNames[pluginId] ?? pluginId),
                        selected: _selectedPluginId == pluginId,
                        onSelected: (selected) {
                          setState(() {
                            _selectedPluginId = selected ? pluginId : null;
                          });
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 方法列表
            Expanded(
              child: _filteredMethods.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '没有找到匹配的方法',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey,
                                ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredMethods.length,
                      itemBuilder: (context, index) {
                        final method = _filteredMethods[index];
                        return ListTile(
                          leading: const Icon(Icons.analytics_outlined),
                          title: Text(method.name),
                          subtitle: Text(method.title),
                          trailing: Chip(
                            label: Text(
                              _pluginDisplayNames[method.pluginId] ??
                                  method.pluginId ??
                                  '',
                              style: const TextStyle(fontSize: 11),
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                          onTap: () {
                            // 直接使用默认模板，不打开表单对话框
                            final jsonString = jsonEncode(method.template);
                            Navigator.pop(context, {
                              'methodName': method.name,
                              'jsonString': jsonString,
                            });
                          },
                        );
                      },
                    ),
            ),

            // 底部按钮
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(OpenAILocalizations.of(context).cancel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
