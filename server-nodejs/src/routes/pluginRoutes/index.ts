import { Router } from 'express';
import { PluginDataService } from '../../services/pluginDataService';
import { createPluginRoutes, createPluginRoutesIndex as createRoutesIndex, getSupportedPlugins as getPlugins } from './factory';
import { PLUGIN_ROUTE_CONFIGS, getPluginRouteConfig } from './routeConfig';

// 重新导出路由配置
export { PLUGIN_ROUTE_CONFIGS, getPluginRouteConfig } from './routeConfig';

/**
 * 创建所有插件路由
 */
export function createPluginRoutesIndex(pluginDataService: PluginDataService): Map<string, Router> {
  return createRoutesIndex(pluginDataService);
}

/**
 * 获取支持的插件列表
 */
export function getSupportedPlugins(): string[] {
  return getPlugins();
}

export { createPluginRoutes } from './factory';
