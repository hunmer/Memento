import { PluginDataService } from '../../../services/pluginDataService';
import { PluginHandlers, PluginResult } from '../types';
import { generateUUID, formatDate, createPaginatedResult } from '../utils';
import { addHooksToHandlers, ActionType } from '../hooks';

/**
 * 创建 Activity 插件专用处理器
 *
 * 数据格式：使用按日期分割的文件 activities_{date}.json
 * 文件内容可以是数组 [...] 或对象 {"activities": [...]}
 */
export function createActivityHandlers(pluginDataService: PluginDataService): PluginHandlers {
  // 读取指定日期的活动
  async function readActivitiesForDate(
    userId: string,
    encryptionKey: string,
    dateStr: string
  ): Promise<Record<string, unknown>[]> {
    const data = await pluginDataService.readPluginData(
      userId,
      'activity',
      `activities_${dateStr}.json`,
      encryptionKey
    );
    if (!data) return [];

    // 兼容两种格式：数组 [...] 或对象 {"activities": [...]}
    if (Array.isArray(data)) {
      return data as Record<string, unknown>[];
    }
    return ((data as Record<string, unknown>)?.activities as Record<string, unknown>[]) || [];
  }

  // 保存指定日期的活动
  async function saveActivitiesForDate(
    userId: string,
    encryptionKey: string,
    dateStr: string,
    activities: Record<string, unknown>[]
  ): Promise<void> {
    await pluginDataService.writePluginData(
      userId,
      'activity',
      `activities_${dateStr}.json`,
      { activities: activities.map((a) => ({ ...a })) },
      encryptionKey
    );
  }

  const handlers: PluginHandlers = {
    // 获取活动列表
    async getList(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const date = (params.date as string) || formatDate(new Date());
        let activities = await readActivitiesForDate(userId, encryptionKey, date);

        // 按开始时间排序
        activities.sort((a, b) => {
          const aTime = (a.startTime as string) || '';
          const bTime = (b.startTime as string) || '';
          return aTime.localeCompare(bTime);
        });

        const result = createPaginatedResult(activities, {
          offset: params.offset as number,
          count: params.count as number,
        });

        return { isSuccess: true, data: result };
      } catch (e) {
        return { isSuccess: false, message: `获取活动失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 根据 ID 获取
    async getById(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const date = (params.date as string) || formatDate(new Date());
        const activities = await readActivitiesForDate(userId, encryptionKey, date);
        const item = activities.find((a: Record<string, unknown>) => a.id === params.id);

        if (!item) {
          return { isSuccess: false, message: '活动不存在', code: 'NOT_FOUND' };
        }

        return { isSuccess: true, data: item };
      } catch (e) {
        return { isSuccess: false, message: `获取活动失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 创建活动
    async create(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const startTime = params.startTime as string;
        const dateStr = startTime ? startTime.split('T')[0] : formatDate(new Date());
        const activities = await readActivitiesForDate(userId, encryptionKey, dateStr);

        const now = new Date().toISOString();
        const newItem = {
          ...params,
          id: params.id || generateUUID(),
          createdAt: now,
          updatedAt: now,
        };

        activities.push(newItem);

        // 按开始时间排序
        activities.sort((a, b) => {
          const aTime = (a.startTime as string) || '';
          const bTime = (b.startTime as string) || '';
          return aTime.localeCompare(bTime);
        });

        await saveActivitiesForDate(userId, encryptionKey, dateStr, activities);

        return { isSuccess: true, data: newItem };
      } catch (e) {
        return { isSuccess: false, message: `创建活动失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 更新活动
    async update(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const date = (params.date as string) || formatDate(new Date());
        const activities = await readActivitiesForDate(userId, encryptionKey, date);
        const index = activities.findIndex((a: Record<string, unknown>) => a.id === params.id);

        if (index === -1) {
          return { isSuccess: false, message: '活动不存在', code: 'NOT_FOUND' };
        }

        const updatedItem = {
          ...activities[index],
          ...params,
          updatedAt: new Date().toISOString(),
        };
        activities[index] = updatedItem;

        // 按开始时间排序
        activities.sort((a, b) => {
          const aTime = (a.startTime as string) || '';
          const bTime = (b.startTime as string) || '';
          return aTime.localeCompare(bTime);
        });

        await saveActivitiesForDate(userId, encryptionKey, date, activities);

        return { isSuccess: true, data: updatedItem };
      } catch (e) {
        return { isSuccess: false, message: `更新活动失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 删除活动
    async delete(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const date = (params.date as string) || formatDate(new Date());
        const activities = await readActivitiesForDate(userId, encryptionKey, date);
        const index = activities.findIndex((a: Record<string, unknown>) => a.id === params.id);

        if (index === -1) {
          return { isSuccess: false, message: '活动不存在', code: 'NOT_FOUND' };
        }

        activities.splice(index, 1);
        await saveActivitiesForDate(userId, encryptionKey, date, activities);

        return { isSuccess: true, data: { id: params.id } };
      } catch (e) {
        return { isSuccess: false, message: `删除活动失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 获取今日统计
    async getTodayStats(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const today = formatDate(new Date());
        const activities = await readActivitiesForDate(userId, encryptionKey, today);

        const totalDuration = activities.reduce((sum: number, a: Record<string, unknown>) => {
          const start = new Date(a.startTime as string).getTime();
          const end = new Date(a.endTime as string).getTime();
          return sum + (end - start);
        }, 0);

        return {
          isSuccess: true,
          data: {
            date: today,
            activityCount: activities.length,
            durationMinutes: Math.round(totalDuration / 60000),
            durationHours: Math.floor(totalDuration / 3600000),
            remainingMinutes: Math.round((totalDuration % 3600000) / 60000),
          },
        };
      } catch (e) {
        return { isSuccess: false, message: `获取统计失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },
  };

  const hookMappings: Record<string, { action: ActionType; entity?: string }> = {
    getList: { action: 'read', entity: 'Activity' },
    getById: { action: 'read', entity: 'Activity' },
    create: { action: 'create', entity: 'Activity' },
    update: { action: 'update', entity: 'Activity' },
    delete: { action: 'delete', entity: 'Activity' },
    getTodayStats: { action: 'read', entity: 'ActivityStats' },
  };

  return addHooksToHandlers('activity', handlers, hookMappings);
}
