import { PluginDataService } from '../../../services/pluginDataService';
import { PluginHandlers, PluginResult } from '../types';
import { generateUUID, createPaginatedResult } from '../utils';

/**
 * 创建 Chat 插件专用处理器
 *
 * 数据格式：
 * - channels.json: 频道 ID 列表 {"channels": ["id1", "id2", ...]}
 * - channel/{id}.json: 频道详情 {"channel": {...}}
 * - messages/{channelId}.json: 频道消息 {"messages": [...]}
 */
export function createChatHandlers(pluginDataService: PluginDataService): PluginHandlers {
  // 读取频道 ID 列表
  async function readChannelIds(userId: string, encryptionKey: string): Promise<string[]> {
    const data = await pluginDataService.readPluginData(
      userId,
      'chat',
      'channels.json',
      encryptionKey
    );
    if (!data) return [];
    return ((data as Record<string, unknown>)?.channels as string[]) || [];
  }

  // 保存频道 ID 列表
  async function saveChannelIds(
    userId: string,
    encryptionKey: string,
    channelIds: string[]
  ): Promise<void> {
    await pluginDataService.writePluginData(
      userId,
      'chat',
      'channels.json',
      { channels: channelIds },
      encryptionKey
    );
  }

  // 读取频道详情
  async function readChannel(
    userId: string,
    encryptionKey: string,
    channelId: string
  ): Promise<Record<string, unknown> | null> {
    const data = await pluginDataService.readPluginData(
      userId,
      'chat',
      `channel/${channelId}.json`,
      encryptionKey
    );
    if (!data) return null;
    return (data as Record<string, unknown>)?.channel as Record<string, unknown> || null;
  }

  // 保存频道详情
  async function saveChannel(
    userId: string,
    encryptionKey: string,
    channelId: string,
    channel: Record<string, unknown>
  ): Promise<void> {
    await pluginDataService.writePluginData(
      userId,
      'chat',
      `channel/${channelId}.json`,
      { channel },
      encryptionKey
    );
  }

  // 读取频道消息
  async function readMessages(
    userId: string,
    encryptionKey: string,
    channelId: string
  ): Promise<Record<string, unknown>[]> {
    const data = await pluginDataService.readPluginData(
      userId,
      'chat',
      `messages/${channelId}.json`,
      encryptionKey
    );
    if (!data) return [];
    return ((data as Record<string, unknown>)?.messages as Record<string, unknown>[]) || [];
  }

  // 保存频道消息
  async function saveMessages(
    userId: string,
    encryptionKey: string,
    channelId: string,
    messages: Record<string, unknown>[]
  ): Promise<void> {
    await pluginDataService.writePluginData(
      userId,
      'chat',
      `messages/${channelId}.json`,
      { messages },
      encryptionKey
    );
  }

  return {
    // 获取频道列表
    async getList(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const channelIds = await readChannelIds(userId, encryptionKey);
        const channels: Record<string, unknown>[] = [];

        for (const channelId of channelIds) {
          const channel = await readChannel(userId, encryptionKey, channelId);
          if (channel) {
            channels.push(channel);
          }
        }

        const result = createPaginatedResult(channels, {
          offset: params.offset as number,
          count: params.count as number,
        });

        return { isSuccess: true, data: result };
      } catch (e) {
        return { isSuccess: false, message: `获取频道失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 获取单个频道
    async getById(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
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
    async create(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
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
    async update(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
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
    async delete(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const channelId = params.id as string;

        // 删除频道文件
        await pluginDataService.deletePluginFile(userId, 'chat', `channel/${channelId}.json`);

        // 删除消息文件
        await pluginDataService.deletePluginFile(userId, 'chat', `messages/${channelId}.json`);

        // 从频道列表中移除
        const channelIds = await readChannelIds(userId, encryptionKey);
        const filteredIds = channelIds.filter((id) => id !== channelId);
        await saveChannelIds(userId, encryptionKey, filteredIds);

        return { isSuccess: true, data: { id: channelId } };
      } catch (e) {
        return { isSuccess: false, message: `删除频道失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 获取消息列表
    async getMessages(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const channelId = params.channelId as string;
        let messages = await readMessages(userId, encryptionKey, channelId);

        const result = createPaginatedResult(messages, {
          offset: params.offset as number,
          count: params.count as number,
        });

        return { isSuccess: true, data: result };
      } catch (e) {
        return { isSuccess: false, message: `读取消息失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 发送消息
    async sendMessage(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
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
    async deleteMessage(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
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
    async findChannel(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
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
              String(c[field as string] || '')
                .toLowerCase()
                .includes(String(value).toLowerCase())
            );
          } else {
            channels = channels.filter(
              (c: Record<string, unknown>) => c[field as string] === value
            );
          }
        }

        return { isSuccess: true, data: { data: channels, total: channels.length } };
      } catch (e) {
        return { isSuccess: false, message: `查找频道失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 查找消息
    async findMessage(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
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
              String(m[field as string] || '')
                .toLowerCase()
                .includes(String(value).toLowerCase())
            );
          } else {
            messages = messages.filter(
              (m: Record<string, unknown>) => m[field as string] === value
            );
          }
        }

        return { isSuccess: true, data: { data: messages, total: messages.length } };
      } catch (e) {
        return { isSuccess: false, message: `查找消息失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },
  };
}
