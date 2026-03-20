import { PluginDataService } from '../../../services/pluginDataService';
import { PluginHandlers, PluginResult } from '../types';
import { generateUUID, createPaginatedResult } from '../utils';
import { addHooksToHandlers, ActionType } from '../hooks';

/**
 * 创建 Tracker 插件专用处理器
 *
 * 数据格式：
 * - goals.json: 目标列表
 * - records.json: 记录列表
 */
export function createTrackerHandlers(pluginDataService: PluginDataService): PluginHandlers {
  // 读取所有目标
  async function readAllGoals(
    userId: string,
    encryptionKey: string
  ): Promise<Record<string, unknown>[]> {
    const data = await pluginDataService.readPluginData(
      userId,
      'tracker',
      'goals.json',
      encryptionKey
    );
    if (!data) return [];
    return ((data as Record<string, unknown>)?.goals as Record<string, unknown>[]) || [];
  }

  // 保存所有目标
  async function saveAllGoals(
    userId: string,
    encryptionKey: string,
    goals: Record<string, unknown>[]
  ): Promise<void> {
    await pluginDataService.writePluginData(
      userId,
      'tracker',
      'goals.json',
      { goals },
      encryptionKey
    );
  }

  // 读取所有记录
  async function readAllRecords(
    userId: string,
    encryptionKey: string
  ): Promise<Record<string, unknown>[]> {
    const data = await pluginDataService.readPluginData(
      userId,
      'tracker',
      'records.json',
      encryptionKey
    );
    if (!data) return [];
    return ((data as Record<string, unknown>)?.records as Record<string, unknown>[]) || [];
  }

  // 保存所有记录
  async function saveAllRecords(
    userId: string,
    encryptionKey: string,
    records: Record<string, unknown>[]
  ): Promise<void> {
    await pluginDataService.writePluginData(
      userId,
      'tracker',
      'records.json',
      { records },
      encryptionKey
    );
  }

  const handlers: PluginHandlers = {
    // 获取目标列表
    async getList(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        let goals = await readAllGoals(userId, encryptionKey);

        // 按状态过滤
        const status = params.status as string | undefined;
        if (status === 'active') {
          goals = goals.filter((g: Record<string, unknown>) => !g.isCompleted);
        } else if (status === 'completed') {
          goals = goals.filter((g: Record<string, unknown>) => g.isCompleted);
        }

        // 按分组过滤
        const group = params.group as string | undefined;
        if (group) {
          goals = goals.filter((g: Record<string, unknown>) => g.group === group);
        }

        const result = createPaginatedResult(goals, {
          offset: params.offset as number,
          count: params.count as number,
        });

        return { isSuccess: true, data: result };
      } catch (e) {
        return { isSuccess: false, message: `获取目标列表失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 根据 ID 获取
    async getById(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const goals = await readAllGoals(userId, encryptionKey);
        const goal = goals.find((g: Record<string, unknown>) => g.id === params.id);

        if (!goal) {
          return { isSuccess: false, message: '目标不存在', code: 'NOT_FOUND' };
        }

        return { isSuccess: true, data: goal };
      } catch (e) {
        return { isSuccess: false, message: `获取目标失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 创建目标
    async create(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const goals = await readAllGoals(userId, encryptionKey);
        const now = new Date().toISOString();

        const newGoal = {
          ...params,
          id: params.id || generateUUID(),
          currentValue: params.currentValue || 0,
          isCompleted: params.isCompleted || false,
          createdAt: now,
          updatedAt: now,
        };

        goals.push(newGoal);
        await saveAllGoals(userId, encryptionKey, goals);

        return { isSuccess: true, data: newGoal };
      } catch (e) {
        return { isSuccess: false, message: `创建目标失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 更新目标
    async update(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const goals = await readAllGoals(userId, encryptionKey);
        const index = goals.findIndex((g: Record<string, unknown>) => g.id === params.id);

        if (index === -1) {
          return { isSuccess: false, message: '目标不存在', code: 'NOT_FOUND' };
        }

        const updatedGoal = {
          ...goals[index],
          ...params,
          updatedAt: new Date().toISOString(),
        };
        goals[index] = updatedGoal;

        await saveAllGoals(userId, encryptionKey, goals);
        return { isSuccess: true, data: updatedGoal };
      } catch (e) {
        return { isSuccess: false, message: `更新目标失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 删除目标
    async delete(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const goals = await readAllGoals(userId, encryptionKey);
        const initialLength = goals.length;
        const filteredGoals = goals.filter((g: Record<string, unknown>) => g.id !== params.id);

        if (filteredGoals.length === initialLength) {
          return { isSuccess: false, message: '目标不存在', code: 'NOT_FOUND' };
        }

        await saveAllGoals(userId, encryptionKey, filteredGoals);

        // 同时删除相关记录
        const records = await readAllRecords(userId, encryptionKey);
        const filteredRecords = records.filter(
          (r: Record<string, unknown>) => r.goalId !== params.id
        );
        await saveAllRecords(userId, encryptionKey, filteredRecords);

        return { isSuccess: true, data: { id: params.id } };
      } catch (e) {
        return { isSuccess: false, message: `删除目标失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 添加记录
    async addRecord(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const { goalId, value, date, note } = params;
        const records = await readAllRecords(userId, encryptionKey);

        const now = new Date().toISOString();
        const newRecord = {
          id: generateUUID(),
          goalId,
          value,
          date,
          note,
          recordedAt: now,
          createdAt: now,
        };

        records.push(newRecord);
        await saveAllRecords(userId, encryptionKey, records);

        // 更新目标的 currentValue
        const goals = await readAllGoals(userId, encryptionKey);
        const goalIndex = goals.findIndex((g: Record<string, unknown>) => g.id === goalId);

        if (goalIndex !== -1) {
          const goal = goals[goalIndex];
          const currentValue = (goal.currentValue as number) || 0;
          goals[goalIndex] = {
            ...goal,
            currentValue: currentValue + ((value as number) || 0),
            updatedAt: now,
          };
          await saveAllGoals(userId, encryptionKey, goals);
        }

        return { isSuccess: true, data: newRecord };
      } catch (e) {
        return { isSuccess: false, message: `添加记录失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 获取目标的记录
    async getRecords(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const { goalId } = params;
        let records = await readAllRecords(userId, encryptionKey);

        records = records.filter((r: Record<string, unknown>) => r.goalId === goalId);

        // 按记录时间排序
        records.sort((a, b) => {
          const aTime = (a.recordedAt as string) || '';
          const bTime = (b.recordedAt as string) || '';
          return bTime.localeCompare(aTime);
        });

        return { isSuccess: true, data: { data: records, total: records.length } };
      } catch (e) {
        return { isSuccess: false, message: `获取记录失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 获取统计
    async getStats(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const goals = await readAllGoals(userId, encryptionKey);
        const records = await readAllRecords(userId, encryptionKey);

        const totalGoals = goals.length;
        const activeGoals = goals.filter((g: Record<string, unknown>) => !g.isCompleted).length;
        const completedGoals = goals.filter((g: Record<string, unknown>) => g.isCompleted).length;

        // 今日记录数
        const today = new Date().toISOString().split('T')[0];
        const todayRecords = records.filter((r: Record<string, unknown>) => {
          const recordedAt = (r.recordedAt as string) || '';
          return recordedAt.startsWith(today);
        }).length;

        return {
          isSuccess: true,
          data: {
            totalGoals,
            activeGoals,
            completedGoals,
            totalRecords: records.length,
            todayRecordCount: todayRecords,
          },
        };
      } catch (e) {
        return { isSuccess: false, message: `获取统计失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },
  };

  const hookMappings: Record<string, { action: ActionType; entity?: string }> = {
    getList: { action: 'read', entity: 'Goal' },
    getById: { action: 'read', entity: 'Goal' },
    create: { action: 'create', entity: 'Goal' },
    update: { action: 'update', entity: 'Goal' },
    delete: { action: 'delete', entity: 'Goal' },
    addRecord: { action: 'create', entity: 'Record' },
    getRecords: { action: 'read', entity: 'Record' },
    getStats: { action: 'read', entity: 'TrackerStats' },
  };

  return addHooksToHandlers('tracker', handlers, hookMappings);
}
