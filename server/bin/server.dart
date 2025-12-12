import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

import 'package:memento_server/config/server_config.dart';
import 'package:memento_server/services/file_storage_service.dart';
import 'package:memento_server/services/auth_service.dart';
import 'package:memento_server/services/plugin_data_service.dart';
import 'package:memento_server/routes/auth_routes.dart';
import 'package:memento_server/routes/sync_routes.dart';
import 'package:memento_server/routes/plugin_routes/chat_routes.dart';
import 'package:memento_server/routes/plugin_routes/notes_routes.dart';
import 'package:memento_server/routes/plugin_routes/activity_routes.dart';
import 'package:memento_server/routes/plugin_routes/goods_routes.dart';
import 'package:memento_server/routes/plugin_routes/bill_routes.dart';
import 'package:memento_server/routes/plugin_routes/todo_routes.dart';
import 'package:memento_server/routes/plugin_routes/agent_chat_routes.dart';
import 'package:memento_server/routes/plugin_routes/calendar_album_routes.dart';
import 'package:memento_server/routes/plugin_routes/calendar_routes.dart';
import 'package:memento_server/routes/plugin_routes/checkin_routes.dart';
import 'package:memento_server/routes/plugin_routes/contact_routes.dart';
import 'package:memento_server/routes/plugin_routes/database_routes.dart';
import 'package:memento_server/routes/plugin_routes/day_routes.dart';
import 'package:memento_server/routes/plugin_routes/diary_routes.dart';
import 'package:memento_server/routes/plugin_routes/nodes_routes.dart';
import 'package:memento_server/routes/plugin_routes/openai_routes.dart';
import 'package:memento_server/routes/plugin_routes/store_routes.dart';
import 'package:memento_server/routes/plugin_routes/timer_routes.dart';
import 'package:memento_server/routes/plugin_routes/tracker_routes.dart';
import 'package:memento_server/middleware/auth_middleware.dart';
import 'package:memento_server/middleware/api_enabled_middleware.dart';

/// 根据文件扩展名获取 MIME 类型
String _getMimeType(String fileName) {
  final ext = path.extension(fileName).toLowerCase();
  switch (ext) {
    case '.html':
    case '.htm':
      return 'text/html; charset=utf-8';
    case '.css':
      return 'text/css; charset=utf-8';
    case '.js':
      return 'application/javascript; charset=utf-8';
    case '.json':
      return 'application/json; charset=utf-8';
    case '.png':
      return 'image/png';
    case '.jpg':
    case '.jpeg':
      return 'image/jpeg';
    case '.gif':
      return 'image/gif';
    case '.svg':
      return 'image/svg+xml';
    case '.ico':
      return 'image/x-icon';
    case '.woff':
      return 'font/woff';
    case '.woff2':
      return 'font/woff2';
    case '.ttf':
      return 'font/ttf';
    case '.eot':
      return 'application/vnd.ms-fontobject';
    default:
      return 'application/octet-stream';
  }
}

void main(List<String> args) async {
  // 设置日志
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  final logger = Logger('MementoServer');

  // 1. 加载配置
  final config = ServerConfig.fromEnv();
  config.printConfig();

  // 2. 初始化服务
  final storageService = FileStorageService(config.dataDir);
  await storageService.initialize();
  logger.info('文件存储服务初始化完成: ${config.dataDir}');

  final authService = AuthService(
    storageService: storageService,
    jwtSecret: config.jwtSecret,
    tokenExpiryDays: config.tokenExpiryDays,
  );
  logger.info('认证服务初始化完成');

  // 初始化加密服务和插件数据服务
  final pluginDataService = PluginDataService(storageService, config.dataDir);
  await pluginDataService.initialize();
  logger.info('插件数据服务初始化完成');

  // 3. 创建路由
  final router = Router();

  // 健康检查 (无需认证)
  router.get('/health', (Request request) {
    return Response.ok(
        '{"status": "healthy", "timestamp": "${DateTime.now().toIso8601String()}"}',
        headers: {'Content-Type': 'application/json'});
  });

  // 版本信息 (无需认证)
  router.get('/version', (Request request) {
    return Response.ok('{"version": "1.0.0", "name": "Memento Sync Server"}',
        headers: {'Content-Type': 'application/json'});
  });

  // 认证路由 (无需认证)
  final authRoutes = AuthRoutes(authService, pluginDataService);
  router.mount('/api/v1/auth', authRoutes.router.call);

  // 同步路由 (需要认证)
  final syncRoutes = SyncRoutes(storageService);
  router.mount(
    '/api/v1/sync',
    Pipeline()
        .addMiddleware(authMiddleware(authService))
        .addHandler(syncRoutes.router.call),
  );

  // ==================== 插件路由 (需要认证 + API 启用) ====================

  // 创建带认证和 API 检查的中间件管道
  Pipeline pluginPipeline() => Pipeline()
      .addMiddleware(authMiddleware(authService))
      .addMiddleware(apiEnabledMiddleware(pluginDataService));

  // Chat 插件路由
  final chatRoutes = ChatRoutes(pluginDataService);
  router.mount(
    '/api/v1/plugins/chat',
    pluginPipeline().addHandler(chatRoutes.router.call),
  );

  // Notes 插件路由
  final notesRoutes = NotesRoutes(pluginDataService);
  router.mount(
    '/api/v1/plugins/notes',
    pluginPipeline().addHandler(notesRoutes.router.call),
  );

  // Activity 插件路由
  final activityRoutes = ActivityRoutes(pluginDataService);
  router.mount(
    '/api/v1/plugins/activity',
    pluginPipeline().addHandler(activityRoutes.router.call as Handler),
  );

  // Goods 插件路由
  final goodsRoutes = GoodsRoutes(pluginDataService);
  router.mount(
    '/api/v1/plugins/goods',
    pluginPipeline().addHandler(goodsRoutes.router.call),
  );

  // Bill 插件路由
  final billRoutes = BillRoutes(pluginDataService);
  router.mount(
    '/api/v1/plugins/bill',
    pluginPipeline().addHandler(billRoutes.router.call),
  );

  // Todo 插件路由
  final todoRoutes = TodoRoutes(pluginDataService);
  router.mount(
    '/api/v1/plugins/todo',
    pluginPipeline().addHandler(todoRoutes.router.call),
  );

  // AgentChat 插件路由
  final agentChatRoutes = AgentChatRoutes(pluginDataService);
  router.mount(
    '/api/v1/plugins/agent_chat',
    pluginPipeline().addHandler(agentChatRoutes.router.call),
  );

  // CalendarAlbum 插件路由
  final calendarAlbumRoutes = CalendarAlbumRoutes(pluginDataService);
  router.mount(
    '/api/v1/plugins/calendar_album',
    pluginPipeline().addHandler(calendarAlbumRoutes.router.call),
  );

  // Calendar 插件路由
  final calendarRoutes = CalendarRoutes(pluginDataService);
  router.mount(
    '/api/v1/plugins/calendar',
    pluginPipeline().addHandler(calendarRoutes.router.call),
  );

  // Checkin 插件路由
  final checkinRoutes = CheckinRoutes(pluginDataService);
  router.mount(
    '/api/v1/plugins/checkin',
    pluginPipeline().addHandler(checkinRoutes.router.call),
  );

  // Contact 插件路由
  final contactRoutes = ContactRoutes(pluginDataService);
  router.mount(
    '/api/v1/plugins/contact',
    pluginPipeline().addHandler(contactRoutes.router.call),
  );

  // Database 插件路由
  final databaseRoutes = DatabaseRoutes(pluginDataService);
  router.mount(
    '/api/v1/plugins/database',
    pluginPipeline().addHandler(databaseRoutes.router.call),
  );

  // Day 插件路由
  final dayRoutes = DayRoutes(pluginDataService);
  router.mount(
    '/api/v1/plugins/day',
    pluginPipeline().addHandler(dayRoutes.router.call),
  );

  // Diary 插件路由
  final diaryRoutes = DiaryRoutes(pluginDataService);
  router.mount(
    '/api/v1/plugins/diary',
    pluginPipeline().addHandler(diaryRoutes.router.call),
  );

  // Nodes 插件路由
  final nodesRoutes = NodesRoutes(pluginDataService);
  router.mount(
    '/api/v1/plugins/nodes',
    pluginPipeline().addHandler(nodesRoutes.router.call),
  );

  // OpenAI 插件路由
  final openaiRoutes = OpenAIRoutes(pluginDataService);
  router.mount(
    '/api/v1/plugins/openai',
    pluginPipeline().addHandler(openaiRoutes.router.call),
  );

  // Store 插件路由
  final storeRoutes = StoreRoutes(pluginDataService);
  router.mount(
    '/api/v1/plugins/store',
    pluginPipeline().addHandler(storeRoutes.router.call),
  );

  // Timer 插件路由
  final timerRoutes = TimerRoutes(pluginDataService);
  router.mount(
    '/api/v1/plugins/timer',
    pluginPipeline().addHandler(timerRoutes.router.call),
  );

  // Tracker 插件路由
  final trackerRoutes = TrackerRoutes(pluginDataService);
  router.mount(
    '/api/v1/plugins/tracker',
    pluginPipeline().addHandler(trackerRoutes.router.call),
  );

  logger.info('已挂载 19 个插件路由: chat, notes, activity, goods, bill, todo, agent_chat, calendar_album, calendar, checkin, contact, database, day, diary, nodes, openai, store, timer, tracker');

  // 管理界面静态文件服务
  final scriptDir = path.dirname(Platform.script.toFilePath());
  final adminDir = path.normalize(path.join(scriptDir, '..', 'admin'));
  logger.info('管理界面目录: $adminDir');

  // 检查管理界面目录是否存在
  if (!Directory(adminDir).existsSync()) {
    logger.warning('管理界面目录不存在: $adminDir');
  }

  // 根路径重定向到管理界面
  router.get('/', (Request request) {
    return Response.found('/admin/');
  });

  // 管理界面主页
  router.get('/admin/', (Request request) async {
    final indexFile = File(path.join(adminDir, 'index.html'));
    if (await indexFile.exists()) {
      return Response.ok(
        await indexFile.readAsString(),
        headers: {'Content-Type': 'text/html; charset=utf-8'},
      );
    }
    return Response.notFound('Admin page not found');
  });

  // 管理界面静态资源
  router.get('/admin/<file|.*>', (Request request, String file) async {
    // 安全检查：防止路径遍历攻击
    if (file.contains('..')) {
      return Response.forbidden('Invalid path');
    }

    final filePath = path.join(adminDir, file);
    final targetFile = File(filePath);

    if (await targetFile.exists()) {
      final content = await targetFile.readAsBytes();
      final mimeType = _getMimeType(file);
      return Response.ok(
        content,
        headers: {'Content-Type': mimeType},
      );
    }

    return Response.notFound('File not found: $file');
  });

  // 4. 构建处理管道
  var handler =
      const Pipeline().addMiddleware(logRequests()).addHandler(router.call);

  // 添加 CORS 支持
  if (config.enableCors) {
    handler = const Pipeline()
        .addMiddleware(corsHeaders(
          headers: {
            ACCESS_CONTROL_ALLOW_ORIGIN: config.corsOrigins.join(','),
            ACCESS_CONTROL_ALLOW_METHODS: 'GET, POST, PUT, DELETE, OPTIONS',
            ACCESS_CONTROL_ALLOW_HEADERS: 'Origin, Content-Type, Authorization',
          },
        ))
        .addMiddleware(logRequests())
        .addHandler(router.call);
  }

  // 5. 启动服务器
  final server = await shelf_io.serve(
    handler,
    InternetAddress.anyIPv4,
    config.port,
  );

  logger.info('服务器启动成功!');
  print('');
  print('====================================');
  print('  Memento Sync Server');
  print('  http://${server.address.host}:${server.port}');
  print('====================================');
  print('');
  print('可用端点:');
  print('  GET  /                    - 重定向到管理界面');
  print('  GET  /admin               - 管理界面');
  print('  GET  /health              - 健康检查');
  print('  GET  /version             - 版本信息');
  print('  POST /api/v1/auth/register - 用户注册');
  print('  POST /api/v1/auth/login    - 用户登录');
  print('  POST /api/v1/auth/enable-api  - 启用 API 访问');
  print('  POST /api/v1/auth/disable-api - 禁用 API 访问');
  print('  GET  /api/v1/auth/api-status  - API 状态查询');
  print('  POST /api/v1/sync/push     - 推送文件 (需认证)');
  print('  GET  /api/v1/sync/pull/*   - 拉取文件 (需认证)');
  print('  GET  /api/v1/sync/list     - 文件列表 (需认证)');
  print('');
  print('插件 API (需认证 + API 启用):');
  print('  /api/v1/plugins/chat           - 聊天插件');
  print('  /api/v1/plugins/notes          - 笔记插件');
  print('  /api/v1/plugins/activity       - 活动记录插件');
  print('  /api/v1/plugins/goods          - 物品管理插件');
  print('  /api/v1/plugins/bill           - 账单插件');
  print('  /api/v1/plugins/todo           - 任务插件');
  print('  /api/v1/plugins/agent_chat     - AI 代理聊天插件');
  print('  /api/v1/plugins/calendar_album - 日记相册插件');
  print('  /api/v1/plugins/calendar       - 日历插件');
  print('  /api/v1/plugins/checkin        - 签到插件');
  print('  /api/v1/plugins/contact        - 联系人插件');
  print('  /api/v1/plugins/database       - 自定义数据库插件');
  print('  /api/v1/plugins/day            - 纪念日插件');
  print('  /api/v1/plugins/diary          - 日记插件');
  print('  /api/v1/plugins/nodes          - 节点插件');
  print('  /api/v1/plugins/openai         - AI 助手插件');
  print('  /api/v1/plugins/store          - 物品兑换插件');
  print('  /api/v1/plugins/timer          - 计时器插件');
  print('  /api/v1/plugins/tracker        - 目标追踪插件');
  print('');

  // 优雅关闭
  ProcessSignal.sigint.watch().listen((_) async {
    logger.info('收到关闭信号，正在停止服务器...');
    await server.close();
    exit(0);
  });
}
