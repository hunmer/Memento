import 'dart:convert';
import 'package:Memento/l10n/app_localizations.dart';
import 'package:Memento/plugins/contact/l10n/contact_localizations.dart';
import 'package:flutter/material.dart';
import '../base_plugin.dart';

import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';
import '../../core/js_bridge/js_bridge_plugin.dart';
import 'controllers/contact_controller.dart';
import 'models/contact_model.dart';
import 'models/interaction_record_model.dart';
import 'models/filter_sort_config.dart';
import 'widgets/contact_card.dart';
import 'widgets/contact_form.dart';
import 'widgets/filter_dialog.dart';
import 'package:uuid/uuid.dart';
import 'controls/prompt_controller.dart';

class ContactPlugin extends BasePlugin with JSBridgePlugin {
  late ContactController _controller;

  // 暴露控制器供外部访问
  ContactController get controller => _controller;

  @override
  String get id => 'contact';

  @override
  Color get color => Colors.deepPurple;

  @override
  IconData get icon => Icons.contacts;

  @override
  Future<void> initialize() async {
    _controller = ContactController(this);

    // 注册 JS API（最后一步）
    await registerJSAPI();

    // 初始化 Prompt Controller
    final promptController = ContactPromptController(this);
    promptController.initialize();
  }

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    await initialize();
  }

  @override
  Widget buildMainView(BuildContext context) {
    return ContactMainView();
  }

  @override
  String? getPluginName(context) {
    return ContactLocalizations.of(context).name;
  }

  @override
  Widget buildCardView(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getCardStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = snapshot.data!;
        final theme = Theme.of(context);

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部图标和标题
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 24, color: color),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    ContactLocalizations.of(context).name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 统计信息
              Column(
                children: [
                  // 联系人统计
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // 总联系人
                      Column(
                        children: [
                          Text(
                            ContactLocalizations.of(context).totalContacts,
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(
                            '${stats['totalContacts']}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),

                      // 最近联系人
                      Column(
                        children: [
                          Text(
                            ContactLocalizations.of(context).recentContacts,
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(
                            '${stats['recentContacts']}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getCardStats() async {
    final contacts = await _controller.getAllContacts();
    final recentContacts = await _controller.getRecentlyContactedCount();
    return {'totalContacts': contacts.length, 'recentContacts': recentContacts};
  }

  @override
  Map<String, Function> defineJSAPI() {
    return {
      // 联系人相关
      'getContacts': _jsGetContacts,
      'getContact': _jsGetContact,
      'createContact': _jsCreateContact,
      'updateContact': _jsUpdateContact,
      'deleteContact': _jsDeleteContact,

      // 交���记录相关
      'addInteraction': _jsAddInteraction,
      'getInteractions': _jsGetInteractions,
      'deleteInteraction': _jsDeleteInteraction,

      // 筛选与统计
      'getRecentContacts': _jsGetRecentContacts,
      'getAllTags': _jsGetAllTags,
    };
  }

  // ==================== JS API 实现 ====================

  /// 获取所有联系人
  Future<String> _jsGetContacts() async {
    final contacts = await _controller.getAllContacts();
    return jsonEncode(contacts.map((c) => c.toJson()).toList());
  }

  /// 获取联系人详情
  /// 参数: contactId
  Future<String> _jsGetContact(String contactId) async {
    final contact = await _controller.getContact(contactId);
    if (contact == null) {
      return jsonEncode({'error': 'Contact not found'});
    }
    return jsonEncode(contact.toJson());
  }

  /// 创建联系人
  /// 参数: name, phone, [avatar], [address], [notes], [tags], [customFields]
  Future<String> _jsCreateContact(
    String name,
    String phone, [
    String? avatar,
    String? address,
    String? notes,
    List<dynamic>? tags,
    Map<dynamic, dynamic>? customFields,
  ]) async {
    final uuid = const Uuid();
    final contact = Contact(
      id: uuid.v4(),
      name: name,
      phone: phone,
      avatar: avatar,
      address: address,
      notes: notes,
      icon: Icons.person,
      iconColor: color,
      tags: tags?.map((t) => t.toString()).toList() ?? [],
      customFields: customFields?.map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          ) ??
          {},
    );

    await _controller.addContact(contact);
    return jsonEncode(contact.toJson());
  }

  /// 更新联系人
  /// 参数: contactId, [name], [phone], [avatar], [address], [notes], [tags], [customFields]
  Future<String> _jsUpdateContact(
    String contactId, {
    String? name,
    String? phone,
    String? avatar,
    String? address,
    String? notes,
    List<dynamic>? tags,
    Map<dynamic, dynamic>? customFields,
  }) async {
    final contact = await _controller.getContact(contactId);
    if (contact == null) {
      return jsonEncode({'error': 'Contact not found'});
    }

    final updatedContact = contact.copyWith(
      name: name,
      phone: phone,
      avatar: avatar,
      address: address,
      notes: notes,
      tags: tags?.map((t) => t.toString()).toList(),
      customFields: customFields?.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      ),
    );

    await _controller.updateContact(updatedContact);
    return jsonEncode(updatedContact.toJson());
  }

  /// 删除联系人
  /// 参数: contactId
  Future<bool> _jsDeleteContact(String contactId) async {
    try {
      await _controller.deleteContact(contactId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 添加交互记录
  /// 参数: contactId, notes, [date], [participants]
  Future<String> _jsAddInteraction(
    String contactId,
    String notes, [
    String? dateStr,
    List<dynamic>? participants,
  ]) async {
    final uuid = const Uuid();
    final date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();

    final interaction = InteractionRecord(
      id: uuid.v4(),
      contactId: contactId,
      date: date,
      notes: notes,
      participants: participants?.map((p) => p.toString()).toList() ?? [],
    );

    await _controller.addInteraction(interaction);
    return jsonEncode(interaction.toJson());
  }

  /// 获取交互记录
  /// 参数: contactId
  Future<String> _jsGetInteractions(String contactId) async {
    final interactions =
        await _controller.getInteractionsByContactId(contactId);
    return jsonEncode(interactions.map((i) => i.toJson()).toList());
  }

  /// 删除交互记录
  /// 参数: interactionId
  Future<bool> _jsDeleteInteraction(String interactionId) async {
    try {
      await _controller.deleteInteraction(interactionId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 获取最近联系的联系人数量
  Future<int> _jsGetRecentContacts() async {
    return await _controller.getRecentlyContactedCount();
  }

  /// 获取所有标签
  Future<String> _jsGetAllTags() async {
    final tags = await _controller.getAllTags();
    return jsonEncode(tags);
  }
}

class ContactMainView extends StatefulWidget {
  const ContactMainView({super.key});

  @override
  State<ContactMainView> createState() => ContactMainViewState();
}

class ContactMainViewState extends State<ContactMainView> {
  late ContactPlugin _plugin;
  late ContactController _controller;
  bool _isListView = false;

  @override
  void initState() {
    super.initState();
    _plugin = PluginManager().getPlugin('contact') as ContactPlugin;
    _controller = _plugin._controller;
  }

  Future<void> _showFilterDialog() async {
    final currentFilter = await _controller.getFilterConfig();
    final tags = await _controller.getAllTags();

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder:
          (context) => FilterDialog(
            initialFilter: currentFilter,
            availableTags: tags,
            onApply: (filter) async {
              await _controller.saveFilterConfig(filter);
              if (mounted) {
                setState(() {});
              }
            },
          ),
    );
  }

  Future<void> _showSortMenu() async {
    final currentSort = await _controller.getSortConfig();

    if (!mounted) return;

    final result = await showDialog<SortConfig>(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: Text(ContactLocalizations.of(context).sortBy),
            children: [
              for (final type in SortType.values)
                RadioListTile<SortType>(
                  title: Text(_getSortTypeName(type)),
                  value: type,
                  groupValue: currentSort.type,
                  onChanged: (value) {
                    Navigator.pop(
                      context,
                      SortConfig(
                        type: value!,
                        isReverse:
                            type == currentSort.type
                                ? !currentSort.isReverse
                                : false,
                      ),
                    );
                  },
                  secondary:
                      type == currentSort.type
                          ? Icon(
                            currentSort.isReverse
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                          )
                          : null,
                ),
            ],
          ),
    );

    if (result != null) {
      await _controller.saveSortConfig(result);
      setState(() {});
    }
  }

  String _getSortTypeName(SortType type) {
    switch (type) {
      case SortType.name:
        return ContactLocalizations.of(context).name;
      case SortType.createdTime:
        return ContactLocalizations.of(context).createdTime;
      case SortType.lastContactTime:
        return ContactLocalizations.of(context).lastContactTime;
      case SortType.contactCount:
        return ContactLocalizations.of(context).contactCount;
    }
  }

  Future<void> _addOrEditContact([Contact? contact]) async {
    final formStateKey = GlobalKey<ContactFormState>();
    Contact? savedContact;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (context) => Scaffold(
              appBar: AppBar(
                title: Text(
                  contact == null
                      ? ContactLocalizations.of(context).addContact
                      : ContactLocalizations.of(context).editContact,
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: () async {
                      // 调用表单的保存方法
                      formStateKey.currentState?.saveContact();
                      if (savedContact != null) {
                        try {
                          if (contact == null) {
                            await _controller.addContact(savedContact!);
                          } else {
                            await _controller.updateContact(savedContact!);
                          }
                          if (mounted) {
                            Navigator.of(context).pop();
                            setState(() {});
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  ContactLocalizations.of(
                                        context,
                                      ).saveFailedMessage ??
                                      'Save failed',
                                ),
                              ),
                            );
                          }
                        }
                      } else {
                        // 如果 savedContact 为 null，可能是表单验证失败
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ContactLocalizations.of(
                                context,
                              ).formValidationMessage,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  if (contact != null)
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteContact(contact),
                    ),
                ],
              ),
              body: ContactForm(
                key: formStateKey,
                formStateKey: formStateKey,
                controller: _controller,
                contact: contact,
                onSave: (updatedContact) {
                  savedContact = updatedContact;
                },
              ),
            ),
      ),
    );
  }

  Future<void> _deleteContact(Contact contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(ContactLocalizations.of(context).confirmDelete),
            content: Text(
              ContactLocalizations.of(context).deleteConfirmMessage,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context)!.no),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(AppLocalizations.of(context)!.yes),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      await _controller.deleteContact(contact.id);
      Navigator.pop(context);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => PluginManager.toHomeScreen(context),
        ),
        title: Text(ContactLocalizations.of(context).contacts),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(icon: const Icon(Icons.sort), onPressed: _showSortMenu),
          IconButton(
            icon: Icon(_isListView ? Icons.grid_view : Icons.list),
            onPressed: () {
              setState(() {
                _isListView = !_isListView;
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Contact>>(
        future: _controller.getFilteredAndSortedContacts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(ContactLocalizations.of(context).errorMessage),
            );
          }

          final contacts = snapshot.data ?? [];

          if (contacts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    ContactLocalizations.of(context).noContacts,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          if (_isListView) {
            return ListView.builder(
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                return ContactCard(
                  contact: contacts[index],
                  onTap: () => _addOrEditContact(contacts[index]),
                  isListView: true,
                );
              },
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
            ),
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              return ContactCard(
                contact: contacts[index],
                onTap: () => _addOrEditContact(contacts[index]),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditContact(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
