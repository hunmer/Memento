import { PluginDataService } from '../../../services/pluginDataService';
import { PluginHandlers, PluginResult } from '../types';
import { generateUUID } from '../utils';

/**
 * 创建 Day 插件专用处理器
 *
 * 数据格式：memorial_days.json 直接存储纪念日数组
 */
export function createDayHandlers(pluginDataService: PluginDataService): PluginHandlers {
  // 读取所有纪念日
  async function readAllMemorialDays(
    userId: string,
    encryptionKey: string
  ): Promise<Record<string, unknown>[]> {
    const data = await pluginDataService.readPluginData(
      userId,
      'day',
      'memorial_days.json',
      encryptionKey
    );
    if (!data) return [];
    // memorial_days.json 直接是数组格式
    if (Array.isArray(data)) {
      return data as Record<string, unknown>[];
    }
    return [];
  }

  // 保存所有纪念日
  async function saveAllMemorialDays(
    userId: string,
    encryptionKey: string,
    days: Record<string, unknown>[]
  ): Promise<void> {
    await pluginDataService.writePluginData(
      userId,
      'day',
      'memorial_days.json',
      days,
      encryptionKey
    );
  }

  return {
    // 获取纪念日列表
    async getList(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        let days = await readAllMemorialDays(userId, encryptionKey);

        // 排序
        const sortMode = params.sortMode as string | undefined;
        if (sortMode) {
          switch (sortMode) {
            case 'upcoming':
              days.sort((a, b) => {
                const aDays = (a.daysRemaining as number) || 0;
                const bDays = (b.daysRemaining as number) || 0;
                return aDays - bDays;
              });
              break;
            case 'recent':
              days.sort((a, b) => {
                const aDate = (a.targetDate as string) || '';
                const bDate = (b.targetDate as string) || '';
                return bDate.localeCompare(aDate);
              });
              break;
            case 'manual':
              days.sort((a, b) => {
                const aIndex = (a.sortIndex as number) || 0;
                const bIndex = (b.sortIndex as number) || 0;
                return aIndex - bIndex;
              });
              break;
          }
        }

        // 分页
        const offset = (params.offset as number) || 0;
        const count = (params.count as number) || 100;
        const total = days.length;
        const paginatedDays = days.slice(offset, offset + count);

        return {
          isSuccess: true,
          data: {
            data: paginatedDays,
            total,
            offset,
            count: paginatedDays.length,
            hasMore: offset + paginatedDays.length < total,
          },
        };
      } catch (e) {
        return { isSuccess: false, message: `获取纪念日列表失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 根据 ID 获取
    async getById(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const days = await readAllMemorialDays(userId, encryptionKey);
        const day = days.find((d: Record<string, unknown>) => d.id === params.id);

        if (!day) {
          return { isSuccess: false, message: '纪念日不存在', code: 'NOT_FOUND' };
        }

        return { isSuccess: true, data: day };
      } catch (e) {
        return { isSuccess: false, message: `获取纪念日失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 创建纪念日
    async create(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const days = await readAllMemorialDays(userId, encryptionKey);
        const now = new Date().toISOString();

        const newDay = {
          ...params,
          id: params.id || generateUUID(),
          createdAt: now,
          updatedAt: now,
        };

        days.push(newDay);
        await saveAllMemorialDays(userId, encryptionKey, days);

        return { isSuccess: true, data: newDay };
      } catch (e) {
        return { isSuccess: false, message: `创建纪念日失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 更新纪念日
    async update(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const days = await readAllMemorialDays(userId, encryptionKey);
        const index = days.findIndex((d: Record<string, unknown>) => d.id === params.id);

        if (index === -1) {
          return { isSuccess: false, message: '纪念日不存在', code: 'NOT_FOUND' };
        }

        const updatedDay = {
          ...days[index],
          ...params,
          updatedAt: new Date().toISOString(),
        };
        days[index] = updatedDay;

        await saveAllMemorialDays(userId, encryptionKey, days);
        return { isSuccess: true, data: updatedDay };
      } catch (e) {
        return { isSuccess: false, message: `更新纪念日失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 删除纪念日
    async delete(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const days = await readAllMemorialDays(userId, encryptionKey);
        const initialLength = days.length;
        const filtered = days.filter((d: Record<string, unknown>) => d.id !== params.id);

        if (filtered.length === initialLength) {
          return { isSuccess: false, message: '纪念日不存在', code: 'NOT_FOUND' };
        }

        await saveAllMemorialDays(userId, encryptionKey, filtered);
        return { isSuccess: true, data: { id: params.id } };
      } catch (e) {
        return { isSuccess: false, message: `删除纪念日失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 搜索纪念日
    async search(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        let days = await readAllMemorialDays(userId, encryptionKey);

        const { startDate, endDate, includeExpired, sortMode } = params;
        const today = new Date().toISOString().split('T')[0];

        if (!includeExpired) {
          days = days.filter((d: Record<string, unknown>) => {
            const targetDate = (d.targetDate as string) || (d.date as string);
            return targetDate >= today;
          });
        }
        if (startDate) {
          days = days.filter((d: Record<string, unknown>) => {
            const targetDate = (d.targetDate as string) || (d.date as string);
            return targetDate >= (startDate as string);
          });
        }
        if (endDate) {
          days = days.filter((d: Record<string, unknown>) => {
            const targetDate = (d.targetDate as string) || (d.date as string);
            return targetDate <= (endDate as string);
          });
        }

        return { isSuccess: true, data: { data: days, total: days.length } };
      } catch (e) {
        return { isSuccess: false, message: `搜索失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 获取统计
    async getStats(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const days = await readAllMemorialDays(userId, encryptionKey);

        return {
          isSuccess: true,
          data: {
            totalDays: days.length,
          },
        };
      } catch (e) {
        return { isSuccess: false, message: `获取统计失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },
  };
}
