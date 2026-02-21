/// 联系人插件 - 公共小组件数据提供者
library;

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/contact/contact_plugin.dart';
import 'package:Memento/plugins/contact/models/contact_model.dart';

/// 提供公共小组件的数据
class ContactCommandWidgetsProvider {
  /// 获取联系人卡片数据（仅用于 contact_person 小组件）
  static Future<Map<String, Map<String, dynamic>>> provideContactCardData(
    String contactId,
  ) async {
    final plugin = PluginManager.instance.getPlugin('contact') as ContactPlugin?;
    if (plugin == null) return {};

    final contacts = await plugin.controller.getAllContacts();

    return {
      'contactCard': await _buildContactCardData(plugin.controller, contactId, contacts),
    };
  }

  /// 获取最近联系人卡片数据（仅用于 contact_recent 小组件）
  static Future<Map<String, Map<String, dynamic>>> provideRecentContactCardData() async {
    final plugin = PluginManager.instance.getPlugin('contact') as ContactPlugin?;
    if (plugin == null) return {};

    final contacts = await plugin.controller.getAllContacts();

    return {
      'recentContactCard': await _buildRecentContactCardData(contacts),
    };
  }

  /// 构建联系人卡片数据
  static Future<Map<String, dynamic>> _buildContactCardData(
    dynamic controller,
    String contactId,
    List<Contact> contacts,
  ) async {
    if (contactId.isEmpty) {
      // 如果没有联系人 ID，返回空数据
      return {};
    }

    // 尝试从预加载的联系人列表中查找
    Contact? contact;
    try {
      // 先从列表中查找（避免额外的异步调用）
      for (final c in contacts) {
        if (c.id == contactId) {
          contact = c;
          break;
        }
      }
    } catch (e) {
      debugPrint('获取联系人失败: $e');
    }

    if (contact == null) {
      return {};
    }

    return {
      'id': contact.id,
      'name': contact.name,
      'phone': contact.phone,
      'lastContactTime': formatLastContactTime(contact.lastContactTime),
      'hasAvatar': contact.avatar != null && contact.avatar!.isNotEmpty,
      'icon': contact.icon.codePoint,
      'iconColor': contact.iconColor.value,
      'tags': contact.tags,
    };
  }

  /// 构建最近联系人卡片数据
  static Future<Map<String, dynamic>> _buildRecentContactCardData(
    List<Contact> contacts,
  ) async {
    // 按最后联系时间降序排序，取前5个
    final sortedContacts = List<Contact>.from(contacts)
      ..sort((a, b) => b.lastContactTime.compareTo(a.lastContactTime));

    final recentContacts = sortedContacts.take(5).toList();

    final contactItems = recentContacts.map((c) {
      return {
        'id': c.id,
        'name': c.name,
        'phone': c.phone,
        'lastContactTime': formatLastContactTime(c.lastContactTime),
        'hasAvatar': c.avatar != null && c.avatar!.isNotEmpty,
        'icon': c.icon.codePoint,
        'iconColor': c.iconColor.value,
      };
    }).toList();

    return {
      'contactCount': contacts.length,
      'label': 'contact_recentContacts'.tr,
      'contacts': contactItems,
      'moreCount': contacts.length > 5 ? contacts.length - 5 : 0,
    };
  }

  /// 格式化最后联系时间
  static String formatLastContactTime(DateTime lastContactTime) {
    final now = DateTime.now();
    final difference = now.difference(lastContactTime);

    if (difference.inDays == 0) {
      return 'contact_today'.tr;
    } else if (difference.inDays == 1) {
      return 'contact_yesterday'.tr;
    } else if (difference.inDays < 7) {
      return 'contact_daysAgo'.trParams({'days': '${difference.inDays}'});
    } else {
      return '${difference.inDays}d';
    }
  }
}
