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

      // 联系人查找方法
      'findContactBy': _jsFindContactBy,
      'findContactById': _jsFindContactById,
      'findContactByName': _jsFindContactByName,

      // 交互记录查找方法
      'findInteractionBy': _jsFindInteractionBy,
      'findInteractionById': _jsFindInteractionById,
    };
  }

  // ==================== JS API 实现 ====================

  /// 获取所有联系人
  Future<String> _jsGetContacts(Map<String, dynamic> params) async {
    final contacts = await _controller.getAllContacts();
    return jsonEncode(contacts.map((c) => c.toJson()).toList());
  }

  /// 获取联系人详情
  Future<String> _jsGetContact(Map<String, dynamic> params) async {
    final String? contactId = params['contactId'];
    if (contactId == null || contactId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: contactId'});
    }

    final contact = await _controller.getContact(contactId);
    if (contact == null) {
      return jsonEncode({'error': 'Contact not found'});
    }
    return jsonEncode(contact.toJson());
  }

  /// 创建联系人
  Future<String> _jsCreateContact(Map<String, dynamic> params) async {
    // 提取必需参数
    final String? name = params['name'];
    if (name == null || name.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: name'});
    }

    final String? phone = params['phone'];
    if (phone == null || phone.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: phone'});
    }

    // 提取可选参数
    final String? id = params['id'];
    final String? avatar = params['avatar'];
    final String? address = params['address'];
    final String? notes = params['notes'];
    final List<String>? tags =
        params['tags'] != null ? List<String>.from(params['tags']) : null;
    final Map<String, String>? customFields =
        params['customFields'] != null
            ? Map<String, String>.from(params['customFields'])
            : null;

    // 检查自定义ID是否已存在
    if (id != null && id.isNotEmpty) {
      final existingContact = await _controller.getContact(id);
      if (existingContact != null) {
        return jsonEncode({'error': '联系人ID已存在: $id'});
      }
    }

    final uuid = const Uuid();
    final contact = Contact(
      id: (id != null && id.isNotEmpty) ? id : uuid.v4(), // 如果传入自定义ID则使用，否则自动生成
      name: name,
      phone: phone,
      avatar: avatar,
      address: address,
      notes: notes,
      icon: Icons.person,
      iconColor: color,
      tags: tags ?? [],
      customFields: customFields ?? {},
    );

    await _controller.addContact(contact);
    return jsonEncode(contact.toJson());
  }

  /// 更新联系人
  Future<String> _jsUpdateContact(Map<String, dynamic> params) async {
    // 提取必需参数
    final String? contactId = params['contactId'];
    if (contactId == null || contactId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: contactId'});
    }

    final contact = await _controller.getContact(contactId);
    if (contact == null) {
      return jsonEncode({'error': 'Contact not found'});
    }

    // 提取可选参数
    final String? name = params['name'];
    final String? phone = params['phone'];
    final String? avatar = params['avatar'];
    final String? address = params['address'];
    final String? notes = params['notes'];
    final List<String>? tags =
        params['tags'] != null ? List<String>.from(params['tags']) : null;
    final Map<String, String>? customFields =
        params['customFields'] != null
            ? Map<String, String>.from(params['customFields'])
            : null;

    final updatedContact = contact.copyWith(
      name: name,
      phone: phone,
      avatar: avatar,
      address: address,
      notes: notes,
      tags: tags,
      customFields: customFields,
    );

    await _controller.updateContact(updatedContact);
    return jsonEncode(updatedContact.toJson());
  }

  /// 删除联系人
  Future<String> _jsDeleteContact(Map<String, dynamic> params) async {
    try {
      final String? contactId = params['contactId'];
      if (contactId == null || contactId.isEmpty) {
        return jsonEncode({'success': false, 'error': '缺少必需参数: contactId'});
      }

      await _controller.deleteContact(contactId);
      return jsonEncode({'success': true, 'contactId': contactId});
    } catch (e) {
      return jsonEncode({'success': false, 'error': e.toString()});
    }
  }

  /// 添加交互记录
  Future<String> _jsAddInteraction(Map<String, dynamic> params) async {
    // 提取必需参数
    final String? contactId = params['contactId'];
    if (contactId == null || contactId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: contactId'});
    }

    final String? notes = params['notes'];
    if (notes == null || notes.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: notes'});
    }

    // 提取可选参数
    final String? dateStr = params['dateStr'];
    final List<String>? participants =
        params['participants'] != null
            ? List<String>.from(params['participants'])
            : null;

    final uuid = const Uuid();
    final date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();

    final interaction = InteractionRecord(
      id: uuid.v4(),
      contactId: contactId,
      date: date,
      notes: notes,
      participants: participants ?? [],
    );

    await _controller.addInteraction(interaction);
    return jsonEncode(interaction.toJson());
  }

  /// 获取交互记录
  Future<String> _jsGetInteractions(Map<String, dynamic> params) async {
    final String? contactId = params['contactId'];
    if (contactId == null || contactId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: contactId'});
    }

    final interactions = await _controller.getInteractionsByContactId(
      contactId,
    );
    return jsonEncode(interactions.map((i) => i.toJson()).toList());
  }

  /// 删除交互记录
  Future<String> _jsDeleteInteraction(Map<String, dynamic> params) async {
    try {
      final String? interactionId = params['interactionId'];
      if (interactionId == null || interactionId.isEmpty) {
        return jsonEncode({'success': false, 'error': '缺少必需参数: interactionId'});
      }

      await _controller.deleteInteraction(interactionId);
      return jsonEncode({'success': true, 'interactionId': interactionId});
    } catch (e) {
      return jsonEncode({'success': false, 'error': e.toString()});
    }
  }

  /// 获取最近联系的联系人数量
  Future<int> _jsGetRecentContacts(Map<String, dynamic> params) async {
    return await _controller.getRecentlyContactedCount();
  }

  /// 获取所有标签
  Future<String> _jsGetAllTags(Map<String, dynamic> params) async {
    final tags = await _controller.getAllTags();
    return jsonEncode(tags);
  }

  // ==================== 联系人查找方法 ====================

  /// 通用联系人查找
  Future<String> _jsFindContactBy(Map<String, dynamic> params) async {
    try {
      final String? field = params['field'];
      if (field == null || field.isEmpty) {
        return jsonEncode({'error': '缺少必需参数: field'});
      }

      final dynamic value = params['value'];
      if (value == null) {
        return jsonEncode({'error': '缺少必需参数: value'});
      }

      final bool findAll = params['findAll'] ?? false;

      final contacts = await _controller.getAllContacts();
      final List<Contact> matchedContacts = [];

      for (final contact in contacts) {
        final contactJson = contact.toJson();
        if (contactJson.containsKey(field) && contactJson[field] == value) {
          matchedContacts.add(contact);
          if (!findAll) break;
        }
      }

      if (findAll) {
        return jsonEncode(matchedContacts.map((c) => c.toJson()).toList());
      } else {
        return matchedContacts.isEmpty
            ? jsonEncode(null)
            : jsonEncode(matchedContacts.first.toJson());
      }
    } catch (e) {
      return jsonEncode({'error': '查找联系人失败: $e'});
    }
  }

  /// 根据 ID 查找联系人
  Future<String> _jsFindContactById(Map<String, dynamic> params) async {
    try {
      final String? id = params['id'];
      if (id == null || id.isEmpty) {
        return jsonEncode({'error': '缺少必需参数: id'});
      }

      final contact = await _controller.getContact(id);
      return jsonEncode(contact?.toJson());
    } catch (e) {
      return jsonEncode({'error': '查找联系人失败: $e'});
    }
  }

  /// 根据姓名查找联系人
  Future<String> _jsFindContactByName(Map<String, dynamic> params) async {
    try {
      final String? name = params['name'];
      if (name == null || name.isEmpty) {
        return jsonEncode({'error': '缺少必需参数: name'});
      }

      final bool fuzzy = params['fuzzy'] ?? false;
      final bool findAll = params['findAll'] ?? false;

      final contacts = await _controller.getAllContacts();
      final List<Contact> matchedContacts = [];

      for (final contact in contacts) {
        final bool matches = fuzzy
            ? contact.name.toLowerCase().contains(name.toLowerCase())
            : contact.name == name;

        if (matches) {
          matchedContacts.add(contact);
          if (!findAll) break;
        }
      }

      if (findAll) {
        return jsonEncode(matchedContacts.map((c) => c.toJson()).toList());
      } else {
        return matchedContacts.isEmpty
            ? jsonEncode(null)
            : jsonEncode(matchedContacts.first.toJson());
      }
    } catch (e) {
      return jsonEncode({'error': '查找联系人失败: $e'});
    }
  }

  // ==================== 交互记录查找方法 ====================

  /// 通用交互记录查找
  Future<String> _jsFindInteractionBy(Map<String, dynamic> params) async {
    try {
      final String? field = params['field'];
      if (field == null || field.isEmpty) {
        return jsonEncode({'error': '缺少必需参数: field'});
      }

      final dynamic value = params['value'];
      if (value == null) {
        return jsonEncode({'error': '缺少必需参数: value'});
      }

      final bool findAll = params['findAll'] ?? false;

      final interactions = await _controller.getAllInteractions();
      final List<InteractionRecord> matchedInteractions = [];

      for (final interaction in interactions) {
        final interactionJson = interaction.toJson();
        if (interactionJson.containsKey(field) &&
            interactionJson[field] == value) {
          matchedInteractions.add(interaction);
          if (!findAll) break;
        }
      }

      if (findAll) {
        return jsonEncode(
            matchedInteractions.map((i) => i.toJson()).toList());
      } else {
        return matchedInteractions.isEmpty
            ? jsonEncode(null)
            : jsonEncode(matchedInteractions.first.toJson());
      }
    } catch (e) {
      return jsonEncode({'error': '查找交互记录失败: $e'});
    }
  }

  /// 根据 ID 查找交互记录
  Future<String> _jsFindInteractionById(Map<String, dynamic> params) async {
    try {
      final String? id = params['id'];
      if (id == null || id.isEmpty) {
        return jsonEncode({'error': '缺少必需参数: id'});
      }

      final interactions = await _controller.getAllInteractions();
      final interaction =
          interactions.where((i) => i.id == id).firstOrNull;

      return jsonEncode(interaction?.toJson());
    } catch (e) {
      return jsonEncode({'error': '查找交互记录失败: $e'});
    }
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
