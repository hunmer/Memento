import { Router, Request, Response } from 'express';
import { PluginService } from '../services/pluginService';
import { AuthService } from '../services/authService';

/**
 * 插件系统 API 路由
 *
 * 所有端点需要管理员权限
 */
export function createPluginSystemRoutes(
  pluginService: PluginService,
  authService: AuthService,
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
   * 验证管理员权限
   */
  async function requireAdmin(req: Request, res: Response): Promise<string | null> {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      errorResponse(res, 401, '未认证');
      return null;
    }

    const token = authHeader.substring(7);
    const userId = authService.getUserIdFromToken(token);

    if (!userId) {
      errorResponse(res, 401, 'Token 无效或已过期');
      return null;
    }

    // 检查管理员权限
    const user = await authService.getUserById(userId);
    if (!user || !user.isAdmin) {
      errorResponse(res, 403, '需要管理员权限');
      return null;
    }

    return userId;
  }

  // ==================== 已安装插件管理 ====================

  /**
   * GET /api/v1/system/plugins - 获取已安装插件列表
   */
  router.get('/plugins', async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = await requireAdmin(req, res);
      if (!userId) return;

      const plugins = await pluginService.getInstalledPlugins();

      res.json({
        success: true,
        plugins,
        total: plugins.length,
        timestamp: new Date().toISOString(),
      });
    } catch (e) {
      errorResponse(res, 500, `服务器错误: ${e}`);
    }
  });

  /**
   * GET /api/v1/system/plugins/:uuid - 获取单个插件详情
   */
  router.get('/plugins/:uuid', async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = await requireAdmin(req, res);
      if (!userId) return;

      const plugin = await pluginService.getPluginByUUID(req.params.uuid);

      if (!plugin) {
        errorResponse(res, 404, '插件不存在');
        return;
      }

      res.json({
        success: true,
        plugin,
        timestamp: new Date().toISOString(),
      });
    } catch (e) {
      errorResponse(res, 500, `服务器错误: ${e}`);
    }
  });

  /**
   * POST /api/v1/system/plugins/upload - 上传并安装插件
   */
  router.post('/plugins/upload', async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = await requireAdmin(req, res);
      if (!userId) return;

      // 检查文件上传
      if (!req.file) {
        errorResponse(res, 400, '请上传插件 ZIP 文件');
        return;
      }

      const plugin = await pluginService.installFromZip(req.file.buffer);

      res.json({
        success: true,
        plugin,
        message: '插件安装成功',
        timestamp: new Date().toISOString(),
      });
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e);
      errorResponse(res, 400, message);
    }
  });

  /**
   * POST /api/v1/system/plugins/:uuid/enable - 启用插件
   */
  router.post('/plugins/:uuid/enable', async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = await requireAdmin(req, res);
      if (!userId) return;

      await pluginService.enablePlugin(req.params.uuid);

      res.json({
        success: true,
        message: '插件已启用',
        uuid: req.params.uuid,
        timestamp: new Date().toISOString(),
      });
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e);
      errorResponse(res, 400, message);
    }
  });

  /**
   * POST /api/v1/system/plugins/:uuid/disable - 禁用插件
   */
  router.post('/plugins/:uuid/disable', async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = await requireAdmin(req, res);
      if (!userId) return;

      await pluginService.disablePlugin(req.params.uuid);

      res.json({
        success: true,
        message: '插件已禁用',
        uuid: req.params.uuid,
        timestamp: new Date().toISOString(),
      });
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e);
      errorResponse(res, 400, message);
    }
  });

  /**
   * DELETE /api/v1/system/plugins/:uuid - 卸载插件
   */
  router.delete('/plugins/:uuid', async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = await requireAdmin(req, res);
      if (!userId) return;

      await pluginService.uninstallPlugin(req.params.uuid);

      res.json({
        success: true,
        message: '插件已卸载',
        uuid: req.params.uuid,
        timestamp: new Date().toISOString(),
      });
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e);
      errorResponse(res, 400, message);
    }
  });

  // ==================== 插件商店 ====================

  /**
   * GET /api/v1/system/plugins/store - 获取商店插件列表
   */
  router.get('/plugins/store', async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = await requireAdmin(req, res);
      if (!userId) return;

      const plugins = await pluginService.fetchStorePlugins();
      const config = await pluginService.getStoreConfig();

      res.json({
        success: true,
        plugins,
        sourceURL: config.storeURL,
        lastSyncAt: config.lastSyncAt,
        total: plugins.length,
        timestamp: new Date().toISOString(),
      });
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e);
      errorResponse(res, 500, message);
    }
  });

  /**
   * POST /api/v1/system/plugins/store/install - 从商店安装插件
   */
  router.post('/plugins/store/install', async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = await requireAdmin(req, res);
      if (!userId) return;

      const { downloadURL } = req.body;
      if (!downloadURL) {
        errorResponse(res, 400, '请提供 downloadURL');
        return;
      }

      const plugin = await pluginService.installFromStore(downloadURL);

      res.json({
        success: true,
        plugin,
        message: '插件安装成功',
        timestamp: new Date().toISOString(),
      });
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e);
      errorResponse(res, 400, message);
    }
  });

  /**
   * GET /api/v1/system/plugins/config - 获取商店配置
   */
  router.get('/plugins/config', async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = await requireAdmin(req, res);
      if (!userId) return;

      const config = await pluginService.getStoreConfig();

      res.json({
        success: true,
        config,
        timestamp: new Date().toISOString(),
      });
    } catch (e) {
      errorResponse(res, 500, `服务器错误: ${e}`);
    }
  });

  /**
   * PUT /api/v1/system/plugins/config - 更新商店配置
   */
  router.put('/plugins/config', async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = await requireAdmin(req, res);
      if (!userId) return;

      const config = await pluginService.updateStoreConfig(req.body);

      res.json({
        success: true,
        config,
        message: '配置已更新',
        timestamp: new Date().toISOString(),
      });
    } catch (e) {
      errorResponse(res, 500, `服务器错误: ${e}`);
    }
  });

  return router;
}
