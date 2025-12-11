import 'dart:io';

/// 服务器配置
class ServerConfig {
  /// 服务器端口
  final int port;

  /// 数据存储目录
  final String dataDir;

  /// JWT 密钥
  final String jwtSecret;

  /// JWT Token 有效期 (天)
  final int tokenExpiryDays;

  /// 是否启用 CORS
  final bool enableCors;

  /// 允许的 CORS 源
  final List<String> corsOrigins;

  /// 最大请求体大小 (字节)
  final int maxRequestSize;

  /// 是否启用日志
  final bool enableLogging;

  ServerConfig({
    required this.port,
    required this.dataDir,
    required this.jwtSecret,
    this.tokenExpiryDays = 36500, // 约100年，相当于永不过期
    this.enableCors = true,
    this.corsOrigins = const ['*'],
    this.maxRequestSize = 10 * 1024 * 1024, // 10MB
    this.enableLogging = true,
  });

  /// 从环境变量加载配置
  factory ServerConfig.fromEnv() {
    return ServerConfig(
      port: int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080,
      dataDir: Platform.environment['DATA_DIR'] ?? './data',
      jwtSecret:
          Platform.environment['JWT_SECRET'] ?? _generateDefaultSecret(),
      tokenExpiryDays:
          int.tryParse(Platform.environment['TOKEN_EXPIRY_DAYS'] ?? '') ?? 36500, // 约100年，相当于永不过期
      enableCors:
          Platform.environment['ENABLE_CORS']?.toLowerCase() != 'false',
      corsOrigins: Platform.environment['CORS_ORIGINS']?.split(',') ?? ['*'],
      maxRequestSize: int.tryParse(Platform.environment['MAX_REQUEST_SIZE'] ??
              '') ??
          10 * 1024 * 1024,
      enableLogging:
          Platform.environment['ENABLE_LOGGING']?.toLowerCase() != 'false',
    );
  }

  /// 生成默认密钥 (仅用于开发环境)
  static String _generateDefaultSecret() {
    print('警告: 未设置 JWT_SECRET 环境变量，使用固定默认密钥（仅限开发环境）');
    // 使用固定密钥，确保服务器重启后 token 仍然有效
    return 'memento-dev-fixed-secret-key-do-not-use-in-production';
  }

  /// 打印配置信息 (隐藏敏感信息)
  void printConfig() {
    print('服务器配置:');
    print('  - 端口: $port');
    print('  - 数据目录: $dataDir');
    print('  - JWT 密钥: ${jwtSecret.substring(0, 8)}...');
    print('  - Token 有效期: $tokenExpiryDays 天');
    print('  - CORS: $enableCors');
    print('  - 最大请求体: ${maxRequestSize ~/ 1024 ~/ 1024}MB');
    print('  - 日志: $enableLogging');
  }
}
