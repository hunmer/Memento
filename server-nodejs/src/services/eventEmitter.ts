import {
  BeforeHookContext,
  AfterHookContext,
  BeforeHookHandler,
  AfterHookHandler,
  eventMatchesPattern,
  buildEventName,
} from '../types/plugin';

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyHandler = (ctx: any) => any;

/**
 * 插件事件发射器
 *
 * 实现细粒度事件系统，支持 before/after 钩子、通配符订阅
 */
export class PluginEventEmitter {
  /** 已注册的钩子映射：事件模式 -> 处理器 ID 列表 */
  private registeredHandlers: Map<string, Set<string>> = new Map();
  /** 处理器存储：事件模式 -> 处理器列表 */
  private handlers: Map<string, AnyHandler[]> = new Map();
  /** 处理器 ID -> 事件模式映射 */
  private handlerIdToPattern: Map<string, string> = new Map();
  /** 处理器 ID 生成器 */
  private handlerIdCounter = 0;

  /**
   * 注册 before 钩子
   */
  onBefore<T = unknown>(
    pluginId: string,
    action: 'create' | 'read' | 'update' | 'delete',
    entity: string,
    handler: BeforeHookHandler<T>,
  ): () => void {
    const eventName = buildEventName(pluginId, action, entity, 'before');
    return this.registerHandler(eventName, handler);
  }

  /**
   * 注册 after 钩子
   */
  onAfter<T = unknown>(
    pluginId: string,
    action: 'create' | 'read' | 'update' | 'delete',
    entity: string,
    handler: AfterHookHandler<T>,
  ): () => void {
    const eventName = buildEventName(pluginId, action, entity, 'after');
    return this.registerHandler(eventName, handler as AnyHandler);
  }

  /**
   * 通过事件模式注册钩子（支持通配符）
   */
  onPattern(pattern: string, handler: BeforeHookHandler | AfterHookHandler): () => void {
    return this.registerHandler(pattern, handler as AnyHandler);
  }

  /**
   * 触发 before 钩子
   * @returns 修改后的上下文，如果被取消则 ctx.canceled 为 true
   */
  async emitBefore<T = unknown>(ctx: BeforeHookContext<T>): Promise<BeforeHookContext<T>> {
    const eventName = buildEventName(ctx.pluginId, ctx.action, ctx.entity, 'before');

    // 找到所有匹配的处理器
    const matchingPatterns = this.getMatchingPatterns(eventName);

    let currentCtx = ctx;

    for (const pattern of matchingPatterns) {
      const handlers = this.handlers.get(pattern) || [];
      for (const handler of handlers) {
        try {
          currentCtx = await handler(currentCtx);
          if (currentCtx.canceled) {
            return currentCtx;
          }
        } catch (error) {
          console.error(`Error in before hook ${pattern}:`, error);
        }
      }
    }

    return currentCtx;
  }

  /**
   * 触发 after 钩子
   */
  async emitAfter<T = unknown>(ctx: AfterHookContext<T>): Promise<void> {
    const eventName = buildEventName(ctx.pluginId, ctx.action, ctx.entity, 'after');

    const matchingPatterns = this.getMatchingPatterns(eventName);

    for (const pattern of matchingPatterns) {
      const handlers = this.handlers.get(pattern) || [];
      for (const handler of handlers) {
        try {
          await handler(ctx);
        } catch (error) {
          console.error(`Error in after hook ${pattern}:`, error);
        }
      }
    }
  }

  /**
   * 批量注册事件处理器
   */
  registerHandlers(
    events: string[],
    handlers: Record<string, BeforeHookHandler | AfterHookHandler>,
  ): (() => void)[] {
    const unsubscribers: (() => void)[] = [];

    for (const event of events) {
      const handler = handlers[event];
      if (handler) {
        const unsub = this.onPattern(event, handler);
        unsubscribers.push(unsub);
      }
    }

    return unsubscribers;
  }

  /**
   * 清除所有钩子
   */
  clearAll(): void {
    this.registeredHandlers.clear();
    this.handlers.clear();
    this.handlerIdToPattern.clear();
  }

  /**
   * 获取已注册的事件模式列表
   */
  getRegisteredPatterns(): string[] {
    return Array.from(this.registeredHandlers.keys());
  }

  // ==================== 私有方法 ====================

  /**
   * 注册处理器并返回取消函数
   */
  private registerHandler(eventName: string, handler: AnyHandler): () => void {
    const hookId = `hook_${++this.handlerIdCounter}_${Date.now()}`;

    // 存储处理器
    if (!this.handlers.has(eventName)) {
      this.handlers.set(eventName, []);
    }
    this.handlers.get(eventName)!.push(handler);

    // 记录已注册的模式
    if (!this.registeredHandlers.has(eventName)) {
      this.registeredHandlers.set(eventName, new Set());
    }
    this.registeredHandlers.get(eventName)!.add(hookId);
    this.handlerIdToPattern.set(hookId, eventName);

    // 返回取消函数
    return () => {
      // 从处理器列表中移除
      const handlers = this.handlers.get(eventName);
      if (handlers) {
        const index = handlers.indexOf(handler);
        if (index > -1) {
          handlers.splice(index, 1);
        }
        // 如果没有处理器了，清理映射
        if (handlers.length === 0) {
          this.handlers.delete(eventName);
        }
      }
      // 从 ID 映射中移除
      this.registeredHandlers.get(eventName)?.delete(hookId);
      this.handlerIdToPattern.delete(hookId);
    };
  }

  /**
   * 获取匹配指定事件名的所有模式
   */
  private getMatchingPatterns(eventName: string): string[] {
    const matching: string[] = [];

    for (const pattern of this.registeredHandlers.keys()) {
      if (eventMatchesPattern(eventName, pattern)) {
        matching.push(pattern);
      }
    }

    return matching;
  }
}

/** 全局单例 */
export const pluginEventEmitter = new PluginEventEmitter();
