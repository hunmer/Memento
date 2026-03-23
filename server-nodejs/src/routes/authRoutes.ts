import { Router, Request, Response } from 'express';
import { AuthService, PasswordHashUtils } from '../services/authService';
import { FileStorageService } from '../services/fileStorageService';
import { PluginDataService } from '../services/pluginDataService';
import { sendMulticast } from '../services/fcmService';

/**
 * 认证路由
 *
 * 安全说明：服务端不保存用户密钥，每次请求需要通过请求头 X-Encryption-Key 传递密钥
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
   * 从请求头获取加密密钥
   */
  function getEncryptionKeyFromRequest(req: Request): string | undefined {
    return req.headers['x-encryption-key'] as string | undefined;
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
   * GET /key-verification - 获取密钥验证文件
   *
   * 返回加密的验证文件内容，由客户端在本地解密验证
   * 服务端不接触明文密钥
   */
  router.get('/key-verification', async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = getUserIdFromRequest(req);
      if (!userId) {
        errorResponse(res, 401, '未认证或 Token 无效');
        return;
      }

      // 读取加密的验证文件
      const verificationFile = await storageService.readEncryptedFile(userId, '.key_verification.json');

      if (!verificationFile) {
        res.json({
          success: true,
          exists: false,
          message: '密钥验证文件不存在',
        });
        return;
      }

      // 返回加密的验证文件内容，由客户端解密
      res.json({
        success: true,
        exists: true,
        encrypted_data: verificationFile.encrypted_data,
        md5: verificationFile.md5,
        updated_at: verificationFile.updated_at,
      });
    } catch (e) {
      errorResponse(res, 500, `服务器错误: ${e}`);
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

  // ==================== 设备管理 ====================

  /**
   * GET /devices - 获取设备列表
   */
  router.get('/devices', async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = getUserIdFromRequest(req);
      if (!userId) {
        errorResponse(res, 401, '未认证或 Token 无效');
        return;
      }

      const devices = await authService.getDevices(userId);

      res.json({
        success: true,
        devices: devices.map(d => ({
          device_id: d.deviceId,
          device_name: d.deviceName,
          created_at: new Date(d.createdAt).toISOString(),
          last_sync_at: d.lastSyncAt ? new Date(d.lastSyncAt).toISOString() : undefined,
          fcm_token: d.fcmToken ? `${d.fcmToken.substring(0, 10)}...` : undefined, // 只返回前缀
          platform: d.platform,
        })),
        count: devices.length,
        timestamp: new Date().toISOString(),
      });
    } catch (e) {
      errorResponse(res, 500, `服务器错误: ${e}`);
    }
  });

  /**
   * POST /devices - 注册/更新设备
   */
  router.post('/devices', async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = getUserIdFromRequest(req);
      if (!userId) {
        errorResponse(res, 401, '未认证或 Token 无效');
        return;
      }

      const data = req.body;

      if (!data.device_id) {
        errorResponse(res, 400, '设备 ID 不能为空');
        return;
      }

      const device = await authService.registerDevice({
        userId,
        deviceId: data.device_id,
        deviceName: data.device_name || 'Unknown Device',
        fcmToken: data.fcm_token,
        platform: data.platform,
      });

      res.json({
        success: true,
        message: '设备注册成功',
        device: {
          device_id: device.deviceId,
          device_name: device.deviceName,
        },
        timestamp: new Date().toISOString(),
      });
    } catch (e) {
      errorResponse(res, 500, `服务器错误: ${e}`);
    }
  });

  /**
   * DELETE /devices/:deviceId - 删除设备
   */
  router.delete('/devices/:deviceId', async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = getUserIdFromRequest(req);
      if (!userId) {
        errorResponse(res, 401, '未认证或 Token 无效');
        return;
      }

      const deviceId = req.params.deviceId;

      await authService.deleteDevice(userId, deviceId);

      res.json({
        success: true,
        message: '设备已删除',
        device_id: deviceId,
        timestamp: new Date().toISOString(),
      });
    } catch (e) {
      const errorMessage = e instanceof Error ? e.message : String(e);
      if (errorMessage.includes('不存在')) {
        errorResponse(res, 404, errorMessage);
      } else {
        errorResponse(res, 500, `服务器错误: ${e}`);
      }
    }
  });

  /**
   * POST /devices/push - 推送消息到设备
   */
  router.post('/devices/push', async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = getUserIdFromRequest(req);
      if (!userId) {
        errorResponse(res, 401, '未认证或 Token 无效');
        return;
      }

      const { device_id, title, body, data } = req.body;

      if (!title || !body) {
        errorResponse(res, 400, '标题和内容不能为空');
        return;
      }

      // 获取目标设备的 FCM Tokens
      const fcmTokens = await authService.getDeviceFcmTokens(userId, device_id);

      if (fcmTokens.length === 0) {
        errorResponse(res, 400, '没有可用的设备或设备未注册 FCM Token');
        return;
      }

      // 发送 FCM 推送
      const result = await sendMulticast(fcmTokens, title, body, data);

      res.json({
        success: result.success > 0,
        message: `成功发送 ${result.success} 条，失败 ${result.failure} 条`,
        sent_count: result.success,
        failure_count: result.failure,
        target_devices: fcmTokens.length,
        results: result.results,
        timestamp: new Date().toISOString(),
      });
    } catch (e) {
      errorResponse(res, 500, `服务器错误: ${e}`);
    }
  });

  // ==================== API 访问控制 ====================

  /**
   * GET /api-access - 获取 API 访问状态
   */
  router.get('/api-access', async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = getUserIdFromRequest(req);
      if (!userId) {
        errorResponse(res, 401, '未认证或 Token 无效');
        return;
      }

      const enabled = await authService.getApiAccessStatus(userId);

      res.json({
        success: true,
        enabled,
        timestamp: new Date().toISOString(),
      });
    } catch (e) {
      errorResponse(res, 500, `服务器错误: ${e}`);
    }
  });

  /**
   * PUT /api-access - 设置 API 访问状态
   */
  router.put('/api-access', async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = getUserIdFromRequest(req);
      if (!userId) {
        errorResponse(res, 401, '未认证或 Token 无效');
        return;
      }

      const { enabled } = req.body;
      if (typeof enabled !== 'boolean') {
        errorResponse(res, 400, 'enabled 参数必须是布尔值');
        return;
      }

      await authService.setApiAccessStatus(userId, enabled);

      res.json({
        success: true,
        enabled,
        message: enabled ? 'API 访问已开启' : 'API 访问已关闭',
        timestamp: new Date().toISOString(),
      });
    } catch (e) {
      errorResponse(res, 500, `服务器错误: ${e}`);
    }
  });

  return router;
}
