import { PluginDataService } from '../../../services/pluginDataService';
import { PluginHandlers, PluginResult } from '../types';
import { generateUUID } from '../utils';
import { addHooksToHandlers, ActionType } from '../hooks';

/**
 * 创建 Calendar 插件专用处理器
 *
 * 数据格式：calendar_events.json 包含 {events: [...], completedEvents: [...]}
 */
export function createCalendarHandlers(pluginDataService: PluginDataService): PluginHandlers {
  // 读取所有事件数据
  async function readAllEventsData(
    userId: string,
    encryptionKey: string
  ): Promise<Record<string, unknown>> {
    const data = await pluginDataService.readPluginData(
      userId,
      'calendar',
      'calendar_events.json',
      encryptionKey
    );
    return (data as Record<string, unknown>) || {};
  }

  // 保存所有事件数据
  async function saveAllEventsData(
    userId: string,
    encryptionKey: string,
    data: Record<string, unknown>
  ): Promise<void> {
    await pluginDataService.writePluginData(
      userId,
      'calendar',
      'calendar_events.json',
      data,
      encryptionKey
    );
  }

  // 解析事件列表
  function parseEvents(data: Record<string, unknown>): Record<string, unknown>[] {
    return (data.events as Record<string, unknown>[]) || [];
  }

  // 解析已完成事件列表
  function parseCompletedEvents(data: Record<string, unknown>): Record<string, unknown>[] {
    return (data.completedEvents as Record<string, unknown>[]) || [];
  }

  const handlers: PluginHandlers = {
    // 获取事件列表
    async getList(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const data = await readAllEventsData(userId, encryptionKey);
        let events = parseEvents(data);

        // 按日期范围过滤
        const startDate = params.startDate as string | undefined;
        const endDate = params.endDate as string | undefined;

        if (startDate) {
          events = events.filter(
            (e: Record<string, unknown>) => (e.startTime as string) >= startDate
          );
        }
        if (endDate) {
          events = events.filter(
            (e: Record<string, unknown>) => (e.startTime as string) <= endDate + 'T23:59:59'
          );
        }

        // 分页
        const offset = (params.offset as number) || 0;
        const count = (params.count as number) || 100;
        const total = events.length;
        const paginatedEvents = events.slice(offset, offset + count);

        return {
          isSuccess: true,
          data: {
            data: paginatedEvents,
            total,
            offset,
            count: paginatedEvents.length,
            hasMore: offset + paginatedEvents.length < total,
          },
        };
      } catch (e) {
        return { isSuccess: false, message: `获取事件列表失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 根据 ID 获取
    async getById(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const data = await readAllEventsData(userId, encryptionKey);
        const events = parseEvents(data);
        const event = events.find((e: Record<string, unknown>) => e.id === params.id);

        if (!event) {
          return { isSuccess: false, message: '事件不存在', code: 'NOT_FOUND' };
        }

        return { isSuccess: true, data: event };
      } catch (e) {
        return { isSuccess: false, message: `获取事件失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 创建事件
    async create(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const data = await readAllEventsData(userId, encryptionKey);
        const events = parseEvents(data);
        const now = new Date().toISOString();

        const newEvent = {
          ...params,
          id: params.id || generateUUID(),
          createdAt: now,
          updatedAt: now,
        };

        events.push(newEvent);
        data.events = events;
        await saveAllEventsData(userId, encryptionKey, data);

        return { isSuccess: true, data: newEvent };
      } catch (e) {
        return { isSuccess: false, message: `创建事件失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 更新事件
    async update(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const data = await readAllEventsData(userId, encryptionKey);
        const events = parseEvents(data);
        const index = events.findIndex((e: Record<string, unknown>) => e.id === params.id);

        if (index === -1) {
          return { isSuccess: false, message: '事件不存在', code: 'NOT_FOUND' };
        }

        const updatedEvent = {
          ...events[index],
          ...params,
          updatedAt: new Date().toISOString(),
        };
        events[index] = updatedEvent;
        data.events = events;

        await saveAllEventsData(userId, encryptionKey, data);
        return { isSuccess: true, data: updatedEvent };
      } catch (e) {
        return { isSuccess: false, message: `更新事件失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 删除事件
    async delete(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const data = await readAllEventsData(userId, encryptionKey);
        const events = parseEvents(data);
        const initialLength = events.length;
        const filtered = events.filter((e: Record<string, unknown>) => e.id !== params.id);

        if (filtered.length === initialLength) {
          return { isSuccess: false, message: '事件不存在', code: 'NOT_FOUND' };
        }

        data.events = filtered;
        await saveAllEventsData(userId, encryptionKey, data);
        return { isSuccess: true, data: { id: params.id } };
      } catch (e) {
        return { isSuccess: false, message: `删除事件失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 完成事件
    async completeEvent(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const data = await readAllEventsData(userId, encryptionKey);
        const events = parseEvents(data);
        const completedEvents = parseCompletedEvents(data);
        const index = events.findIndex((e: Record<string, unknown>) => e.id === params.id);

        if (index === -1) {
          return { isSuccess: false, message: '事件不存在', code: 'NOT_FOUND' };
        }

        const event = events[index];
        const now = new Date().toISOString();
        const completedEvent = {
          ...event,
          completed: true,
          completedAt: now,
          updatedAt: now,
        };

        // 从事件列表移除，添加到已完成列表
        events.splice(index, 1);
        completedEvents.push(completedEvent);

        data.events = events;
        data.completedEvents = completedEvents;
        await saveAllEventsData(userId, encryptionKey, data);

        return { isSuccess: true, data: completedEvent };
      } catch (e) {
        return { isSuccess: false, message: `完成事件失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 搜索事件
    async search(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const data = await readAllEventsData(userId, encryptionKey);
        let events = parseEvents(data);

        const { keyword, startDate, endDate } = params;

        if (startDate) {
          events = events.filter(
            (e: Record<string, unknown>) => (e.startTime as string) >= (startDate as string)
          );
        }
        if (endDate) {
          events = events.filter(
            (e: Record<string, unknown>) =>
              (e.startTime as string) <= (endDate as string) + 'T23:59:59'
          );
        }
        if (keyword) {
          const kw = String(keyword).toLowerCase();
          events = events.filter(
            (e: Record<string, unknown>) =>
              String(e.title || '').toLowerCase().includes(kw) ||
              String(e.description || '').toLowerCase().includes(kw)
          );
        }

        return { isSuccess: true, data: { data: events, total: events.length } };
      } catch (e) {
        return { isSuccess: false, message: `搜索失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },
  };

  const hookMappings: Record<string, { action: ActionType; entity?: string }> = {
    getList: { action: 'read', entity: 'Event' },
    getById: { action: 'read', entity: 'Event' },
    create: { action: 'create', entity: 'Event' },
    update: { action: 'update', entity: 'Event' },
    delete: { action: 'delete', entity: 'Event' },
    completeEvent: { action: 'update', entity: 'Event' },
    search: { action: 'read', entity: 'Event' },
  };

  return addHooksToHandlers('calendar', handlers, hookMappings);
}
