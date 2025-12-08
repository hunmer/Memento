import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:Memento/plugins/chat/models/channel.dart';
import 'package:Memento/plugins/chat/chat_plugin.dart';
import 'package:Memento/plugins/chat/l10n/chat_localizations.dart';
import 'package:Memento/core/services/toast_service.dart';

/// 创建频道 Sheet 内容
///
/// 使用 smooth_sheets 的 modal sheet 展示
class CreateChannelSheet extends StatefulWidget {
  final ChatPlugin plugin;

  const CreateChannelSheet({
    super.key,
    required this.plugin,
  });

  @override
  State<CreateChannelSheet> createState() => _CreateChannelSheetState();
}

class _CreateChannelSheetState extends State<CreateChannelSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// 创建频道
  Future<void> _createChannel() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final l10n = ChatLocalizations.of(context);
      final channelName = _nameController.text.trim();

      // 创建频道对象
      final channel = Channel(
        id: const Uuid().v4(),
        title: channelName,
        icon: Icons.chat,
        backgroundColor: widget.plugin.color,
        messages: [],
      );

      await widget.plugin.channelService.createChannel(channel);

      if (mounted) {
        toastService.showToast(l10n.channelCreated);
        // 返回 true 表示创建成功
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        final l10n = ChatLocalizations.of(context);
        toastService.showToast('${l10n.createChannelFailed}: $e');
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ChatLocalizations.of(context);
    final theme = Theme.of(context);

    // 使用简单的 Column 布局，不使用 SheetContentScaffold
    return Material(
      color: theme.scaffoldBackgroundColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min, // 关键：让 Column 根据内容收缩
        children: [
          // 顶部栏
          SheetTopBar(
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(l10n.createChannel),
            actions: [
              if (_isCreating)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                TextButton(
                  onPressed: _createChannel,
                  child: Text(
                    l10n.create,
                    style: TextStyle(
                      color: widget.plugin.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          // 内容区域
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 频道名称输入
                  TextFormField(
                    controller: _nameController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: l10n.channelName,
                      hintText: '例如：工作、学习、随笔...',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.label),
                    ),
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _createChannel(),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入频道名称';
                      }
                      return null;
                    },
                    enabled: !_isCreating,
                  ),
                  const SizedBox(height: 16),

                  // 创建按钮
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isCreating ? null : _createChannel,
                      icon: _isCreating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.add),
                      label: Text(_isCreating ? '创建中...' : l10n.create),
                      style: FilledButton.styleFrom(
                        backgroundColor: widget.plugin.color,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  // 底部安全区域
                  SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// SheetTopBar 组件
///
/// 用于 SheetContentScaffold 的顶部栏
class SheetTopBar extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final List<Widget>? actions;

  const SheetTopBar({
    super.key,
    this.leading,
    this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Stack(
            children: [
              // 标题居中
              if (title != null)
                Center(
                  child: DefaultTextStyle(
                    style: Theme.of(context).textTheme.titleLarge!,
                    textAlign: TextAlign.center,
                    child: title!,
                  ),
                ),
              // 左侧和右侧按钮
              Row(
                children: [
                  if (leading != null)
                    leading!
                  else
                    const SizedBox(width: 48), // 占位，保持对称
                  const Spacer(),
                  if (actions != null) ...actions!,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

