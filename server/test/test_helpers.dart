import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shared_models/shared_models.dart';

import 'package:memento_server/services/file_storage_service.dart';
import 'package:memento_server/services/auth_service.dart';
import 'package:memento_server/services/plugin_data_service.dart';
import 'package:memento_server/middleware/auth_middleware.dart';
import 'package:memento_server/middleware/api_enabled_middleware.dart';

/// 测试配置
class TestConfig {
  static const String testDataDir = 'test_data';
  static const String testUserId = 'test_user_123';
  static const String testUsername = 'testuser';
  static const String testPassword = 'testpassword';
  static const String testDeviceId = 'test_device_001';
  static const String jwtSecret = 'test_jwt_secret_key_for_testing_purposes_only';
  static const int tokenExpiryDays = 1;

  // 32 字节的测试加密密钥 (base64)
  static const String testEncryptionKey =
      'dGVzdF9lbmNyeXB0aW9uX2tleV8zMl9ieXRlcyE='; // test_encryption_key_32_bytes!
}

/// 测试服务容器
class TestServices {
  late final Directory testDir;
  late final FileStorageService storageService;
  late final AuthService authService;
  late final PluginDataService pluginDataService;
  String? authToken;

  /// 初始化测试服务
  Future<void> setUp() async {
    // 创建测试数据目录
    testDir = Directory(TestConfig.testDataDir);
    if (await testDir.exists()) {
      await testDir.delete(recursive: true);
    }
    await testDir.create(recursive: true);

    // 初始化服务
    storageService = FileStorageService(TestConfig.testDataDir);
    await storageService.initialize();

    authService = AuthService(
      storageService: storageService,
      jwtSecret: TestConfig.jwtSecret,
      tokenExpiryDays: TestConfig.tokenExpiryDays,
    );

    pluginDataService = PluginDataService(
      storageService,
      TestConfig.testDataDir,
    );
    await pluginDataService.initialize();
  }

  /// 清理测试数据
  Future<void> tearDown() async {
    if (await testDir.exists()) {
      await testDir.delete(recursive: true);
    }
  }

  /// 注册并登录测试用户，返回 Token
  Future<String> registerAndLogin() async {
    // 注册用户
    final registerResponse = await authService.register(
      RegisterRequest(
        username: TestConfig.testUsername,
        password: TestConfig.testPassword,
        deviceId: TestConfig.testDeviceId,
      ),
    );

    if (!registerResponse.success) {
      throw StateError('注册失败: ${registerResponse.error}');
    }

    authToken = registerResponse.token;
    return authToken!;
  }

  /// 启用 API 访问
  Future<void> enableApi() async {
    if (authToken == null) {
      await registerAndLogin();
    }

    // 从 Token 获取 userId
    final userId = authService.getUserIdFromToken(authToken!);
    if (userId == null) {
      throw StateError('无法从 Token 获取用户 ID');
    }

    await pluginDataService.enableApi(userId, TestConfig.testEncryptionKey);
  }

  /// 创建带认证的请求
  Request createAuthenticatedRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) {
    if (authToken == null) {
      throw StateError('未登录，请先调用 registerAndLogin()');
    }

    var uri = Uri.parse('http://localhost$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    final headers = <String, String>{
      'Authorization': 'Bearer $authToken',
      'Content-Type': 'application/json',
    };

    return Request(
      method,
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  /// 创建无认证的请求
  Request createRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) {
    var uri = Uri.parse('http://localhost$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    return Request(
      method,
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body != null ? jsonEncode(body) : null,
    );
  }

  /// 创建带中间件的处理器
  Handler createPluginHandler(Router router) {
    return Pipeline()
        .addMiddleware(authMiddleware(authService))
        .addMiddleware(apiEnabledMiddleware(pluginDataService))
        .addHandler(router.call);
  }
}

/// 响应解析帮助方法
class ResponseHelper {
  /// 解析响应体为 JSON
  static Future<Map<String, dynamic>> parseResponse(Response response) async {
    final body = await response.readAsString();
    return jsonDecode(body) as Map<String, dynamic>;
  }

  /// 检查响应是否成功
  static Future<bool> isSuccess(Response response) async {
    final data = await parseResponse(response);
    return data['success'] == true;
  }

  /// 获取响应中的数据
  static Future<dynamic> getData(Response response) async {
    final data = await parseResponse(response);
    return data['data'];
  }

  /// 获取响应中的错误信息
  static Future<String?> getError(Response response) async {
    final data = await parseResponse(response);
    return data['error'] as String?;
  }
}
