import { PluginDataService } from '../../../services/pluginDataService';
import { PluginHandlers, PluginResult } from '../types';
import { createPaginatedResult } from '../utils';
import { addHooksToHandlers, ActionType } from '../hooks';

/**
 * 创建 Diary 插件专用处理器
 *
 * 数据格式：
 * - {date}.json: 每天的日记文件
 * - diary_index.json: 索引文件（包含日期列表和统计信息）
 */
export function createDiaryHandlers(pluginDataService: PluginDataService): PluginHandlers {
  // 读取索引文件
  async function readIndex(
    userId: string,
    encryptionKey: string
  ): Promise<Record<string, unknown>> {
    const data = await pluginDataService.readPluginData(
      userId,
      'diary',
      'diary_index.json',
      encryptionKey
    );
    return (data as Record<string, unknown>) || {};
  }

  // 保存索引文件
  async function saveIndex(
    userId: string,
    encryptionKey: string,
    index: Record<string, unknown>
  ): Promise<void> {
    await pluginDataService.writePluginData(
      userId,
      'diary',
      'diary_index.json',
      index,
      encryptionKey
    );
  }

  // 读取单日日记
  async function readEntry(
    userId: string,
    encryptionKey: string,
    date: string
  ): Promise<Record<string, unknown> | null> {
    const data = await pluginDataService.readPluginData(
      userId,
      'diary',
      `${date}.json`,
      encryptionKey
    );
    if (!data) return null;
    return data as Record<string, unknown>;
  }

  // 保存单日日记
  async function saveEntry(
    userId: string,
    encryptionKey: string,
    entry: Record<string, unknown>
  ): Promise<void> {
    const date = entry.date as string;
    await pluginDataService.writePluginData(userId, 'diary', `${date}.json`, entry, encryptionKey);
  }

  // 删除单日日记
  async function deleteEntry(userId: string, encryptionKey: string, date: string): Promise<boolean> {
    return await pluginDataService.deletePluginFile(userId, 'diary', `${date}.json`);
  }

  // 读取所有日记（通过索引文件）
  async function readAllEntries(
    userId: string,
    encryptionKey: string
  ): Promise<Record<string, unknown>[]> {
    const index = await readIndex(userId, encryptionKey);
    const entries: Record<string, unknown>[] = [];

    for (const key of Object.keys(index)) {
      // 跳过统计字段
      if (key === 'totalCharCount') continue;

      const entry = await readEntry(userId, encryptionKey, key);
      if (entry) {
        entries.push(entry);
      }
    }

    // 按日期降序排序
    entries.sort((a, b) => {
      const aDate = (a.date as string) || '';
      const bDate = (b.date as string) || '';
      return bDate.localeCompare(aDate);
    });

    return entries;
  }

  const handlers: PluginHandlers = {
    // 获取日记列表
    async getList(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        let entries = await readAllEntries(userId, encryptionKey);

        // 按日期范围过滤
        const startDate = params.startDate as string | undefined;
        const endDate = params.endDate as string | undefined;

        if (startDate) {
          entries = entries.filter((e: Record<string, unknown>) => (e.date as string) >= startDate);
        }
        if (endDate) {
          entries = entries.filter((e: Record<string, unknown>) => (e.date as string) <= endDate);
        }

        const result = createPaginatedResult(entries, {
          offset: params.offset as number,
          count: params.count as number,
        });

        return { isSuccess: true, data: result };
      } catch (e) {
        return { isSuccess: false, message: `获取日记列表失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 按日期获取
    async getByDate(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const date = params.date as string;
        const entry = await readEntry(userId, encryptionKey, date);

        if (!entry) {
          return { isSuccess: false, message: '日记不存在', code: 'NOT_FOUND' };
        }

        return { isSuccess: true, data: entry };
      } catch (e) {
        return { isSuccess: false, message: `获取日记失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 创建日记
    async create(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const date = params.date as string;

        // 检查是否已存在
        const existing = await readEntry(userId, encryptionKey, date);
        if (existing) {
          return { isSuccess: false, message: '该日期已有日记', code: 'CONFLICT' };
        }

        const now = new Date().toISOString();
        const newEntry = {
          ...params,
          createdAt: now,
          updatedAt: now,
        };

        // 保存日记文件
        await saveEntry(userId, encryptionKey, newEntry);

        // 更新索引
        const index = await readIndex(userId, encryptionKey);
        index[date] = { lastUpdated: now };
        const totalCharCount = (index.totalCharCount as number) || 0;
        index.totalCharCount = totalCharCount + String(params.content || '').length;
        await saveIndex(userId, encryptionKey, index);

        return { isSuccess: true, data: newEntry };
      } catch (e) {
        return { isSuccess: false, message: `创建日记失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 按日期更新
    async updateByDate(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const date = params.date as string;
        const existing = await readEntry(userId, encryptionKey, date);

        if (!existing) {
          return { isSuccess: false, message: '日记不存在', code: 'NOT_FOUND' };
        }

        // 计算字数差异
        const oldLength = String(existing.content || '').length;
        const newLength = String(params.content || '').length;
        const lengthDiff = newLength - oldLength;

        const updatedEntry = {
          ...existing,
          ...params,
          updatedAt: new Date().toISOString(),
        };

        // 保存日记文件
        await saveEntry(userId, encryptionKey, updatedEntry);

        // 更新索引
        const index = await readIndex(userId, encryptionKey);
        const totalCharCount = (index.totalCharCount as number) || 0;
        index.totalCharCount = totalCharCount + lengthDiff;
        index[date] = { lastUpdated: new Date().toISOString() };
        await saveIndex(userId, encryptionKey, index);

        return { isSuccess: true, data: updatedEntry };
      } catch (e) {
        return { isSuccess: false, message: `更新日记失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 按日期删除
    async deleteByDate(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const date = params.date as string;
        const existing = await readEntry(userId, encryptionKey, date);

        if (!existing) {
          return { isSuccess: false, message: '日记不存在', code: 'NOT_FOUND' };
        }

        // 获取内容长度
        const contentLength = String(existing.content || '').length;

        // 删除日记文件
        await deleteEntry(userId, encryptionKey, date);

        // 从索引中移除
        const index = await readIndex(userId, encryptionKey);
        delete index[date];
        const totalCharCount = (index.totalCharCount as number) || 0;
        index.totalCharCount = Math.max(0, totalCharCount - contentLength);
        await saveIndex(userId, encryptionKey, index);

        return { isSuccess: true, data: { date } };
      } catch (e) {
        return { isSuccess: false, message: `删除日记失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 搜索
    async search(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        let entries = await readAllEntries(userId, encryptionKey);

        const { keyword, startDate, endDate, mood } = params;

        if (startDate) {
          entries = entries.filter(
            (e: Record<string, unknown>) => (e.date as string) >= (startDate as string)
          );
        }
        if (endDate) {
          entries = entries.filter(
            (e: Record<string, unknown>) => (e.date as string) <= (endDate as string)
          );
        }
        if (mood) {
          entries = entries.filter((e: Record<string, unknown>) => e.mood === mood);
        }
        if (keyword) {
          const kw = String(keyword).toLowerCase();
          entries = entries.filter((e: Record<string, unknown>) => {
            const title = String(e.title || '').toLowerCase();
            const content = String(e.content || '').toLowerCase();
            return title.includes(kw) || content.includes(kw);
          });
        }

        return { isSuccess: true, data: { data: entries, total: entries.length } };
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
        const entries = await readAllEntries(userId, encryptionKey);

        const totalEntries = entries.length;
        const totalWords = entries.reduce((sum: number, e: Record<string, unknown>) => {
          return sum + String(e.content || '').length;
        }, 0);
        const averageWords = totalEntries > 0 ? Math.round(totalWords / totalEntries) : 0;

        return {
          isSuccess: true,
          data: {
            totalEntries,
            totalWords,
            averageWords,
          },
        };
      } catch (e) {
        return { isSuccess: false, message: `获取统计失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },
  };

  const hookMappings: Record<string, { action: ActionType; entity?: string }> = {
    getList: { action: 'read', entity: 'Entry' },
    getByDate: { action: 'read', entity: 'Entry' },
    create: { action: 'create', entity: 'Entry' },
    updateByDate: { action: 'update', entity: 'Entry' },
    deleteByDate: { action: 'delete', entity: 'Entry' },
    search: { action: 'read', entity: 'Entry' },
    getStats: { action: 'read', entity: 'EntryStats' },
  };

  return addHooksToHandlers('diary', handlers, hookMappings);
}
