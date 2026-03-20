/**
 * Hook 集成工具
 *
 * 为插件处理器提供 before/after hook 集成
 */

import { pluginEventEmitter } from '../../services/eventEmitter';
import { BeforeHookContext, AfterHookContext } from '../../types/plugin';
import { PluginResult } from './types';

/**
 * 操作类型
 */
export type ActionType = 'create' | 'read' | 'update' | 'delete';

/**
 * 原始处理器函数类型
 */
export type HandlerFn = (
  userId: string,
  encryptionKey: string,
  params: Record<string, unknown>,
  req?: unknown
) => Promise<PluginResult>;

/**
 * 带钩子的处理器函数类型
 */
export type HookedHandlerFn = HandlerFn;

/**
 * Hook 配置
 */
export interface HookConfig {
  /** 插件 ID */
  pluginId: string;
  /** 操作类型 */
  action: ActionType;
  /** 实体名称（默认为 'Item'） */
  entity?: string;
}

/**
 * 创建带 hook 的处理器
 *
 * @param config Hook 配置
 * @param handler 原始处理器
 * @returns 带钩子的处理器
 */
export function withHooks(
  config: HookConfig,
  handler: HandlerFn
): HookedHandlerFn {
  const { pluginId, action, entity = 'Item' } = config;

  return async (
    userId: string,
    encryptionKey: string,
    params: Record<string, unknown>,
    req?: unknown
  ): Promise<PluginResult> => {
    // 构建 before hook 上下文
    const beforeCtx: BeforeHookContext = {
      event: `${pluginId}::before:${action}${entity}`,
      action,
      pluginId,
      entity,
      userId,
      data: params,
      canceled: false,
    };

    // 触发 before hook
    const afterBeforeCtx = await pluginEventEmitter.emitBefore(beforeCtx);

    // 检查是否被取消
    if (afterBeforeCtx.canceled) {
      return {
        isSuccess: false,
        message: afterBeforeCtx.cancelReason || '操作被钩子取消',
        code: 'CANCELED_BY_HOOK',
      };
    }

    // 使用可能被修改的参数
    const modifiedParams = afterBeforeCtx.data as Record<string, unknown>;

    // 执行原始处理器
    let result: PluginResult;
    try {
      result = await handler(userId, encryptionKey, modifiedParams, req);
    } catch (error) {
      // 执行失败，触发 after hook
      const errorAfterCtx: AfterHookContext = {
        event: `${pluginId}::after:${action}${entity}`,
        action,
        pluginId,
        entity,
        userId,
        result: null,
        success: false,
        error: String(error),
      };
      await pluginEventEmitter.emitAfter(errorAfterCtx);
      throw error;
    }

    // 触发 after hook
    const afterCtx: AfterHookContext = {
      event: `${pluginId}::after:${action}${entity}`,
      action,
      pluginId,
      entity,
      userId,
      result: result.data,
      success: result.isSuccess,
      error: result.isSuccess ? undefined : result.message,
    };
    await pluginEventEmitter.emitAfter(afterCtx);

    return result;
  };
}

/**
 * 为处理器对象批量添加 hooks
 *
 * @param pluginId 插件 ID
 * @param handlers 原始处理器映射
 * @param entityMappings handler 名称到 (action, entity) 的映射
 * @returns 带钩子的处理器映射
 */
export function addHooksToHandlers(
  pluginId: string,
  handlers: Record<string, HandlerFn>,
  entityMappings: Record<string, { action: ActionType; entity?: string }>
): Record<string, HandlerFn> {
  const result: Record<string, HandlerFn> = {};

  for (const [name, handler] of Object.entries(handlers)) {
    const mapping = entityMappings[name];
    if (mapping) {
      result[name] = withHooks(
        {
          pluginId,
          action: mapping.action,
          entity: mapping.entity,
        },
        handler
      );
    } else {
      // 没有 mapping 的处理器保持原样
      result[name] = handler;
    }
  }

  return result;
}

/**
 * 通用 CRUD handler 名称到 hook 的映射
 */
export const CRUD_HOOK_MAPPINGS: Record<string, { action: ActionType; entity?: string }> = {
  getList: { action: 'read', entity: 'List' },
  getById: { action: 'read', entity: 'Item' },
  find: { action: 'read', entity: 'Item' },
  create: { action: 'create', entity: 'Item' },
  update: { action: 'update', entity: 'Item' },
  delete: { action: 'delete', entity: 'Item' },
};

/**
 * 为 CRUD 处理器添加 hooks
 */
export function addHooksToCrudHandlers(
  pluginId: string,
  handlers: Record<string, HandlerFn>,
  entityName: string = 'Item'
): Record<string, HandlerFn> {
  const mappings: Record<string, { action: ActionType; entity?: string }> = {
    getList: { action: 'read', entity: `${entityName}List` },
    getById: { action: 'read', entity: entityName },
    find: { action: 'read', entity: entityName },
    create: { action: 'create', entity: entityName },
    update: { action: 'update', entity: entityName },
    delete: { action: 'delete', entity: entityName },
  };

  return addHooksToHandlers(pluginId, handlers, mappings);
}
