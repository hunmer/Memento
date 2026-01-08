import 'package:Memento/screens/routing/route_definition.dart';
import 'package:Memento/screens/routing/route_helpers.dart';
import 'package:Memento/plugins/todo/views/todo_bottombar_view.dart';

/// Todo 插件路由注册表
class TodoRoutes implements RouteRegistry {
  @override
  String get name => 'TodoRoutes';

  @override
  List<RouteDefinition> get routes => [
        // Todo 主页面
        RouteDefinition(
          path: '/todo',
          handler: (settings) => RouteHelpers.createRoute(const TodoBottomBarView()),
          description: '待办事项主页面',
        ),
        RouteDefinition(
          path: 'todo',
          handler: (settings) => RouteHelpers.createRoute(const TodoBottomBarView()),
          description: '待办事项主页面（别名）',
        ),

        // Todo 子路由由 TodoRouteHandler 处理
        // /todo_list_selector, /todo_task_detail, /todo_add 等由 TodoRouteHandler 处理
      ];
}
