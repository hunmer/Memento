import { Request, Response, NextFunction } from 'express';
import { AuthService } from '../services/authService';
import { AuthContext } from '../types';

/**
 * 扩展 Express Request 类型
 */
declare global {
  namespace Express {
    interface Request {
      context?: {
        userId?: string;
        authContext?: AuthContext;
        encryptionKey?: string;
      };
    }
  }
}

/**
 * 从请求上下文获取用户 ID
 */
export function getUserIdFromContext(req: Request): string | undefined {
  return req.context?.userId;
}

/**
 * 从请求上下文获取认证上下文
 */
export function getAuthContextFromRequest(req: Request): AuthContext | undefined {
  return req.context?.authContext;
}

/**
 * 从请求头获取设备 ID
 */
export function getDeviceIdFromContext(req: Request): string | undefined {
  return req.headers['x-device-id'] as string | undefined;
}

/**
 * 从请求上下文获取加密密钥
 */
export function getEncryptionKeyFromContext(req: Request): string | undefined {
  return req.context?.encryptionKey;
}

/**
 * 生成未授权响应
 */
function unauthorizedResponse(res: Response, message: string): void {
  res.status(401).json({
    success: false,
    error: message,
    timestamp: new Date().toISOString(),
  });
}

/**
 * JWT 认证中间件
 *
 * 支持两种认证方式：
 * 1. Authorization: Bearer <jwt_token>
 * 2. X-API-Key: <api_key>
 *
 * 成功后将认证信息添加到 req.context
 */
export function authMiddleware(authService: AuthService) {
  return async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    // 跳过 OPTIONS 请求 (CORS 预检)
    if (req.method === 'OPTIONS') {
      next();
      return;
    }

    // 优先检查 X-API-Key 头
    const apiKeyHeader = req.headers['x-api-key'] as string | undefined;
    if (apiKeyHeader && apiKeyHeader.length > 0) {
      try {
        const result = await authService.verifyApiKey(apiKeyHeader);
        if (!result) {
          unauthorizedResponse(res, 'API Key 无效或已过期');
          return;
        }

        req.context = {
          ...req.context,
          userId: result.userId,
          authContext: {
            userId: result.userId,
            keyId: result.keyId,
            keyName: result.keyName,
            isApiKey: true,
          },
        };
        next();
        return;
      } catch (e) {
        unauthorizedResponse(res, 'API Key 验证失败');
        return;
      }
    }

    // 检查 Authorization Bearer Token
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      unauthorizedResponse(res, '缺少认证信息');
      return;
    }

    // 提取 Token
    const token = authHeader.substring(7); // 去掉 "Bearer " 前缀

    // 验证 Token
    const userId = authService.getUserIdFromToken(token);

    if (!userId) {
      unauthorizedResponse(res, 'Token 无效或已过期');
      return;
    }

    // 将 userId 添加到请求上下文
    req.context = {
      ...req.context,
      userId,
      authContext: {
        userId,
        isApiKey: false,
      },
    };

    next();
  };
}
