import 'package:flutter/material.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/screens/routing/route_definition.dart';
import 'package:Memento/screens/routing/route_helpers.dart';
import 'package:Memento/plugins/contact/contact_plugin.dart';
import 'package:Memento/plugins/contact/widgets/contact_form.dart';
import 'package:Memento/plugins/contact/models/contact_model.dart';
import 'package:get/get.dart';

/// Contact 插件路由注册表
class ContactRoutes implements RouteRegistry {
  @override
  String get name => 'ContactRoutes';

  @override
  List<RouteDefinition> get routes => [
        // Contact 主页面（已在 plugin_common_routes.dart 中定义，此处只定义详情页）

        // 联系人详情页（从小组件打开）
        RouteDefinition(
          path: '/contact/detail',
          handler: (settings) {
            String? contactId;
            if (settings.arguments is Map<String, dynamic>) {
              contactId = (settings.arguments as Map<String, dynamic>)['contactId'] as String?;
            }

            if (contactId != null && contactId.isNotEmpty) {
              return RouteHelpers.createRoute(
                _ContactDetailLoader(contactId: contactId),
              );
            }
            return RouteHelpers.createRoute(const ContactMainView());
          },
          description: '联系人详情页',
        ),
        RouteDefinition(
          path: 'contact/detail',
          handler: (settings) {
            String? contactId;
            if (settings.arguments is Map<String, dynamic>) {
              contactId = (settings.arguments as Map<String, dynamic>)['contactId'] as String?;
            }

            if (contactId != null && contactId.isNotEmpty) {
              return RouteHelpers.createRoute(
                _ContactDetailLoader(contactId: contactId),
              );
            }
            return RouteHelpers.createRoute(const ContactMainView());
          },
          description: '联系人详情页（别名）',
        ),
      ];
}

/// 联系人详情页加载器
class _ContactDetailLoader extends StatelessWidget {
  final String contactId;

  const _ContactDetailLoader({required this.contactId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ContactPlugin?>(
      future: _loadContactPlugin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final plugin = snapshot.data;
        if (plugin == null) {
          return Scaffold(
            body: Center(
              child: Text('contact_pluginNotFound'.tr),
            ),
          );
        }

        return FutureBuilder<Contact?>(
          future: plugin.controller.getContact(contactId),
          builder: (context, contactSnapshot) {
            if (contactSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final contact = contactSnapshot.data;
            if (contact == null) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text('contact_notFound'.tr),
                    ],
                  ),
                ),
              );
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => ContactForm(
                    contact: contact,
                    onSave: (savedContact) async {
                      await plugin.controller.updateContact(savedContact);
                    },
                  ),
                ),
              );
            });

            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          },
        );
      },
    );
  }

  Future<ContactPlugin?> _loadContactPlugin() async {
    return PluginManager.instance.getPlugin('contact') as ContactPlugin?;
  }
}
