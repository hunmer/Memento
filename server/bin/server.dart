import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:logging/logging.dart';

import 'package:memento_server/config/server_config.dart';
import 'package:memento_server/services/file_storage_service.dart';
import 'package:memento_server/services/auth_service.dart';
import 'package:memento_server/routes/auth_routes.dart';
import 'package:memento_server/routes/sync_routes.dart';
import 'package:memento_server/middleware/auth_middleware.dart';

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

  // 3. 创建路由
  final router = Router();

  // 健康检查 (无需认证)
  router.get('/health', (Request request) {
    return Response.ok('{"status": "healthy", "timestamp": "${DateTime.now().toIso8601String()}"}',
        headers: {'Content-Type': 'application/json'});
  });

  // 版本信息 (无需认证)
  router.get('/version', (Request request) {
    return Response.ok(
        '{"version": "1.0.0", "name": "Memento Sync Server"}',
        headers: {'Content-Type': 'application/json'});
  });

  // 认证路由 (无需认证)
  final authRoutes = AuthRoutes(authService);
  router.mount('/api/v1/auth', authRoutes.router);

  // 同步路由 (需要认证)
  final syncRoutes = SyncRoutes(storageService);
  router.mount(
    '/api/v1/sync',
    Pipeline()
        .addMiddleware(authMiddleware(authService))
        .addHandler(syncRoutes.router.call),
  );

  // 4. 构建处理管道
  var handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router.call);

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
  print('  GET  /health              - 健康检查');
  print('  GET  /version             - 版本信息');
  print('  POST /api/v1/auth/register - 用户注册');
  print('  POST /api/v1/auth/login    - 用户登录');
  print('  POST /api/v1/sync/push     - 推送文件 (需认证)');
  print('  GET  /api/v1/sync/pull/*   - 拉取文件 (需认证)');
  print('  GET  /api/v1/sync/list     - 文件列表 (需认证)');
  print('');

  // 优雅关闭
  ProcessSignal.sigint.watch().listen((_) async {
    logger.info('收到关闭信号，正在停止服务器...');
    await server.close();
    exit(0);
  });
}
