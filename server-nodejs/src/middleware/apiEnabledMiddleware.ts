import { Request, Response, NextFunction } from 'express';
import { PluginDataService } from '../services/pluginDataService';

/**
 * API 启用中间件
 *
 * 检查用户是否已设置加密密钥（用于插件 API 访问）
 * 如果未设置，返回 403 Forbidden
 */
export function apiEnabledMiddleware(pluginDataService: PluginDataService) {
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

    // 检查用户是否已设置加密密钥
    if (!pluginDataService.hasEncryptionKey(userId)) {
      res.status(403).json({
        success: false,
        error: '请先通过 /api/v1/auth/set-encryption-key 设置加密密钥',
        timestamp: new Date().toISOString(),
      });
      return;
    }

    next();
  };
}
