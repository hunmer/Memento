import { PluginDataService } from '../../../services/pluginDataService';
import { PluginHandlers, PluginResult } from '../types';
import { generateUUID, createPaginatedResult } from '../utils';

/**
 * 创建 Checkin 插件专用处理器
 *
 * 数据格式：items.json 文件包含打卡项目列表，每个项目有嵌套的 checkInRecords
 */
export function createCheckinHandlers(pluginDataService: PluginDataService): PluginHandlers {
  // 读取所有打卡项目
  async function readAllItems(
    userId: string,
    encryptionKey: string
  ): Promise<Record<string, unknown>[]> {
    const data = await pluginDataService.readPluginData(
      userId,
      'checkin',
      'items.json',
      encryptionKey
    );
    if (!data) return [];
    return ((data as Record<string, unknown>)?.items as Record<string, unknown>[]) || [];
  }

  // 保存所有打卡项目
  async function saveAllItems(
    userId: string,
    encryptionKey: string,
    items: Record<string, unknown>[]
  ): Promise<void> {
    await pluginDataService.writePluginData(
      userId,
      'checkin',
      'items.json',
      { items },
      encryptionKey
    );
  }

  return {
    // 获取打卡项目列表
    async getList(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        let items = await readAllItems(userId, encryptionKey);

        const result = createPaginatedResult(items, {
          offset: params.offset as number,
          count: params.count as number,
        });

        return { isSuccess: true, data: result };
      } catch (e) {
        return { isSuccess: false, message: `获取打卡项目失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 根据 ID 获取
    async getById(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const items = await readAllItems(userId, encryptionKey);
        const item = items.find((i: Record<string, unknown>) => i.id === params.id);

        if (!item) {
          return { isSuccess: false, message: '打卡项目不存在', code: 'NOT_FOUND' };
        }

        return { isSuccess: true, data: item };
      } catch (e) {
        return { isSuccess: false, message: `获取打卡项目失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 创建打卡项目
    async create(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const items = await readAllItems(userId, encryptionKey);
        const now = new Date().toISOString();

        const newItem = {
          ...params,
          id: params.id || generateUUID(),
          checkInRecords: params.checkInRecords || {},
          createdAt: now,
          updatedAt: now,
        };

        items.push(newItem);
        await saveAllItems(userId, encryptionKey, items);

        return { isSuccess: true, data: newItem };
      } catch (e) {
        return { isSuccess: false, message: `创建打卡项目失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 更新打卡项目
    async update(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const items = await readAllItems(userId, encryptionKey);
        const index = items.findIndex((i: Record<string, unknown>) => i.id === params.id);

        if (index === -1) {
          return { isSuccess: false, message: '打卡项目不存在', code: 'NOT_FOUND' };
        }

        const updatedItem = {
          ...items[index],
          ...params,
          updatedAt: new Date().toISOString(),
        };
        items[index] = updatedItem;

        await saveAllItems(userId, encryptionKey, items);
        return { isSuccess: true, data: updatedItem };
      } catch (e) {
        return { isSuccess: false, message: `更新打卡项目失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 删除打卡项目
    async delete(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const items = await readAllItems(userId, encryptionKey);
        const initialLength = items.length;
        const filtered = items.filter((i: Record<string, unknown>) => i.id !== params.id);

        if (filtered.length === initialLength) {
          return { isSuccess: false, message: '打卡项目不存在', code: 'NOT_FOUND' };
        }

        await saveAllItems(userId, encryptionKey, filtered);
        return { isSuccess: true, data: { id: params.id } };
      } catch (e) {
        return { isSuccess: false, message: `删除打卡项目失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 添加签到记录
    async addRecord(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const { id: itemId, date, note } = params;
        const items = await readAllItems(userId, encryptionKey);
        const index = items.findIndex((i: Record<string, unknown>) => i.id === itemId);

        if (index === -1) {
          return { isSuccess: false, message: '打卡项目不存在', code: 'NOT_FOUND' };
        }

        const item = items[index];
        const checkInRecords = (item.checkInRecords as Record<string, unknown[]>) || {};

        const now = new Date().toISOString();
        const newRecord = {
          id: generateUUID(),
          checkinTime: now,
          note,
        };

        if (!checkInRecords[date as string]) {
          checkInRecords[date as string] = [];
        }
        checkInRecords[date as string].push(newRecord);

        const updatedItem = {
          ...item,
          checkInRecords,
          updatedAt: now,
        };
        items[index] = updatedItem;

        await saveAllItems(userId, encryptionKey, items);
        return { isSuccess: true, data: newRecord };
      } catch (e) {
        return { isSuccess: false, message: `签到失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 获取统计
    async getStats(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const items = await readAllItems(userId, encryptionKey);
        const totalItems = items.length;

        let totalCheckins = 0;
        for (const item of items) {
          const records = (item.checkInRecords as Record<string, unknown[]>) || {};
          for (const dateRecords of Object.values(records)) {
            totalCheckins += (dateRecords as unknown[]).length;
          }
        }

        // 今日统计
        const today = new Date().toISOString().split('T')[0];
        let todayCheckins = 0;
        let todayCompletedItems = 0;

        for (const item of items) {
          const records = (item.checkInRecords as Record<string, unknown[]>) || {};
          const todayRecords = records[today] || [];
          todayCheckins += todayRecords.length;
          if (todayRecords.length > 0) {
            todayCompletedItems++;
          }
        }

        const completionRate = totalItems > 0 ? todayCompletedItems / totalItems : 0;

        // 按分组统计
        const groupStats: Record<string, number> = {};
        for (const item of items) {
          const group = (item.group as string) || 'default';
          groupStats[group] = (groupStats[group] || 0) + 1;
        }

        return {
          isSuccess: true,
          data: {
            totalCheckins,
            todayCheckins,
            totalItems,
            todayCompletedItems,
            completionRate,
            groupStats,
          },
        };
      } catch (e) {
        return { isSuccess: false, message: `获取统计失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },
  };
}
