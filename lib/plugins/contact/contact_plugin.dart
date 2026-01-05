import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/plugins/base_plugin.dart';

import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/config_manager.dart';
import 'package:Memento/core/js_bridge/js_bridge_plugin.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import 'package:shared_models/repositories/contact/contact_repository.dart';
import 'controllers/contact_controller.dart';
import 'models/contact_model.dart';
import 'models/interaction_record_model.dart';
import 'widgets/contact_card.dart';
import 'widgets/contact_form.dart';
import 'widgets/filter_dialog.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/core/services/plugin_data_selector/index.dart';

// UseCase 架构相关导入
import 'package:shared_models/usecases/contact/contact_usecase.dart';
import 'repositories/client_contact_repository.dart';

// HTTP 服务器导入
import 'package:Memento/plugins/webview/services/local_http_server.dart';

part 'contact_js_api.dart';
part 'contact_data_selectors.dart';

class ContactPlugin extends BasePlugin with JSBridgePlugin {
  late ContactController _controller;
  late ContactUseCase _useCase;

  // 暴露控制器和 UseCase 供外部访问
  ContactController get controller => _controller;
  ContactUseCase get useCase => _useCase;

  @override
  String get id => 'contact';

  @override
  Color get color => Colors.deepPurple;

  @override
  IconData get icon => Icons.contacts;

  @override
  Future<void> initialize() async {
    // 1. 初始化控制器
    _controller = ContactController(this);

    // 2. 创建 Repository
    final repository = ClientContactRepository(controller: _controller);

    // 3. 创建 UseCase
    _useCase = ContactUseCase(repository as IContactRepository);

    // 4. 初始化默认数据
    await _controller.createDefaultContacts();

    // 5. 注册 JS API（最后一步）
    await registerJSAPI();

    // 6. 注册数据选择器
    _registerDataSelectors();
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
    // 使用 UseCase 获取统计数据
    final totalContactsResult = await _useCase.getTotalContactCount({});
    final recentContactsResult = await _useCase.getRecentlyContactedCount({});

    return {
      'totalContacts': totalContactsResult.dataOrNull ?? 0,
      'recentContacts': recentContactsResult.dataOrNull ?? 0,
    };
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
  String _selectedTag = '全部'; // 当前选中的标签

  // GlobalKey for OpenContainer animation
  final GlobalKey _addButtonKey = GlobalKey();

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

      final results =
          allContacts.where((contact) {
            // 搜索姓名
            final nameMatch = contact.name.toLowerCase().contains(
              normalizedQuery,
            );

            // 搜索备注
            final notesMatch =
                contact.notes != null &&
                contact.notes!.toLowerCase().contains(normalizedQuery);

            // 搜索电话（精确匹配和模糊匹配）
            final phoneMatch = contact.phone.contains(query);

            // 搜索组织/公司
            final orgMatch =
                contact.organization != null &&
                contact.organization!.toLowerCase().contains(normalizedQuery);

            // 搜索邮箱
            final emailMatch =
                contact.email != null &&
                contact.email!.toLowerCase().contains(normalizedQuery);

            // 搜索地址
            final addressMatch =
                contact.address != null &&
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
            const Icon(Icons.search, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              '输入关键词搜索联系人',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.grey),
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
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              '没有找到匹配的联系人',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final contact = _searchResults[index];
        return ContactCard(
          contact: contact,
          controller: _controller,
          onTap: () => _addOrEditContact(contact),
          onContactUpdated: () => setState(() {}),
        );
      },
    );
  }

  Future<void> _addOrEditContact([Contact? contact]) async {
    await NavigationHelper.push(
      context,
      ContactForm(
        contact: contact,
        onSave: (savedContact) async {
          try {
            if (contact == null) {
              await _controller.addContact(savedContact);
            } else {
              await _controller.updateContact(savedContact);
            }
            if (mounted) {
              setState(() {});
            }
          } catch (e) {
            ToastService.instance.showToast('contact_saveFailedMessage'.tr);
          }
        },
        onDelete: () async {
          // 删除联系人，导航由 ContactForm 处理
          if (contact != null) {
            await _controller.deleteContact(contact.id);
          }
        },
      ),
    );
  }

  /// 获取所有标签(用于过滤栏)
  Future<List<String>> _getTags() async {
    final tags = await _controller.getAllTags();
    return ['全部', ...tags];
  }

  /// 选择标签
  void _selectTag(String tag) {
    setState(() {
      _selectedTag = tag;
    });
  }

  /// 根据选中的标签过滤联系人
  Future<List<Contact>> _getFilteredByTag() async {
    final contacts = await _controller.getFilteredAndSortedContacts();
    if (_selectedTag == '全部') {
      return contacts;
    } else {
      return contacts
          .where((contact) => contact.tags.contains(_selectedTag))
          .toList();
    }
  }

  /// 构建标签过滤栏
  Widget _buildFilterBar() {
    return FutureBuilder<List<String>>(
      future: _getTags(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final tags = snapshot.data!;
        if (tags.length <= 1) {
          // 只有"全部"标签,不显示过滤栏
          return const SizedBox.shrink();
        }

        return Container(
          height: 50,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: tags.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final tag = tags[index];
              final isSelected = tag == _selectedTag;
              return ChoiceChip(
                label: Text(tag),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    _selectTag(tag);
                  }
                },
                showCheckmark: false,
                labelStyle: TextStyle(
                  color:
                      isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).textTheme.bodyMedium?.color,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                selectedColor: Theme.of(context).primaryColor,
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SuperCupertinoNavigationWrapper(
      title: Text('contact_contacts'.tr),
      largeTitle: 'contact_contactListTitle'.tr,

      // ========== 搜索相关配置 ==========
      enableSearchBar: true,
      searchPlaceholder: 'contact_searchPlaceholder'.tr,
      onSearchChanged: (query) {
        _searchContacts(query);
      },
      searchBody: _buildSearchResults(),
      // ========== 过滤栏配置 ==========
      enableFilterBar: true,
      filterBarChild: _buildFilterBar(),
      body: FutureBuilder<List<Contact>>(
        future: _getFilteredByTag(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('contact_errorMessage'.tr));
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
            padding: EdgeInsets.zero,
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              return ContactCard(
                contact: contacts[index],
                controller: _controller,
                onTap: () => _addOrEditContact(contacts[index]),
                onContactUpdated: () => setState(() {}),
              );
            },
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: _showFilterDialog,
        ),
        IconButton(
          key: _addButtonKey,
          icon: const Icon(Icons.add),
          onPressed: () {
            NavigationHelper.openContainerWithHero(
              context,
              (context) => ContactForm(
                onSave: (savedContact) async {
                  await _controller.addContact(savedContact);
                  setState(() {});
                },
              ),
              sourceKey: _addButtonKey,
              heroTag: 'contact_add_button',
            );
          },
        ),
      ],
      enableLargeTitle: true,
    );
  }
}
