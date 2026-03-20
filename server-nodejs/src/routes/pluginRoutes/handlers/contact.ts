import { PluginDataService } from '../../../services/pluginDataService';
import { PluginHandlers, PluginResult } from '../types';
import { generateUUID } from '../utils';
import { addHooksToHandlers, ActionType } from '../hooks';

/**
 * 创建 Contact 插件专用处理器
 *
 * 数据格式：
 * - contacts.json: 联系人列表（数组格式）
 * - interactions.json: 互动记录 {records: [...]}
 */
export function createContactHandlers(pluginDataService: PluginDataService): PluginHandlers {
  // 读取所有联系人
  async function readAllContacts(
    userId: string,
    encryptionKey: string
  ): Promise<Record<string, unknown>[]> {
    const data = await pluginDataService.readPluginData(
      userId,
      'contact',
      'contacts.json',
      encryptionKey
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
    contacts: Record<string, unknown>[]
  ): Promise<void> {
    await pluginDataService.writePluginData(
      userId,
      'contact',
      'contacts.json',
      contacts,
      encryptionKey
    );
  }

  const handlers: PluginHandlers = {
    // 获取联系人列表
    async getList(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const contacts = await readAllContacts(userId, encryptionKey);

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
    async getById(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
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
    async create(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
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
    async update(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
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
    async delete(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
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
    async search(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        let contacts = await readAllContacts(userId, encryptionKey);
        const { keyword } = params;

        if (keyword) {
          const kw = String(keyword).toLowerCase();
          contacts = contacts.filter(
            (c: Record<string, unknown>) =>
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
    async getStats(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
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

  const hookMappings: Record<string, { action: ActionType; entity?: string }> = {
    getList: { action: 'read', entity: 'Contact' },
    getById: { action: 'read', entity: 'Contact' },
    create: { action: 'create', entity: 'Contact' },
    update: { action: 'update', entity: 'Contact' },
    delete: { action: 'delete', entity: 'Contact' },
    search: { action: 'read', entity: 'Contact' },
    getStats: { action: 'read', entity: 'ContactStats' },
  };

  return addHooksToHandlers('contact', handlers, hookMappings);
}
