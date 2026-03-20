import { Router } from 'express';
import { PluginDataService } from '../../services/pluginDataService';
import { createPluginRoutes, createBasePluginHandlers } from './factory';

/**
 * 支持的插件列表
 */
const SUPPORTED_PLUGINS = [
  'chat',
  'notes',
  'activity',
  'goods',
  'bill',
  'todo',
  'agent_chat',
  'calendar_album',
  'calendar',
  'checkin',
  'contact',
  'database',
  'day',
  'diary',
  'nodes',
  'openai',
  'store',
  'timer',
  'tracker',
];

/**
 * 创建所有插件路由
 */
export function createPluginRoutesIndex(pluginDataService: PluginDataService): Map<string, Router> {
  const routes = new Map<string, Router>();

  for (const pluginId of SUPPORTED_PLUGINS) {
    const handlers = createBasePluginHandlers(pluginDataService, pluginId);
    const router = createPluginRoutes(pluginDataService, pluginId, handlers);
    routes.set(pluginId, router);
  }

  return routes;
}

/**
 * 获取支持的插件列表
 */
export function getSupportedPlugins(): string[] {
  return [...SUPPORTED_PLUGINS];
}

export { createPluginRoutes, createBasePluginHandlers } from './factory';
