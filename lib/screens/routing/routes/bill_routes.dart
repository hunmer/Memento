import 'package:flutter/material.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/screens/routing/route_definition.dart';
import 'package:Memento/screens/routing/route_helpers.dart';
import 'package:Memento/plugins/bill/bill_plugin.dart';
import 'package:Memento/plugins/bill/screens/bill_edit_screen.dart';
import 'package:Memento/plugins/bill/screens/bill_shortcuts_selector_screen.dart';

/// Bill 插件路由注册表
class BillRoutes implements RouteRegistry {
  @override
  String get name => 'BillRoutes';

  @override
  List<RouteDefinition> get routes => [
        // Bill 主页面
        RouteDefinition(
          path: '/bill',
          handler: (settings) {
            debugPrint('[Route] ========== /bill 路由开始 ==========');
            debugPrint('[Route] settings.name: ${settings.name}');
            debugPrint('[Route] settings.arguments: ${settings.arguments}');
            debugPrint('[Route] 参数类型: ${settings.arguments?.runtimeType}');

            final billPlugin = PluginManager.instance.getPlugin('bill') as BillPlugin?;

            if (billPlugin == null) {
              debugPrint('[Route] BillPlugin 未初始化，回退到主视图');
              return RouteHelpers.createRoute(const BillMainView(), settings: settings);
            }

            if (settings.arguments != null) {
              debugPrint('[Route] 开始解析参数...');
              Map<String, dynamic> args;
              try {
                args = Map<String, dynamic>.from(settings.arguments as Map);
              } catch (e) {
                debugPrint('[Route] 参数转换失败: $e，使用空 Map');
                args = {};
              }

              debugPrint('[Route] 解析后的参数: $args');

              // 1. 检查是否是创建账单动作（来自创建账单快捷入口小组件）
              if (args['action'] == 'create') {
                debugPrint('[Route] 检测到 action=create，开始创建账单');
                final String? accountId = args['accountId'] as String?;
                final bool? isExpense = args['isExpense'] != null
                    ? (args['isExpense'].toString().toLowerCase() == 'true')
                    : null;

                debugPrint('[Route] accountId: $accountId, isExpense: $isExpense');

                final finalAccountId = accountId ??
                    (billPlugin.selectedAccount?.id ??
                     (billPlugin.accounts.isNotEmpty ? billPlugin.accounts.first.id : ''));

                if (finalAccountId.isEmpty) {
                  debugPrint('[Route] 没有可用账户，回退到主视图');
                  return RouteHelpers.createRoute(const BillMainView(), settings: settings);
                }

                debugPrint('[Route] 打开 BillEditScreen，accountId: $finalAccountId');
                return RouteHelpers.createRoute(
                  BillEditScreen(
                    billPlugin: billPlugin,
                    accountId: finalAccountId,
                    initialIsExpense: isExpense,
                  ),
                  settings: settings,
                );
              }

              // 2. 检查是否来自快捷记账小组件（带有预填充参数）
              if (args.containsKey('category')) {
                debugPrint('[Route] 检测到 category 参数');
                final String? accountId = args['accountId'] as String?;
                final String? category = args['category'] as String?;
                final double? amount = args['amount'] != null
                    ? double.tryParse(args['amount'].toString())
                    : null;
                final bool? isExpense = args['isExpense'] != null
                    ? (args['isExpense'].toString().toLowerCase() == 'true')
                    : null;

                if (accountId == null || accountId.isEmpty) {
                  debugPrint('[Route] 缺少 accountId 参数，回退到主视图');
                  return RouteHelpers.createRoute(const BillMainView(), settings: settings);
                }

                return RouteHelpers.createRoute(
                  BillEditScreen(
                    billPlugin: billPlugin,
                    accountId: accountId,
                    initialCategory: category,
                    initialAmount: amount,
                    initialIsExpense: isExpense,
                  ),
                  settings: settings,
                );
              }

              debugPrint('[Route] 未匹配任何特殊参数，打开默认视图');
            }

            debugPrint('[Route] 打开 BillMainView');
            return RouteHelpers.createRoute(const BillMainView(), settings: settings);
          },
          description: '账单主页面',
        ),
        RouteDefinition(
          path: 'bill',
          handler: (settings) {
            debugPrint('[Route] ========== /bill 路由开始 ==========');
            debugPrint('[Route] settings.name: ${settings.name}');
            debugPrint('[Route] settings.arguments: ${settings.arguments}');
            debugPrint('[Route] 参数类型: ${settings.arguments?.runtimeType}');

            final billPlugin = PluginManager.instance.getPlugin('bill') as BillPlugin?;

            if (billPlugin == null) {
              debugPrint('[Route] BillPlugin 未初始化，回退到主视图');
              return RouteHelpers.createRoute(const BillMainView(), settings: settings);
            }

            if (settings.arguments != null) {
              debugPrint('[Route] 开始解析参数...');
              Map<String, dynamic> args;
              try {
                args = Map<String, dynamic>.from(settings.arguments as Map);
              } catch (e) {
                debugPrint('[Route] 参数转换失败: $e，使用空 Map');
                args = {};
              }

              debugPrint('[Route] 解析后的参数: $args');

              if (args['action'] == 'create') {
                debugPrint('[Route] 检测到 action=create，开始创建账单');
                final String? accountId = args['accountId'] as String?;
                final bool? isExpense = args['isExpense'] != null
                    ? (args['isExpense'].toString().toLowerCase() == 'true')
                    : null;

                debugPrint('[Route] accountId: $accountId, isExpense: $isExpense');

                final finalAccountId = accountId ??
                    (billPlugin.selectedAccount?.id ??
                     (billPlugin.accounts.isNotEmpty ? billPlugin.accounts.first.id : ''));

                if (finalAccountId.isEmpty) {
                  debugPrint('[Route] 没有可用账户，回退到主视图');
                  return RouteHelpers.createRoute(const BillMainView(), settings: settings);
                }

                debugPrint('[Route] 打开 BillEditScreen，accountId: $finalAccountId');
                return RouteHelpers.createRoute(
                  BillEditScreen(
                    billPlugin: billPlugin,
                    accountId: finalAccountId,
                    initialIsExpense: isExpense,
                  ),
                  settings: settings,
                );
              }

              if (args.containsKey('category')) {
                debugPrint('[Route] 检测到 category 参数');
                final String? accountId = args['accountId'] as String?;
                final String? category = args['category'] as String?;
                final double? amount = args['amount'] != null
                    ? double.tryParse(args['amount'].toString())
                    : null;
                final bool? isExpense = args['isExpense'] != null
                    ? (args['isExpense'].toString().toLowerCase() == 'true')
                    : null;

                if (accountId == null || accountId.isEmpty) {
                  debugPrint('[Route] 缺少 accountId 参数，回退到主视图');
                  return RouteHelpers.createRoute(const BillMainView(), settings: settings);
                }

                return RouteHelpers.createRoute(
                  BillEditScreen(
                    billPlugin: billPlugin,
                    accountId: accountId,
                    initialCategory: category,
                    initialAmount: amount,
                    initialIsExpense: isExpense,
                  ),
                  settings: settings,
                );
              }

              debugPrint('[Route] 未匹配任何特殊参数，打开默认视图');
            }

            debugPrint('[Route] 打开 BillMainView');
            return RouteHelpers.createRoute(const BillMainView(), settings: settings);
          },
          description: '账单主页面（别名）',
        ),

        // 快捷记账小组件配置界面
        RouteDefinition(
          path: '/bill_shortcuts_selector',
          handler: (settings) {
            int? billShortcutsWidgetId;

            if (settings.arguments is Map<String, dynamic>) {
              final args = settings.arguments as Map<String, dynamic>;
              final widgetIdValue = args['widgetId'];
              if (widgetIdValue is int) {
                billShortcutsWidgetId = widgetIdValue;
              } else if (widgetIdValue is String) {
                billShortcutsWidgetId = int.tryParse(widgetIdValue);
              }
            } else if (settings.arguments is int) {
              billShortcutsWidgetId = settings.arguments as int;
            }

            return RouteHelpers.createRoute(
              BillShortcutsSelectorScreen(widgetId: billShortcutsWidgetId ?? 0),
            );
          },
          description: '快捷记账小组件配置界面',
        ),
        RouteDefinition(
          path: 'bill_shortcuts_selector',
          handler: (settings) {
            int? billShortcutsWidgetId;

            if (settings.arguments is Map<String, dynamic>) {
              final args = settings.arguments as Map<String, dynamic>;
              final widgetIdValue = args['widgetId'];
              if (widgetIdValue is int) {
                billShortcutsWidgetId = widgetIdValue;
              } else if (widgetIdValue is String) {
                billShortcutsWidgetId = int.tryParse(widgetIdValue);
              }
            } else if (settings.arguments is int) {
              billShortcutsWidgetId = settings.arguments as int;
            }

            return RouteHelpers.createRoute(
              BillShortcutsSelectorScreen(widgetId: billShortcutsWidgetId ?? 0),
            );
          },
          description: '快捷记账小组件配置界面（别名）',
        ),
      ];
}
