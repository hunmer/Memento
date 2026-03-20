import { PluginDataService } from '../../../services/pluginDataService';
import { PluginHandlers, PluginResult } from '../types';
import { generateUUID, createPaginatedResult } from '../utils';

/**
 * 创建 Todo 插件专用处理器
 *
 * 数据格式：tasks.json 文件包含任务列表
 */
export function createTodoHandlers(pluginDataService: PluginDataService): PluginHandlers {
  // 读取所有任务
  async function readAllTasks(
    userId: string,
    encryptionKey: string
  ): Promise<Record<string, unknown>[]> {
    const data = await pluginDataService.readPluginData(
      userId,
      'todo',
      'tasks.json',
      encryptionKey
    );
    if (!data) return [];
    return ((data as Record<string, unknown>)?.tasks as Record<string, unknown>[]) || [];
  }

  // 保存所有任务
  async function saveAllTasks(
    userId: string,
    encryptionKey: string,
    tasks: Record<string, unknown>[]
  ): Promise<void> {
    await pluginDataService.writePluginData(
      userId,
      'todo',
      'tasks.json',
      { tasks },
      encryptionKey
    );
  }

  // 检查任务是否过期
  function isOverdue(task: Record<string, unknown>): boolean {
    if (task.completed) return false;
    const dueDate = task.dueDate as string;
    if (!dueDate) return false;
    const today = new Date().toISOString().split('T')[0];
    return dueDate < today;
  }

  // 检查任务是否是今日任务
  function isToday(task: Record<string, unknown>): boolean {
    const dueDate = task.dueDate as string;
    if (!dueDate) return false;
    const today = new Date().toISOString().split('T')[0];
    return dueDate === today;
  }

  return {
    // 获取任务列表
    async getList(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        let tasks = await readAllTasks(userId, encryptionKey);

        // 按完成状态过滤
        if (params.completed !== undefined) {
          const completed = params.completed === true || params.completed === 'true';
          tasks = tasks.filter(
            (t: Record<string, unknown>) => (t.completed as boolean) === completed
          );
        }

        // 按优先级过滤
        if (params.priority !== undefined) {
          tasks = tasks.filter(
            (t: Record<string, unknown>) => t.priority === params.priority
          );
        }

        // 按分类过滤
        if (params.category) {
          tasks = tasks.filter(
            (t: Record<string, unknown>) => t.category === params.category
          );
        }

        const result = createPaginatedResult(tasks, {
          offset: params.offset as number,
          count: params.count as number,
        });

        return { isSuccess: true, data: result };
      } catch (e) {
        return { isSuccess: false, message: `获取任务失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 根据 ID 获取
    async getById(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const tasks = await readAllTasks(userId, encryptionKey);
        const task = tasks.find((t: Record<string, unknown>) => t.id === params.id);

        if (!task) {
          return { isSuccess: false, message: '任务不存在', code: 'NOT_FOUND' };
        }

        return { isSuccess: true, data: task };
      } catch (e) {
        return { isSuccess: false, message: `获取任务失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 创建任务
    async create(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const tasks = await readAllTasks(userId, encryptionKey);
        const now = new Date().toISOString();

        const newTask = {
          ...params,
          id: params.id || generateUUID(),
          completed: params.completed || false,
          createdAt: now,
          updatedAt: now,
        };

        tasks.push(newTask);
        await saveAllTasks(userId, encryptionKey, tasks);

        return { isSuccess: true, data: newTask };
      } catch (e) {
        return { isSuccess: false, message: `创建任务失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 更新任务
    async update(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const tasks = await readAllTasks(userId, encryptionKey);
        const index = tasks.findIndex((t: Record<string, unknown>) => t.id === params.id);

        if (index === -1) {
          return { isSuccess: false, message: '任务不存在', code: 'NOT_FOUND' };
        }

        const updatedTask = {
          ...tasks[index],
          ...params,
          updatedAt: new Date().toISOString(),
        };
        tasks[index] = updatedTask;

        await saveAllTasks(userId, encryptionKey, tasks);
        return { isSuccess: true, data: updatedTask };
      } catch (e) {
        return { isSuccess: false, message: `更新任务失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 删除任务
    async delete(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const tasks = await readAllTasks(userId, encryptionKey);
        const initialLength = tasks.length;
        const filtered = tasks.filter((t: Record<string, unknown>) => t.id !== params.id);

        if (filtered.length === initialLength) {
          return { isSuccess: false, message: '任务不存在', code: 'NOT_FOUND' };
        }

        await saveAllTasks(userId, encryptionKey, filtered);
        return { isSuccess: true, data: { id: params.id } };
      } catch (e) {
        return { isSuccess: false, message: `删除任务失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 完成任务
    async completeTask(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const tasks = await readAllTasks(userId, encryptionKey);
        const index = tasks.findIndex((t: Record<string, unknown>) => t.id === params.id);

        if (index === -1) {
          return { isSuccess: false, message: '任务不存在', code: 'NOT_FOUND' };
        }

        const task = tasks[index];
        if (task.completed) {
          return { isSuccess: false, message: '任务已完成', code: 'INVALID_PARAMS' };
        }

        const now = new Date().toISOString();
        const updatedTask = {
          ...task,
          completed: true,
          completedAt: now,
          updatedAt: now,
        };
        tasks[index] = updatedTask;

        await saveAllTasks(userId, encryptionKey, tasks);
        return { isSuccess: true, data: updatedTask };
      } catch (e) {
        return { isSuccess: false, message: `完成任务失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 获取今日任务
    async getTodayTasks(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const tasks = await readAllTasks(userId, encryptionKey);
        const todayTasks = tasks.filter(isToday);

        return { isSuccess: true, data: { data: todayTasks, total: todayTasks.length } };
      } catch (e) {
        return { isSuccess: false, message: `获取今日任务失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 获取过期任务
    async getOverdueTasks(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const tasks = await readAllTasks(userId, encryptionKey);
        const overdueTasks = tasks.filter(isOverdue);

        return { isSuccess: true, data: { data: overdueTasks, total: overdueTasks.length } };
      } catch (e) {
        return { isSuccess: false, message: `获取过期任务失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 搜索任务
    async search(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        let tasks = await readAllTasks(userId, encryptionKey);
        const { keyword } = params;

        if (keyword) {
          const kw = String(keyword).toLowerCase();
          tasks = tasks.filter((t: Record<string, unknown>) => {
            const title = String(t.title || '').toLowerCase();
            const description = String(t.description || '').toLowerCase();
            return title.includes(kw) || description.includes(kw);
          });
        }

        return { isSuccess: true, data: { data: tasks, total: tasks.length } };
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
        const tasks = await readAllTasks(userId, encryptionKey);

        const total = tasks.length;
        const completed = tasks.filter((t: Record<string, unknown>) => t.completed).length;
        const pending = total - completed;
        const overdue = tasks.filter(isOverdue).length;
        const dueToday = tasks.filter(isToday).length;

        return {
          isSuccess: true,
          data: {
            total,
            completed,
            pending,
            overdue,
            dueToday,
            completionRate: total > 0 ? Math.round((completed / total) * 100) : 0,
          },
        };
      } catch (e) {
        return { isSuccess: false, message: `获取统计失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },
  };
}
