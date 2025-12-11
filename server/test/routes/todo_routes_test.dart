import 'package:test/test.dart';
import 'package:memento_server/routes/plugin_routes/todo_routes.dart';

import '../test_helpers.dart';

void main() {
  late TestServices services;
  late TodoRoutes todoRoutes;

  setUpAll(() async {
    services = TestServices();
    await services.setUp();
    await services.registerAndLogin();
    await services.enableApi();
    todoRoutes = TodoRoutes(services.pluginDataService);
  });

  tearDownAll(() async {
    await services.tearDown();
  });

  group('Todo Routes', () {
    group('任务 CRUD', () {
      test('GET /tasks - 获取空任务列表', () async {
        final handler = services.createPluginHandler(todoRoutes.router);
        final request = services.createAuthenticatedRequest('GET', '/tasks');
        final response = await handler(request);

        expect(response.statusCode, equals(200));
        expect(await ResponseHelper.isSuccess(response), isTrue);
        final data = await ResponseHelper.getData(response);
        expect(data, isA<List>());
      });

      test('POST /tasks - 创建任务', () async {
        final handler = services.createPluginHandler(todoRoutes.router);
        final request = services.createAuthenticatedRequest(
          'POST',
          '/tasks',
          body: {
            'title': '完成 MCP 服务开发',
            'description': '编写 Node.js MCP 服务',
            'priority': 3,
            'dueDate': '2025-12-31',
            'tags': ['开发', '重要'],
          },
        );
        final response = await handler(request);

        expect(response.statusCode, equals(200));
        expect(await ResponseHelper.isSuccess(response), isTrue);
        final data = await ResponseHelper.getData(response);
        expect(data['title'], equals('完成 MCP 服务开发'));
        expect(data['priority'], equals(3));
        expect(data['completed'], isFalse);
        expect(data['id'], isNotNull);
      });

      test('PUT /tasks/:id - 更新任务', () async {
        final handler = services.createPluginHandler(todoRoutes.router);

        // 创建任务
        final createResponse = await handler(services.createAuthenticatedRequest(
          'POST',
          '/tasks',
          body: {'title': '原始任务', 'priority': 1},
        ));
        final createData = await ResponseHelper.getData(createResponse);
        final taskId = createData['id'] as String;

        // 更新任务
        final updateRequest = services.createAuthenticatedRequest(
          'PUT',
          '/tasks/$taskId',
          body: {'title': '更新后的任务', 'priority': 3},
        );
        final response = await handler(updateRequest);

        expect(response.statusCode, equals(200));
        final data = await ResponseHelper.getData(response);
        expect(data['title'], equals('更新后的任务'));
        expect(data['priority'], equals(3));
      });

      test('DELETE /tasks/:id - 删除任务', () async {
        final handler = services.createPluginHandler(todoRoutes.router);

        // 创建任务
        final createResponse = await handler(services.createAuthenticatedRequest(
          'POST',
          '/tasks',
          body: {'title': '待删除任务'},
        ));
        final createData = await ResponseHelper.getData(createResponse);
        final taskId = createData['id'] as String;

        // 删除任务
        final response = await handler(services.createAuthenticatedRequest(
          'DELETE',
          '/tasks/$taskId',
        ));

        expect(response.statusCode, equals(200));
        final data = await ResponseHelper.getData(response);
        expect(data['deleted'], isTrue);
      });

      test('POST /tasks - 缺少标题返回错误', () async {
        final handler = services.createPluginHandler(todoRoutes.router);
        final request = services.createAuthenticatedRequest(
          'POST',
          '/tasks',
          body: {'description': '没有标题的任务'},
        );
        final response = await handler(request);

        expect(response.statusCode, equals(400));
        expect(await ResponseHelper.isSuccess(response), isFalse);
      });
    });

    group('任务完成操作', () {
      test('POST /tasks/:id/complete - 完成任务', () async {
        final handler = services.createPluginHandler(todoRoutes.router);

        // 创建任务
        final createResponse = await handler(services.createAuthenticatedRequest(
          'POST',
          '/tasks',
          body: {'title': '待完成任务'},
        ));
        final createData = await ResponseHelper.getData(createResponse);
        final taskId = createData['id'] as String;

        // 完成任务
        final response = await handler(services.createAuthenticatedRequest(
          'POST',
          '/tasks/$taskId/complete',
        ));

        expect(response.statusCode, equals(200));
        final data = await ResponseHelper.getData(response);
        expect(data['completed'], isTrue);
        expect(data['completedAt'], isNotNull);
      });

      test('POST /tasks/:id/uncomplete - 取消完成', () async {
        final handler = services.createPluginHandler(todoRoutes.router);

        // 创建并完成任务
        final createResponse = await handler(services.createAuthenticatedRequest(
          'POST',
          '/tasks',
          body: {'title': '测试任务'},
        ));
        final createData = await ResponseHelper.getData(createResponse);
        final taskId = createData['id'] as String;

        await handler(services.createAuthenticatedRequest(
          'POST',
          '/tasks/$taskId/complete',
        ));

        // 取消完成
        final response = await handler(services.createAuthenticatedRequest(
          'POST',
          '/tasks/$taskId/uncomplete',
        ));

        expect(response.statusCode, equals(200));
        final data = await ResponseHelper.getData(response);
        expect(data['completed'], isFalse);
        expect(data['completedAt'], isNull);
      });
    });

    group('任务筛选', () {
      test('GET /tasks?completed=true - 获取已完成任务', () async {
        final handler = services.createPluginHandler(todoRoutes.router);

        // 创建并完成一个任务
        final createResponse = await handler(services.createAuthenticatedRequest(
          'POST',
          '/tasks',
          body: {'title': '筛选测试任务'},
        ));
        final taskId = (await ResponseHelper.getData(createResponse))['id'] as String;

        await handler(services.createAuthenticatedRequest(
          'POST',
          '/tasks/$taskId/complete',
        ));

        // 筛选已完成
        final request = services.createAuthenticatedRequest(
          'GET',
          '/tasks',
          queryParams: {'completed': 'true'},
        );
        final response = await handler(request);

        expect(response.statusCode, equals(200));
        final data = await ResponseHelper.getData(response);
        expect(data, isA<List>());
        for (final task in data) {
          expect(task['completed'], isTrue);
        }
      });

      test('GET /tasks?priority=3 - 按优先级筛选', () async {
        final handler = services.createPluginHandler(todoRoutes.router);

        // 创建高优先级任务
        await handler(services.createAuthenticatedRequest(
          'POST',
          '/tasks',
          body: {'title': '高优先级任务', 'priority': 3},
        ));

        // 筛选高优先级
        final request = services.createAuthenticatedRequest(
          'GET',
          '/tasks',
          queryParams: {'priority': '3'},
        );
        final response = await handler(request);

        expect(response.statusCode, equals(200));
        final data = await ResponseHelper.getData(response);
        expect(data, isA<List>());
        for (final task in data) {
          expect(task['priority'], equals(3));
        }
      });
    });

    group('搜索 API', () {
      test('GET /search - 搜索任务', () async {
        final handler = services.createPluginHandler(todoRoutes.router);

        // 创建测试任务
        await handler(services.createAuthenticatedRequest(
          'POST',
          '/tasks',
          body: {'title': 'Flutter 开发任务', 'description': '完成 Flutter 应用开发'},
        ));

        // 搜索
        final request = services.createAuthenticatedRequest(
          'GET',
          '/search',
          queryParams: {'keyword': 'Flutter'},
        );
        final response = await handler(request);

        expect(response.statusCode, equals(200));
        final data = await ResponseHelper.getData(response);
        expect(data, isA<List>());
        expect(data.length, greaterThanOrEqualTo(1));
      });
    });

    group('统计 API', () {
      test('GET /stats - 获取统计信息', () async {
        final handler = services.createPluginHandler(todoRoutes.router);
        final request = services.createAuthenticatedRequest('GET', '/stats');
        final response = await handler(request);

        expect(response.statusCode, equals(200));
        final data = await ResponseHelper.getData(response);
        expect(data, isA<Map>());
        expect(data['total'], isA<int>());
        expect(data['completed'], isA<int>());
        expect(data['pending'], isA<int>());
        expect(data['byPriority'], isA<Map>());
      });
    });
  });
}
