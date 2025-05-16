import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/contact_model.dart';
import '../models/interaction_record_model.dart';
import '../models/filter_sort_config.dart';
import '../../base_plugin.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;

class ContactController {
  static ContactController? _instance;
  final BasePlugin plugin;
  late final String contactsKey;
  late final String interactionsKey;
  late final String filterConfigKey;
  late final String sortConfigKey;

  // 获取单例实例
  static ContactController getInstance(BasePlugin plugin) {
    _instance ??= ContactController._internal(plugin);
    return _instance!;
  }

  // 私有构造函数
  ContactController._internal(this.plugin) {
    // 初始化时规范化所有路径
    contactsKey = _normalizePath('contacts${path.separator}contacts.json');
    interactionsKey = _normalizePath('interactions');
    filterConfigKey = _normalizePath('filter_config');
    sortConfigKey = _normalizePath('sort_config');
  }

  @Deprecated('Use getInstance() instead')

  // 内存缓存
  List<Contact>? _contactsCache;
  List<InteractionRecord>? _interactionsCache;
  FilterConfig? _filterConfigCache;
  SortConfig? _sortConfigCache;
  
  // 是否有未保存的更改
  bool _hasContactsChanges = false;
  bool _hasInteractionsChanges = false;
  
  // 使用平台特定的路径分隔符
  String _normalizePath(String filePath) {
    return filePath.replaceAll('/', path.separator);
  }

  ContactController(this.plugin) {
    // 初始化时规范化所有路径
    contactsKey = _normalizePath('contacts${path.separator}contacts.json');
    interactionsKey = _normalizePath('interactions');
    filterConfigKey = _normalizePath('filter_config');
    sortConfigKey = _normalizePath('sort_config');
  }

  // 用于测试的清理方法
  @visibleForTesting
  static void reset() {
    _instance = null;
  }

  // 从存储加载联系人数据到缓存
  Future<void> _loadContactsToCache() async {
    if (_contactsCache != null) return; // 如果已经有缓存，直接返回

    final storage = plugin.storage;
    try {
      final dynamic rawData = await storage.readJson(contactsKey);
      if (rawData == null) {
        _contactsCache = [];
        return;
      }
      
      if (rawData is! List) {
        throw FormatException('Contacts data must be a List');
      }
      
      _contactsCache = List<Contact>.from(
        rawData.map((json) => Contact.fromJson(Map<String, dynamic>.from(json as Map)))
      );
    } catch (e) {
      if (e.toString().contains('FileSystemException: 文件不存在')) {
        // 如果文件不存在，创建默认联系人
        await createDefaultContacts();
        // 默认联系人已经设置到缓存中
        return;
      }
      rethrow;
    }
  }

  // 将缓存的联系人数据保存到存储
  Future<void> _saveContactsToStorage() async {
    if (!_hasContactsChanges || _contactsCache == null) return;
    
    final storage = plugin.storage;
    final List<Map<String, dynamic>> jsonData = _contactsCache!.map((c) => c.toJson()).toList();
    await storage.writeJson(contactsKey, jsonData);
    _hasContactsChanges = false;
  }

  // 获取所有联系人（使用缓存）
  Future<List<Contact>> getAllContacts() async {
    await _loadContactsToCache();
    return List<Contact>.from(_contactsCache!);
  }

  // 保存所有联系人（更新缓存）
  Future<void> saveAllContacts(List<Contact> contacts) async {
    _contactsCache = List<Contact>.from(contacts);
    _hasContactsChanges = true;
    await _saveContactsToStorage();
  }

  // 添加联系人
  Future<Contact> addContact(Contact contact) async {
    final contacts = await getAllContacts();
    contacts.add(contact);
    await saveAllContacts(contacts);
    return contact;
  }

  // 更新联系人
  Future<Contact> updateContact(Contact contact) async {
    final contacts = await getAllContacts();
    final index = contacts.indexWhere((c) => c.id == contact.id);
    if (index != -1) {
      contacts[index] = contact;
      await saveAllContacts(contacts);
      return contact;
    }
    throw Exception('Contact not found');
  }

  // 删除联系人
  Future<void> deleteContact(String id) async {
    final contacts = await getAllContacts();
    contacts.removeWhere((c) => c.id == id);
    await saveAllContacts(contacts);
    
    // 级联删除相关的交互记录
    await deleteInteractionsByContactId(id);
  }

  // 获取联系人
  Future<Contact?> getContact(String id) async {
    final contacts = await getAllContacts();
    return contacts.firstWhere((c) => c.id == id, orElse: () => null as Contact);
  }

  // 从存储加载交互记录到缓存
  Future<void> _loadInteractionsToCache() async {
    if (_interactionsCache != null) return;

    final storage = plugin.storage;
    try {
      final dynamic rawData = await storage.readJson(interactionsKey);
      if (rawData == null) {
        _interactionsCache = [];
        return;
      }
      
      if (rawData is! List) {
        throw FormatException('Interactions data must be a List');
      }
      
      _interactionsCache = List<InteractionRecord>.from(
        rawData.map((json) => InteractionRecord.fromJson(Map<String, dynamic>.from(json as Map)))
      );
    } catch (e) {
      if (e.toString().contains('FileSystemException: 文件不存在')) {
        _interactionsCache = [];
        await _saveInteractionsToStorage();
      } else {
        rethrow;
      }
    }
  }

  // 将缓存的交互记录保存到存储
  Future<void> _saveInteractionsToStorage() async {
    if (!_hasInteractionsChanges || _interactionsCache == null) return;
    
    final storage = plugin.storage;
    await storage.writeJson(interactionsKey, _interactionsCache!.map((i) => i.toJson()).toList());
    _hasInteractionsChanges = false;
  }

  // 获取所有交互记录（使用缓存）
  Future<List<InteractionRecord>> getAllInteractions() async {
    await _loadInteractionsToCache();
    return List<InteractionRecord>.from(_interactionsCache!);
  }

  // 保存所有交互记录（更新缓存）
  Future<void> saveAllInteractions(List<InteractionRecord> interactions) async {
    _interactionsCache = List<InteractionRecord>.from(interactions);
    _hasInteractionsChanges = true;
    await _saveInteractionsToStorage();
  }

  // 添加交互记录
  Future<InteractionRecord> addInteraction(InteractionRecord interaction) async {
    final interactions = await getAllInteractions();
    interactions.add(interaction);
    await saveAllInteractions(interactions);

    // 更新联系人的最近联系时间
    final contact = await getContact(interaction.contactId);
    if (contact != null) {
      final updatedContact = contact.copyWith(
        lastContactTime: interaction.date,
      );
      await updateContact(updatedContact);
    }

    return interaction;
  }

  // 删除交互记录
  Future<void> deleteInteraction(String id) async {
    final interactions = await getAllInteractions();
    interactions.removeWhere((i) => i.id == id);
    await saveAllInteractions(interactions);
  }

  // 根据联系人ID删除所有交互记录
  Future<void> deleteInteractionsByContactId(String contactId) async {
    final interactions = await getAllInteractions();
    interactions.removeWhere((i) => i.contactId == contactId);
    await saveAllInteractions(interactions);
  }

  // 获取联系人的所有交互记录
  Future<List<InteractionRecord>> getInteractionsByContactId(String contactId) async {
    final interactions = await getAllInteractions();
    return interactions.where((i) => i.contactId == contactId).toList();
  }

  // 保存筛选配置
  Future<void> saveFilterConfig(FilterConfig config) async {
    _filterConfigCache = config;
    final storage = plugin.storage;
    await storage.writeJson(filterConfigKey, config.toJson());
  }

  // 获取筛选配置
  Future<FilterConfig> getFilterConfig() async {
    if (_filterConfigCache != null) {
      return _filterConfigCache!;
    }

    final storage = plugin.storage;
    try {
      final configJson = await storage.readJson(filterConfigKey);
      if (configJson == null) {
        final defaultConfig = FilterConfig();
        _filterConfigCache = defaultConfig;
        await storage.writeJson(filterConfigKey, defaultConfig.toJson());
        return defaultConfig;
      }
      _filterConfigCache = FilterConfig.fromJson(configJson);
      return _filterConfigCache!;
    } catch (e) {
      if (e.toString().contains('FileSystemException: 文件不存在')) {
        final defaultConfig = FilterConfig();
        _filterConfigCache = defaultConfig;
        await storage.writeJson(filterConfigKey, defaultConfig.toJson());
        return defaultConfig;
      }
      rethrow;
    }
  }

  // 保存排序配置
  Future<void> saveSortConfig(SortConfig config) async {
    _sortConfigCache = config;
    final storage = plugin.storage;
    await storage.writeJson(sortConfigKey, config.toJson());
  }

  // 获取排序配置
  Future<SortConfig> getSortConfig() async {
    if (_sortConfigCache != null) {
      return _sortConfigCache!;
    }

    final storage = plugin.storage;
    try {
      final configJson = await storage.readJson(sortConfigKey);
      if (configJson == null) {
        final defaultConfig = const SortConfig();
        _sortConfigCache = defaultConfig;
        await storage.writeJson(sortConfigKey, defaultConfig.toJson());
        return defaultConfig;
      }
      _sortConfigCache = SortConfig.fromJson(configJson);
      return _sortConfigCache!;
    } catch (e) {
      if (e.toString().contains('FileSystemException: 文件不存在')) {
        final defaultConfig = const SortConfig();
        _sortConfigCache = defaultConfig;
        await storage.writeJson(sortConfigKey, defaultConfig.toJson());
        return defaultConfig;
      }
      rethrow;
    }
  }

  // 应用筛选和排序
  Future<List<Contact>> getFilteredAndSortedContacts() async {
    final contacts = await getAllContacts();
    final filterConfig = await getFilterConfig();
    final sortConfig = await getSortConfig();

    // 应用筛选
    var filteredContacts = contacts.where((contact) {
      // 名称关键词筛选
      if (filterConfig.nameKeyword != null &&
          filterConfig.nameKeyword!.isNotEmpty &&
          !contact.name.toLowerCase().contains(filterConfig.nameKeyword!.toLowerCase())) {
        return false;
      }

      // 创建日期范围筛选
      if (filterConfig.startDate != null &&
          contact.createdTime.isBefore(filterConfig.startDate!)) {
        return false;
      }
      if (filterConfig.endDate != null &&
          contact.createdTime.isAfter(filterConfig.endDate!.add(const Duration(days: 1)))) {
        return false;
      }

      // 未联系天数筛选
      if (filterConfig.uncontactedDays != null) {
        final daysSinceLastContact =
            DateTime.now().difference(contact.lastContactTime).inDays;
        if (daysSinceLastContact < filterConfig.uncontactedDays!) {
          return false;
        }
      }

      // 标签筛选
      if (filterConfig.selectedTags.isNotEmpty &&
          !filterConfig.selectedTags.any((tag) => contact.tags.contains(tag))) {
        return false;
      }

      return true;
    }).toList();

      // 应用排序
      filteredContacts.sort((a, b) {
        int compareResult;
        switch (sortConfig.type) {
          case SortType.name:
            compareResult = a.name.compareTo(b.name);
            break;
          case SortType.createdTime:
            compareResult = a.createdTime.compareTo(b.createdTime);
            break;
          case SortType.lastContactTime:
            compareResult = a.lastContactTime.compareTo(b.lastContactTime);
            break;
          case SortType.contactCount:
            // 获取联系记录数量进行比较
            compareResult = 0; // 默认值
            getInteractionsByContactId(a.id).then((aInteractions) {
              getInteractionsByContactId(b.id).then((bInteractions) {
                compareResult = aInteractions.length.compareTo(bInteractions.length);
              });
            });
            break;
        }

        return sortConfig.isReverse ? -compareResult : compareResult;
      });

    return filteredContacts;
  }

  // 获取所有标签
  Future<List<String>> getAllTags() async {
    final contacts = await getAllContacts();
    final Set<String> tags = {};
    for (final contact in contacts) {
      tags.addAll(contact.tags);
    }
    return tags.toList();
  }

  // 获取最近一个月内联系的人数
  Future<int> getRecentlyContactedCount() async {
    final contacts = await getAllContacts();
    final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));
    return contacts.where((c) => c.lastContactTime.isAfter(oneMonthAgo)).length;
  }
  
  // 获取联系人的联系记录数量
  Future<int> getContactInteractionsCount(String contactId) async {
    final interactions = await getInteractionsByContactId(contactId);
    return interactions.length;
  }

  // 创建默认联系人数据
  Future<void> createDefaultContacts() async {
    if (_contactsCache != null && _contactsCache!.isNotEmpty) return;
      final uuid = const Uuid();
      
      // 添加一些默认联系人
      final defaultContacts = [
        Contact(
          id: uuid.v4(),
          name: '张三',
          icon: Icons.person,
          iconColor: Colors.blue,
          phone: '13800138000',
          address: '北京市海淀区',
          tags: ['家人'],
          customFields: {'公司': '北京科技有限公司'},
        ),
        Contact(
          id: uuid.v4(),
          name: '李四',
          icon: Icons.work,
          iconColor: Colors.green,
          phone: '13900139000',
          address: '上海市浦东新区',
          tags: ['同事', '朋友'],
          customFields: {'职位': '技术总监'},
        ),
      ];
      
      _contactsCache = defaultContacts;
      _hasContactsChanges = true;
      await _saveContactsToStorage();
      
      // 创建一些默认交互记录
      final defaultInteractions = [
        InteractionRecord(
          id: uuid.v4(),
          contactId: defaultContacts[0].id,
          date: DateTime.now().subtract(const Duration(days: 5)),
          notes: '讨论了项目进度',
          participants: [],
        ),
        InteractionRecord(
          id: uuid.v4(),
          contactId: defaultContacts[1].id,
          date: DateTime.now().subtract(const Duration(days: 2)),
          notes: '电话讨论了合作事宜',
          participants: [defaultContacts[0].id],
        ),
      ];
      
      _interactionsCache = defaultInteractions;
      _hasInteractionsChanges = true;
      await _saveInteractionsToStorage();
  }

  // 在应用退出前保存所有更改
  Future<void> saveAllChanges() async {
    await _saveContactsToStorage();
    await _saveInteractionsToStorage();
  }
}