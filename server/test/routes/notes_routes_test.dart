import 'package:test/test.dart';
import 'package:memento_server/routes/plugin_routes/notes_routes.dart';

import '../test_helpers.dart';

void main() {
  late TestServices services;
  late NotesRoutes notesRoutes;

  setUpAll(() async {
    services = TestServices();
    await services.setUp();
    await services.registerAndLogin();
    await services.enableApi();
    notesRoutes = NotesRoutes(services.pluginDataService);
  });

  tearDownAll(() async {
    await services.tearDown();
  });

  group('Notes Routes', () {
    group('笔记 API', () {
      test('GET /notes - 获取空笔记列表', () async {
        final handler = services.createPluginHandler(notesRoutes.router);
        final request = services.createAuthenticatedRequest('GET', '/notes');
        final response = await handler(request);

        expect(response.statusCode, equals(200));
        expect(await ResponseHelper.isSuccess(response), isTrue);
        final data = await ResponseHelper.getData(response);
        expect(data, isA<List>());
      });

      test('POST /notes - 创建笔记', () async {
        final handler = services.createPluginHandler(notesRoutes.router);
        final request = services.createAuthenticatedRequest(
          'POST',
          '/notes',
          body: {
            'title': '测试笔记',
            'content': '这是笔记内容',
            'tags': ['测试', 'demo'],
          },
        );
        final response = await handler(request);

        expect(response.statusCode, equals(200));
        expect(await ResponseHelper.isSuccess(response), isTrue);
        final data = await ResponseHelper.getData(response);
        expect(data['title'], equals('测试笔记'));
        expect(data['id'], isNotNull);
      });

      test('GET /notes/:id - 获取单个笔记', () async {
        final handler = services.createPluginHandler(notesRoutes.router);

        // 先创建笔记
        final createResponse = await handler(services.createAuthenticatedRequest(
          'POST',
          '/notes',
          body: {'title': '单个笔记测试', 'content': '内容'},
        ));
        final createData = await ResponseHelper.getData(createResponse);
        final noteId = createData['id'] as String;

        // 获取笔记
        final request = services.createAuthenticatedRequest('GET', '/notes/$noteId');
        final response = await handler(request);

        expect(response.statusCode, equals(200));
        final data = await ResponseHelper.getData(response);
        expect(data['title'], equals('单个笔记测试'));
      });

      test('PUT /notes/:id - 更新笔记', () async {
        final handler = services.createPluginHandler(notesRoutes.router);

        // 创建笔记
        final createResponse = await handler(services.createAuthenticatedRequest(
          'POST',
          '/notes',
          body: {'title': '原始标题', 'content': '原始内容'},
        ));
        final createData = await ResponseHelper.getData(createResponse);
        final noteId = createData['id'] as String;

        // 更新笔记
        final updateRequest = services.createAuthenticatedRequest(
          'PUT',
          '/notes/$noteId',
          body: {'title': '更新后的标题', 'content': '更新后的内容'},
        );
        final response = await handler(updateRequest);

        expect(response.statusCode, equals(200));
        final data = await ResponseHelper.getData(response);
        expect(data['title'], equals('更新后的标题'));
      });

      test('DELETE /notes/:id - 删除笔记', () async {
        final handler = services.createPluginHandler(notesRoutes.router);

        // 创建笔记
        final createResponse = await handler(services.createAuthenticatedRequest(
          'POST',
          '/notes',
          body: {'title': '待删除', 'content': '内容'},
        ));
        final createData = await ResponseHelper.getData(createResponse);
        final noteId = createData['id'] as String;

        // 删除笔记
        final deleteRequest = services.createAuthenticatedRequest(
          'DELETE',
          '/notes/$noteId',
        );
        final response = await handler(deleteRequest);

        expect(response.statusCode, equals(200));
        final data = await ResponseHelper.getData(response);
        expect(data['deleted'], isTrue);
      });

      test('GET /notes/:id - 获取不存在的笔记返回 404', () async {
        final handler = services.createPluginHandler(notesRoutes.router);
        final request = services.createAuthenticatedRequest(
          'GET',
          '/notes/non_existent_id',
        );
        final response = await handler(request);

        expect(response.statusCode, equals(404));
      });
    });

    group('文件夹 API', () {
      test('POST /folders - 创建文件夹', () async {
        final handler = services.createPluginHandler(notesRoutes.router);
        final request = services.createAuthenticatedRequest(
          'POST',
          '/folders',
          body: {
            'name': '工作笔记',
            'color': '#FF5733',
          },
        );
        final response = await handler(request);

        expect(response.statusCode, equals(200));
        expect(await ResponseHelper.isSuccess(response), isTrue);
        final data = await ResponseHelper.getData(response);
        expect(data['name'], equals('工作笔记'));
        expect(data['id'], isNotNull);
      });

      test('GET /folders - 获取文件夹列表', () async {
        final handler = services.createPluginHandler(notesRoutes.router);
        final request = services.createAuthenticatedRequest('GET', '/folders');
        final response = await handler(request);

        expect(response.statusCode, equals(200));
        final data = await ResponseHelper.getData(response);
        expect(data, isA<List>());
      });
    });

    group('搜索 API', () {
      test('GET /search - 搜索笔记', () async {
        final handler = services.createPluginHandler(notesRoutes.router);

        // 创建测试笔记
        await handler(services.createAuthenticatedRequest(
          'POST',
          '/notes',
          body: {'title': 'Flutter 开发指南', 'content': 'Flutter 是一个跨平台框架'},
        ));
        await handler(services.createAuthenticatedRequest(
          'POST',
          '/notes',
          body: {'title': 'Dart 语言', 'content': 'Dart 是 Flutter 的编程语言'},
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
  });
}
