import 'dart:convert';
import 'package:get/get.dart';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/plugins/base_plugin.dart';

import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/config_manager.dart';
import 'package:Memento/core/js_bridge/js_bridge_plugin.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import 'controllers/contact_controller.dart';
import 'models/contact_model.dart';
import 'models/interaction_record_model.dart';
import 'widgets/contact_card.dart';
import 'widgets/contact_form.dart';
import 'widgets/filter_dialog.dart';
import 'package:uuid/uuid.dart';
import 'package:Memento/core/services/toast_service.dart';

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
    // 初始化默认数据
    await _controller.createDefaultContacts();

    // 注册 JS API（最后一步）
    await registerJSAPI();
  }

  @override
  Future<void> registerToApp(
    
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    // 插件已在 initialize() 中完成初始化
    // 这里可以添加额外的应用级注册逻辑
  }

  @override
  Widget buildMainView(BuildContext context) {
    return ContactMainView();
  }

  @override
  String? getPluginName(context) {
    return 'contact_name'.tr;
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
                    'contact_name'.tr,
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
                            'contact_totalContacts'.tr,
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
                            'contact_recentContacts'.tr,
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

      // 记录相关
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

  // ==================== 分页控制器 ====================

  /// 分页控制器 - 对列表进行分页处理
  /// @param list 原始数据列表
  /// @param offset 起始位置（默认 0）
  /// @param count 返回数量（默认 100）
  /// @return 分页后的数据，包含 data、total、offset、count、hasMore
  Map<String, dynamic> _paginate<T>(
    List<T> list, {
    int offset = 0,
    int count = 100,
  }) {
    final total = list.length;
    final start = offset.clamp(0, total);
    final end = (start + count).clamp(start, total);
    final data = list.sublist(start, end);

    return {
      'data': data,
      'total': total,
      'offset': start,
      'count': data.length,
      'hasMore': end < total,
    };
  }

  // ==================== JS API 实现 ====================

  /// 获取所有联系人
  /// 支持分页参数: offset, count
  Future<String> _jsGetContacts(Map<String, dynamic> params) async {
    final contacts = await _controller.getAllContacts();
    final contactsJson = contacts.map((c) => c.toJson()).toList();

    // 检查是否需要分页
    final int? offset = params['offset'];
    final int? count = params['count'];

    if (offset != null || count != null) {
      final paginated = _paginate(
        contactsJson,
        offset: offset ?? 0,
        count: count ?? 100,
      );
      return jsonEncode(paginated);
    }

    return jsonEncode(contactsJson);
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
  /// 支持分页参数: offset, count
  Future<String> _jsGetInteractions(Map<String, dynamic> params) async {
    final String? contactId = params['contactId'];
    if (contactId == null || contactId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: contactId'});
    }

    final interactions = await _controller.getInteractionsByContactId(
      contactId,
    );
    final interactionsJson = interactions.map((i) => i.toJson()).toList();

    // 检查是否需要分页
    final int? offset = params['offset'];
    final int? count = params['count'];

    if (offset != null || count != null) {
      final paginated = _paginate(
        interactionsJson,
        offset: offset ?? 0,
        count: count ?? 100,
      );
      return jsonEncode(paginated);
    }

    return jsonEncode(interactionsJson);
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
  /// 支持分页参数: offset, count (仅 findAll=true 时有效)
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
      final int? offset = params['offset'];
      final int? count = params['count'];

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
        final contactsJson = matchedContacts.map((c) => c.toJson()).toList();

        // 检查是否需要分页
        if (offset != null || count != null) {
          final paginated = _paginate(
            contactsJson,
            offset: offset ?? 0,
            count: count ?? 100,
          );
          return jsonEncode(paginated);
        }

        return jsonEncode(contactsJson);
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
  /// 支持分页参数: offset, count (仅 findAll=true 时有效)
  Future<String> _jsFindContactByName(Map<String, dynamic> params) async {
    try {
      final String? name = params['name'];
      if (name == null || name.isEmpty) {
        return jsonEncode({'error': '缺少必需参数: name'});
      }

      final bool fuzzy = params['fuzzy'] ?? false;
      final bool findAll = params['findAll'] ?? false;
      final int? offset = params['offset'];
      final int? count = params['count'];

      final contacts = await _controller.getAllContacts();
      final List<Contact> matchedContacts = [];

      for (final contact in contacts) {
        final bool matches =
            fuzzy
                ? contact.name.toLowerCase().contains(name.toLowerCase())
                : contact.name == name;

        if (matches) {
          matchedContacts.add(contact);
          if (!findAll) break;
        }
      }

      if (findAll) {
        final contactsJson = matchedContacts.map((c) => c.toJson()).toList();

        // 检查是否需要分页
        if (offset != null || count != null) {
          final paginated = _paginate(
            contactsJson,
            offset: offset ?? 0,
            count: count ?? 100,
          );
          return jsonEncode(paginated);
        }

        return jsonEncode(contactsJson);
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
  /// 支持分页参数: offset, count (仅 findAll=true 时有效)
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
      final int? offset = params['offset'];
      final int? count = params['count'];

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
        final interactionsJson =
            matchedInteractions.map((i) => i.toJson()).toList();

        // 检查是否需要分页
        if (offset != null || count != null) {
          final paginated = _paginate(
            interactionsJson,
            offset: offset ?? 0,
            count: count ?? 100,
          );
          return jsonEncode(paginated);
        }

        return jsonEncode(interactionsJson);
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
      final interaction = interactions.where((i) => i.id == id).firstOrNull;

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

// ... (imports and other code remain the same until ContactMainViewState)

class ContactMainViewState extends State<ContactMainView> {
  late ContactPlugin _plugin;

  late ContactController _controller;

  List<Contact> _searchResults = [];
  String _currentSearchQuery = '';
  bool _isSearching = false;

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

  /// 搜索联系人（按姓名和备注搜索）
  Future<void> _searchContacts(String query) async {
    _currentSearchQuery = query;

    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final allContacts = await _controller.getAllContacts();
      final normalizedQuery = query.toLowerCase();

      final results = allContacts.where((contact) {
        // 搜索姓名
        final nameMatch = contact.name.toLowerCase().contains(normalizedQuery);

        // 搜索备注
        final notesMatch = contact.notes != null &&
            contact.notes!.toLowerCase().contains(normalizedQuery);

        // 搜索电话（精确匹配和模糊匹配）
        final phoneMatch = contact.phone.contains(query);

        // 搜索组织/公司
        final orgMatch = contact.organization != null &&
            contact.organization!.toLowerCase().contains(normalizedQuery);

        // 搜索邮箱
        final emailMatch = contact.email != null &&
            contact.email!.toLowerCase().contains(normalizedQuery);

        // 搜索地址
        final addressMatch = contact.address != null &&
            contact.address!.toLowerCase().contains(normalizedQuery);

        // 搜索标签
        final tagsMatch = contact.tags.any(
          (tag) => tag.toLowerCase().contains(normalizedQuery),
        );

        return nameMatch ||
            notesMatch ||
            phoneMatch ||
            orgMatch ||
            emailMatch ||
            addressMatch ||
            tagsMatch;
      }).toList();

      if (mounted && _currentSearchQuery == query) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    }
  }

  /// 构建搜索结果列表
  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_currentSearchQuery.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              '输入关键词搜索联系人',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
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
              '没有找到匹配的联系人',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final contact = _searchResults[index];
        return ContactCard(
          contact: contact,
          controller: _controller,
          onTap: () => _addOrEditContact(contact),
        );
      },
    );
  }

  Future<void> _showSortMenu() async {
    await _controller.getSortConfig();

    if (!mounted) return;

    // ... (rest of the _showSortMenu method is the same)
  }

  Future<void> _addOrEditContact([Contact? contact]) async {
    final formStateKey = GlobalKey<ContactFormState>();

    Contact? savedContact;

    await NavigationHelper.push(
      context,
      Scaffold(
        appBar: AppBar(
          leading: TextButton(
            child: Text('contact_cancel'.tr),

            onPressed: () => Navigator.of(context).pop(),
          ),

          leadingWidth: 80,

          title: Text(
            contact == null
                ? 'contact_addContact'.tr
                : 'contact_editContact'.tr,
          ),

          actions: [
            TextButton(
              child: Text(
                'contact_done'.tr,

                style: const TextStyle(fontWeight: FontWeight.bold),
              ),

              onPressed: () async {
                formStateKey.currentState?.saveContact();

                // a small delay to allow savedContact to be set

                await Future.delayed(const Duration(milliseconds: 50));

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
                      ToastService.instance.showToast(
                        'contact_saveFailedMessage'.tr,
                      );
                    }
                  }
                } else {
                  ToastService.instance.showToast(
                    'contact_formValidationMessage'.tr,
                  );
                }
              },
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return SuperCupertinoNavigationWrapper(
      title: Text('contact_contacts'.tr),
      largeTitle: 'contact_contactListTitle'.tr,
      automaticallyImplyLeading: !(Platform.isAndroid || Platform.isIOS),
      body: FutureBuilder<List<Contact>>(
        future: _controller.getFilteredAndSortedContacts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('contact_errorMessage'.tr),
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
                    'contact_noContacts'.tr,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              return ContactCard(
                contact: contacts[index],
                controller: _controller,
                onTap: () => _addOrEditContact(contacts[index]),
              );
            },
          );
        },
      ),
      // 启用搜索栏
      enableSearchBar: true,
      searchPlaceholder: 'contact_searchPlaceholder'.tr,
      onSearchChanged: (query) {
        _searchContacts(query);
      },
      // 搜索结果页面
      searchBody: _buildSearchResults(),
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: _showFilterDialog,
        ),
        IconButton(icon: const Icon(Icons.sort), onPressed: _showSortMenu),
        OpenContainer(
          transitionType: ContainerTransitionType.fade,
          openBuilder: (context, _) {
            return ContactForm(
              controller: _controller,
              onSave: (savedContact) {},
            );
          },
          closedBuilder: (context, VoidCallback openContainer) {
            return IconButton(
              icon: const Icon(Icons.add),
              onPressed: openContainer,
            );
          },
        ),
      ],
      enableLargeTitle: true,
    );
  }
}
