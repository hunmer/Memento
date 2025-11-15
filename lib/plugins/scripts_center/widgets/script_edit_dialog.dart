import 'package:flutter/material.dart';
import '../models/script_info.dart';
import '../models/script_input.dart';
import 'script_input_edit_dialog.dart';

/// 脚本编辑对话框
///
/// 支持创建新脚本和编辑现有脚本
class ScriptEditDialog extends StatefulWidget {
  /// 如果为null则为创建模式，否则为编辑模式
  final ScriptInfo? script;

  const ScriptEditDialog({
    super.key,
    this.script,
  });

  @override
  State<ScriptEditDialog> createState() => _ScriptEditDialogState();
}

class _ScriptEditDialogState extends State<ScriptEditDialog> {
  final _formKey = GlobalKey<FormState>();

  // 表单控制器
  late final TextEditingController _nameController;
  late final TextEditingController _idController;
  late final TextEditingController _descController;
  late final TextEditingController _authorController;
  late final TextEditingController _versionController;
  late final TextEditingController _updateUrlController;

  // 表单值
  String _selectedIcon = 'code';
  String _selectedType = 'module';
  bool _enabled = true;

  // 输入参数列表
  List<ScriptInput> _inputs = [];

  // 可用图标列表
  final List<_IconOption> _availableIcons = [
    _IconOption('code', Icons.code, '代码'),
    _IconOption('backup', Icons.backup, '备份'),
    _IconOption('analytics', Icons.analytics, '分析'),
    _IconOption('settings', Icons.settings, '设置'),
    _IconOption('sync', Icons.sync, '同步'),
    _IconOption('schedule', Icons.schedule, '定时'),
    _IconOption('notification', Icons.notifications, '通知'),
    _IconOption('data', Icons.storage, '数据'),
    _IconOption('auto', Icons.autorenew, '自动'),
    _IconOption('star', Icons.star, '星标'),
    _IconOption('favorite', Icons.favorite, '喜欢'),
    _IconOption('build', Icons.build, '构建'),
  ];

  bool get isEditMode => widget.script != null;

  @override
  void initState() {
    super.initState();

    // 初始化控制器
    final script = widget.script;
    _nameController = TextEditingController(text: script?.name ?? '');
    _idController = TextEditingController(text: script?.id ?? '');
    _descController = TextEditingController(text: script?.description ?? '');
    _authorController = TextEditingController(text: script?.author ?? '');
    _versionController = TextEditingController(text: script?.version ?? '1.0.0');
    _updateUrlController = TextEditingController(text: script?.updateUrl ?? '');

    // 初始化下拉选择值
    if (script != null) {
      _selectedIcon = script.icon;
      _selectedType = script.type;
      _enabled = script.enabled;
      _inputs = List.from(script.inputs);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _descController.dispose();
    _authorController.dispose();
    _versionController.dispose();
    _updateUrlController.dispose();
    super.dispose();
  }

  /// 验证并保存
  void _saveScript() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 返回脚本数据
    final scriptData = {
      'name': _nameController.text.trim(),
      'id': _idController.text.trim(),
      'description': _descController.text.trim(),
      'author': _authorController.text.trim(),
      'version': _versionController.text.trim(),
      'icon': _selectedIcon,
      'type': _selectedType,
      'enabled': _enabled,
      'inputs': _inputs,
      'updateUrl': _updateUrlController.text.trim().isEmpty
          ? null
          : _updateUrlController.text.trim(),
    };

    Navigator.of(context).pop(scriptData);
  }

  /// 添加输入参数
  Future<void> _addInput() async {
    final input = await showDialog<ScriptInput>(
      context: context,
      builder: (context) => const ScriptInputEditDialog(),
    );

    if (input != null) {
      setState(() {
        _inputs.add(input);
      });
    }
  }

  /// 编辑输入参数
  Future<void> _editInput(int index) async {
    final input = await showDialog<ScriptInput>(
      context: context,
      builder: (context) => ScriptInputEditDialog(input: _inputs[index]),
    );

    if (input != null) {
      setState(() {
        _inputs[index] = input;
      });
    }
  }

  /// 删除输入参数
  void _deleteInput(int index) {
    setState(() {
      _inputs.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isEditMode ? Icons.edit : Icons.add_circle,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEditMode ? '编辑脚本' : '创建新脚本',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // 表单内容
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 基本信息标题
                      _buildSectionTitle('基本信息', Icons.info_outline),
                      const SizedBox(height: 16),

                      // 脚本名称
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: '脚本名称 *',
                          hintText: '例如：自动备份助手',
                          prefixIcon: Icon(Icons.title),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '请输入脚本名称';
                          }
                          return null;
                        },
                        autofocus: !isEditMode,
                      ),
                      const SizedBox(height: 16),

                      // 脚本ID
                      TextFormField(
                        controller: _idController,
                        decoration: InputDecoration(
                          labelText: '脚本ID *',
                          hintText: '例如：auto_backup',
                          helperText: '仅支持小写字母、数字和下划线',
                          prefixIcon: const Icon(Icons.fingerprint),
                          border: const OutlineInputBorder(),
                          enabled: !isEditMode, // 编辑模式下不可修改
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '请输入脚本ID';
                          }
                          if (!RegExp(r'^[a-z0-9_]+$').hasMatch(value)) {
                            return '只能包含小写字母、数字和下划线';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 描述
                      TextFormField(
                        controller: _descController,
                        decoration: const InputDecoration(
                          labelText: '描述',
                          hintText: '简短描述脚本的功能',
                          prefixIcon: Icon(Icons.description),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),

                      // 外观设置标题
                      _buildSectionTitle('外观设置', Icons.palette_outlined),
                      const SizedBox(height: 16),

                      // 图标选择
                      _buildIconSelector(),
                      const SizedBox(height: 24),

                      // 作者信息标题
                      _buildSectionTitle('作者信息', Icons.person_outline),
                      const SizedBox(height: 16),

                      // 作者
                      TextFormField(
                        controller: _authorController,
                        decoration: const InputDecoration(
                          labelText: '作者',
                          hintText: '例如：张三',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 版本号
                      TextFormField(
                        controller: _versionController,
                        decoration: const InputDecoration(
                          labelText: '版本号',
                          hintText: '例如：1.0.0',
                          helperText: '推荐使用语义化版本号',
                          prefixIcon: Icon(Icons.tag),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '请输入版本号';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // 高级设置标题
                      _buildSectionTitle('高级设置', Icons.settings_outlined),
                      const SizedBox(height: 16),

                      // 脚本类型
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: '脚本类型',
                          prefixIcon: Icon(Icons.category),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'module',
                            child: Text('Module（可接受参数）'),
                          ),
                          DropdownMenuItem(
                            value: 'standalone',
                            child: Text('Standalone（独立运行）'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 24),

                      // 输入参数设置（仅用于 module 类型）
                      if (_selectedType == 'module') ...[
                        _buildSectionTitle('输入参数', Icons.input_outlined),
                        const SizedBox(height: 12),

                        // 参数列表
                        if (_inputs.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '暂无输入参数',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '为 Module 类型脚本添加输入参数，执行时会显示表单收集用户输入',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        else
                          ..._inputs.asMap().entries.map((entry) {
                            final index = entry.key;
                            final input = entry.value;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.deepPurple.withValues(alpha: 0.1),
                                  child: Icon(
                                    _getInputTypeIcon(input.type),
                                    color: Colors.deepPurple,
                                    size: 20,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Text(
                                      input.label,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '(${input.key})',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (input.required) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          '必填',
                                          style: TextStyle(
                                            color: Colors.orange,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle: Text(
                                  input.description ?? '类型: ${input.type}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20),
                                      onPressed: () => _editInput(index),
                                      tooltip: '编辑',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 20),
                                      color: Colors.red,
                                      onPressed: () => _deleteInput(index),
                                      tooltip: '删除',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),

                        const SizedBox(height: 12),

                        // 添加参数按钮
                        OutlinedButton.icon(
                          onPressed: _addInput,
                          icon: const Icon(Icons.add),
                          label: const Text('添加输入参数'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.deepPurple,
                            side: const BorderSide(color: Colors.deepPurple),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // 更新地址
                      TextFormField(
                        controller: _updateUrlController,
                        decoration: const InputDecoration(
                          labelText: '更新地址（可选）',
                          hintText: '例如：https://example.com/script.js',
                          helperText: '用于未来的自动更新功能',
                          prefixIcon: Icon(Icons.cloud_download),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            final uri = Uri.tryParse(value);
                            if (uri == null || !uri.hasAbsolutePath) {
                              return '请输入有效的URL';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 启用开关
                      SwitchListTile(
                        value: _enabled,
                        onChanged: (value) {
                          setState(() {
                            _enabled = value;
                          });
                        },
                        title: const Text('启用脚本'),
                        subtitle: Text(
                          _enabled ? '脚本将在触发条件满足时执行' : '脚本已禁用，不会执行',
                        ),
                        secondary: Icon(
                          _enabled ? Icons.check_circle : Icons.cancel,
                          color: _enabled ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 底部按钮
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _saveScript,
                    icon: Icon(isEditMode ? Icons.save : Icons.add),
                    label: Text(isEditMode ? '保存' : '创建'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
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
      ),
    );
  }

  /// 构建区域标题
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.deepPurple),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
      ],
    );
  }

  /// 根据输入类型获取对应图标
  IconData _getInputTypeIcon(String type) {
    switch (type) {
      case 'string':
        return Icons.text_fields;
      case 'number':
        return Icons.numbers;
      case 'boolean':
        return Icons.toggle_on;
      case 'select':
        return Icons.list;
      default:
        return Icons.input;
    }
  }

  /// 构建图标选择器
  Widget _buildIconSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '选择图标',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableIcons.map((iconOption) {
              final isSelected = _selectedIcon == iconOption.name;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedIcon = iconOption.name;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.deepPurple.withValues(alpha: 0.1)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? Colors.deepPurple : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        iconOption.icon,
                        size: 28,
                        color: isSelected ? Colors.deepPurple : Colors.grey[700],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        iconOption.label,
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected ? Colors.deepPurple : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// 图标选项
class _IconOption {
  final String name;
  final IconData icon;
  final String label;

  _IconOption(this.name, this.icon, this.label);
}
