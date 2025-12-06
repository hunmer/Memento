import 'package:flutter/material.dart';
import '../models/script_info.dart';
import '../models/script_input.dart';
import '../models/script_trigger.dart';
import '../services/script_manager.dart';
import '../widgets/script_input_edit_dialog.dart';
import '../../../core/services/toast_service.dart';

/// 脚本编辑屏幕
///
/// 完整的脚本编辑界面，包含：
/// - 基本信息编辑
/// - 代码编辑器
/// - 触发条件选择器
/// - 高级设置
class ScriptEditScreen extends StatefulWidget {
  /// 如果为null则为创建模式，否则为编辑模式
  final ScriptInfo? script;

  /// 脚本管理器（用于加载代码）
  final ScriptManager scriptManager;

  const ScriptEditScreen({
    super.key,
    this.script,
    required this.scriptManager,
  });

  @override
  State<ScriptEditScreen> createState() => _ScriptEditScreenState();
}

class _ScriptEditScreenState extends State<ScriptEditScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  // 表单控制器
  late final TextEditingController _nameController;
  late final TextEditingController _idController;
  late final TextEditingController _descController;
  late final TextEditingController _authorController;
  late final TextEditingController _versionController;
  late final TextEditingController _updateUrlController;
  late final TextEditingController _codeController;

  // 表单值
  String _selectedIcon = 'code';
  String _selectedType = 'module';
  bool _enabled = true;

  // 输入参数列表
  List<ScriptInput> _inputs = [];

  // 触发条件列表
  List<ScriptTrigger> _triggers = [];

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

  // 可用事件列表（从项目中收集的所有事件）
  final List<_EventOption> _availableEvents = [
    // 核心事件
    _EventOption('plugins_initialized', '插件系统', '所有插件初始化完成'),

    // 日记插件事件
    _EventOption('diary_entry_created', '日记', '创建日记条目'),
    _EventOption('diary_entry_updated', '日记', '更新日记条目'),
    _EventOption('diary_entry_deleted', '日记', '删除日记条目'),

    // 活动插件事件
    _EventOption('activity_added', '活动', '添加活动记录'),
    _EventOption('activity_deleted', '活动', '删除活动记录'),

    // 笔记插件事件
    _EventOption('note_added', '笔记', '添加笔记'),
    _EventOption('note_deleted', '笔记', '删除笔记'),

    // 任务插件事件
    _EventOption('task_added', '任务', '添加任务'),
    _EventOption('task_deleted', '任务', '删除任务'),
    _EventOption('task_completed', '任务', '完成任务'),

    // 签到插件事件
    _EventOption('checkin_completed', '签到', '完成签到'),
    _EventOption('checkin_deleted', '签到', '删除签到记录'),

    // 账单插件事件
    _EventOption('bill_added', '账单', '添加账单'),
    _EventOption('bill_deleted', '账单', '删除账单'),
    _EventOption('account_added', '账单', '添加账户'),
    _EventOption('account_deleted', '账单', '删除账户'),

    // 物品管理事件
    _EventOption('goods_item_added', '物品', '添加物品'),
    _EventOption('goods_item_deleted', '物品', '删除物品'),

    // 聊天插件事件
    _EventOption('onMessageSent', '聊天', '发送消息'),
    _EventOption('onMessageUpdated', '聊天', '更新消息'),
    _EventOption('UserEventNames.userAvatarUpdated', '聊天', '更新用户头像'),

    // 追踪器事件
    _EventOption('onRecordAdded', '追踪器', '添加记录'),

    // 计时器事件
    _EventOption('timer_task_changed', '计时器', '任务变更'),
    _EventOption('timer_item_changed', '计时器', '项目变更'),
    _EventOption('timer_item_progress', '计时器', '项目进度更新'),

    // 商店事件
    _EventOption('store_product_added', '商店', '添加商品'),
    _EventOption('store_product_deleted', '商店', '删除商品'),
    _EventOption('store_purchase', '商店', '购买商品'),

    // 习惯插件事件
    _EventOption('habit_added', '习惯', '添加习惯'),
    _EventOption('habit_deleted', '习惯', '删除习惯'),
    _EventOption('habit_checked', '习惯', '打卡习惯'),

    // 联系人事件
    _EventOption('contact_added', '联系人', '添加联系人'),
    _EventOption('contact_deleted', '联系人', '删除联系人'),

    // 纪念日事件
    _EventOption('memorial_day_added', '纪念日', '添加纪念日'),
    _EventOption('memorial_day_deleted', '纪念日', '删除纪念日'),

    // 日历事件
    _EventOption('calendar_event_added', '日历', '添加事件'),
    _EventOption('calendar_event_deleted', '日历', '删除事件'),
  ];

  bool get isEditMode => widget.script != null;

  @override
  void initState() {
    super.initState();

    // 初始化Tab控制器
    _tabController = TabController(length: 4, vsync: this);

    // 初始化控制器
    final script = widget.script;
    _nameController = TextEditingController(text: script?.name ?? '');
    _idController = TextEditingController(text: script?.id ?? '');
    _descController = TextEditingController(text: script?.description ?? '');
    _authorController = TextEditingController(text: script?.author ?? '');
    _versionController = TextEditingController(text: script?.version ?? '1.0.0');
    _updateUrlController = TextEditingController(text: script?.updateUrl ?? '');
    _codeController = TextEditingController();

    // 初始化下拉选择值
    if (script != null) {
      _selectedIcon = script.icon;
      _selectedType = script.type;
      _enabled = script.enabled;
      _inputs = List.from(script.inputs);
      _triggers = List.from(script.triggers);

      // 异步加载代码
      _loadScriptCode();
    }
  }

  /// 加载脚本代码
  Future<void> _loadScriptCode() async {
    if (widget.script == null) return;

    try {
      final code = await widget.scriptManager.getScriptCode(widget.script!.id);
      if (code != null && mounted) {
        _codeController.text = code;
      }
    } catch (e) {
      // 加载失败，保持空代码
      debugPrint('Failed to load script code: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _idController.dispose();
    _descController.dispose();
    _authorController.dispose();
    _versionController.dispose();
    _updateUrlController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  /// 验证并保存
  void _saveScript() {
    if (!_formKey.currentState!.validate()) {
      // 切换到包含错误的Tab
      toastService.showToast('请检查并修正表单中的错误');
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
      'code': _codeController.text,
      'inputs': _inputs,
      'triggers': _triggers.map((t) => t.toJson()).toList(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? '编辑脚本' : '创建新脚本'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: _saveScript,
            icon: Icon(
              isEditMode ? Icons.save : Icons.add,
              color: Colors.white,
            ),
            label: Text(
              isEditMode ? '保存' : '创建',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.info_outline), text: '基本信息'),
            Tab(icon: Icon(Icons.code), text: '代码编辑'),
            Tab(icon: Icon(Icons.bolt), text: '触发条件'),
            Tab(icon: Icon(Icons.settings_outlined), text: '高级设置'),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildBasicInfoTab(),
            _buildCodeEditorTab(),
            _buildTriggersTab(),
            _buildAdvancedTab(),
          ],
        ),
      ),
    );
  }

  /// 构建基本信息标签页
  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

          // 图标选择
          _buildIconSelector(),
          const SizedBox(height: 24),

          // 作者信息
          const Divider(),
          const SizedBox(height: 16),
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
        ],
      ),
    );
  }

  /// 构建代码编辑器标签页
  Widget _buildCodeEditorTab() {
    return Column(
      children: [
        // 工具栏
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey[100],
          child: Row(
            children: [
              const Icon(Icons.code, size: 20, color: Colors.deepPurple),
              const SizedBox(width: 8),
              const Text(
                'JavaScript 代码',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  // TODO: 添加代码格式化功能
                  toastService.showToast('代码格式化功能即将推出');
                },
                icon: const Icon(Icons.format_align_left, size: 18),
                label: const Text('格式化'),
              ),
            ],
          ),
        ),
        // 代码编辑器
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _codeController,
              maxLines: null,
              expands: true,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
              ),
              decoration: const InputDecoration(
                hintText: '// 在此输入 JavaScript 代码\n'
                    '// 例如：\n'
                    '// function execute(context, args) {\n'
                    '//   console.log("Hello from script!");\n'
                    '//   return { success: true };\n'
                    '// }',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(16),
              ),
              textAlignVertical: TextAlignVertical.top,
            ),
          ),
        ),
        // 提示信息
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.blue[50],
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '脚本将在满足触发条件时执行。可以访问 context 对象获取应用上下文。',
                  style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建触发条件标签页
  Widget _buildTriggersTab() {
    return Column(
      children: [
        // 添加触发器按钮
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.bolt, color: Colors.deepPurple),
              const SizedBox(width: 8),
              const Text(
                '触发条件',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _showAddTriggerDialog,
                icon: const Icon(Icons.add),
                label: const Text('添加触发器'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // 触发器列表
        Expanded(
          child: _triggers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bolt_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '暂无触发条件',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '点击上方按钮添加触发条件',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _triggers.length,
                  itemBuilder: (context, index) {
                    final trigger = _triggers[index];
                    final eventOption = _availableEvents.firstWhere(
                      (e) => e.eventName == trigger.event,
                      orElse: () => _EventOption(
                        trigger.event,
                        '未知',
                        trigger.event,
                      ),
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.deepPurple,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(eventOption.eventName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('类别: ${eventOption.category}'),
                            Text('描述: ${eventOption.description}'),
                            if (trigger.delay != null && trigger.delay! > 0)
                              Text('延迟: ${trigger.delay}ms'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _triggers.removeAt(index);
                            });
                          },
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// 构建高级设置标签页
  Widget _buildAdvancedTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 脚本类型
          DropdownButtonFormField<String>(
            initialValue: _selectedType,
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
            Row(
              children: [
                const Icon(Icons.input_outlined, size: 20, color: Colors.deepPurple),
                const SizedBox(width: 8),
                const Text(
                  '输入参数',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
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
          const SizedBox(height: 24),

          // 启用开关
          Card(
            child: SwitchListTile(
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
          ),
        ],
      ),
    );
  }

  /// 显示添加触发器对话框
  Future<void> _showAddTriggerDialog() async {
    String? selectedEvent;
    int delay = 0;
    final delayController = TextEditingController(text: '0');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('添加触发条件'),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 事件选择
                const Text(
                  '选择事件 *',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                          initialValue: selectedEvent,
                  decoration: const InputDecoration(
                    hintText: '请选择一个事件',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: _availableEvents.map((event) {
                    return DropdownMenuItem(
                      value: event.eventName,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(event.eventName),
                          Text(
                            '${event.category} - ${event.description}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedEvent = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // 延迟设置
                TextField(
                  controller: delayController,
                  decoration: const InputDecoration(
                    labelText: '延迟（毫秒）',
                    hintText: '0',
                    helperText: '触发后延迟多久执行脚本',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    delay = int.tryParse(value) ?? 0;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: selectedEvent == null
                  ? null
                  : () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );

    if (result == true && selectedEvent != null) {
      setState(() {
        _triggers.add(ScriptTrigger(
          event: selectedEvent!,
          delay: delay > 0 ? delay : null,
        ));
      });
    }

    delayController.dispose();
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

  /// 构建图标选择器
  Widget _buildIconSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('选择图标', Icons.palette_outlined),
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

/// 事件选项
class _EventOption {
  final String eventName;
  final String category;
  final String description;

  _EventOption(this.eventName, this.category, this.description);
}
