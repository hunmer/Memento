import 'package:flutter/material.dart';
import '../models/contact_model.dart';
import '../models/interaction_record_model.dart';
import '../models/filter_sort_config.dart';
import '../../base_plugin.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;

class ContactController {
  final BasePlugin plugin;
  late final String contactsKey;
  late final String interactionsKey;
  late final String filterConfigKey;
  late final String sortConfigKey;

  // 使用平台特定的路径分隔符
  String _normalizePath(String filePath) {
    return filePath.replaceAll('/', path.separator);
  }

  ContactController(this.plugin) {
    // 初始化时规范化所有路径
    contactsKey = _normalizePath('contacts${path.separator}contacts.json');
    interactionsKey = _normalizePath('contacts${path.separator}interactions');
    filterConfigKey = _normalizePath('contacts${path.separator}filter_config');
    sortConfigKey = _normalizePath('contacts${path.separator}sort_config');
  }

  // 获取所有联系人
  Future<List<Contact>> getAllContacts() async {
    final storage = plugin.storage;
    try {
      final dynamic rawData = await storage.readJson(contactsKey);

      // 处理数据不存在或为空的情况
      if (rawData == null) return [];

      // 处理不同数据格式
      if (rawData is List) {
        // 列表格式处理
        return rawData.map<Contact>((json) {
          if (json is! Map) return Contact.empty();
          return Contact.fromJson(json);
        }).toList();
      } else if (rawData is Map) {
        // Map格式处理 - 转换为List
        return rawData.values.map<Contact>((json) {
          if (json is! Map) return Contact.empty();
          return Contact.fromJson(json);
        }).toList();
      } else {
        // 其他格式返回空列表
        return [];
      }
    } catch (e) {
      // 所有异常情况都返回空列表
      return [];
    }
  }

  // 保存所有联系人
  Future<void> saveAllContacts(List<Contact> contacts) async {
    final storage = plugin.storage;
    final List<Map<String, dynamic>> jsonData =
        contacts.map((c) => c.toJson()).toList();
    await storage.writeJson(contactsKey, jsonData);
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
    for (final contact in contacts) {
      if (contact.id == id) {
        return contact;
      }
    }
    return null;
  }

  // 获取所有交互记录
  Future<List<InteractionRecord>> getAllInteractions() async {
    final storage = plugin.storage;
    try {
      final dynamic rawData = await storage.readJson(interactionsKey);
      if (rawData == null) {
        return [];
      }

      // 处理不同数据格式
      List<dynamic> interactionsList;
      if (rawData is List) {
        interactionsList = rawData;
      } else if (rawData is Map) {
        // 如果是Map格式，转换为List
        interactionsList = rawData.values.toList();
      } else {
        // 其他格式返回空列表
        return [];
      }

      // 验证并转换数据
      return interactionsList.map<InteractionRecord>((item) {
        try {
          if (item is Map) {
            return InteractionRecord.fromJson(Map<String, dynamic>.from(item));
          }
          return InteractionRecord.empty();
        } catch (_) {
          return InteractionRecord.empty();
        }
      }).toList();
    } catch (e) {
      if (e.toString().contains('FileSystemException: 文件不存在')) {
        return [];
      }
      return []; // 其他异常也返回空列表而不是抛出异常
    }
  }

  // 保存所有交互记录
  Future<void> saveAllInteractions(List<InteractionRecord> interactions) async {
    final storage = plugin.storage;
    await storage.writeJson(
      interactionsKey,
      interactions.map((i) => i.toJson()).toList(),
    );
  }

  // 添加交互记录
  Future<InteractionRecord> addInteraction(
    InteractionRecord interaction,
  ) async {
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
  Future<List<InteractionRecord>> getInteractionsByContactId(
    String contactId,
  ) async {
    final interactions = await getAllInteractions();
    return interactions.where((i) => i.contactId == contactId).toList();
  }

  // 保存筛选配置
  Future<void> saveFilterConfig(FilterConfig config) async {
    final storage = plugin.storage;
    await storage.writeJson(filterConfigKey, config.toJson());
  }

  // 获取筛选配置
  Future<FilterConfig> getFilterConfig() async {
    final storage = plugin.storage;
    try {
      final configJson = await storage.readJson(filterConfigKey);
      if (configJson == null) {
        final defaultConfig = FilterConfig();
        await storage.writeJson(filterConfigKey, defaultConfig.toJson());
        return defaultConfig;
      }
      return FilterConfig.fromJson(Map<String, dynamic>.from(configJson));
    } catch (e) {
      if (e.toString().contains('FileSystemException: 文件不存在')) {
        final defaultConfig = FilterConfig();
        await storage.writeJson(filterConfigKey, defaultConfig.toJson());
        return defaultConfig;
      }
      rethrow;
    }
  }

  // 保存排序配置
  Future<void> saveSortConfig(SortConfig config) async {
    final storage = plugin.storage;
    await storage.writeJson(sortConfigKey, config.toJson());
  }

  // 获取排序配置
  Future<SortConfig> getSortConfig() async {
    final storage = plugin.storage;
    try {
      final configJson = await storage.readJson(sortConfigKey);
      if (configJson == null) {
        final defaultConfig = const SortConfig();
        await storage.writeJson(sortConfigKey, defaultConfig.toJson());
        return defaultConfig;
      }
      return SortConfig.fromJson(Map<String, dynamic>.from(configJson));
    } catch (e) {
      if (e.toString().contains('FileSystemException: 文件不存在')) {
        final defaultConfig = const SortConfig();
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
    var filteredContacts =
        contacts.where((contact) {
          // 名称关键词筛选
          if (filterConfig.nameKeyword != null &&
              filterConfig.nameKeyword!.isNotEmpty &&
              !contact.name.toLowerCase().contains(
                filterConfig.nameKeyword!.toLowerCase(),
              )) {
            return false;
          }

          // 创建日期范围筛选
          if (filterConfig.startDate != null &&
              contact.createdTime.isBefore(filterConfig.startDate!)) {
            return false;
          }
          if (filterConfig.endDate != null &&
              contact.createdTime.isAfter(
                filterConfig.endDate!.add(const Duration(days: 1)),
              )) {
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
              !filterConfig.selectedTags.any(
                (tag) => contact.tags.contains(tag),
              )) {
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
              compareResult = aInteractions.length.compareTo(
                bInteractions.length,
              );
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
    final storage = plugin.storage;
    final uuid = const Uuid();

    // 检查是否已有联系人数据
    final existingContacts = await storage.readJson(contactsKey);
    if (existingContacts != null &&
        existingContacts is List &&
        existingContacts.isNotEmpty) {
      return;
    }

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

    // 保存默认联系人
    await storage.writeJson(
      contactsKey,
      defaultContacts.map((c) => c.toJson()).toList(),
    );

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

    // 保存默认交互记录
    await storage.writeJson(
      interactionsKey,
      defaultInteractions.map((i) => i.toJson()).toList(),
    );
  }

  // 在应用退出前保存所有更改
  Future<void> saveAllChanges() async {
    // 由于现在每次修改都直接保存，此方法可以保留为空
    // 或者可以添加其他需要在退出时执行的操作
  }
}
