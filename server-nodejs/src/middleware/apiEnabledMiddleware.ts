import { Request, Response, NextFunction } from 'express';

/**
 * API 启用中间件
 *
 * 检查请求头中是否包含加密密钥（用于插件 API 访问）
 * 密钥通过 X-Encryption-Key 请求头传递
 */
export function apiEnabledMiddleware() {
  return (req: Request, res: Response, next: NextFunction): void => {
    const userId = req.context?.userId;

    if (!userId) {
      res.status(401).json({
        success: false,
        error: '未认证',
        timestamp: new Date().toISOString(),
      });
      return;
    }

    // 从请求头获取加密密钥
    const encryptionKey = req.headers['x-encryption-key'] as string | undefined;
    if (!encryptionKey || encryptionKey.length === 0) {
      res.status(403).json({
        success: false,
        error: '请通过 X-Encryption-Key 请求头传递加密密钥',
        timestamp: new Date().toISOString(),
      });
      return;
    }

    // 将加密密钥存储到请求上下文中
    req.context = req.context || {};
    req.context.encryptionKey = encryptionKey;

    next();
  };
}
