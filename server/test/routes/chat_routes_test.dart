import 'package:test/test.dart';
import 'package:memento_server/routes/plugin_routes/chat_routes.dart';

import '../test_helpers.dart';

void main() {
  late TestServices services;
  late ChatRoutes chatRoutes;

  setUpAll(() async {
    services = TestServices();
    await services.setUp();
    await services.registerAndLogin();
    await services.enableApi();
    chatRoutes = ChatRoutes(services.pluginDataService);
  });

  tearDownAll(() async {
    await services.tearDown();
  });

  group('Chat Routes', () {
    group('频道 API', () {
      test('GET /channels - 获取空频道列表', () async {
        final handler = services.createPluginHandler(chatRoutes.router);
        final request = services.createAuthenticatedRequest('GET', '/channels');
        final response = await handler(request);

        expect(response.statusCode, equals(200));
        expect(await ResponseHelper.isSuccess(response), isTrue);
        final data = await ResponseHelper.getData(response);
        expect(data, isA<List>());
        expect(data, isEmpty);
      });

      test('POST /channels - 创建频道', () async {
        final handler = services.createPluginHandler(chatRoutes.router);
        final request = services.createAuthenticatedRequest(
          'POST',
          '/channels',
          body: {
            'name': '测试频道',
            'description': '这是一个测试频道',
          },
        );
        final response = await handler(request);

        expect(response.statusCode, equals(200));
        expect(await ResponseHelper.isSuccess(response), isTrue);
        final data = await ResponseHelper.getData(response);
        expect(data['name'], equals('测试频道'));
        expect(data['id'], isNotNull);
      });

      test('GET /channels - 获取频道列表', () async {
        final handler = services.createPluginHandler(chatRoutes.router);
        final request = services.createAuthenticatedRequest('GET', '/channels');
        final response = await handler(request);

        expect(response.statusCode, equals(200));
        final data = await ResponseHelper.getData(response);
        expect(data, isA<List>());
        expect(data.length, greaterThan(0));
      });

      test('POST /channels - 缺少必需参数返回错误', () async {
        final handler = services.createPluginHandler(chatRoutes.router);
        final request = services.createAuthenticatedRequest(
          'POST',
          '/channels',
          body: {'description': '没有名称'},
        );
        final response = await handler(request);

        expect(response.statusCode, equals(400));
        expect(await ResponseHelper.isSuccess(response), isFalse);
      });
    });

    group('消息 API', () {
      late String channelId;

      setUp(() async {
        // 创建测试频道
        final handler = services.createPluginHandler(chatRoutes.router);
        final request = services.createAuthenticatedRequest(
          'POST',
          '/channels',
          body: {'name': '消息测试频道'},
        );
        final response = await handler(request);
        final data = await ResponseHelper.getData(response);
        channelId = data['id'] as String;
      });

      test('POST /channels/:id/messages - 发送消息', () async {
        final handler = services.createPluginHandler(chatRoutes.router);
        final request = services.createAuthenticatedRequest(
          'POST',
          '/channels/$channelId/messages',
          body: {
            'content': '你好，这是一条测试消息',
            'senderId': 'user1',
            'senderName': '用户1',
          },
        );
        final response = await handler(request);

        expect(response.statusCode, equals(200));
        expect(await ResponseHelper.isSuccess(response), isTrue);
        final data = await ResponseHelper.getData(response);
        expect(data['content'], equals('你好，这是一条测试消息'));
        expect(data['id'], isNotNull);
      });

      test('GET /channels/:id/messages - 获取消息列表', () async {
        final handler = services.createPluginHandler(chatRoutes.router);

        // 先发送一条消息
        await handler(services.createAuthenticatedRequest(
          'POST',
          '/channels/$channelId/messages',
          body: {
            'content': '测试消息',
            'senderId': 'user1',
            'senderName': '用户1',
          },
        ));

        // 获取消息列表
        final request = services.createAuthenticatedRequest(
          'GET',
          '/channels/$channelId/messages',
        );
        final response = await handler(request);

        expect(response.statusCode, equals(200));
        final data = await ResponseHelper.getData(response);
        expect(data, isA<List>());
        expect(data.length, greaterThan(0));
      });

      test('GET /channels/:id/messages - 分页支持', () async {
        final handler = services.createPluginHandler(chatRoutes.router);

        // 发送多条消息
        for (var i = 0; i < 5; i++) {
          await handler(services.createAuthenticatedRequest(
            'POST',
            '/channels/$channelId/messages',
            body: {
              'content': '消息 $i',
              'senderId': 'user1',
              'senderName': '用户1',
            },
          ));
        }

        // 测试分页
        final request = services.createAuthenticatedRequest(
          'GET',
          '/channels/$channelId/messages',
          queryParams: {'offset': '0', 'count': '2'},
        );
        final response = await handler(request);

        expect(response.statusCode, equals(200));
        final responseData = await ResponseHelper.parseResponse(response);
        expect(responseData['data'], isA<List>());
        expect(responseData['data'].length, equals(2));
        expect(responseData['hasMore'], isTrue);
      });
    });

    group('认证测试', () {
      test('无 Token 访问返回 401', () async {
        final handler = services.createPluginHandler(chatRoutes.router);
        final request = services.createRequest('GET', '/channels');
        final response = await handler(request);

        expect(response.statusCode, equals(401));
      });
    });
  });
}
