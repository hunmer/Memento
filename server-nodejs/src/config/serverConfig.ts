import path from 'path';

/**
 * 生成默认 JWT 密钥 (仅用于开发环境)
 */
function generateDefaultSecret(): string {
  console.log('警告: 未设置 JWT_SECRET 环境变量，使用固定默认密钥（仅限开发环境）');
  return 'memento-dev-fixed-secret-key-do-not-use-in-production';
}

/**
 * 服务器配置
 */
export const config = {
  /** 服务器端口 */
  port: parseInt(process.env.PORT || '8874', 10),
  /** 数据存储目录 */
  dataDir: process.env.DATA_DIR || path.join(process.cwd(), 'data'),
  /** JWT 密钥 */
  jwtSecret: process.env.JWT_SECRET || generateDefaultSecret(),
  /** JWT Token 有效期 (天) */
  tokenExpiryDays: parseInt(process.env.TOKEN_EXPIRY_DAYS || '36500', 10),
  /** 是否启用 CORS */
  enableCors: process.env.ENABLE_CORS?.toLowerCase() !== 'false',
  /** 允许的 CORS 源 */
  corsOrigins: (process.env.CORS_ORIGINS || '*').split(','),
  /** 最大请求体大小 */
  maxRequestSize: process.env.MAX_REQUEST_SIZE || '10mb',
  /** 是否启用日志 */
  enableLogging: process.env.ENABLE_LOGGING?.toLowerCase() !== 'false',
};

/**
 * 打印配置信息 (隐藏敏感信息)
 */
export function printConfig(): void {
  console.log('服务器配置:');
  console.log(`  - 端口: ${config.port}`);
  console.log(`  - 数据目录: ${config.dataDir}`);
  console.log(`  - JWT 密钥: ${config.jwtSecret.substring(0, 8)}...`);
  console.log(`  - Token 有效期: ${config.tokenExpiryDays} 天`);
  console.log(`  - CORS: ${config.enableCors}`);
  console.log(`  - 最大请求体: ${config.maxRequestSize}`);
  console.log(`  - 日志: ${config.enableLogging}`);
}
