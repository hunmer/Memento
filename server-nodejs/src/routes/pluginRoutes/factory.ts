import { Router, Request, Response } from 'express';
import { PluginDataService } from '../../services/pluginDataService';
import { getUserIdFromContext } from '../../middleware/authMiddleware';
import { PluginRouteConfig, RouteDefinition, PLUGIN_ROUTE_CONFIGS } from './routeConfig';

/**
 * 错误码到 HTTP 状态码的映射
 */
function errorCodeToStatus(code?: string): number {
  switch (code) {
    case 'NOT_FOUND': return 404;
    case 'INVALID_PARAMS': return 400;
    case 'UNAUTHORIZED': return 401;
    case 'FORBIDDEN': return 403;
    case 'CONFLICT': return 409;
    default: return 500;
  }
}

/**
 * 错误响应
 */
function errorResponse(res: Response, statusCode: number, message: string): void {
  res.status(statusCode).json({
    success: false,
    error: message,
    timestamp: new Date().toISOString(),
  });
}

/**
 * 结果转换为 HTTP 响应
 */
function resultToResponse<T>(res: Response, result: {
  isSuccess: boolean;
  data?: T;
  message?: string;
  code?: string;
}, successStatus: number = 200): void {
  if (result.isSuccess) {
    res.status(successStatus).json({
      success: true,
      data: result.data,
      timestamp: new Date().toISOString(),
    });
  } else {
    const statusCode = errorCodeToStatus(result.code);
    res.status(statusCode).json({
      success: false,
      error: result.message,
      code: result.code,
      timestamp: new Date().toISOString(),
    });
  }
}

/**
 * 插件处理器类型
 */
export interface PluginHandlers {
  [key: string]: (userId: string, params: Record<string, unknown>, req?: Request) => Promise<PluginResult>;
}

/**
 * 插件结果类型
 */
export interface PluginResult {
  isSuccess: boolean;
  data?: unknown;
  message?: string;
  code?: string;
}

/**
 * 生成 UUID
 */
function generateUUID(): string {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = Math.random() * 16 | 0;
    const v = c === 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
}

/**
 * 创建通用 CRUD 处理器
 */
function createCrudHandlers(
  pluginDataService: PluginDataService,
  pluginId: string,
  resourceName: string,
  dataFile: string = 'data.json'
): PluginHandlers {
  return {
    // 获取列表
    async getList(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const data = await pluginDataService.readPluginData(userId, pluginId, dataFile);
        let items: Record<string, unknown>[] = Array.isArray(data)
          ? data
          : (data as Record<string, unknown>)?.[resourceName] as Record<string, unknown>[] || [];

        // 分页
        const offset = (params.offset as number) || 0;
        const count = (params.count as number) || 100;
        const total = items.length;
        items = items.slice(offset, offset + count);

        return {
          isSuccess: true,
          data: {
            data: items,
            total,
            offset,
            count: items.length,
            hasMore: offset + items.length < total,
          },
        };
      } catch (e) {
        return { isSuccess: false, message: `读取数据失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 根据 ID 获取
    async getById(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const data = await pluginDataService.readPluginData(userId, pluginId, dataFile);
        const items: Record<string, unknown>[] = Array.isArray(data)
          ? data
          : (data as Record<string, unknown>)?.[resourceName] as Record<string, unknown>[] || [];
        const item = items.find((i: Record<string, unknown>) => i.id === params.id);

        if (!item) {
          return { isSuccess: false, message: '项目不存在', code: 'NOT_FOUND' };
        }

        return { isSuccess: true, data: item };
      } catch (e) {
        return { isSuccess: false, message: `读取数据失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 创建
    async create(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const data = await pluginDataService.readPluginData(userId, pluginId, dataFile);
        const items: Record<string, unknown>[] = Array.isArray(data)
          ? [...data]
          : [...(((data as Record<string, unknown>)?.[resourceName] as Record<string, unknown>[]) || [])];

        const now = new Date().toISOString();
        const newItem = {
          ...params,
          id: params.id || generateUUID(),
          createdAt: now,
          updatedAt: now,
        };

        items.push(newItem);

        await pluginDataService.writePluginData(userId, pluginId, dataFile, { [resourceName]: items });

        return { isSuccess: true, data: newItem };
      } catch (e) {
        return { isSuccess: false, message: `创建失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 更新
    async update(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const data = await pluginDataService.readPluginData(userId, pluginId, dataFile);
        const items: Record<string, unknown>[] = Array.isArray(data)
          ? [...data]
          : [...(((data as Record<string, unknown>)?.[resourceName] as Record<string, unknown>[]) || [])];
        const index = items.findIndex((i: Record<string, unknown>) => i.id === params.id);

        if (index === -1) {
          return { isSuccess: false, message: '项目不存在', code: 'NOT_FOUND' };
        }

        const updatedItem = {
          ...items[index],
          ...params,
          updatedAt: new Date().toISOString(),
        };
        items[index] = updatedItem;

        await pluginDataService.writePluginData(userId, pluginId, dataFile, { [resourceName]: items });

        return { isSuccess: true, data: updatedItem };
      } catch (e) {
        return { isSuccess: false, message: `更新失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 删除
    async delete(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const data = await pluginDataService.readPluginData(userId, pluginId, dataFile);
        const items: Record<string, unknown>[] = Array.isArray(data)
          ? [...data]
          : [...(((data as Record<string, unknown>)?.[resourceName] as Record<string, unknown>[]) || [])];
        const index = items.findIndex((i: Record<string, unknown>) => i.id === params.id);

        if (index === -1) {
          return { isSuccess: false, message: '项目不存在', code: 'NOT_FOUND' };
        }

        items.splice(index, 1);
        await pluginDataService.writePluginData(userId, pluginId, dataFile, { [resourceName]: items });

        return { isSuccess: true, data: { id: params.id } };
      } catch (e) {
        return { isSuccess: false, message: `删除失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },
  };
}

/**
 * 创建 Chat 插件专用处理器
 */
function createChatHandlers(pluginDataService: PluginDataService): PluginHandlers {
  const crud = createCrudHandlers(pluginDataService, 'chat', 'channels');

  return {
    ...crud,

    // 获取消息列表
    async getMessages(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const channelId = params.channelId as string;
        const data = await pluginDataService.readPluginData(userId, 'chat', 'messages.json');
        let messages: Record<string, unknown>[] = (data as Record<string, unknown>)?.messages as Record<string, unknown>[] || [];

        // 按频道过滤
        messages = messages.filter((m: Record<string, unknown>) => m.channelId === channelId);

        // 分页
        const offset = (params.offset as number) || 0;
        const count = (params.count as number) || 100;
        const total = messages.length;
        messages = messages.slice(offset, offset + count);

        return {
          isSuccess: true,
          data: {
            data: messages,
            total,
            offset,
            count: messages.length,
            hasMore: offset + messages.length < total,
          },
        };
      } catch (e) {
        return { isSuccess: false, message: `读取消息失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 发送消息
    async sendMessage(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const channelId = params.channelId as string;
        const data = await pluginDataService.readPluginData(userId, 'chat', 'messages.json');
        const messages: Record<string, unknown>[] = ((data as Record<string, unknown>)?.messages as Record<string, unknown>[]) || [];

        const now = new Date().toISOString();
        const newMessage = {
          ...params,
          id: generateUUID(),
          channelId,
          createdAt: now,
          updatedAt: now,
        };

        messages.push(newMessage);
        await pluginDataService.writePluginData(userId, 'chat', 'messages.json', { messages });

        return { isSuccess: true, data: newMessage };
      } catch (e) {
        return { isSuccess: false, message: `发送消息失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 删除消息
    async deleteMessage(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const { channelId, messageId } = params as { channelId: string; messageId: string };
        const data = await pluginDataService.readPluginData(userId, 'chat', 'messages.json');
        const messages: Record<string, unknown>[] = ((data as Record<string, unknown>)?.messages as Record<string, unknown>[]) || [];
        const index = messages.findIndex((m: Record<string, unknown>) => m.id === messageId && m.channelId === channelId);

        if (index === -1) {
          return { isSuccess: false, message: '消息不存在', code: 'NOT_FOUND' };
        }

        messages.splice(index, 1);
        await pluginDataService.writePluginData(userId, 'chat', 'messages.json', { messages });

        return { isSuccess: true, data: { id: messageId } };
      } catch (e) {
        return { isSuccess: false, message: `删除消息失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 查找频道
    async findChannel(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const data = await pluginDataService.readPluginData(userId, 'chat', 'data.json');
        let channels: Record<string, unknown>[] = (data as Record<string, unknown>)?.channels as Record<string, unknown>[] || [];

        const { field, value, fuzzy } = params;
        if (field && value) {
          if (fuzzy) {
            channels = channels.filter((c: Record<string, unknown>) =>
              String(c[field as string] || '').toLowerCase().includes(String(value).toLowerCase())
            );
          } else {
            channels = channels.filter((c: Record<string, unknown>) => c[field as string] === value);
          }
        }

        return { isSuccess: true, data: { data: channels, total: channels.length } };
      } catch (e) {
        return { isSuccess: false, message: `查找频道失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 查找消息
    async findMessage(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const data = await pluginDataService.readPluginData(userId, 'chat', 'messages.json');
        let messages: Record<string, unknown>[] = (data as Record<string, unknown>)?.messages as Record<string, unknown>[] || [];

        const { field, value, channelId, fuzzy } = params;
        if (channelId) {
          messages = messages.filter((m: Record<string, unknown>) => m.channelId === channelId);
        }
        if (field && value) {
          if (fuzzy) {
            messages = messages.filter((m: Record<string, unknown>) =>
              String(m[field as string] || '').toLowerCase().includes(String(value).toLowerCase())
            );
          } else {
            messages = messages.filter((m: Record<string, unknown>) => m[field as string] === value);
          }
        }

        return { isSuccess: true, data: { data: messages, total: messages.length } };
      } catch (e) {
        return { isSuccess: false, message: `查找消息失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },
  };
}

/**
 * 创建 Notes 插件专用处理器
 */
function createNotesHandlers(pluginDataService: PluginDataService): PluginHandlers {
  const crud = createCrudHandlers(pluginDataService, 'notes', 'notes');
  const folderCrud = createCrudHandlers(pluginDataService, 'notes', 'folders');

  return {
    ...crud,
    ...Object.fromEntries(
      Object.entries(folderCrud).map(([key, handler]) => [`Folder${key.charAt(0).toUpperCase() + key.slice(1)}`, handler])
    ),

    // 获取文件夹列表
    async getFolders(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      return folderCrud.getList(userId, params);
    },

    async getFolderById(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      return folderCrud.getById(userId, params);
    },

    async createFolder(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      return folderCrud.create(userId, params);
    },

    async updateFolder(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      return folderCrud.update(userId, params);
    },

    async deleteFolder(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      return folderCrud.delete(userId, params);
    },

    // 移动笔记
    async moveNote(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const data = await pluginDataService.readPluginData(userId, 'notes', 'data.json');
        const notes: Record<string, unknown>[] = ((data as Record<string, unknown>)?.notes as Record<string, unknown>[]) || [];
        const index = notes.findIndex((n: Record<string, unknown>) => n.id === params.id);

        if (index === -1) {
          return { isSuccess: false, message: '笔记不存在', code: 'NOT_FOUND' };
        }

        notes[index] = {
          ...notes[index],
          folderId: params.folderId,
          updatedAt: new Date().toISOString(),
        };

        await pluginDataService.writePluginData(userId, 'notes', 'data.json', { notes, folders: (data as Record<string, unknown>)?.folders || [] });

        return { isSuccess: true, data: notes[index] };
      } catch (e) {
        return { isSuccess: false, message: `移动笔记失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 获取文件夹的笔记
    async getFolderNotes(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const folderId = params.id;
        const data = await pluginDataService.readPluginData(userId, 'notes', 'data.json');
        let notes: Record<string, unknown>[] = ((data as Record<string, unknown>)?.notes as Record<string, unknown>[]) || [];

        notes = notes.filter((n: Record<string, unknown>) => n.folderId === folderId);

        return { isSuccess: true, data: { data: notes, total: notes.length } };
      } catch (e) {
        return { isSuccess: false, message: `获取笔记失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 搜索笔记
    async search(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const { keyword, folderId } = params;
        const data = await pluginDataService.readPluginData(userId, 'notes', 'data.json');
        let notes: Record<string, unknown>[] = ((data as Record<string, unknown>)?.notes as Record<string, unknown>[]) || [];

        if (folderId) {
          notes = notes.filter((n: Record<string, unknown>) => n.folderId === folderId);
        }
        if (keyword) {
          const kw = String(keyword).toLowerCase();
          notes = notes.filter((n: Record<string, unknown>) =>
            String(n.title || '').toLowerCase().includes(kw) ||
            String(n.content || '').toLowerCase().includes(kw)
          );
        }

        return { isSuccess: true, data: { data: notes, total: notes.length } };
      } catch (e) {
        return { isSuccess: false, message: `搜索失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },
  };
}

/**
 * 创建 Bill 插件专用处理器
 */
function createBillHandlers(pluginDataService: PluginDataService): PluginHandlers {
  const accountCrud = createCrudHandlers(pluginDataService, 'bill', 'accounts');
  const billCrud = createCrudHandlers(pluginDataService, 'bill', 'bills');

  return {
    ...accountCrud,
    ...Object.fromEntries(
      Object.entries(billCrud).map(([key, handler]) => [`Bill${key.charAt(0).toUpperCase() + key.slice(1)}`, handler])
    ),

    // 获取账单列表
    async getBills(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      return billCrud.getList(userId, params);
    },

    async getBillById(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      return billCrud.getById(userId, params);
    },

    async createBill(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      return billCrud.create(userId, params);
    },

    async updateBill(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      return billCrud.update(userId, params);
    },

    async deleteBill(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      return billCrud.delete(userId, params);
    },

    // 按账户获取账单
    async getBillsByAccount(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      const accountId = params.accountId as string;
      return billCrud.getList(userId, { ...params, accountId });
    },

    // 为账户创建账单
    async createBillForAccount(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      const accountId = params.accountId as string;
      return billCrud.create(userId, { ...params, accountId });
    },

    // 获取统计
    async getStats(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const data = await pluginDataService.readPluginData(userId, 'bill', 'data.json');
        const bills: Record<string, unknown>[] = ((data as Record<string, unknown>)?.bills as Record<string, unknown>[]) || [];
        const accounts: Record<string, unknown>[] = ((data as Record<string, unknown>)?.accounts as Record<string, unknown>[]) || [];

        const totalIncome = bills
          .filter((b: Record<string, unknown>) => b.type === 'income')
          .reduce((sum: number, b: Record<string, unknown>) => sum + (b.amount as number || 0), 0);
        const totalExpense = bills
          .filter((b: Record<string, unknown>) => b.type === 'expense')
          .reduce((sum: number, b: Record<string, unknown>) => sum + (b.amount as number || 0), 0);

        return {
          isSuccess: true,
          data: {
            totalIncome,
            totalExpense,
            balance: totalIncome - totalExpense,
            billCount: bills.length,
            accountCount: accounts.length,
          },
        };
      } catch (e) {
        return { isSuccess: false, message: `获取统计失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },
  };
}

/**
 * 创建 Todo 插件专用处理器
 */
function createTodoHandlers(pluginDataService: PluginDataService): PluginHandlers {
  const crud = createCrudHandlers(pluginDataService, 'todo', 'tasks');

  return {
    ...crud,

    // 完成任务
    async completeTask(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      return crud.update(userId, { id: params.id, completed: true, completedAt: new Date().toISOString() });
    },

    // 获取今日任务
    async getTodayTasks(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const today = new Date().toISOString().split('T')[0];
        const data = await pluginDataService.readPluginData(userId, 'todo', 'data.json');
        let tasks: Record<string, unknown>[] = ((data as Record<string, unknown>)?.tasks as Record<string, unknown>[]) || [];

        tasks = tasks.filter((t: Record<string, unknown>) => {
          const dueDate = t.dueDate as string;
          return dueDate === today || (dueDate && dueDate <= today && !t.completed);
        });

        return { isSuccess: true, data: { data: tasks, total: tasks.length } };
      } catch (e) {
        return { isSuccess: false, message: `获取今日任务失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 获取过期任务
    async getOverdueTasks(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const today = new Date().toISOString().split('T')[0];
        const data = await pluginDataService.readPluginData(userId, 'todo', 'data.json');
        let tasks: Record<string, unknown>[] = ((data as Record<string, unknown>)?.tasks as Record<string, unknown>[]) || [];

        tasks = tasks.filter((t: Record<string, unknown>) => {
          const dueDate = t.dueDate as string;
          return dueDate && dueDate < today && !t.completed;
        });

        return { isSuccess: true, data: { data: tasks, total: tasks.length } };
      } catch (e) {
        return { isSuccess: false, message: `获取过期任务失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 搜索任务
    async search(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const { keyword } = params;
        const data = await pluginDataService.readPluginData(userId, 'todo', 'data.json');
        let tasks: Record<string, unknown>[] = ((data as Record<string, unknown>)?.tasks as Record<string, unknown>[]) || [];

        if (keyword) {
          const kw = String(keyword).toLowerCase();
          tasks = tasks.filter((t: Record<string, unknown>) =>
            String(t.title || '').toLowerCase().includes(kw) ||
            String(t.description || '').toLowerCase().includes(kw)
          );
        }

        return { isSuccess: true, data: { data: tasks, total: tasks.length } };
      } catch (e) {
        return { isSuccess: false, message: `搜索失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 获取统计
    async getStats(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const data = await pluginDataService.readPluginData(userId, 'todo', 'data.json');
        const tasks: Record<string, unknown>[] = ((data as Record<string, unknown>)?.tasks as Record<string, unknown>[]) || [];

        const completed = tasks.filter((t: Record<string, unknown>) => t.completed).length;
        const pending = tasks.filter((t: Record<string, unknown>) => !t.completed).length;

        return {
          isSuccess: true,
          data: {
            total: tasks.length,
            completed,
            pending,
            completionRate: tasks.length > 0 ? Math.round((completed / tasks.length) * 100) : 0,
          },
        };
      } catch (e) {
        return { isSuccess: false, message: `获取统计失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },
  };
}

/**
 * 创建 Diary 插件专用处理器
 */
function createDiaryHandlers(pluginDataService: PluginDataService): PluginHandlers {
  const crud = createCrudHandlers(pluginDataService, 'diary', 'entries');

  return {
    ...crud,

    // 按日期获取
    async getByDate(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const date = params.date as string;
        const data = await pluginDataService.readPluginData(userId, 'diary', 'data.json');
        const entries: Record<string, unknown>[] = ((data as Record<string, unknown>)?.entries as Record<string, unknown>[]) || [];
        const entry = entries.find((e: Record<string, unknown>) => e.date === date);

        if (!entry) {
          return { isSuccess: false, message: '日记不存在', code: 'NOT_FOUND' };
        }

        return { isSuccess: true, data: entry };
      } catch (e) {
        return { isSuccess: false, message: `获取日记失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 按日期更新
    async updateByDate(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const date = params.date as string;
        const data = await pluginDataService.readPluginData(userId, 'diary', 'data.json');
        const entries: Record<string, unknown>[] = ((data as Record<string, unknown>)?.entries as Record<string, unknown>[]) || [];
        const index = entries.findIndex((e: Record<string, unknown>) => e.date === date);

        if (index === -1) {
          return { isSuccess: false, message: '日记不存在', code: 'NOT_FOUND' };
        }

        entries[index] = {
          ...entries[index],
          ...params,
          updatedAt: new Date().toISOString(),
        };

        await pluginDataService.writePluginData(userId, 'diary', 'data.json', { entries });

        return { isSuccess: true, data: entries[index] };
      } catch (e) {
        return { isSuccess: false, message: `更新日记失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 按日期删除
    async deleteByDate(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const date = params.date as string;
        const data = await pluginDataService.readPluginData(userId, 'diary', 'data.json');
        const entries: Record<string, unknown>[] = ((data as Record<string, unknown>)?.entries as Record<string, unknown>[]) || [];
        const index = entries.findIndex((e: Record<string, unknown>) => e.date === date);

        if (index === -1) {
          return { isSuccess: false, message: '日记不存在', code: 'NOT_FOUND' };
        }

        entries.splice(index, 1);
        await pluginDataService.writePluginData(userId, 'diary', 'data.json', { entries });

        return { isSuccess: true, data: { date } };
      } catch (e) {
        return { isSuccess: false, message: `删除日记失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 搜索
    async search(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const { keyword, startDate, endDate, mood } = params;
        const data = await pluginDataService.readPluginData(userId, 'diary', 'data.json');
        let entries: Record<string, unknown>[] = ((data as Record<string, unknown>)?.entries as Record<string, unknown>[]) || [];

        if (startDate) {
          entries = entries.filter((e: Record<string, unknown>) => (e.date as string) >= (startDate as string));
        }
        if (endDate) {
          entries = entries.filter((e: Record<string, unknown>) => (e.date as string) <= (endDate as string));
        }
        if (mood) {
          entries = entries.filter((e: Record<string, unknown>) => e.mood === mood);
        }
        if (keyword) {
          const kw = String(keyword).toLowerCase();
          entries = entries.filter((e: Record<string, unknown>) =>
            String(e.content || '').toLowerCase().includes(kw)
          );
        }

        return { isSuccess: true, data: { data: entries, total: entries.length } };
      } catch (e) {
        return { isSuccess: false, message: `搜索失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 获取统计
    async getStats(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const data = await pluginDataService.readPluginData(userId, 'diary', 'data.json');
        const entries: Record<string, unknown>[] = ((data as Record<string, unknown>)?.entries as Record<string, unknown>[]) || [];

        const totalWords = entries.reduce((sum: number, e: Record<string, unknown>) => {
          return sum + String(e.content || '').length;
        }, 0);

        return {
          isSuccess: true,
          data: {
            totalEntries: entries.length,
            totalWords,
            averageWords: entries.length > 0 ? Math.round(totalWords / entries.length) : 0,
          },
        };
      } catch (e) {
        return { isSuccess: false, message: `获取统计失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },
  };
}

/**
 * 创建 Goods 插件专用处理器
 */
function createGoodsHandlers(pluginDataService: PluginDataService): PluginHandlers {
  const itemCrud = createCrudHandlers(pluginDataService, 'goods', 'items');

  return {
    ...itemCrud,

    // 获取仓库列表
    async getWarehouses(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const data = await pluginDataService.readPluginData(userId, 'goods', 'data.json');
        const warehouses: Record<string, unknown>[] = ((data as Record<string, unknown>)?.warehouses as Record<string, unknown>[]) || [];

        return { isSuccess: true, data: { data: warehouses, total: warehouses.length } };
      } catch (e) {
        return { isSuccess: false, message: `获取仓库失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 搜索物品
    async search(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const { keyword, warehouseId } = params;
        const data = await pluginDataService.readPluginData(userId, 'goods', 'data.json');
        let items: Record<string, unknown>[] = ((data as Record<string, unknown>)?.items as Record<string, unknown>[]) || [];

        if (warehouseId) {
          items = items.filter((i: Record<string, unknown>) => i.warehouseId === warehouseId);
        }
        if (keyword) {
          const kw = String(keyword).toLowerCase();
          items = items.filter((i: Record<string, unknown>) =>
            String(i.name || '').toLowerCase().includes(kw) ||
            String(i.description || '').toLowerCase().includes(kw)
          );
        }

        return { isSuccess: true, data: { data: items, total: items.length } };
      } catch (e) {
        return { isSuccess: false, message: `搜索失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },
  };
}

/**
 * 创建 Activity 插件专用处理器
 */
function createActivityHandlers(pluginDataService: PluginDataService): PluginHandlers {
  const crud = createCrudHandlers(pluginDataService, 'activity', 'activities');

  return {
    ...crud,

    // 获取今日统计
    async getTodayStats(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const today = new Date().toISOString().split('T')[0];
        const data = await pluginDataService.readPluginData(userId, 'activity', 'data.json');
        const activities: Record<string, unknown>[] = ((data as Record<string, unknown>)?.activities as Record<string, unknown>[]) || [];

        const todayActivities = activities.filter((a: Record<string, unknown>) => {
          const startTime = a.startTime as string;
          return startTime && startTime.startsWith(today);
        });

        const totalDuration = todayActivities.reduce((sum: number, a: Record<string, unknown>) => {
          const start = new Date(a.startTime as string).getTime();
          const end = new Date(a.endTime as string).getTime();
          return sum + (end - start);
        }, 0);

        return {
          isSuccess: true,
          data: {
            count: todayActivities.length,
            totalDuration,
            totalMinutes: Math.round(totalDuration / 60000),
          },
        };
      } catch (e) {
        return { isSuccess: false, message: `获取统计失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },
  };
}

/**
 * 创建 Checkin 插件专用处理器
 */
function createCheckinHandlers(pluginDataService: PluginDataService): PluginHandlers {
  const crud = createCrudHandlers(pluginDataService, 'checkin', 'items');

  return {
    ...crud,

    // 添加签到记录
    async addRecord(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const { id: itemId, date, note } = params;
        const data = await pluginDataService.readPluginData(userId, 'checkin', 'data.json');
        const records: Record<string, unknown>[] = ((data as Record<string, unknown>)?.records as Record<string, unknown>[]) || [];

        const newRecord = {
          id: generateUUID(),
          itemId,
          date,
          note,
          createdAt: new Date().toISOString(),
        };

        records.push(newRecord);
        await pluginDataService.writePluginData(userId, 'checkin', 'data.json', {
          items: (data as Record<string, unknown>)?.items || [],
          records,
        });

        return { isSuccess: true, data: newRecord };
      } catch (e) {
        return { isSuccess: false, message: `签到失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 获取统计
    async getStats(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const data = await pluginDataService.readPluginData(userId, 'checkin', 'data.json');
        const items: Record<string, unknown>[] = ((data as Record<string, unknown>)?.items as Record<string, unknown>[]) || [];
        const records: Record<string, unknown>[] = ((data as Record<string, unknown>)?.records as Record<string, unknown>[]) || [];

        return {
          isSuccess: true,
          data: {
            totalItems: items.length,
            totalRecords: records.length,
          },
        };
      } catch (e) {
        return { isSuccess: false, message: `获取统计失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },
  };
}

/**
 * 创建 Tracker 插件专用处理器
 */
function createTrackerHandlers(pluginDataService: PluginDataService): PluginHandlers {
  const crud = createCrudHandlers(pluginDataService, 'tracker', 'goals');

  return {
    ...crud,

    // 添加记录
    async addRecord(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const { goalId, value, date, note } = params;
        const data = await pluginDataService.readPluginData(userId, 'tracker', 'data.json');
        const records: Record<string, unknown>[] = ((data as Record<string, unknown>)?.records as Record<string, unknown>[]) || [];

        const newRecord = {
          id: generateUUID(),
          goalId,
          value,
          date,
          note,
          createdAt: new Date().toISOString(),
        };

        records.push(newRecord);
        await pluginDataService.writePluginData(userId, 'tracker', 'data.json', {
          goals: (data as Record<string, unknown>)?.goals || [],
          records,
        });

        return { isSuccess: true, data: newRecord };
      } catch (e) {
        return { isSuccess: false, message: `添加记录失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 获取目标的记录
    async getRecords(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const { goalId } = params;
        const data = await pluginDataService.readPluginData(userId, 'tracker', 'data.json');
        let records: Record<string, unknown>[] = ((data as Record<string, unknown>)?.records as Record<string, unknown>[]) || [];

        records = records.filter((r: Record<string, unknown>) => r.goalId === goalId);

        return { isSuccess: true, data: { data: records, total: records.length } };
      } catch (e) {
        return { isSuccess: false, message: `获取记录失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 获取统计
    async getStats(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const data = await pluginDataService.readPluginData(userId, 'tracker', 'data.json');
        const goals: Record<string, unknown>[] = ((data as Record<string, unknown>)?.goals as Record<string, unknown>[]) || [];
        const records: Record<string, unknown>[] = ((data as Record<string, unknown>)?.records as Record<string, unknown>[]) || [];

        return {
          isSuccess: true,
          data: {
            totalGoals: goals.length,
            totalRecords: records.length,
          },
        };
      } catch (e) {
        return { isSuccess: false, message: `获取统计失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },
  };
}

/**
 * 创建 Calendar 插件专用处理器
 */
function createCalendarHandlers(pluginDataService: PluginDataService): PluginHandlers {
  const crud = createCrudHandlers(pluginDataService, 'calendar', 'events');

  return {
    ...crud,

    // 完成事件
    async completeEvent(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      return crud.update(userId, { id: params.id, completed: true, completedAt: new Date().toISOString() });
    },

    // 搜索事件
    async search(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const { keyword, startDate, endDate } = params;
        const data = await pluginDataService.readPluginData(userId, 'calendar', 'data.json');
        let events: Record<string, unknown>[] = ((data as Record<string, unknown>)?.events as Record<string, unknown>[]) || [];

        if (startDate) {
          events = events.filter((e: Record<string, unknown>) => (e.startTime as string) >= (startDate as string));
        }
        if (endDate) {
          events = events.filter((e: Record<string, unknown>) => (e.startTime as string) <= (endDate as string) + 'T23:59:59');
        }
        if (keyword) {
          const kw = String(keyword).toLowerCase();
          events = events.filter((e: Record<string, unknown>) =>
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
}

/**
 * 创建 Contact 插件专用处理器
 */
function createContactHandlers(pluginDataService: PluginDataService): PluginHandlers {
  const crud = createCrudHandlers(pluginDataService, 'contact', 'contacts');

  return {
    ...crud,

    // 搜索联系人
    async search(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const { keyword } = params;
        const data = await pluginDataService.readPluginData(userId, 'contact', 'data.json');
        let contacts: Record<string, unknown>[] = ((data as Record<string, unknown>)?.contacts as Record<string, unknown>[]) || [];

        if (keyword) {
          const kw = String(keyword).toLowerCase();
          contacts = contacts.filter((c: Record<string, unknown>) =>
            String(c.name || '').toLowerCase().includes(kw) ||
            String(c.phone || '').includes(kw) ||
            String(c.email || '').toLowerCase().includes(kw)
          );
        }

        return { isSuccess: true, data: { data: contacts, total: contacts.length } };
      } catch (e) {
        return { isSuccess: false, message: `搜索失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 获取统计
    async getStats(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const data = await pluginDataService.readPluginData(userId, 'contact', 'data.json');
        const contacts: Record<string, unknown>[] = ((data as Record<string, unknown>)?.contacts as Record<string, unknown>[]) || [];

        return {
          isSuccess: true,
          data: {
            totalContacts: contacts.length,
          },
        };
      } catch (e) {
        return { isSuccess: false, message: `获取统计失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },
  };
}

/**
 * 创建 Day 插件专用处理器
 */
function createDayHandlers(pluginDataService: PluginDataService): PluginHandlers {
  const crud = createCrudHandlers(pluginDataService, 'day', 'days');

  return {
    ...crud,

    // 搜索纪念日
    async search(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const { startDate, endDate, includeExpired } = params;
        const data = await pluginDataService.readPluginData(userId, 'day', 'data.json');
        let days: Record<string, unknown>[] = ((data as Record<string, unknown>)?.days as Record<string, unknown>[]) || [];

        const today = new Date().toISOString().split('T')[0];

        if (!includeExpired) {
          days = days.filter((d: Record<string, unknown>) => (d.date as string) >= today);
        }
        if (startDate) {
          days = days.filter((d: Record<string, unknown>) => (d.date as string) >= (startDate as string));
        }
        if (endDate) {
          days = days.filter((d: Record<string, unknown>) => (d.date as string) <= (endDate as string));
        }

        return { isSuccess: true, data: { data: days, total: days.length } };
      } catch (e) {
        return { isSuccess: false, message: `搜索失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 获取统计
    async getStats(userId: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const data = await pluginDataService.readPluginData(userId, 'day', 'data.json');
        const days: Record<string, unknown>[] = ((data as Record<string, unknown>)?.days as Record<string, unknown>[]) || [];

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

/**
 * 为指定插件创建处理器
 */
function createHandlersForPlugin(pluginDataService: PluginDataService, pluginId: string): PluginHandlers {
  switch (pluginId) {
    case 'chat':
      return createChatHandlers(pluginDataService);
    case 'notes':
      return createNotesHandlers(pluginDataService);
    case 'bill':
      return createBillHandlers(pluginDataService);
    case 'todo':
      return createTodoHandlers(pluginDataService);
    case 'diary':
      return createDiaryHandlers(pluginDataService);
    case 'goods':
      return createGoodsHandlers(pluginDataService);
    case 'activity':
      return createActivityHandlers(pluginDataService);
    case 'checkin':
      return createCheckinHandlers(pluginDataService);
    case 'tracker':
      return createTrackerHandlers(pluginDataService);
    case 'calendar':
      return createCalendarHandlers(pluginDataService);
    case 'contact':
      return createContactHandlers(pluginDataService);
    case 'day':
      return createDayHandlers(pluginDataService);
    default:
      return createCrudHandlers(pluginDataService, pluginId, 'items');
  }
}

/**
 * 从请求中提取路径参数
 */
function extractPathParams(req: Request, pathPattern: string): Record<string, string> {
  const params: Record<string, string> = {};
  const pathParts = pathPattern.split('/');
  const urlParts = req.path.split('/');

  for (let i = 0; i < pathParts.length; i++) {
    if (pathParts[i].startsWith(':')) {
      const paramName = pathParts[i].slice(1);
      params[paramName] = urlParts[i] || '';
    }
  }

  return params;
}

/**
 * 从请求中提取查询参数
 */
function extractQueryParams(req: Request): Record<string, unknown> {
  const params: Record<string, unknown> = {};

  for (const [key, value] of Object.entries(req.query)) {
    // 尝试转换数字
    const num = Number(value);
    if (!isNaN(num) && value !== '') {
      params[key] = num;
    } else if (value === 'true') {
      params[key] = true;
    } else if (value === 'false') {
      params[key] = false;
    } else {
      params[key] = value;
    }
  }

  return params;
}

/**
 * 为插件创建路由
 */
export function createPluginRoutes(
  pluginDataService: PluginDataService,
  config: PluginRouteConfig,
): Router {
  const router = Router();
  const handlers = createHandlersForPlugin(pluginDataService, config.pluginId);

  for (const route of config.routes) {
    const handler = handlers[route.handler];

    if (!handler) {
      console.warn(`Handler "${route.handler}" not found for plugin ${config.pluginId}`);
      continue;
    }

    const method = route.method;

    router[method](route.path, async (req: Request, res: Response): Promise<void> => {
      const userId = getUserIdFromContext(req);
      if (!userId) {
        errorResponse(res, 401, '未认证');
        return;
      }

      try {
        // 合并路径参数、查询参数和请求体
        const pathParams = extractPathParams(req, route.path);
        const queryParams = extractQueryParams(req);
        const bodyParams = req.body || {};

        const params = { ...queryParams, ...pathParams, ...bodyParams };

        const result = await handler(userId, params, req);
        resultToResponse(res, result, method === 'post' ? 201 : 200);
      } catch (e) {
        errorResponse(res, 500, `服务器错误: ${e}`);
      }
    });
  }

  return router;
}

/**
 * 创建所有插件路由
 */
export function createPluginRoutesIndex(pluginDataService: PluginDataService): Map<string, Router> {
  const routes = new Map<string, Router>();

  for (const config of PLUGIN_ROUTE_CONFIGS) {
    const router = createPluginRoutes(pluginDataService, config);
    routes.set(config.pluginId, router);
  }

  return routes;
}

/**
 * 获取支持的插件列表
 */
export function getSupportedPlugins(): string[] {
  return PLUGIN_ROUTE_CONFIGS.map(c => c.pluginId);
}
