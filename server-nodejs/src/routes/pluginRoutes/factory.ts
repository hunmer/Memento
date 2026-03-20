import { Router, Request, Response } from 'express';
import { PluginDataService } from '../../services/pluginDataService';
import { getUserIdFromContext, getEncryptionKeyFromContext } from '../../middleware/authMiddleware';
import { PluginRouteConfig, PLUGIN_ROUTE_CONFIGS } from './routeConfig';

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
  [key: string]: (userId: string, encryptionKey: string, params: Record<string, unknown>, req?: Request) => Promise<PluginResult>;
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
    async getList(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const data = await pluginDataService.readPluginData(userId, pluginId, dataFile, encryptionKey);
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
    async getById(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const data = await pluginDataService.readPluginData(userId, pluginId, dataFile, encryptionKey);
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
    async create(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const data = await pluginDataService.readPluginData(userId, pluginId, dataFile, encryptionKey);
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

        await pluginDataService.writePluginData(userId, pluginId, dataFile, { [resourceName]: items }, encryptionKey);

        return { isSuccess: true, data: newItem };
      } catch (e) {
        return { isSuccess: false, message: `创建失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 更新
    async update(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const data = await pluginDataService.readPluginData(userId, pluginId, dataFile, encryptionKey);
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

        await pluginDataService.writePluginData(userId, pluginId, dataFile, { [resourceName]: items }, encryptionKey);

        return { isSuccess: true, data: updatedItem };
      } catch (e) {
        return { isSuccess: false, message: `更新失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 删除
    async delete(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const data = await pluginDataService.readPluginData(userId, pluginId, dataFile, encryptionKey);
        const items: Record<string, unknown>[] = Array.isArray(data)
          ? [...data]
          : [...(((data as Record<string, unknown>)?.[resourceName] as Record<string, unknown>[]) || [])];
        const index = items.findIndex((i: Record<string, unknown>) => i.id === params.id);

        if (index === -1) {
          return { isSuccess: false, message: '项目不存在', code: 'NOT_FOUND' };
        }

        items.splice(index, 1);
        await pluginDataService.writePluginData(userId, pluginId, dataFile, { [resourceName]: items }, encryptionKey);

        return { isSuccess: true, data: { id: params.id } };
      } catch (e) {
        return { isSuccess: false, message: `删除失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },
  };
}

/**
 * 创建 Chat 插件专用处理器
 *
 * 数据格式：
 * - channels.json: 频道 ID 列表 {"channels": ["id1", "id2", ...]}
 * - channel/{id}.json: 频道详情 {"channel": {...}}
 * - messages/{channelId}.json: 频道消息 {"messages": [...]}
 */
function createChatHandlers(pluginDataService: PluginDataService): PluginHandlers {
  // 读取频道 ID 列表
  async function readChannelIds(userId: string, encryptionKey: string): Promise<string[]> {
    const data = await pluginDataService.readPluginData(
      userId,
      'chat',
      'channels.json',
      encryptionKey,
    );
    if (!data) return [];
    return ((data as Record<string, unknown>)?.channels as string[]) || [];
  }

  // 保存频道 ID 列表
  async function saveChannelIds(userId: string, encryptionKey: string, channelIds: string[]): Promise<void> {
    await pluginDataService.writePluginData(
      userId,
      'chat',
      'channels.json',
      { channels: channelIds },
      encryptionKey,
    );
  }

  // 读取频道详情
  async function readChannel(
    userId: string,
    encryptionKey: string,
    channelId: string,
  ): Promise<Record<string, unknown> | null> {
    const data = await pluginDataService.readPluginData(
      userId,
      'chat',
      `channel/${channelId}.json`,
      encryptionKey,
    );
    if (!data) return null;
    return (data as Record<string, unknown>)?.channel as Record<string, unknown> || null;
  }

  // 保存频道详情
  async function saveChannel(
    userId: string,
    encryptionKey: string,
    channelId: string,
    channel: Record<string, unknown>,
  ): Promise<void> {
    await pluginDataService.writePluginData(
      userId,
      'chat',
      `channel/${channelId}.json`,
      { channel },
      encryptionKey,
    );
  }

  // 读取频道消息
  async function readMessages(
    userId: string,
    encryptionKey: string,
    channelId: string,
  ): Promise<Record<string, unknown>[]> {
    const data = await pluginDataService.readPluginData(
      userId,
      'chat',
      `messages/${channelId}.json`,
      encryptionKey,
    );
    if (!data) return [];
    return ((data as Record<string, unknown>)?.messages as Record<string, unknown>[]) || [];
  }

  // 保存频道消息
  async function saveMessages(
    userId: string,
    encryptionKey: string,
    channelId: string,
    messages: Record<string, unknown>[],
  ): Promise<void> {
    await pluginDataService.writePluginData(
      userId,
      'chat',
      `messages/${channelId}.json`,
      { messages },
      encryptionKey,
    );
  }

  return {
    // 获取频道列表
    async getList(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const channelIds = await readChannelIds(userId, encryptionKey);
        const channels: Record<string, unknown>[] = [];

        for (const channelId of channelIds) {
          const channel = await readChannel(userId, encryptionKey, channelId);
          if (channel) {
            channels.push(channel);
          }
        }

        // 分页
        const offset = (params.offset as number) || 0;
        const count = (params.count as number) || 100;
        const total = channels.length;
        const paginatedChannels = channels.slice(offset, offset + count);

        return {
          isSuccess: true,
          data: {
            data: paginatedChannels,
            total,
            offset,
            count: paginatedChannels.length,
            hasMore: offset + paginatedChannels.length < total,
          },
        };
      } catch (e) {
        return { isSuccess: false, message: `获取频道失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 获取单个频道
    async getById(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const channel = await readChannel(userId, encryptionKey, params.id as string);

        if (!channel) {
          return { isSuccess: false, message: '频道不存在', code: 'NOT_FOUND' };
        }

        return { isSuccess: true, data: channel };
      } catch (e) {
        return { isSuccess: false, message: `获取频道失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 创建频道
    async create(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const channelId = (params.id as string) || generateUUID();
        const now = new Date().toISOString();

        const newChannel = {
          ...params,
          id: channelId,
          createdAt: now,
          updatedAt: now,
        };

        // 保存频道详情
        await saveChannel(userId, encryptionKey, channelId, newChannel);

        // 创建空消息列表
        await saveMessages(userId, encryptionKey, channelId, []);

        // 更新频道 ID 列表
        const channelIds = await readChannelIds(userId, encryptionKey);
        if (!channelIds.includes(channelId)) {
          channelIds.push(channelId);
          await saveChannelIds(userId, encryptionKey, channelIds);
        }

        return { isSuccess: true, data: newChannel };
      } catch (e) {
        return { isSuccess: false, message: `创建频道失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 更新频道
    async update(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const channelId = params.id as string;
        const channel = await readChannel(userId, encryptionKey, channelId);

        if (!channel) {
          return { isSuccess: false, message: '频道不存在', code: 'NOT_FOUND' };
        }

        const updatedChannel = {
          ...channel,
          ...params,
          updatedAt: new Date().toISOString(),
        };

        await saveChannel(userId, encryptionKey, channelId, updatedChannel);
        return { isSuccess: true, data: updatedChannel };
      } catch (e) {
        return { isSuccess: false, message: `更新频道失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 删除频道
    async delete(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const channelId = params.id as string;

        // 删除频道文件
        await pluginDataService.deletePluginFile(userId, 'chat', `channel/${channelId}.json`);

        // 删除消息文件
        await pluginDataService.deletePluginFile(userId, 'chat', `messages/${channelId}.json`);

        // 从频道列表中移除
        const channelIds = await readChannelIds(userId, encryptionKey);
        const filteredIds = channelIds.filter(id => id !== channelId);
        await saveChannelIds(userId, encryptionKey, filteredIds);

        return { isSuccess: true, data: { id: channelId } };
      } catch (e) {
        return { isSuccess: false, message: `删除频道失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 获取消息列表
    async getMessages(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const channelId = params.channelId as string;
        let messages = await readMessages(userId, encryptionKey, channelId);

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
    async sendMessage(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const channelId = params.channelId as string;
        const messages = await readMessages(userId, encryptionKey, channelId);

        const now = new Date().toISOString();
        const newMessage = {
          ...params,
          id: generateUUID(),
          channelId,
          createdAt: now,
          updatedAt: now,
        };

        messages.push(newMessage);
        await saveMessages(userId, encryptionKey, channelId, messages);

        // 更新频道最后消息时间
        const channel = await readChannel(userId, encryptionKey, channelId);
        if (channel) {
          channel.lastMessageTime = now;
          await saveChannel(userId, encryptionKey, channelId, channel);
        }

        return { isSuccess: true, data: newMessage };
      } catch (e) {
        return { isSuccess: false, message: `发送消息失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 删除消息
    async deleteMessage(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const { channelId, messageId } = params as { channelId: string; messageId: string };
        const messages = await readMessages(userId, encryptionKey, channelId);
        const index = messages.findIndex((m: Record<string, unknown>) => m.id === messageId);

        if (index === -1) {
          return { isSuccess: false, message: '消息不存在', code: 'NOT_FOUND' };
        }

        messages.splice(index, 1);
        await saveMessages(userId, encryptionKey, channelId, messages);

        return { isSuccess: true, data: { id: messageId } };
      } catch (e) {
        return { isSuccess: false, message: `删除消息失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 查找频道
    async findChannel(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const channelIds = await readChannelIds(userId, encryptionKey);
        let channels: Record<string, unknown>[] = [];

        for (const channelId of channelIds) {
          const channel = await readChannel(userId, encryptionKey, channelId);
          if (channel) {
            channels.push(channel);
          }
        }

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
    async findMessage(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const { channelId, field, value, fuzzy } = params;
        let messages: Record<string, unknown>[] = [];

        if (channelId) {
          messages = await readMessages(userId, encryptionKey, channelId as string);
        } else {
          // 搜索所有频道的消息
          const channelIds = await readChannelIds(userId, encryptionKey);
          for (const chId of channelIds) {
            const channelMessages = await readMessages(userId, encryptionKey, chId);
            messages = messages.concat(channelMessages);
          }
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
    async getFolders(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      return folderCrud.getList(userId, encryptionKey, params);
    },

    async getFolderById(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      return folderCrud.getById(userId, encryptionKey, params);
    },

    async createFolder(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      return folderCrud.create(userId, encryptionKey, params);
    },

    async updateFolder(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      return folderCrud.update(userId, encryptionKey, params);
    },

    async deleteFolder(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      return folderCrud.delete(userId, encryptionKey, params);
    },

    // 移动笔记
    async moveNote(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const data = await pluginDataService.readPluginData(userId, 'notes', 'data.json', encryptionKey);
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

        await pluginDataService.writePluginData(userId, 'notes', 'data.json', { notes, folders: (data as Record<string, unknown>)?.folders || [] }, encryptionKey);

        return { isSuccess: true, data: notes[index] };
      } catch (e) {
        return { isSuccess: false, message: `移动笔记失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 获取文件夹的笔记
    async getFolderNotes(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const folderId = params.id;
        const data = await pluginDataService.readPluginData(userId, 'notes', 'data.json', encryptionKey);
        let notes: Record<string, unknown>[] = ((data as Record<string, unknown>)?.notes as Record<string, unknown>[]) || [];

        notes = notes.filter((n: Record<string, unknown>) => n.folderId === folderId);

        return { isSuccess: true, data: { data: notes, total: notes.length } };
      } catch (e) {
        return { isSuccess: false, message: `获取笔记失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 搜索笔记
    async search(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const { keyword, folderId } = params;
        const data = await pluginDataService.readPluginData(userId, 'notes', 'data.json', encryptionKey);
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
 *
 * 数据格式：accounts.json 文件包含账户列表，每个账户有嵌套的 bills 数组
 * 账户可能是 JSON 编码的字符串或 Map 对象
 */
function createBillHandlers(pluginDataService: PluginDataService): PluginHandlers {
  // 读取所有账户（包含嵌套的账单）
  async function readAllAccounts(
    userId: string,
    encryptionKey: string,
  ): Promise<Record<string, unknown>[]> {
    const accountsData = await pluginDataService.readPluginData(
      userId,
      'bill',
      'accounts.json',
      encryptionKey,
    );

    if (!accountsData) return [];

    const accountsRaw = (accountsData as Record<string, unknown>)?.accounts as Array<unknown> || [];
    return accountsRaw.map((a: unknown) => {
      // 兼容两种存储格式：
      // 1. 客户端格式：账户是 JSON 编码的字符串
      // 2. 标准格式：账户是 Map 对象
      if (typeof a === 'string') {
        try {
          return JSON.parse(a) as Record<string, unknown>;
        } catch {
          return {};
        }
      }
      return a as Record<string, unknown>;
    }).filter(a => Object.keys(a).length > 0);
  }

  // 保存所有账户
  async function saveAllAccounts(
    userId: string,
    encryptionKey: string,
    accounts: Record<string, unknown>[],
  ): Promise<void> {
    await pluginDataService.writePluginData(
      userId,
      'bill',
      'accounts.json',
      { accounts: accounts.map(a => JSON.stringify(a)) },
      encryptionKey,
    );
  }

  // 将客户端格式的账单转换为标准格式
  function convertClientBillToDto(bill: Record<string, unknown>): Record<string, unknown> {
    const amount = (bill.amount as number) || 0;
    const type = amount >= 0 ? 'income' : 'expense';

    return {
      id: bill.id || generateUUID(),
      accountId: bill.accountId || '',
      amount: Math.abs(amount),
      type,
      category: bill.category || '其他',
      description: bill.description || bill.note || '',
      date: bill.date || bill.createdAt || new Date().toISOString(),
      createdAt: bill.createdAt || new Date().toISOString(),
      updatedAt: bill.updatedAt || new Date().toISOString(),
      tags: bill.tags || (bill.tag ? [bill.tag] : []),
      ...bill, // 保留其他字段
    };
  }

  return {
    // 获取账户列表
    async getList(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        let accounts = await readAllAccounts(userId, encryptionKey);

        // 转换为 AccountDto（不包含账单列表）
        const accountDtos = accounts.map(a => ({
          id: a.id,
          name: a.name || a.title,
          balance: a.balance ?? a.totalAmount ?? 0,
          icon: a.icon || (a.iconCodePoint ? String(a.iconCodePoint) : undefined),
          color: a.color || (a.backgroundColor ? `#${(a.backgroundColor as number).toString(16).padStart(8, '0')}` : undefined),
          createdAt: a.createdAt,
          updatedAt: a.updatedAt,
        }));

        // 分页
        const offset = (params.offset as number) || 0;
        const count = (params.count as number) || 100;
        const total = accountDtos.length;
        const paginatedAccounts = accountDtos.slice(offset, offset + count);

        return {
          isSuccess: true,
          data: {
            data: paginatedAccounts,
            total,
            offset,
            count: paginatedAccounts.length,
            hasMore: offset + paginatedAccounts.length < total,
          },
        };
      } catch (e) {
        return { isSuccess: false, message: `获取账户失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 根据 ID 获取账户
    async getById(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const accounts = await readAllAccounts(userId, encryptionKey);
        const account = accounts.find((a: Record<string, unknown>) => a.id === params.id);

        if (!account) {
          return { isSuccess: false, message: '账户不存在', code: 'NOT_FOUND' };
        }

        const accountDto = {
          id: account.id,
          name: account.name || account.title,
          balance: account.balance ?? account.totalAmount ?? 0,
          icon: account.icon || (account.iconCodePoint ? String(account.iconCodePoint) : undefined),
          color: account.color || (account.backgroundColor ? `#${(account.backgroundColor as number).toString(16).padStart(8, '0')}` : undefined),
          createdAt: account.createdAt,
          updatedAt: account.updatedAt,
        };

        return { isSuccess: true, data: accountDto };
      } catch (e) {
        return { isSuccess: false, message: `获取账户失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 创建账户
    async create(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const accounts = await readAllAccounts(userId, encryptionKey);
        const now = new Date().toISOString();

        const newAccount = {
          ...params,
          id: params.id || generateUUID(),
          bills: [],
          createdAt: now,
          updatedAt: now,
        };

        accounts.push(newAccount);
        await saveAllAccounts(userId, encryptionKey, accounts);

        return { isSuccess: true, data: newAccount };
      } catch (e) {
        return { isSuccess: false, message: `创建账户失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 更新账户
    async update(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const accounts = await readAllAccounts(userId, encryptionKey);
        const index = accounts.findIndex((a: Record<string, unknown>) => a.id === params.id);

        if (index === -1) {
          return { isSuccess: false, message: '账户不存在', code: 'NOT_FOUND' };
        }

        const updatedAccount = {
          ...accounts[index],
          ...params,
          updatedAt: new Date().toISOString(),
        };
        accounts[index] = updatedAccount;

        await saveAllAccounts(userId, encryptionKey, accounts);
        return { isSuccess: true, data: updatedAccount };
      } catch (e) {
        return { isSuccess: false, message: `更新账户失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 删除账户
    async delete(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const accounts = await readAllAccounts(userId, encryptionKey);
        const initialLength = accounts.length;
        const filtered = accounts.filter((a: Record<string, unknown>) => a.id !== params.id);

        if (filtered.length === initialLength) {
          return { isSuccess: false, message: '账户不存在', code: 'NOT_FOUND' };
        }

        await saveAllAccounts(userId, encryptionKey, filtered);
        return { isSuccess: true, data: { id: params.id } };
      } catch (e) {
        return { isSuccess: false, message: `删除账户失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 获取账单列表
    async getBills(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const accounts = await readAllAccounts(userId, encryptionKey);
        const accountId = params.accountId as string | undefined;
        let allBills: Record<string, unknown>[] = [];

        for (const account of accounts) {
          if (accountId && account.id !== accountId) continue;
          const bills = (account.bills as Array<unknown>) || [];
          allBills = allBills.concat(bills.map(b => convertClientBillToDto(b as Record<string, unknown>)));
        }

        // 按日期排序（最新在前）
        allBills.sort((a, b) => {
          const aDate = (a.date as string) || '';
          const bDate = (b.date as string) || '';
          return bDate.localeCompare(aDate);
        });

        // 分页
        const offset = (params.offset as number) || 0;
        const count = (params.count as number) || 100;
        const total = allBills.length;
        const paginatedBills = allBills.slice(offset, offset + count);

        return {
          isSuccess: true,
          data: {
            data: paginatedBills,
            total,
            offset,
            count: paginatedBills.length,
            hasMore: offset + paginatedBills.length < total,
          },
        };
      } catch (e) {
        return { isSuccess: false, message: `获取账单失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 获取单个账单
    async getBillById(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const accounts = await readAllAccounts(userId, encryptionKey);

        for (const account of accounts) {
          const bills = (account.bills as Array<unknown>) || [];
          const bill = bills.find((b: Record<string, unknown>) => b.id === params.id);
          if (bill) {
            return { isSuccess: true, data: convertClientBillToDto(bill as Record<string, unknown>) };
          }
        }

        return { isSuccess: false, message: '账单不存在', code: 'NOT_FOUND' };
      } catch (e) {
        return { isSuccess: false, message: `获取账单失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 创建账单
    async createBill(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const accounts = await readAllAccounts(userId, encryptionKey);
        const accountIndex = accounts.findIndex((a: Record<string, unknown>) => a.id === params.accountId);

        if (accountIndex === -1) {
          return { isSuccess: false, message: '账户不存在', code: 'NOT_FOUND' };
        }

        const now = new Date().toISOString();
        const newBill = {
          ...params,
          id: params.id || generateUUID(),
          createdAt: now,
          updatedAt: now,
        };

        const account = accounts[accountIndex];
        const bills = (account.bills as Array<unknown>) || [];
        bills.push(newBill);
        account.bills = bills;

        // 更新账户余额
        const amount = (params.amount as number) || 0;
        const currentBalance = (account.balance as number) ?? (account.totalAmount as number) ?? 0;
        account.balance = currentBalance + amount;
        account.updatedAt = now;

        await saveAllAccounts(userId, encryptionKey, accounts);
        return { isSuccess: true, data: convertClientBillToDto(newBill) };
      } catch (e) {
        return { isSuccess: false, message: `创建账单失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 更新账单
    async updateBill(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const accounts = await readAllAccounts(userId, encryptionKey);

        for (let i = 0; i < accounts.length; i++) {
          const account = accounts[i];
          const bills = (account.bills as Array<unknown>) || [];
          const billIndex = bills.findIndex((b: Record<string, unknown>) => b.id === params.id);

          if (billIndex !== -1) {
            const oldBill = bills[billIndex] as Record<string, unknown>;
            const oldAmount = (oldBill.amount as number) || 0;
            const newAmount = (params.amount as number) || 0;

            const updatedBill = {
              ...oldBill,
              ...params,
              updatedAt: new Date().toISOString(),
            };
            bills[billIndex] = updatedBill;
            account.bills = bills;

            // 更新账户余额
            const currentBalance = (account.balance as number) ?? (account.totalAmount as number) ?? 0;
            account.balance = currentBalance - oldAmount + newAmount;
            account.updatedAt = new Date().toISOString();

            await saveAllAccounts(userId, encryptionKey, accounts);
            return { isSuccess: true, data: convertClientBillToDto(updatedBill) };
          }
        }

        return { isSuccess: false, message: '账单不存在', code: 'NOT_FOUND' };
      } catch (e) {
        return { isSuccess: false, message: `更新账单失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 删除账单
    async deleteBill(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const accounts = await readAllAccounts(userId, encryptionKey);

        for (let i = 0; i < accounts.length; i++) {
          const account = accounts[i];
          const bills = (account.bills as Array<unknown>) || [];
          const billIndex = bills.findIndex((b: Record<string, unknown>) => b.id === params.id);

          if (billIndex !== -1) {
            const oldBill = bills[billIndex] as Record<string, unknown>;
            const oldAmount = (oldBill.amount as number) || 0;

            bills.splice(billIndex, 1);
            account.bills = bills;

            // 更新账户余额
            const currentBalance = (account.balance as number) ?? (account.totalAmount as number) ?? 0;
            account.balance = currentBalance - oldAmount;
            account.updatedAt = new Date().toISOString();

            await saveAllAccounts(userId, encryptionKey, accounts);
            return { isSuccess: true, data: { id: params.id } };
          }
        }

        return { isSuccess: false, message: '账单不存在', code: 'NOT_FOUND' };
      } catch (e) {
        return { isSuccess: false, message: `删除账单失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 按账户获取账单
    async getBillsByAccount(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      return this.getBills(userId, encryptionKey, params);
    },

    // 为账户创建账单
    async createBillForAccount(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      return this.createBill(userId, encryptionKey, params);
    },

    // 获取统计
    async getStats(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const accounts = await readAllAccounts(userId, encryptionKey);
        let totalIncome = 0;
        let totalExpense = 0;
        let billCount = 0;

        for (const account of accounts) {
          const bills = (account.bills as Array<unknown>) || [];
          for (const bill of bills) {
            const b = bill as Record<string, unknown>;
            const amount = (b.amount as number) || 0;

            if (amount >= 0) {
              totalIncome += amount;
            } else {
              totalExpense += Math.abs(amount);
            }
            billCount++;
          }
        }

        return {
          isSuccess: true,
          data: {
            totalIncome,
            totalExpense,
            balance: totalIncome - totalExpense,
            billCount,
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
 *
 * 数据格式：tasks.json 文件包含任务列表
 */
function createTodoHandlers(pluginDataService: PluginDataService): PluginHandlers {
  // 读取所有任务
  async function readAllTasks(
    userId: string,
    encryptionKey: string,
  ): Promise<Record<string, unknown>[]> {
    const data = await pluginDataService.readPluginData(
      userId,
      'todo',
      'tasks.json',
      encryptionKey,
    );
    if (!data) return [];
    return ((data as Record<string, unknown>)?.tasks as Record<string, unknown>[]) || [];
  }

  // 保存所有任务
  async function saveAllTasks(
    userId: string,
    encryptionKey: string,
    tasks: Record<string, unknown>[],
  ): Promise<void> {
    await pluginDataService.writePluginData(
      userId,
      'todo',
      'tasks.json',
      { tasks },
      encryptionKey,
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
    async getList(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        let tasks = await readAllTasks(userId, encryptionKey);

        // 按完成状态过滤
        if (params.completed !== undefined) {
          const completed = params.completed === true || params.completed === 'true';
          tasks = tasks.filter((t: Record<string, unknown>) =>
            (t.completed as boolean) === completed
          );
        }

        // 按优先级过滤
        if (params.priority !== undefined) {
          tasks = tasks.filter((t: Record<string, unknown>) =>
            t.priority === params.priority
          );
        }

        // 按分类过滤
        if (params.category) {
          tasks = tasks.filter((t: Record<string, unknown>) =>
            t.category === params.category
          );
        }

        // 分页
        const offset = (params.offset as number) || 0;
        const count = (params.count as number) || 100;
        const total = tasks.length;
        const paginatedTasks = tasks.slice(offset, offset + count);

        return {
          isSuccess: true,
          data: {
            data: paginatedTasks,
            total,
            offset,
            count: paginatedTasks.length,
            hasMore: offset + paginatedTasks.length < total,
          },
        };
      } catch (e) {
        return { isSuccess: false, message: `获取任务失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 根据 ID 获取
    async getById(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
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
    async create(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
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
    async update(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
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
    async delete(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
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
    async completeTask(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
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
    async getTodayTasks(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const tasks = await readAllTasks(userId, encryptionKey);
        const todayTasks = tasks.filter(isToday);

        return { isSuccess: true, data: { data: todayTasks, total: todayTasks.length } };
      } catch (e) {
        return { isSuccess: false, message: `获取今日任务失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 获取过期任务
    async getOverdueTasks(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const tasks = await readAllTasks(userId, encryptionKey);
        const overdueTasks = tasks.filter(isOverdue);

        return { isSuccess: true, data: { data: overdueTasks, total: overdueTasks.length } };
      } catch (e) {
        return { isSuccess: false, message: `获取过期任务失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 搜索任务
    async search(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
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
    async getStats(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
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

/**
 * 创建 Diary 插件专用处理器
 *
 * 数据格式：
 * - {date}.json: 每天的日记文件
 * - diary_index.json: 索引文件（包含日期列表和统计信息）
 */
function createDiaryHandlers(pluginDataService: PluginDataService): PluginHandlers {
  // 读取索引文件
  async function readIndex(
    userId: string,
    encryptionKey: string,
  ): Promise<Record<string, unknown>> {
    const data = await pluginDataService.readPluginData(
      userId,
      'diary',
      'diary_index.json',
      encryptionKey,
    );
    return (data as Record<string, unknown>) || {};
  }

  // 保存索引文件
  async function saveIndex(
    userId: string,
    encryptionKey: string,
    index: Record<string, unknown>,
  ): Promise<void> {
    await pluginDataService.writePluginData(
      userId,
      'diary',
      'diary_index.json',
      index,
      encryptionKey,
    );
  }

  // 读取单日日记
  async function readEntry(
    userId: string,
    encryptionKey: string,
    date: string,
  ): Promise<Record<string, unknown> | null> {
    const data = await pluginDataService.readPluginData(
      userId,
      'diary',
      `${date}.json`,
      encryptionKey,
    );
    if (!data) return null;
    return data as Record<string, unknown>;
  }

  // 保存单日日记
  async function saveEntry(
    userId: string,
    encryptionKey: string,
    entry: Record<string, unknown>,
  ): Promise<void> {
    const date = entry.date as string;
    await pluginDataService.writePluginData(
      userId,
      'diary',
      `${date}.json`,
      entry,
      encryptionKey,
    );
  }

  // 删除单日日记
  async function deleteEntry(
    userId: string,
    encryptionKey: string,
    date: string,
  ): Promise<boolean> {
    return await pluginDataService.deletePluginFile(userId, 'diary', `${date}.json`);
  }

  // 读取所有日记（通过索引文件）
  async function readAllEntries(
    userId: string,
    encryptionKey: string,
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

  return {
    // 获取日记列表
    async getList(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        let entries = await readAllEntries(userId, encryptionKey);

        // 按日期范围过滤
        const startDate = params.startDate as string | undefined;
        const endDate = params.endDate as string | undefined;

        if (startDate) {
          entries = entries.filter((e: Record<string, unknown>) =>
            (e.date as string) >= startDate
          );
        }
        if (endDate) {
          entries = entries.filter((e: Record<string, unknown>) =>
            (e.date as string) <= endDate
          );
        }

        // 分页
        const offset = (params.offset as number) || 0;
        const count = (params.count as number) || 100;
        const total = entries.length;
        const paginatedEntries = entries.slice(offset, offset + count);

        return {
          isSuccess: true,
          data: {
            data: paginatedEntries,
            total,
            offset,
            count: paginatedEntries.length,
            hasMore: offset + paginatedEntries.length < total,
          },
        };
      } catch (e) {
        return { isSuccess: false, message: `获取日记列表失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 按日期获取
    async getByDate(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
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
    async create(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
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
    async updateByDate(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
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
    async deleteByDate(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
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
    async search(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        let entries = await readAllEntries(userId, encryptionKey);

        const { keyword, startDate, endDate, mood } = params;

        if (startDate) {
          entries = entries.filter((e: Record<string, unknown>) =>
            (e.date as string) >= (startDate as string)
          );
        }
        if (endDate) {
          entries = entries.filter((e: Record<string, unknown>) =>
            (e.date as string) <= (endDate as string)
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
    async getStats(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
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
}

/**
 * 创建 Goods 插件专用处理器
 *
 * 数据格式：
 * - warehouses.json: 仓库 ID 列表 {warehouses: ["id1", "id2"]}
 * - warehouse/{id}.json: 仓库详情 {warehouse: {...}}
 * - items.json: 物品列表 {items: [...]}
 */
function createGoodsHandlers(pluginDataService: PluginDataService): PluginHandlers {
  // 读取所有仓库
  async function readAllWarehouses(
    userId: string,
    encryptionKey: string,
  ): Promise<Record<string, unknown>[]> {
    const warehousesData = await pluginDataService.readPluginData(
      userId,
      'goods',
      'warehouses.json',
      encryptionKey,
    );
    if (!warehousesData) return [];

    // 仓库 ID 列表
    const warehouseIds = (warehousesData as Record<string, unknown>)?.warehouses as string[] || [];

    const warehouses: Record<string, unknown>[] = [];
    for (const id of warehouseIds) {
      const warehouseData = await pluginDataService.readPluginData(
        userId,
        'goods',
        `warehouse/${id}.json`,
        encryptionKey,
      );
      if (warehouseData && (warehouseData as Record<string, unknown>).warehouse) {
        warehouses.push((warehouseData as Record<string, unknown>).warehouse as Record<string, unknown>);
      }
    }

    return warehouses;
  }

  // 读取所有物品
  async function readAllItems(
    userId: string,
    encryptionKey: string,
  ): Promise<Record<string, unknown>[]> {
    const data = await pluginDataService.readPluginData(
      userId,
      'goods',
      'items.json',
      encryptionKey,
    );
    if (!data) return [];
    return ((data as Record<string, unknown>)?.items as Record<string, unknown>[]) || [];
  }

  // 保存所有物品
  async function saveAllItems(
    userId: string,
    encryptionKey: string,
    items: Record<string, unknown>[],
  ): Promise<void> {
    await pluginDataService.writePluginData(
      userId,
      'goods',
      'items.json',
      { items },
      encryptionKey,
    );
  }

  return {
    // 获取仓库列表
    async getWarehouses(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const warehouses = await readAllWarehouses(userId, encryptionKey);
        return { isSuccess: true, data: { data: warehouses, total: warehouses.length } };
      } catch (e) {
        return { isSuccess: false, message: `获取仓库失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 获取物品列表
    async getList(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        let items = await readAllItems(userId, encryptionKey);

        // 按仓库过滤
        const warehouseId = params.warehouseId as string | undefined;
        if (warehouseId) {
          items = items.filter((i: Record<string, unknown>) => i.warehouseId === warehouseId);
        }

        // 分页
        const offset = (params.offset as number) || 0;
        const count = (params.count as number) || 100;
        const total = items.length;
        const paginatedItems = items.slice(offset, offset + count);

        return {
          isSuccess: true,
          data: {
            data: paginatedItems,
            total,
            offset,
            count: paginatedItems.length,
            hasMore: offset + paginatedItems.length < total,
          },
        };
      } catch (e) {
        return { isSuccess: false, message: `获取物品失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 根据 ID 获取
    async getById(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const items = await readAllItems(userId, encryptionKey);
        const item = items.find((i: Record<string, unknown>) => i.id === params.id);

        if (!item) {
          return { isSuccess: false, message: '物品不存在', code: 'NOT_FOUND' };
        }

        return { isSuccess: true, data: item };
      } catch (e) {
        return { isSuccess: false, message: `获取物品失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 创建物品
    async create(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const items = await readAllItems(userId, encryptionKey);
        const now = new Date().toISOString();

        const newItem = {
          ...params,
          id: params.id || generateUUID(),
          quantity: params.quantity || 1,
          createdAt: now,
          updatedAt: now,
        };

        items.push(newItem);
        await saveAllItems(userId, encryptionKey, items);

        return { isSuccess: true, data: newItem };
      } catch (e) {
        return { isSuccess: false, message: `创建物品失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 更新物品
    async update(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const items = await readAllItems(userId, encryptionKey);
        const index = items.findIndex((i: Record<string, unknown>) => i.id === params.id);

        if (index === -1) {
          return { isSuccess: false, message: '物品不存在', code: 'NOT_FOUND' };
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
        return { isSuccess: false, message: `更新物品失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 删除物品
    async delete(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const items = await readAllItems(userId, encryptionKey);
        const initialLength = items.length;
        const filtered = items.filter((i: Record<string, unknown>) => i.id !== params.id);

        if (filtered.length === initialLength) {
          return { isSuccess: false, message: '物品不存在', code: 'NOT_FOUND' };
        }

        await saveAllItems(userId, encryptionKey, filtered);
        return { isSuccess: true, data: { id: params.id } };
      } catch (e) {
        return { isSuccess: false, message: `删除物品失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 搜索物品
    async search(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        let items = await readAllItems(userId, encryptionKey);

        const { keyword, warehouseId } = params;

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
 *
 * 数据格式：使用按日期分割的文件 activities_{date}.json
 * 文件内容可以是数组 [...] 或对象 {"activities": [...]}
 */
function createActivityHandlers(pluginDataService: PluginDataService): PluginHandlers {
  // 格式化日期为文件名格式 (YYYY-MM-DD)
  function formatDate(date: Date): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  // 读取指定日期的活动
  async function readActivitiesForDate(
    userId: string,
    encryptionKey: string,
    dateStr: string,
  ): Promise<Record<string, unknown>[]> {
    const data = await pluginDataService.readPluginData(
      userId,
      'activity',
      `activities_${dateStr}.json`,
      encryptionKey,
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
    activities: Record<string, unknown>[],
  ): Promise<void> {
    await pluginDataService.writePluginData(
      userId,
      'activity',
      `activities_${dateStr}.json`,
      { activities: activities.map(a => ({ ...a })) },
      encryptionKey,
    );
  }

  return {
    // 获取活动列表
    async getList(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const date = (params.date as string) || formatDate(new Date());
        let activities = await readActivitiesForDate(userId, encryptionKey, date);

        // 按开始时间排序
        activities.sort((a, b) => {
          const aTime = (a.startTime as string) || '';
          const bTime = (b.startTime as string) || '';
          return aTime.localeCompare(bTime);
        });

        // 分页
        const offset = (params.offset as number) || 0;
        const count = (params.count as number) || 100;
        const total = activities.length;
        const paginatedActivities = activities.slice(offset, offset + count);

        return {
          isSuccess: true,
          data: {
            data: paginatedActivities,
            total,
            offset,
            count: paginatedActivities.length,
            hasMore: offset + paginatedActivities.length < total,
          },
        };
      } catch (e) {
        return { isSuccess: false, message: `获取活动失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 根据 ID 获取
    async getById(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
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
    async create(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
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
    async update(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
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
    async delete(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
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
    async getTodayStats(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
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
}

/**
 * 创建 Checkin 插件专用处理器
 *
 * 数据格式：items.json 文件包含打卡项目列表，每个项目有嵌套的 checkInRecords
 */
function createCheckinHandlers(pluginDataService: PluginDataService): PluginHandlers {
  // 读取所有打卡项目
  async function readAllItems(
    userId: string,
    encryptionKey: string,
  ): Promise<Record<string, unknown>[]> {
    const data = await pluginDataService.readPluginData(
      userId,
      'checkin',
      'items.json',
      encryptionKey,
    );
    if (!data) return [];
    return ((data as Record<string, unknown>)?.items as Record<string, unknown>[]) || [];
  }

  // 保存所有打卡项目
  async function saveAllItems(
    userId: string,
    encryptionKey: string,
    items: Record<string, unknown>[],
  ): Promise<void> {
    await pluginDataService.writePluginData(
      userId,
      'checkin',
      'items.json',
      { items },
      encryptionKey,
    );
  }

  return {
    // 获取打卡项目列表
    async getList(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        let items = await readAllItems(userId, encryptionKey);

        // 分页
        const offset = (params.offset as number) || 0;
        const count = (params.count as number) || 100;
        const total = items.length;
        const paginatedItems = items.slice(offset, offset + count);

        return {
          isSuccess: true,
          data: {
            data: paginatedItems,
            total,
            offset,
            count: paginatedItems.length,
            hasMore: offset + paginatedItems.length < total,
          },
        };
      } catch (e) {
        return { isSuccess: false, message: `获取打卡项目失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 根据 ID 获取
    async getById(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
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
    async create(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
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
    async update(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
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
    async delete(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
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
    async addRecord(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
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

        if (!checkInRecords[date]) {
          checkInRecords[date] = [];
        }
        checkInRecords[date].push(newRecord);

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
    async getStats(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
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

/**
 * 创建 Tracker 插件专用处理器
 *
 * 数据格式：
 * - goals.json: 目标列表
 * - records.json: 记录列表
 */
function createTrackerHandlers(pluginDataService: PluginDataService): PluginHandlers {
  // 读取所有目标
  async function readAllGoals(
    userId: string,
    encryptionKey: string,
  ): Promise<Record<string, unknown>[]> {
    const data = await pluginDataService.readPluginData(
      userId,
      'tracker',
      'goals.json',
      encryptionKey,
    );
    if (!data) return [];
    return ((data as Record<string, unknown>)?.goals as Record<string, unknown>[]) || [];
  }

  // 保存所有目标
  async function saveAllGoals(
    userId: string,
    encryptionKey: string,
    goals: Record<string, unknown>[],
  ): Promise<void> {
    await pluginDataService.writePluginData(
      userId,
      'tracker',
      'goals.json',
      { goals },
      encryptionKey,
    );
  }

  // 读取所有记录
  async function readAllRecords(
    userId: string,
    encryptionKey: string,
  ): Promise<Record<string, unknown>[]> {
    const data = await pluginDataService.readPluginData(
      userId,
      'tracker',
      'records.json',
      encryptionKey,
    );
    if (!data) return [];
    return ((data as Record<string, unknown>)?.records as Record<string, unknown>[]) || [];
  }

  // 保存所有记录
  async function saveAllRecords(
    userId: string,
    encryptionKey: string,
    records: Record<string, unknown>[],
  ): Promise<void> {
    await pluginDataService.writePluginData(
      userId,
      'tracker',
      'records.json',
      { records },
      encryptionKey,
    );
  }

  return {
    // 获取目标列表
    async getList(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
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

        // 分页
        const offset = (params.offset as number) || 0;
        const count = (params.count as number) || 100;
        const total = goals.length;
        const paginatedGoals = goals.slice(offset, offset + count);

        return {
          isSuccess: true,
          data: {
            data: paginatedGoals,
            total,
            offset,
            count: paginatedGoals.length,
            hasMore: offset + paginatedGoals.length < total,
          },
        };
      } catch (e) {
        return { isSuccess: false, message: `获取目标列表失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 根据 ID 获取
    async getById(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
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
    async create(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
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
    async update(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
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
    async delete(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
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
        const filteredRecords = records.filter((r: Record<string, unknown>) => r.goalId !== params.id);
        await saveAllRecords(userId, encryptionKey, filteredRecords);

        return { isSuccess: true, data: { id: params.id } };
      } catch (e) {
        return { isSuccess: false, message: `删除目标失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 添加记录
    async addRecord(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
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
    async getRecords(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
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
    async getStats(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
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
}

/**
 * 创建 Calendar 插件专用处理器
 *
 * 数据格式：calendar_events.json 包含 {events: [...], completedEvents: [...]}
 */
function createCalendarHandlers(pluginDataService: PluginDataService): PluginHandlers {
  // 读取所有事件数据
  async function readAllEventsData(
    userId: string,
    encryptionKey: string,
  ): Promise<Record<string, unknown>> {
    const data = await pluginDataService.readPluginData(
      userId,
      'calendar',
      'calendar_events.json',
      encryptionKey,
    );
    return (data as Record<string, unknown>) || {};
  }

  // 保存所有事件数据
  async function saveAllEventsData(
    userId: string,
    encryptionKey: string,
    data: Record<string, unknown>,
  ): Promise<void> {
    await pluginDataService.writePluginData(
      userId,
      'calendar',
      'calendar_events.json',
      data,
      encryptionKey,
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

  return {
    // 获取事件列表
    async getList(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const data = await readAllEventsData(userId, encryptionKey);
        let events = parseEvents(data);

        // 按日期范围过滤
        const startDate = params.startDate as string | undefined;
        const endDate = params.endDate as string | undefined;

        if (startDate) {
          events = events.filter((e: Record<string, unknown>) =>
            (e.startTime as string) >= startDate
          );
        }
        if (endDate) {
          events = events.filter((e: Record<string, unknown>) =>
            (e.startTime as string) <= endDate + 'T23:59:59'
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
    async getById(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
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
    async create(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
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
    async update(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
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
    async delete(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
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
    async completeEvent(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
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
    async search(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const data = await readAllEventsData(userId, encryptionKey);
        let events = parseEvents(data);

        const { keyword, startDate, endDate } = params;

        if (startDate) {
          events = events.filter((e: Record<string, unknown>) =>
            (e.startTime as string) >= (startDate as string)
          );
        }
        if (endDate) {
          events = events.filter((e: Record<string, unknown>) =>
            (e.startTime as string) <= (endDate as string) + 'T23:59:59'
          );
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
 *
 * 数据格式：
 * - contacts.json: 联系人列表（数组格式）
 * - interactions.json: 互动记录 {records: [...]}
 */
function createContactHandlers(pluginDataService: PluginDataService): PluginHandlers {
  // 读取所有联系人
  async function readAllContacts(
    userId: string,
    encryptionKey: string,
  ): Promise<Record<string, unknown>[]> {
    const data = await pluginDataService.readPluginData(
      userId,
      'contact',
      'contacts.json',
      encryptionKey,
    );
    if (!data) return [];
    // contacts.json 直接是数组格式
    if (Array.isArray(data)) {
      return data as Record<string, unknown>[];
    }
    return ((data as Record<string, unknown>)?.contacts as Record<string, unknown>[]) || [];
  }

  // 保存所有联系人
  async function saveAllContacts(
    userId: string,
    encryptionKey: string,
    contacts: Record<string, unknown>[],
  ): Promise<void> {
    await pluginDataService.writePluginData(
      userId,
      'contact',
      'contacts.json',
      contacts,
      encryptionKey,
    );
  }

  return {
    // 获取联系人列表
    async getList(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        let contacts = await readAllContacts(userId, encryptionKey);

        // 分页
        const offset = (params.offset as number) || 0;
        const count = (params.count as number) || 100;
        const total = contacts.length;
        const paginatedContacts = contacts.slice(offset, offset + count);

        return {
          isSuccess: true,
          data: {
            data: paginatedContacts,
            total,
            offset,
            count: paginatedContacts.length,
            hasMore: offset + paginatedContacts.length < total,
          },
        };
      } catch (e) {
        return { isSuccess: false, message: `获取联系人失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 根据 ID 获取
    async getById(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const contacts = await readAllContacts(userId, encryptionKey);
        const contact = contacts.find((c: Record<string, unknown>) => c.id === params.id);

        if (!contact) {
          return { isSuccess: false, message: '联系人不存在', code: 'NOT_FOUND' };
        }

        return { isSuccess: true, data: contact };
      } catch (e) {
        return { isSuccess: false, message: `获取联系人失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 创建联系人
    async create(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const contacts = await readAllContacts(userId, encryptionKey);
        const now = new Date().toISOString();

        const newContact = {
          ...params,
          id: params.id || generateUUID(),
          createdAt: now,
          updatedAt: now,
        };

        contacts.push(newContact);
        await saveAllContacts(userId, encryptionKey, contacts);

        return { isSuccess: true, data: newContact };
      } catch (e) {
        return { isSuccess: false, message: `创建联系人失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 更新联系人
    async update(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const contacts = await readAllContacts(userId, encryptionKey);
        const index = contacts.findIndex((c: Record<string, unknown>) => c.id === params.id);

        if (index === -1) {
          return { isSuccess: false, message: '联系人不存在', code: 'NOT_FOUND' };
        }

        const updatedContact = {
          ...contacts[index],
          ...params,
          updatedAt: new Date().toISOString(),
        };
        contacts[index] = updatedContact;

        await saveAllContacts(userId, encryptionKey, contacts);
        return { isSuccess: true, data: updatedContact };
      } catch (e) {
        return { isSuccess: false, message: `更新联系人失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 删除联系人
    async delete(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const contacts = await readAllContacts(userId, encryptionKey);
        const initialLength = contacts.length;
        const filtered = contacts.filter((c: Record<string, unknown>) => c.id !== params.id);

        if (filtered.length === initialLength) {
          return { isSuccess: false, message: '联系人不存在', code: 'NOT_FOUND' };
        }

        await saveAllContacts(userId, encryptionKey, filtered);
        return { isSuccess: true, data: { id: params.id } };
      } catch (e) {
        return { isSuccess: false, message: `删除联系人失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 搜索联系人
    async search(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        let contacts = await readAllContacts(userId, encryptionKey);
        const { keyword } = params;

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
    async getStats(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
      try {
        const contacts = await readAllContacts(userId, encryptionKey);

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
 *
 * 数据格式：memorial_days.json 直接存储纪念日数组
 */
function createDayHandlers(pluginDataService: PluginDataService): PluginHandlers {
  // 读取所有纪念日
  async function readAllMemorialDays(
    userId: string,
    encryptionKey: string,
  ): Promise<Record<string, unknown>[]> {
    const data = await pluginDataService.readPluginData(
      userId,
      'day',
      'memorial_days.json',
      encryptionKey,
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
    days: Record<string, unknown>[],
  ): Promise<void> {
    await pluginDataService.writePluginData(
      userId,
      'day',
      'memorial_days.json',
      days,
      encryptionKey,
    );
  }

  return {
    // 获取纪念日列表
    async getList(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
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
    async getById(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
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
    async create(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
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
    async update(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
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
    async delete(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
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
    async search(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
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
    async getStats(userId: string, encryptionKey: string, params: Record<string, unknown>): Promise<PluginResult> {
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

      const encryptionKey = getEncryptionKeyFromContext(req);
      if (!encryptionKey) {
        errorResponse(res, 403, '缺少 X-Encryption-Key 请求头');
        return;
      }

      try {
        // 合并路径参数、查询参数和请求体
        const pathParams = extractPathParams(req, route.path);
        const queryParams = extractQueryParams(req);
        const bodyParams = req.body || {};

        const params = { ...queryParams, ...pathParams, ...bodyParams };

        const result = await handler(userId, encryptionKey, params, req);
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
