import { Router, Request, Response } from 'express';
import { PluginDataService } from '../services/pluginDataService';
import { getUserIdFromContext } from '../middleware/authMiddleware';

/**
 * 错误码到 HTTP 状态码的映射
 */
function errorCodeToStatus(code?: string): number {
  switch (code) {
    case 'NOT_FOUND': return 404;
    case 'INVALID_PARAMS': return 400;
    case 'UNAUTHORIZED': return 401;
    case 'FORBIDDEN': return 403;
    default: return 500;
  }
}

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
 * 结果转换为 HTTP 响应
 */
function resultToResponse<T>(res: Response, result: {
  isSuccess: boolean;
  data?: T;
  message?: string;
  code?: string;
}, successStatus: number = 200): void {
  if (result.isSuccess) {
    res.status(successStatus).json({
      success: true,
      data: result.data,
      timestamp: new Date().toISOString(),
    });
  } else {
    const statusCode = errorCodeToStatus(result.code);
    res.status(statusCode).json({
      success: false,
      error: result.message,
      code: result.code,
      timestamp: new Date().toISOString(),
    });
  }
}

/**
 * 插件路由工厂
 *
 * 为插件创建标准的 CRUD 路由
 */
export function createPluginRoutes(
  pluginDataService: PluginDataService,
  pluginId: string,
  handlers: PluginHandlers,
): Router {
  const router = Router();

  // GET /items - 获取所有项目
  router.get('/items', async (req: Request, res: Response): Promise<void> => {
    const userId = getUserIdFromContext(req);
    if (!userId) {
      errorResponse(res, 401, '未认证');
      return;
    }

    try {
      const params: Record<string, unknown> = {};
      const query = req.query;

      if (query.offset) params.offset = parseInt(query.offset as string, 10) || 0;
      if (query.count) params.count = parseInt(query.count as string, 10) || 100;

      const result = await handlers.getItems(userId, params);
      resultToResponse(res, result);
    } catch (e) {
      errorResponse(res, 500, `服务器错误: ${e}`);
    }
  });

  // GET /item/:id - 获取单个项目
  router.get('/item/:id', async (req: Request, res: Response): Promise<void> => {
    const userId = getUserIdFromContext(req);
    if (!userId) {
      errorResponse(res, 401, '未认证');
      return;
    }

    try {
      const result = await handlers.getItem(userId, { id: req.params.id });
      resultToResponse(res, result);
    } catch (e) {
      errorResponse(res, 500, `服务器错误: ${e}`);
    }
  });

  // POST /item - 创建项目
  router.post('/item', async (req: Request, res: Response): Promise<void> => {
    const userId = getUserIdFromContext(req);
    if (!userId) {
      errorResponse(res, 401, '未认证');
      return;
    }

    try {
      const result = await handlers.createItem(userId, req.body);
      resultToResponse(res, result, 201);
    } catch (e) {
      errorResponse(res, 400, `无效的请求体: ${e}`);
    }
  });

  // PUT /item/:id - 更新项目
  router.put('/item/:id', async (req: Request, res: Response): Promise<void> => {
    const userId = getUserIdFromContext(req);
    if (!userId) {
      errorResponse(res, 401, '未认证');
      return;
    }

    try {
      const params = { ...req.body, id: req.params.id };
      const result = await handlers.updateItem(userId, params);
      resultToResponse(res, result);
    } catch (e) {
      errorResponse(res, 400, `无效的请求体: ${e}`);
    }
  });

  // DELETE /item/:id - 删除项目
  router.delete('/item/:id', async (req: Request, res: Response): Promise<void> => {
    const userId = getUserIdFromContext(req);
    if (!userId) {
      errorResponse(res, 401, '未认证');
      return;
    }

    try {
      const result = await handlers.deleteItem(userId, { id: req.params.id });
      resultToResponse(res, result);
    } catch (e) {
      errorResponse(res, 500, `服务器错误: ${e}`);
    }
  });

  return router;
}

/**
 * 插件处理器接口
 */
export interface PluginHandlers {
  getItems: (userId: string, params: Record<string, unknown>) => Promise<PluginResult>;
  getItem: (userId: string, params: Record<string, unknown>) => Promise<PluginResult>;
  createItem: (userId: string, params: Record<string, unknown>) => Promise<PluginResult>;
  updateItem: (userId: string, params: Record<string, unknown>) => Promise<PluginResult>;
  deleteItem: (userId: string, params: Record<string, unknown>) => Promise<PluginResult>;
}

/**
 * 插件结果类型
 */
export interface PluginResult {
  isSuccess: boolean;
  data?: unknown;
  message?: string;
  code?: string;
}

/**
 * 创建基础插件处理器
 */
export function createBasePluginHandlers(
  pluginDataService: PluginDataService,
  pluginId: string,
  dataFile: string = 'data.json',
): PluginHandlers {
  return {
    async getItems(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const data = await pluginDataService.readPluginData(userId, pluginId, dataFile);
        let items = Array.isArray(data) ? data : (data as Record<string, unknown>)?.items || [];

        // 分页
        const offset = (params.offset as number) || 0;
        const count = (params.count as number) || 100;
        const total = items.length;
        items = items.slice(offset, offset + count);

        return {
          isSuccess: true,
          data: {
            data: items,
            total,
            offset,
            count: items.length,
            hasMore: offset + items.length < total,
          },
        };
      } catch (e) {
        return { isSuccess: false, message: `读取数据失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    async getItem(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const data = await pluginDataService.readPluginData(userId, pluginId, dataFile);
        const items = Array.isArray(data) ? data : (data as Record<string, unknown>)?.items || [];
        const item = items.find((i: Record<string, unknown>) => i.id === params.id);

        if (!item) {
          return { isSuccess: false, message: '项目不存在', code: 'NOT_FOUND' };
        }

        return { isSuccess: true, data: item };
      } catch (e) {
        return { isSuccess: false, message: `读取数据失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    async createItem(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const data = await pluginDataService.readPluginData(userId, pluginId, dataFile);
        let items = Array.isArray(data) ? [...data] : [...((data as Record<string, unknown>)?.items || [])];

        const now = new Date().toISOString();
        const newItem = {
          ...params,
          id: params.id || generateUUID(),
          createdAt: now,
          updatedAt: now,
        };

        items.push(newItem);

        await pluginDataService.writePluginData(userId, pluginId, dataFile, { items });

        return { isSuccess: true, data: newItem };
      } catch (e) {
        return { isSuccess: false, message: `创建失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    async updateItem(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const data = await pluginDataService.readPluginData(userId, pluginId, dataFile);
        let items = Array.isArray(data) ? [...data] : [...((data as Record<string, unknown>)?.items || [])];
        const index = items.findIndex((i: Record<string, unknown>) => i.id === params.id);

        if (index === -1) {
          return { isSuccess: false, message: '项目不存在', code: 'NOT_FOUND' };
        }

        const updatedItem = {
          ...items[index],
          ...params,
          updatedAt: new Date().toISOString(),
        };
        items[index] = updatedItem;

        await pluginDataService.writePluginData(userId, pluginId, dataFile, { items });

        return { isSuccess: true, data: updatedItem };
      } catch (e) {
        return { isSuccess: false, message: `更新失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    async deleteItem(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const data = await pluginDataService.readPluginData(userId, pluginId, dataFile);
        let items = Array.isArray(data) ? [...data] : [...((data as Record<string, unknown>)?.items || [])];
        const index = items.findIndex((i: Record<string, unknown>) => i.id === params.id);

        if (index === -1) {
          return { isSuccess: false, message: '项目不存在', code: 'NOT_FOUND' };
        }

        items.splice(index, 1);
        await pluginDataService.writePluginData(userId, pluginId, dataFile, { items });

        return { isSuccess: true, data: { id: params.id } };
      } catch (e) {
        return { isSuccess: false, message: `删除失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },
  };
}

/**
 * 生成 UUID
 */
function generateUUID(): string {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = Math.random() * 16 | 0;
    const v = c === 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
}
