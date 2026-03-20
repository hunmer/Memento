import { Router, Request, Response } from 'express';
import { AuthService, PasswordHashUtils } from '../services/authService';
import { FileStorageService } from '../services/fileStorageService';
import { PluginDataService } from '../services/pluginDataService';

/**
 * 认证路由
 *
 * 安全说明：加密密钥只保存在内存中，不持久化到文件
 * 每次请求需要通过请求头 X-Encryption-Key 传递密钥
 */
export function createAuthRoutes(
  authService: AuthService,
  pluginDataService: PluginDataService,
  storageService: FileStorageService,
  allowRegister: boolean = true,
): Router {
  const router = Router();

  /**
   * 错误响应
   */
  function errorResponse(res: Response, statusCode: number, message: string): void {
    res.status(statusCode).json({
      success: false,
      error: message,
      timestamp: new Date().toISOString(),
    });
  }

  /**
   * 从请求头获取并验证 Token，返回 userId
   */
  function getUserIdFromRequest(req: Request): string | undefined {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return undefined;
    }
    const token = authHeader.substring(7);
    return authService.getUserIdFromToken(token) ?? undefined;
  }

  /**
   * 解析过期选项
   */
  function parseExpiry(value: string): '7days' | '30days' | '90days' | '1year' | 'never' {
    switch (value) {
      case '7days': return '7days';
      case '30days': return '30days';
      case '90days': return '90days';
      case '1year': return '1year';
      case 'never':
      default:
        return 'never';
    }
  }

  // ==================== 公开端点 ====================

  /**
   * GET /register-status - 获取注册状态
   */
  router.get('/register-status', async (req: Request, res: Response): Promise<void> => {
    res.json({
      success: true,
      allow_register: allowRegister,
      timestamp: new Date().toISOString(),
    });
  });

  /**
   * POST /register - 用户注册
   */
  router.post('/register', async (req: Request, res: Response): Promise<void> => {
    try {
      // 检查是否允许注册
      if (!allowRegister) {
        errorResponse(res, 403, '注册功能已关闭');
        return;
      }

      const data = req.body;

      // 验证必填字段
      if (!data.username || !data.password) {
        errorResponse(res, 400, '用户名和密码不能为空');
        return;
      }

      if (data.username.length < 3) {
        errorResponse(res, 400, '用户名至少需要 3 个字符');
        return;
      }

      if (data.password.length < 6) {
        errorResponse(res, 400, '密码至少需要 6 个字符');
        return;
      }

      if (!data.device_id) {
        errorResponse(res, 400, '设备 ID 不能为空');
        return;
      }

      const response = await authService.register({
        username: data.username,
        password: data.password,
        deviceId: data.device_id,
        deviceName: data.device_name || 'Unknown Device',
      });

      if (response.success) {
        res.json({
          success: true,
          user_id: response.userId,
          token: response.token,
          expires_at: response.expiresAt?.toISOString(),
          user_salt: response.userSalt,
        });
      } else {
        errorResponse(res, 400, response.error || '注册失败');
      }
    } catch (e) {
      errorResponse(res, 500, `服务器错误: ${e}`);
    }
  });

  /**
   * POST /login - 用户登录
   */
  router.post('/login', async (req: Request, res: Response): Promise<void> => {
    try {
      const data = req.body;

      // 验证必填字段
      if (!data.username || !data.password) {
        errorResponse(res, 400, '用户名和密码不能为空');
        return;
      }

      if (!data.device_id) {
        errorResponse(res, 400, '设备 ID 不能为空');
        return;
      }

      const response = await authService.login({
        username: data.username,
        password: data.password,
        deviceId: data.device_id,
        deviceName: data.device_name,
      });

      if (response.success) {
        res.json({
          success: true,
          user_id: response.userId,
          token: response.token,
          expires_at: response.expiresAt?.toISOString(),
          user_salt: response.userSalt,
        });
      } else {
        errorResponse(res, 401, response.error || '登录失败');
      }
    } catch (e) {
      errorResponse(res, 500, `服务器错误: ${e}`);
    }
  });

  /**
   * POST /refresh - 刷新 Token
   */
  router.post('/refresh', async (req: Request, res: Response): Promise<void> => {
    try {
      const data = req.body;

      if (!data.token || !data.device_id) {
        errorResponse(res, 400, 'Token 和设备 ID 不能为空');
        return;
      }

      const response = await authService.refreshToken({
        token: data.token,
        deviceId: data.device_id,
      });

      if (response.success) {
        res.json({
          success: true,
          user_id: response.userId,
          token: response.token,
          fails_at: response.expiresAt?.toISOString(),
          user_salt: response.userSalt,
        });
      } else {
        errorResponse(res, 401, response.error || '刷新失败');
      }
    } catch (e) {
      errorResponse(res, 500, `服务器错误: ${e}`);
    }
  });

  // ==================== 需认证端点 ====================

  /**
   * POST /set-encryption-key - 设置加密密钥
   */
  router.post('/set-encryption-key', async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = getUserIdFromRequest(req);
      if (!userId) {
        errorResponse(res, 401, '未认证或 Token 无效');
        return;
      }

      const data = req.body;
      const encryptionKey = data.encryption_key;
      if (!encryptionKey || typeof encryptionKey !== 'string') {
        errorResponse(res, 400, '缺少 encryption_key 参数');
        return;
      }

      const forceCreate = data.force_create === true;

      // 验证密钥格式（Base64 32字节）
      try {
        const keyBytes = Buffer.from(encryptionKey, 'base64');
        if (keyBytes.length !== 32) {
          errorResponse(res, 400, '密钥长度必须为 32 字节 (256-bit)');
          return;
        }
      } catch (e) {
        errorResponse(res, 400, '无效的 Base64 编码密钥');
        return;
      }

      // 检查是否已存在验证文件
      const hasVerificationFile = await pluginDataService.hasKeyVerificationFile(userId);

      if (hasVerificationFile && !forceCreate) {
        // 已有验证文件，需要验证密钥是否正确
        const [isValid, errorMessage] = await pluginDataService.verifyEncryptionKey(userId, encryptionKey);

        if (!isValid) {
          errorResponse(res, 403, errorMessage || '密钥验证失败');
          return;
        }

        // 验证成功，密钥已设置
        res.json({
          success: true,
          message: '密钥验证成功',
          is_first_time: false,
          user_id: userId,
          timestamp: new Date().toISOString(),
        });
      } else if (forceCreate) {
        // 强制创建模式（更改密钥后）：设置密钥并更新验证文件
        pluginDataService.setEncryptionKey(userId, encryptionKey);
        await pluginDataService.updateKeyVerificationFile(userId);

        res.json({
          success: true,
          message: '加密密钥已更新',
          is_first_time: false,
          is_key_updated: true,
          user_id: userId,
          timestamp: new Date().toISOString(),
        });
      } else {
        // 首次设置密钥
        pluginDataService.setEncryptionKey(userId, encryptionKey);

        // 创建验证文件
        await pluginDataService.createKeyVerificationFile(userId);

        res.json({
          success: true,
          message: '加密密钥已设置并创建验证文件',
          is_first_time: true,
          user_id: userId,
          timestamp: new Date().toISOString(),
        });
      }
    } catch (e) {
      errorResponse(res, 500, `服务器错误: ${e}`);
    }
  });

  /**
   * POST /clear-encryption-key - 清除内存中的加密密钥
   */
  router.post('/clear-encryption-key', async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = getUserIdFromRequest(req);
      if (!userId) {
        errorResponse(res, 401, '未认证或 Token 无效');
        return;
      }

      pluginDataService.removeEncryptionKey(userId);

      res.json({
        success: true,
        message: '加密密钥已清除',
        user_id: userId,
        timestamp: new Date().toISOString(),
      });
    } catch (e) {
      errorResponse(res, 500, `服务器错误: ${e}`);
    }
  });

  /**
   * GET /has-encryption-key - 检查是否已设置密钥
   */
  router.get('/has-encryption-key', async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = getUserIdFromRequest(req);
      if (!userId) {
        errorResponse(res, 401, '未认证或 Token 无效');
        return;
      }

      const hasKey = pluginDataService.hasEncryptionKey(userId);

      res.json({
        success: true,
        has_key: hasKey,
        user_id: userId,
        timestamp: new Date().toISOString(),
      });
    } catch (e) {
      errorResponse(res, 500, `服务器错误: ${e}`);
    }
  });

  /**
   * POST /re-encrypt - 用新密钥重新加密所有文件
   */
  router.post('/re-encrypt', async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = getUserIdFromRequest(req);
      if (!userId) {
        errorResponse(res, 401, '未认证或 Token 无效');
        return;
      }

      const data = req.body;
      const oldKey = data.old_key;
      const newKey = data.new_key;

      if (!oldKey || !newKey) {
        errorResponse(res, 400, '缺少 old_key 或 new_key 参数');
        return;
      }

      // 先设置旧密钥
      pluginDataService.setEncryptionKey(userId, oldKey);

      // 执行重新加密
      const result = await pluginDataService.reEncryptAllFiles(userId, newKey);

      res.json({
        success: true,
        message: '重新加密完成',
        files_re_encrypted: result.fileCount,
        errors: result.errors,
      });
    } catch (e) {
      errorResponse(res, 500, `重新加密失败: ${e}`);
    }
  });

  // ==================== API Key 管理 ====================

  /**
   * POST /api-keys - 创建 API Key
   */
  router.post('/api-keys', async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = getUserIdFromRequest(req);
      if (!userId) {
        errorResponse(res, 401, '未认证或 Token 无效');
        return;
      }

      const data = req.body;
      const name = data.name;
      if (!name || typeof name !== 'string') {
        errorResponse(res, 400, 'API Key 名称不能为空');
        return;
      }

      // 解析过期选项
      const expiryStr = data.expiry || 'never';
      const expiry = parseExpiry(expiryStr);

      // 生成 API Key
      const apiKey = await authService.generateApiKey({
        userId,
        name,
        expiry,
      });

      res.json({
        success: true,
        api_key: {
          id: apiKey.id,
          name: apiKey.name,
          key: apiKey.key,
          createdAt: apiKey.createdAt.toISOString(),
          expiresAt: apiKey.expiresAt?.toISOString(),
        },
        timestamp: new Date().toISOString(),
      });
    } catch (e) {
      errorResponse(res, 500, `服务器错误: ${e}`);
    }
  });

  /**
   * GET /api-keys - 列出用户的 API Keys
   */
  router.get('/api-keys', async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = getUserIdFromRequest(req);
      if (!userId) {
        errorResponse(res, 401, '未认证或 Token 无效');
        return;
      }

      const keys = await authService.listApiKeys(userId);

      res.json({
        success: true,
        api_keys: keys.map(k => ({
          id: k.id,
          name: k.name,
          createdAt: new Date(k.createdAt).toISOString(),
          lastUsedAt: k.lastUsedAt ? new Date(k.lastUsedAt).toISOString() : undefined,
          expiresAt: k.expiresAt ? new Date(k.expiresAt).toISOString() : undefined,
          isRevoked: k.isRevoked,
          isExpired: k.expiresAt ? new Date() > new Date(k.expiresAt) : false,
        })),
        count: keys.length,
        timestamp: new Date().toISOString(),
      });
    } catch (e) {
      errorResponse(res, 500, `服务器错误: ${e}`);
    }
  });

  /**
   * DELETE /api-keys/:id - 撤销 API Key
   */
  router.delete('/api-keys/:id', async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = getUserIdFromRequest(req);
      if (!userId) {
        errorResponse(res, 401, '未认证或 Token 无效');
        return;
      }

      const keyId = req.params.id;
      const success = await authService.revokeApiKey(userId, keyId);

      res.json({
        success,
        message: success ? 'API Key 已撤销' : '撤销失败',
        key_id: keyId,
        timestamp: new Date().toISOString(),
      });
    } catch (e) {
      errorResponse(res, 500, `服务器错误: ${e}`);
    }
  });

  /**
   * GET /user-info - 获取用户信息
   */
  router.get('/user-info', async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = getUserIdFromRequest(req);
      if (!userId) {
        errorResponse(res, 401, '未认证或 Token 无效');
        return;
      }

      // 获取用户基本信息
      const user = await storageService.findUserById(userId);
      if (!user) {
        errorResponse(res, 404, '用户不存在');
        return;
      }

      // 获取存储统计信息
      const stats = await storageService.getUserStorageStats(userId);

      res.json({
        success: true,
        user_info: {
          username: user.username,
          created_at: new Date(user.createdAt).toISOString(),
          sync_folder_count: stats.folderCount,
          sync_file_count: stats.fileCount,
          sync_total_size: stats.totalSize,
          sync_total_size_mb: (stats.totalSize / 1024 / 1024).toFixed(2),
        },
        timestamp: new Date().toISOString(),
      });
    } catch (e) {
      errorResponse(res, 500, `服务器错误: ${e}`);
    }
  });

  return router;
}
