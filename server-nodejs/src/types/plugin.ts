// ==================== 插件系统类型定义 ====================

/**
 * 插件生命周期状态
 */
export type PluginStatus = 'installed' | 'enabled' | 'disabled';

/**
 * 插件权限类型
 */
export interface PluginPermissions {
  /** 可访问的插件 ID 列表，空数组表示无限制 */
  dataAccess: string[];
  /** 允许的操作类型 */
  operations: ('create' | 'read' | 'update' | 'delete')[];
  /** 是否允许 HTTP 请求 */
  networkAccess: boolean;
}

/**
 * 插件元信息（来自 metadata.json）
 */
export interface PluginMetadata {
  uuid: string;
  title: string;
  author: string;
  description: string;
  version: string;
  website?: string;
  permissions: PluginPermissions;
  updateURL?: string;
  priority?: number;
  /** 订阅的事件列表，支持通配符如 'chat::*' */
  events?: string[];
}

/**
 * 已安装的插件信息（包含运行时状态）
 */
export interface InstalledPlugin extends PluginMetadata {
  /** 安装时间 */
  installedAt: string;
  /** 当前状态 */
  status: PluginStatus;
  /** 插件代码目录 */
  pluginPath: string;
  /** 最后更新时间 */
  updatedAt: string;
}

/**
 * 插件商店条目
 */
export interface StorePlugin extends PluginMetadata {
  /** 下载地址 */
  downloadURL: string;
  /** 商店来源 URL */
  sourceURL: string;
}

/**
 * 插件商店配置
 */
export interface StoreConfig {
  /** 商店 JSON URL */
  storeURL: string;
  /** 最后同步时间 */
  lastSyncAt?: string;
  /** 同步间隔（毫秒），0 表示不自动同步 */
  syncInterval: number;
}

/**
 * 插件钩子上下文 - before 钩子
 */
export interface BeforeHookContext<T = unknown> {
  /** 事件名称 */
  event: string;
  /** 操作类型 */
  action: 'create' | 'read' | 'update' | 'delete';
  /** 目标插件 ID */
  pluginId: string;
  /** 目标实体名称 */
  entity: string;
  /** 用户 ID */
  userId: string;
  /** 操作数据（可被修改） */
  data: T;
  /** 是否已取消 */
  canceled: boolean;
  /** 取消原因 */
  cancelReason?: string;
}

/**
 * 插件钩子上下文 - after 钩子
 */
export interface AfterHookContext<T = unknown> {
  /** 事件名称 */
  event: string;
  /** 操作类型 */
  action: 'create' | 'read' | 'update' | 'delete';
  /** 目标插件 ID */
  pluginId: string;
  /** 目标实体名称 */
  entity: string;
  /** 用户 ID */
  userId: string;
  /** 操作结果 */
  result: T;
  /** 是否成功 */
  success: boolean;
  /** 错误信息 */
  error?: string;
}

/**
 * 插件钩子处理器
 */
export type BeforeHookHandler<T = unknown> = (ctx: BeforeHookContext<T>) => BeforeHookContext<T> | Promise<BeforeHookContext<T>>;
export type AfterHookHandler<T = unknown> = (ctx: AfterHookContext<T>) => void | Promise<void>;

/**
 * 插件模块导出接口
 */
export interface PluginModule {
  /** 插件元信息 */
  metadata: PluginMetadata;
  /** 生命周期：加载时调用 */
  onLoad?: () => void | Promise<void>;
  /** 生命周期：卸载时调用 */
  onUnload?: () => void | Promise<void>;
  /** 生命周期：启用时调用 */
  onEnable?: () => void | Promise<void>;
  /** 生命周期：禁用时调用 */
  onDisable?: () => void | Promise<void>;
  /** 事件处理器映射 */
  handlers?: Record<string, BeforeHookHandler | AfterHookHandler>;
}

/**
 * 插件系统 API 响应类型
 */
export interface PluginListResponse {
  plugins: InstalledPlugin[];
  total: number;
}

export interface StoreListResponse {
  plugins: StorePlugin[];
  sourceURL: string;
  lastSyncAt?: string;
}

export interface PluginUploadResponse {
  success: boolean;
  plugin?: InstalledPlugin;
  error?: string;
}

export interface PluginOperationResponse {
  success: boolean;
  message?: string;
  error?: string;
}

/**
 * 事件名称解析结果
 */
export interface ParsedEvent {
  pluginId: string;
  action: 'create' | 'read' | 'update' | 'delete';
  entity: string;
  timing: 'before' | 'after';
}

/**
 * 解析事件名称
 * 格式: {pluginId}::{action}{Entity} 或 {pluginId}::{timing}:{action}{Entity}
 */
export function parseEventName(eventName: string): ParsedEvent | null {
  // 支持两种格式：
  // 1. 'chat::createChannel' -> before/after 通过钩子类型区分
  // 2. 'chat::before:createChannel' -> 显式指定 timing

  const parts = eventName.split('::');
  if (parts.length !== 2) return null;

  const pluginId = parts[0];
  let actionPart = parts[1];
  let timing: 'before' | 'after' = 'before';

  // 检查是否有 timing 前缀
  if (actionPart.startsWith('before:') || actionPart.startsWith('after:')) {
    const [timingStr, rest] = actionPart.split(':');
    timing = timingStr as 'before' | 'after';
    actionPart = rest;
  }

  // 解析 action + entity
  const actions = ['create', 'read', 'update', 'delete'] as const;
  for (const action of actions) {
    if (actionPart.toLowerCase().startsWith(action)) {
      const entity = actionPart.substring(action.length);
      return { pluginId, action, entity, timing };
    }
  }

  return null;
}

/**
 * 生成事件名称
 */
export function buildEventName(
  pluginId: string,
  action: 'create' | 'read' | 'update' | 'delete',
  entity: string,
  timing: 'before' | 'after' = 'before',
): string {
  return `${pluginId}::${timing}:${action}${entity}`;
}

/**
 * 检查事件是否匹配模式（支持通配符）
 */
export function eventMatchesPattern(eventName: string, pattern: string): boolean {
  if (pattern === '*') return true;
  if (pattern.endsWith('::*')) {
    const prefix = pattern.slice(0, -2);
    return eventName.startsWith(prefix + '::');
  }
  return eventName === pattern;
}
