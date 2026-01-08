import 'package:flutter/material.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/screens/routing/route_definition.dart';
import 'package:Memento/screens/routing/route_helpers.dart';
import 'package:Memento/plugins/notes/screens/notes_screen.dart';
import 'package:Memento/plugins/notes/screens/note_edit_screen.dart';
import 'package:Memento/plugins/notes/notes_plugin.dart';
import 'package:get/get.dart';

/// Notes 插件路由注册表
class NotesRoutes implements RouteRegistry {
  @override
  String get name => 'NotesRoutes';

  @override
  List<RouteDefinition> get routes => [
        // Notes 主页面
        RouteDefinition(
          path: '/notes',
          handler: (settings) => RouteHelpers.createRoute(const NotesMainView()),
          description: '笔记主页面',
        ),
        RouteDefinition(
          path: 'notes',
          handler: (settings) => RouteHelpers.createRoute(const NotesMainView()),
          description: '笔记主页面（别名）',
        ),

        // 快速创建笔记页面
        RouteDefinition(
          path: '/notes/create',
          handler: (settings) {
            String? folderId;
            if (settings.arguments is Map<String, dynamic>) {
              folderId = (settings.arguments as Map<String, dynamic>)['folderId'] as String?;
            }
            return RouteHelpers.createRoute(
              NoteEditScreen(
                onSave: (title, content) async {
                  final plugin = PluginManager.instance.getPlugin('notes') as NotesPlugin?;
                  if (plugin != null) {
                    await plugin.controller.createNote(
                      title.isEmpty ? 'untitled'.tr : title,
                      content,
                      folderId ?? 'root',
                    );
                  }
                },
              ),
            );
          },
          description: '快速创建笔记页面',
        ),
        RouteDefinition(
          path: 'notes/create',
          handler: (settings) {
            String? folderId;
            if (settings.arguments is Map<String, dynamic>) {
              folderId = (settings.arguments as Map<String, dynamic>)['folderId'] as String?;
            }
            return RouteHelpers.createRoute(
              NoteEditScreen(
                onSave: (title, content) async {
                  final plugin = PluginManager.instance.getPlugin('notes') as NotesPlugin?;
                  if (plugin != null) {
                    await plugin.controller.createNote(
                      title.isEmpty ? 'untitled'.tr : title,
                      content,
                      folderId ?? 'root',
                    );
                  }
                },
              ),
            );
          },
          description: '快速创建笔记页面（别名）',
        ),
      ];
}
