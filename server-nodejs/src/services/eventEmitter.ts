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
    console.log(`[EventEmitter] emitBefore: ${eventName}, 匹配的模式: [${matchingPatterns.join(', ')}]`);

    let currentCtx = ctx;

    for (const pattern of matchingPatterns) {
      const handlers = this.handlers.get(pattern) || [];
      console.log(`[EventEmitter] 执行模式 ${pattern} 的 ${handlers.length} 个处理器`);
      for (const handler of handlers) {
        try {
          currentCtx = await handler(currentCtx);
          if (currentCtx.canceled) {
            console.log(`[EventEmitter] 钩子被取消: ${pattern}`);
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
    console.log(`[EventEmitter] emitAfter: ${eventName}, 匹配的模式: [${matchingPatterns.join(', ')}]`);

    for (const pattern of matchingPatterns) {
      const handlers = this.handlers.get(pattern) || [];
      console.log(`[EventEmitter] 执行模式 ${pattern} 的 ${handlers.length} 个处理器`);
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
   *
   * @param events 事件模式列表（支持通配符，如 'chat::*'）
   * @param handlers 处理器映射（键为具体事件名，如 'chat::before:createChannel'）
   * @returns 取消函数列表
   */
  registerHandlers(
    events: string[],
    handlers: Record<string, BeforeHookHandler | AfterHookHandler>,
  ): (() => void)[] {
    const unsubscribers: (() => void)[] = [];

    // 遍历 handlers 的键，检查是否匹配 events 中的任意模式
    for (const [handlerKey, handler] of Object.entries(handlers)) {
      // 检查这个 handler 是否匹配 events 中的任意模式
      const matches = events.some(pattern => eventMatchesPattern(handlerKey, pattern));
      if (matches && handler) {
        const unsub = this.onPattern(handlerKey, handler);
        unsubscribers.push(unsub);
      }
    }

    console.log(`[EventEmitter] registerHandlers: ${unsubscribers.length} 个处理器被注册`);
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

    console.log(`[EventEmitter] 注册处理器: ${eventName} (ID: ${hookId}), 当前共 ${this.handlers.get(eventName)!.length} 个处理器`);

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
    const allPatterns = Array.from(this.registeredHandlers.keys());
    console.log(`[EventEmitter] getMatchingPatterns: eventName=${eventName}, 已注册模式=[${allPatterns.join(', ')}]`);

    for (const pattern of allPatterns) {
      const matches = eventMatchesPattern(eventName, pattern);
      console.log(`[EventEmitter]   检查模式 "${pattern}" vs "${eventName}": ${matches}`);
      if (matches) {
        matching.push(pattern);
      }
    }

    return matching;
  }
}

/** 全局单例 */
export const pluginEventEmitter = new PluginEventEmitter();
