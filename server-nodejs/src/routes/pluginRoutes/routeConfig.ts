import { Router, Request, Response } from 'express';
import { PluginDataService } from '../../services/pluginDataService';
import { getUserIdFromContext } from '../../middleware/authMiddleware';

/**
 * 路由定义类型
 */
export interface RouteDefinition {
  method: 'get' | 'post' | 'put' | 'delete';
  path: string;
  handler: string; // handler 名称
  dataFile?: string; // 数据文件名，默认为 'data.json'
  resourceName?: string; // 资源名称，用于 CRUD 操作
}

/**
 * 插件路由配置
 */
export interface PluginRouteConfig {
  pluginId: string;
  routes: RouteDefinition[];
}

/**
 * 所有插件的 RESTful 路由配置
 * 基于 Dart 服务器的路由定义
 */
export const PLUGIN_ROUTE_CONFIGS: PluginRouteConfig[] = [
  // ==================== Chat 插件 ====================
  {
    pluginId: 'chat',
    routes: [
      // 频道 API
      { method: 'get', path: '/channels', handler: 'getList', resourceName: 'channels' },
      { method: 'get', path: '/channels/:id', handler: 'getById', resourceName: 'channels' },
      { method: 'post', path: '/channels', handler: 'create', resourceName: 'channels' },
      { method: 'put', path: '/channels/:id', handler: 'update', resourceName: 'channels' },
      { method: 'delete', path: '/channels/:id', handler: 'delete', resourceName: 'channels' },
      // 消息 API
      { method: 'get', path: '/channels/:channelId/messages', handler: 'getMessages', resourceName: 'messages' },
      { method: 'post', path: '/channels/:channelId/messages', handler: 'sendMessage', resourceName: 'messages' },
      { method: 'delete', path: '/channels/:channelId/messages/:messageId', handler: 'deleteMessage', resourceName: 'messages' },
      // 查找 API
      { method: 'get', path: '/find/channel', handler: 'findChannel', resourceName: 'channels' },
      { method: 'get', path: '/find/message', handler: 'findMessage', resourceName: 'messages' },
    ],
  },

  // ==================== Notes 插件 ====================
  {
    pluginId: 'notes',
    routes: [
      // 笔记 API
      { method: 'get', path: '/notes', handler: 'getList', resourceName: 'notes' },
      { method: 'get', path: '/notes/:id', handler: 'getById', resourceName: 'notes' },
      { method: 'post', path: '/notes', handler: 'create', resourceName: 'notes' },
      { method: 'put', path: '/notes/:id', handler: 'update', resourceName: 'notes' },
      { method: 'delete', path: '/notes/:id', handler: 'delete', resourceName: 'notes' },
      { method: 'post', path: '/notes/:id/move', handler: 'moveNote', resourceName: 'notes' },
      // 搜索 API
      { method: 'get', path: '/search', handler: 'search', resourceName: 'notes' },
      // 文件夹 API
      { method: 'get', path: '/folders', handler: 'getFolders', resourceName: 'folders' },
      { method: 'get', path: '/folders/:id', handler: 'getFolderById', resourceName: 'folders' },
      { method: 'post', path: '/folders', handler: 'createFolder', resourceName: 'folders' },
      { method: 'put', path: '/folders/:id', handler: 'updateFolder', resourceName: 'folders' },
      { method: 'delete', path: '/folders/:id', handler: 'deleteFolder', resourceName: 'folders' },
      { method: 'get', path: '/folders/:id/notes', handler: 'getFolderNotes', resourceName: 'notes' },
    ],
  },

  // ==================== Activity 插件 ====================
  {
    pluginId: 'activity',
    routes: [
      { method: 'get', path: '/activities', handler: 'getList', resourceName: 'activities' },
      { method: 'post', path: '/activities', handler: 'create', resourceName: 'activities' },
      { method: 'put', path: '/activities/:id', handler: 'update', resourceName: 'activities' },
      { method: 'delete', path: '/activities/:id', handler: 'delete', resourceName: 'activities' },
      { method: 'get', path: '/stats/today', handler: 'getTodayStats', resourceName: 'activities' },
    ],
  },

  // ==================== Goods 插件 ====================
  {
    pluginId: 'goods',
    routes: [
      { method: 'get', path: '/warehouses', handler: 'getWarehouses', resourceName: 'warehouses' },
      { method: 'get', path: '/items', handler: 'getList', resourceName: 'items' },
      { method: 'post', path: '/items', handler: 'create', resourceName: 'items' },
      { method: 'put', path: '/items/:id', handler: 'update', resourceName: 'items' },
      { method: 'delete', path: '/items/:id', handler: 'delete', resourceName: 'items' },
      { method: 'get', path: '/search', handler: 'search', resourceName: 'items' },
    ],
  },

  // ==================== Bill 插件 ====================
  {
    pluginId: 'bill',
    routes: [
      // 账户 API
      { method: 'get', path: '/accounts', handler: 'getList', resourceName: 'accounts' },
      { method: 'get', path: '/accounts/:id', handler: 'getById', resourceName: 'accounts' },
      { method: 'post', path: '/accounts', handler: 'create', resourceName: 'accounts' },
      { method: 'put', path: '/accounts/:id', handler: 'update', resourceName: 'accounts' },
      { method: 'delete', path: '/accounts/:id', handler: 'delete', resourceName: 'accounts' },
      // 账单 API
      { method: 'get', path: '/bills', handler: 'getBills', resourceName: 'bills' },
      { method: 'get', path: '/bills/:id', handler: 'getBillById', resourceName: 'bills' },
      { method: 'post', path: '/bills', handler: 'createBill', resourceName: 'bills' },
      { method: 'put', path: '/bills/:id', handler: 'updateBill', resourceName: 'bills' },
      { method: 'delete', path: '/bills/:id', handler: 'deleteBill', resourceName: 'bills' },
      // 嵌套账单 API（MCP 客户端使用）
      { method: 'get', path: '/accounts/:accountId/bills', handler: 'getBillsByAccount', resourceName: 'bills' },
      { method: 'post', path: '/accounts/:accountId/bills', handler: 'createBillForAccount', resourceName: 'bills' },
      // 统计 API
      { method: 'get', path: '/stats', handler: 'getStats', resourceName: 'bills' },
    ],
  },

  // ==================== Todo 插件 ====================
  {
    pluginId: 'todo',
    routes: [
      { method: 'get', path: '/tasks', handler: 'getList', resourceName: 'tasks' },
      { method: 'get', path: '/tasks/:id', handler: 'getById', resourceName: 'tasks' },
      { method: 'post', path: '/tasks', handler: 'create', resourceName: 'tasks' },
      { method: 'put', path: '/tasks/:id', handler: 'update', resourceName: 'tasks' },
      { method: 'delete', path: '/tasks/:id', handler: 'delete', resourceName: 'tasks' },
      { method: 'post', path: '/tasks/:id/complete', handler: 'completeTask', resourceName: 'tasks' },
      { method: 'get', path: '/tasks/filter/today', handler: 'getTodayTasks', resourceName: 'tasks' },
      { method: 'get', path: '/tasks/filter/overdue', handler: 'getOverdueTasks', resourceName: 'tasks' },
      { method: 'get', path: '/search', handler: 'search', resourceName: 'tasks' },
      { method: 'get', path: '/stats', handler: 'getStats', resourceName: 'tasks' },
    ],
  },

  // ==================== Diary 插件 ====================
  {
    pluginId: 'diary',
    routes: [
      { method: 'get', path: '/entries', handler: 'getList', resourceName: 'entries' },
      { method: 'get', path: '/entries/:date', handler: 'getByDate', resourceName: 'entries' },
      { method: 'post', path: '/entries', handler: 'create', resourceName: 'entries' },
      { method: 'put', path: '/entries/:date', handler: 'updateByDate', resourceName: 'entries' },
      { method: 'delete', path: '/entries/:date', handler: 'deleteByDate', resourceName: 'entries' },
      { method: 'get', path: '/search', handler: 'search', resourceName: 'entries' },
      { method: 'get', path: '/stats', handler: 'getStats', resourceName: 'entries' },
    ],
  },

  // ==================== Checkin 插件 ====================
  {
    pluginId: 'checkin',
    routes: [
      { method: 'get', path: '/items', handler: 'getList', resourceName: 'items' },
      { method: 'get', path: '/items/:id', handler: 'getById', resourceName: 'items' },
      { method: 'post', path: '/items', handler: 'create', resourceName: 'items' },
      { method: 'put', path: '/items/:id', handler: 'update', resourceName: 'items' },
      { method: 'delete', path: '/items/:id', handler: 'delete', resourceName: 'items' },
      { method: 'post', path: '/items/:id/checkin', handler: 'addRecord', resourceName: 'records' },
      { method: 'get', path: '/stats', handler: 'getStats', resourceName: 'items' },
    ],
  },

  // ==================== Calendar 插件 ====================
  {
    pluginId: 'calendar',
    routes: [
      { method: 'get', path: '/events', handler: 'getList', resourceName: 'events' },
      { method: 'get', path: '/events/:id', handler: 'getById', resourceName: 'events' },
      { method: 'post', path: '/events', handler: 'create', resourceName: 'events' },
      { method: 'put', path: '/events/:id', handler: 'update', resourceName: 'events' },
      { method: 'delete', path: '/events/:id', handler: 'delete', resourceName: 'events' },
      { method: 'post', path: '/events/:id/complete', handler: 'completeEvent', resourceName: 'events' },
      { method: 'get', path: '/events/search', handler: 'search', resourceName: 'events' },
    ],
  },

  // ==================== Contact 插件 ====================
  {
    pluginId: 'contact',
    routes: [
      { method: 'get', path: '/contacts', handler: 'getList', resourceName: 'contacts' },
      { method: 'get', path: '/contacts/:id', handler: 'getById', resourceName: 'contacts' },
      { method: 'post', path: '/contacts', handler: 'create', resourceName: 'contacts' },
      { method: 'put', path: '/contacts/:id', handler: 'update', resourceName: 'contacts' },
      { method: 'delete', path: '/contacts/:id', handler: 'delete', resourceName: 'contacts' },
      { method: 'get', path: '/contacts/search', handler: 'search', resourceName: 'contacts' },
      { method: 'get', path: '/stats/total-contacts', handler: 'getStats', resourceName: 'contacts' },
    ],
  },

  // ==================== Tracker 插件 ====================
  {
    pluginId: 'tracker',
    routes: [
      { method: 'get', path: '/goals', handler: 'getList', resourceName: 'goals' },
      { method: 'get', path: '/goals/:id', handler: 'getById', resourceName: 'goals' },
      { method: 'post', path: '/goals', handler: 'create', resourceName: 'goals' },
      { method: 'put', path: '/goals/:id', handler: 'update', resourceName: 'goals' },
      { method: 'delete', path: '/goals/:id', handler: 'delete', resourceName: 'goals' },
      { method: 'post', path: '/records', handler: 'addRecord', resourceName: 'records' },
      { method: 'get', path: '/goals/:goalId/records', handler: 'getRecords', resourceName: 'records' },
      { method: 'get', path: '/stats', handler: 'getStats', resourceName: 'goals' },
    ],
  },

  // ==================== Day 插件 ====================
  {
    pluginId: 'day',
    routes: [
      { method: 'get', path: '/days', handler: 'getList', resourceName: 'days' },
      { method: 'get', path: '/days/:id', handler: 'getById', resourceName: 'days' },
      { method: 'post', path: '/days', handler: 'create', resourceName: 'days' },
      { method: 'put', path: '/days/:id', handler: 'update', resourceName: 'days' },
      { method: 'delete', path: '/days/:id', handler: 'delete', resourceName: 'days' },
      { method: 'get', path: '/search', handler: 'search', resourceName: 'days' },
      { method: 'get', path: '/stats', handler: 'getStats', resourceName: 'days' },
    ],
  },

  // ==================== 其他插件使用通用路由 ====================
  {
    pluginId: 'agent_chat',
    routes: [
      { method: 'get', path: '/items', handler: 'getList', resourceName: 'items' },
      { method: 'get', path: '/item/:id', handler: 'getById', resourceName: 'items' },
      { method: 'post', path: '/item', handler: 'create', resourceName: 'items' },
      { method: 'put', path: '/item/:id', handler: 'update', resourceName: 'items' },
      { method: 'delete', path: '/item/:id', handler: 'delete', resourceName: 'items' },
    ],
  },
  {
    pluginId: 'calendar_album',
    routes: [
      { method: 'get', path: '/items', handler: 'getList', resourceName: 'items' },
      { method: 'get', path: '/item/:id', handler: 'getById', resourceName: 'items' },
      { method: 'post', path: '/item', handler: 'create', resourceName: 'items' },
      { method: 'put', path: '/item/:id', handler: 'update', resourceName: 'items' },
      { method: 'delete', path: '/item/:id', handler: 'delete', resourceName: 'items' },
    ],
  },
  {
    pluginId: 'database',
    routes: [
      { method: 'get', path: '/items', handler: 'getList', resourceName: 'items' },
      { method: 'get', path: '/item/:id', handler: 'getById', resourceName: 'items' },
      { method: 'post', path: '/item', handler: 'create', resourceName: 'items' },
      { method: 'put', path: '/item/:id', handler: 'update', resourceName: 'items' },
      { method: 'delete', path: '/item/:id', handler: 'delete', resourceName: 'items' },
    ],
  },
  {
    pluginId: 'nodes',
    routes: [
      { method: 'get', path: '/items', handler: 'getList', resourceName: 'items' },
      { method: 'get', path: '/item/:id', handler: 'getById', resourceName: 'items' },
      { method: 'post', path: '/item', handler: 'create', resourceName: 'items' },
      { method: 'put', path: '/item/:id', handler: 'update', resourceName: 'items' },
      { method: 'delete', path: '/item/:id', handler: 'delete', resourceName: 'items' },
    ],
  },
  {
    pluginId: 'openai',
    routes: [
      { method: 'get', path: '/items', handler: 'getList', resourceName: 'items' },
      { method: 'get', path: '/item/:id', handler: 'getById', resourceName: 'items' },
      { method: 'post', path: '/item', handler: 'create', resourceName: 'items' },
      { method: 'put', path: '/item/:id', handler: 'update', resourceName: 'items' },
      { method: 'delete', path: '/item/:id', handler: 'delete', resourceName: 'items' },
    ],
  },
  {
    pluginId: 'store',
    routes: [
      { method: 'get', path: '/items', handler: 'getList', resourceName: 'items' },
      { method: 'get', path: '/item/:id', handler: 'getById', resourceName: 'items' },
      { method: 'post', path: '/item', handler: 'create', resourceName: 'items' },
      { method: 'put', path: '/item/:id', handler: 'update', resourceName: 'items' },
      { method: 'delete', path: '/item/:id', handler: 'delete', resourceName: 'items' },
    ],
  },
  {
    pluginId: 'timer',
    routes: [
      { method: 'get', path: '/items', handler: 'getList', resourceName: 'items' },
      { method: 'get', path: '/item/:id', handler: 'getById', resourceName: 'items' },
      { method: 'post', path: '/item', handler: 'create', resourceName: 'items' },
      { method: 'put', path: '/item/:id', handler: 'update', resourceName: 'items' },
      { method: 'delete', path: '/item/:id', handler: 'delete', resourceName: 'items' },
    ],
  },
];

/**
 * 获取插件的路由配置
 */
export function getPluginRouteConfig(pluginId: string): PluginRouteConfig | undefined {
  return PLUGIN_ROUTE_CONFIGS.find(config => config.pluginId === pluginId);
}
