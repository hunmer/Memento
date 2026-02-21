/// 联系人插件 - 联系人卡片组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_selector_widget.dart';
import 'package:Memento/utils/image_utils.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import '../contact_plugin.dart';
import '../models/contact_model.dart';
import 'utils.dart';

/// 注册 2x1 联系人卡片 - 选择一个联系人显示
void registerPersonCardWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'contact_person',
      pluginId: 'contact',
      name: 'contact_personCardName'.tr,
      description: 'contact_personCardDescription'.tr,
      icon: Icons.person,
      color: Colors.deepPurple,
      defaultSize: const MediumSize(),
      supportedSizes: [const MediumSize()],
      category: 'home_categoryTools'.tr,
      selectorId: 'contact.person',
      dataRenderer: renderPersonCard,
      navigationHandler: navigateToContactDetail,
      dataSelector: (dataArray) {
        final contactJson = dataArray[0] as Map<String, dynamic>;
        return {
          'id': contactJson['id'] as String,
          'title': contactJson['name'] as String?,
          'phone': contactJson['phone'] as String?,
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

/// 渲染联系人卡片小组件
Widget renderPersonCard(
  BuildContext context,
  SelectorResult result,
  Map<String, dynamic> config,
) {
  final savedData = result.data is Map
      ? Map<String, dynamic>.from(result.data as Map)
      : <String, dynamic>{};
  final contactId = savedData['id'] as String? ?? '';

  if (contactId.isEmpty) {
    return buildContactNotFoundWidget(context, savedData);
  }

  return StatefulBuilder(
    builder: (context, setState) {
      return EventListenerContainer(
        events: const ['contact_created'],
        onEvent: () => setState(() {}),
        child: buildContactCardWidgetByLoad(context, contactId, savedData),
      );
    },
  );
}

/// 构建联系人卡片小组件（从 PluginManager 获取最新数据）
Widget buildContactCardWidgetByLoad(
  BuildContext context,
  String contactId,
  Map<String, dynamic> savedData,
) {
  return FutureBuilder<Contact?>(
    future: loadContactById(contactId),
    builder: (context, snapshot) {
      final contact = snapshot.data;

      if (contact == null) {
        return buildContactNotFoundWidget(context, savedData);
      }

      return SizedBox.expand(
        child: buildContactCardWidget(context, contact),
      );
    },
  );
}

/// 从 controller 加载联系人数据
Future<Contact?> loadContactById(String contactId) async {
  try {
    final plugin = PluginManager.instance.getPlugin('contact') as ContactPlugin?;
    if (plugin == null || contactId.isEmpty) return null;
    return await plugin.controller.getContact(contactId);
  } catch (e) {
    debugPrint('加载联系人失败: $e');
    return null;
  }
}

/// 构建联系人卡片小组件 UI
Widget buildContactCardWidget(BuildContext context, Contact contact) {
  final theme = Theme.of(context);

  return Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            buildContactAvatar(contact, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    contact.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatLastContactTime(contact.lastContactTime),
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
Widget buildContactAvatar(Contact contact, {required double size}) {
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
            return Icon(contact.icon, size: size * 0.5, color: contact.iconColor);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
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

/// 构建联系人未找到提示组件
Widget buildContactNotFoundWidget(
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
void navigateToContactDetail(
  BuildContext context,
  SelectorResult result,
) {
  final data = result.data is Map<String, dynamic>
      ? result.data as Map<String, dynamic>
      : {};
  final contactId = data['id'] as String?;

  if (contactId == null || contactId.isEmpty) {
    debugPrint('联系人 ID 为空，无法导航');
    return;
  }

  NavigationHelper.pushNamed(
    context,
    '/contact/detail',
    arguments: {'contactId': contactId},
  );
}
