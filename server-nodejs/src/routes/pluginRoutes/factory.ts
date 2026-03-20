import { Router, Request, Response } from 'express';
import { PluginDataService } from '../../services/pluginDataService';
import { getUserIdFromContext, getEncryptionKeyFromContext } from '../../middleware/authMiddleware';
import { PluginRouteConfig, PLUGIN_ROUTE_CONFIGS } from './routeConfig';
import { PluginHandlers, PluginResult } from './types';
import { errorResponse, resultToResponse } from './utils';
import { createCrudHandlers } from './crud';

// 导入专用处理器
import {
  createChatHandlers,
  createNotesHandlers,
  createBillHandlers,
  createTodoHandlers,
  createDiaryHandlers,
  createGoodsHandlers,
  createActivityHandlers,
  createCheckinHandlers,
  createTrackerHandlers,
  createCalendarHandlers,
  createContactHandlers,
  createDayHandlers,
} from './handlers';

// 重新导出类型和工具函数，供外部使用
export { PluginHandlers, PluginResult } from './types';
export { errorResponse, resultToResponse } from './utils';
export { createCrudHandlers } from './crud';

/**
 * 为指定插件创建处理器
 */
function createHandlersForPlugin(
  pluginDataService: PluginDataService,
  pluginId: string
): PluginHandlers {
  switch (pluginId) {
    case 'chat':
      return createChatHandlers(pluginDataService);
    case 'notes':
      return createNotesHandlers(pluginDataService);
    case 'bill':
      return createBillHandlers(pluginDataService);
    case 'todo':
      return createTodoHandlers(pluginDataService);
    case 'diary':
      return createDiaryHandlers(pluginDataService);
    case 'goods':
      return createGoodsHandlers(pluginDataService);
    case 'activity':
      return createActivityHandlers(pluginDataService);
    case 'checkin':
      return createCheckinHandlers(pluginDataService);
    case 'tracker':
      return createTrackerHandlers(pluginDataService);
    case 'calendar':
      return createCalendarHandlers(pluginDataService);
    case 'contact':
      return createContactHandlers(pluginDataService);
    case 'day':
      return createDayHandlers(pluginDataService);
    default:
      return createCrudHandlers(pluginDataService, pluginId, 'items');
  }
}

/**
 * 从请求中提取路径参数
 */
function extractPathParams(req: Request, pathPattern: string): Record<string, string> {
  const params: Record<string, string> = {};
  const pathParts = pathPattern.split('/');
  const urlParts = req.path.split('/');

  for (let i = 0; i < pathParts.length; i++) {
    if (pathParts[i].startsWith(':')) {
      const paramName = pathParts[i].slice(1);
      params[paramName] = urlParts[i] || '';
    }
  }

  return params;
}

/**
 * 从请求中提取查询参数
 */
function extractQueryParams(req: Request): Record<string, unknown> {
  const params: Record<string, unknown> = {};

  for (const [key, value] of Object.entries(req.query)) {
    // 尝试转换数字
    const num = Number(value);
    if (!isNaN(num) && value !== '') {
      params[key] = num;
    } else if (value === 'true') {
      params[key] = true;
    } else if (value === 'false') {
      params[key] = false;
    } else {
      params[key] = value;
    }
  }

  return params;
}

/**
 * 为插件创建路由
 */
export function createPluginRoutes(
  pluginDataService: PluginDataService,
  config: PluginRouteConfig
): Router {
  const router = Router();
  const handlers = createHandlersForPlugin(pluginDataService, config.pluginId);

  for (const route of config.routes) {
    const handler = handlers[route.handler];

    if (!handler) {
      console.warn(`Handler "${route.handler}" not found for plugin ${config.pluginId}`);
      continue;
    }

    const method = route.method;

    router[method](route.path, async (req: Request, res: Response): Promise<void> => {
      const userId = getUserIdFromContext(req);
      if (!userId) {
        errorResponse(res, 401, '未认证');
        return;
      }

      const encryptionKey = getEncryptionKeyFromContext(req);
      if (!encryptionKey) {
        errorResponse(res, 403, '缺少 X-Encryption-Key 请求头');
        return;
      }

      try {
        // 合并路径参数、查询参数和请求体
        const pathParams = extractPathParams(req, route.path);
        const queryParams = extractQueryParams(req);
        const bodyParams = req.body || {};

        const params = { ...queryParams, ...pathParams, ...bodyParams };

        const result = await handler(userId, encryptionKey, params, req);
        resultToResponse(res, result, method === 'post' ? 201 : 200);
      } catch (e) {
        errorResponse(res, 500, `服务器错误: ${e}`);
      }
    });
  }

  return router;
}

/**
 * 创建所有插件路由
 */
export function createPluginRoutesIndex(
  pluginDataService: PluginDataService
): Map<string, Router> {
  const routes = new Map<string, Router>();

  for (const config of PLUGIN_ROUTE_CONFIGS) {
    const router = createPluginRoutes(pluginDataService, config);
    routes.set(config.pluginId, router);
  }

  return routes;
}

/**
 * 获取支持的插件列表
 */
export function getSupportedPlugins(): string[] {
  return PLUGIN_ROUTE_CONFIGS.map((c) => c.pluginId);
}
