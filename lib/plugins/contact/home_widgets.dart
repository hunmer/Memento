import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_selector_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'package:Memento/utils/image_utils.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'contact_plugin.dart';
import 'models/contact_model.dart';

/// 联系人插件的主页小组件注册
class ContactHomeWidgets {
  /// 注册所有联系人插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(
      HomeWidget(
        id: 'contact_icon',
        pluginId: 'contact',
        name: 'contact_widgetName'.tr,
        description: 'contact_widgetDescription'.tr,
        icon: Icons.contacts,
        color: Colors.deepPurple,
        defaultSize: HomeWidgetSize.small,
        supportedSizes: [HomeWidgetSize.small],
        category: 'home_categoryTools'.tr,
        builder:
            (context, config) => GenericIconWidget(
              icon: Icons.contacts,
              color: Colors.deepPurple,
              name: 'contact_widgetName'.tr,
            ),
      ),
    );

    // 2x2 详细卡片 - 显示统计信息
    registry.register(
      HomeWidget(
        id: 'contact_overview',
        pluginId: 'contact',
        name: 'contact_overviewName'.tr,
        description: 'contact_overviewDescription'.tr,
        icon: Icons.people,
        color: Colors.deepPurple,
        defaultSize: HomeWidgetSize.large,
        supportedSizes: [HomeWidgetSize.large],
        category: 'home_categoryTools'.tr,
        builder: (context, config) => _buildOverviewWidget(context, config),
        availableStatsProvider: _getAvailableStats,
      ),
    );

    // 2x1 联系人卡片 - 选择一个联系人显示
    registry.register(
      HomeWidget(
        id: 'contact_person',
        pluginId: 'contact',
        name: 'contact_personCardName'.tr,
        description: 'contact_personCardDescription'.tr,
        icon: Icons.person,
        color: Colors.deepPurple,
        defaultSize: HomeWidgetSize.medium,
        supportedSizes: [HomeWidgetSize.medium],
        category: 'home_categoryTools'.tr,

        // 选择器配置
        selectorId: 'contact.person',
        dataRenderer: _renderPersonCard,
        navigationHandler: _navigateToContactDetail,
        dataSelector: (dataArray) {
          // 从 Contact.toJson() 的 Map 中提取需要保存的字段
          final contactJson = dataArray[0] as Map<String, dynamic>;
          return {
            'id': contactJson['id'] as String,
            'title': contactJson['name'] as String?, // 联系人名称
            'phone': contactJson['phone'] as String?, // 电话号码
          };
        },

        builder: (context, config) {
          return GenericSelectorWidget(
            widgetDefinition: registry.getWidget('contact_person')!,
            config: config,
          );
        },
      ),
    );
  }

  /// 获取可用的统计项
  /// 返回联系人插件支持的所有统计项类型定义
  /// 实际数据值由 _buildOverviewWidget 在 FutureBuilder 中异步获取并更新
  static List<StatItemData> _getAvailableStats(BuildContext context) {
    return [
      StatItemData(
        id: 'total_contacts',
        label: 'contact_totalContacts'.tr,
        value: '0', // 占位符，实际值由 _buildOverviewWidget 异步获取
        highlight: false,
      ),
      StatItemData(
        id: 'recent_contacts',
        label: 'contact_recentContacts'.tr,
        value: '0', // 占位符，实际值由 _buildOverviewWidget 异步获取
        highlight: false,
        color: Colors.green,
      ),
    ];
  }

  /// 构建 2x2 详细卡片组件
  static Widget _buildOverviewWidget(
    BuildContext context,
    Map<String, dynamic> config,
  ) {
    try {
      // 解析插件配置
      PluginWidgetConfig widgetConfig;
      try {
        if (config.containsKey('pluginWidgetConfig')) {
          widgetConfig = PluginWidgetConfig.fromJson(
            config['pluginWidgetConfig'] as Map<String, dynamic>,
          );
        } else {
          widgetConfig = PluginWidgetConfig();
        }
      } catch (e) {
        widgetConfig = PluginWidgetConfig();
      }

      // 异步加载实际的统计数据
      return FutureBuilder<List<StatItemData>>(
        future: _loadContactStats(context),
        builder: (context, snapshot) {
          final availableItems = snapshot.data ?? _getAvailableStats(context);

          // 使用通用小组件
          return GenericPluginWidget(
            pluginId: 'contact',
            pluginName: 'contact_name'.tr,
            pluginIcon: Icons.contacts,
            pluginDefaultColor: Colors.deepPurple,
            availableItems: availableItems,
            config: widgetConfig,
          );
        },
      );
    } catch (e) {
      return _buildErrorWidget(context, e.toString());
    }
  }

  /// 异步加载联系人统计数据
  static Future<List<StatItemData>> _loadContactStats(
    BuildContext context,
  ) async {
    try {
      final plugin =
          PluginManager.instance.getPlugin('contact') as ContactPlugin?;
      if (plugin == null) return _getAvailableStats(context);

      final controller = plugin.controller;
      final contacts = await controller.getAllContacts();
      final recentCount = await controller.getRecentlyContactedCount();

      return [
        StatItemData(
          id: 'total_contacts',
          label: 'contact_totalContacts'.tr,
          value: '${contacts.length}',
          highlight: false,
        ),
        StatItemData(
          id: 'recent_contacts',
          label: 'contact_recentContacts'.tr,
          value: '$recentCount',
          highlight: recentCount > 0,
          color: Colors.green,
        ),
      ];
    } catch (e) {
      return _getAvailableStats(context);
    }
  }

  /// 构建错误提示组件
  static Widget _buildErrorWidget(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 32, color: Colors.red),
          const SizedBox(height: 8),
          Text(
            'home_loadFailed'.tr,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  /// 渲染联系人卡片小组件
  static Widget _renderPersonCard(
    BuildContext context,
    SelectorResult result,
    Map<String, dynamic> config,
  ) {
    // 从初始化数据中获取联系人ID
    final savedData =
        result.data is Map
            ? Map<String, dynamic>.from(result.data as Map)
            : <String, dynamic>{};
    final contactId = savedData['id'] as String? ?? '';

    if (contactId.isEmpty) {
      return _buildContactNotFoundWidget(context, savedData);
    }

    // 使用 StatefulBuilder 和 EventListenerContainer 实现动态更新
    return StatefulBuilder(
      builder: (context, setState) {
        return EventListenerContainer(
          events: const ['contact_created'],
          onEvent: () => setState(() {}),
          child: _buildContactCardWidgetByLoad(context, contactId, savedData),
        );
      },
    );
  }

  /// 构建联系人卡片小组件（从 PluginManager 获取最新数据）
  static Widget _buildContactCardWidgetByLoad(
    BuildContext context,
    String contactId,
    Map<String, dynamic> savedData,
  ) {
    return FutureBuilder<Contact?>(
      future: _loadContactById(contactId),
      builder: (context, snapshot) {
        final contact = snapshot.data;

        if (contact == null) {
          // 如果联系人不存在，显示提示
          return _buildContactNotFoundWidget(context, savedData);
        }

        return SizedBox.expand(
          child: _buildContactCardWidget(context, contact),
        );
      },
    );
  }

  /// 从 controller 加载联系人数据（异步方法，保留用于其他可能的用途）
  static Future<Contact?> _loadContactById(String contactId) async {
    try {
      final plugin =
          PluginManager.instance.getPlugin('contact') as ContactPlugin?;
      if (plugin == null || contactId.isEmpty) return null;
      return await plugin.controller.getContact(contactId);
    } catch (e) {
      debugPrint('加载联系人失败: $e');
      return null;
    }
  }

  /// 构建联系人卡片小组件 UI
  static Widget _buildContactCardWidget(BuildContext context, Contact contact) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // 头像或图标
              _buildContactAvatar(contact, size: 48),
              const SizedBox(width: 12),
              // 联系人信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 名称
                    Text(
                      contact.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // 最后联系时间
                    Text(
                      _formatLastContactTime(contact.lastContactTime),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建联系人头像
  static Widget _buildContactAvatar(Contact contact, {required double size}) {
    if (contact.avatar != null && contact.avatar!.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: contact.iconColor.withOpacity(0.2),
        ),
        child: ClipOval(
          child: Image(
            image: ImageUtils.createImageProvider(contact.avatar),
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // 图片加载失败时显示默认图标
              return Icon(contact.icon, size: size * 0.5, color: contact.iconColor);
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              // 显示加载进度
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                ),
              );
            },
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: contact.iconColor,
      ),
      child: Icon(contact.icon, size: size * 0.5, color: Colors.white),
    );
  }

  /// 格式化最后联系时间
  static String _formatLastContactTime(DateTime lastContactTime) {
    final now = DateTime.now();
    final difference = now.difference(lastContactTime);

    if (difference.inDays == 0) {
      return 'contact_today'.tr;
    } else if (difference.inDays == 1) {
      return 'contact_yesterday'.tr;
    } else if (difference.inDays < 7) {
      return 'contact_daysAgo'.trParams({'days': '${difference.inDays}'});
    } else {
      return timeago.format(lastContactTime, locale: 'zh_CN');
    }
  }

  /// 构建联系人未找到提示组件
  static Widget _buildContactNotFoundWidget(
    BuildContext context,
    Map<String, dynamic> savedData,
  ) {
    final theme = Theme.of(context);
    final name = savedData['title'] as String? ?? 'contact_unknownContact'.tr;

    return SizedBox.expand(
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.person_off, size: 32, color: theme.colorScheme.error),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'contact_notFound'.tr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 导航到联系人详情页
  static void _navigateToContactDetail(
    BuildContext context,
    SelectorResult result,
  ) {
    final data =
        result.data is Map<String, dynamic>
            ? result.data as Map<String, dynamic>
            : {};
    final contactId = data['id'] as String?;

    if (contactId == null || contactId.isEmpty) {
      debugPrint('联系人 ID 为空，无法导航');
      return;
    }

    // 导航到联系人详情页
    // 使用路由传参，在 ContactMainView 或详情页中处理
    NavigationHelper.pushNamed(
      context,
      '/contact/detail',
      arguments: {'contactId': contactId},
    );
  }
}
