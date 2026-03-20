import { PluginDataService } from '../../../services/pluginDataService';
import { PluginHandlers, PluginResult } from '../types';
import { createCrudHandlers } from '../crud';
import { createPaginatedResult, generateUUID } from '../utils';
import { addHooksToHandlers, ActionType } from '../hooks';

/**
 * 创建 Notes 插件专用处理器
 *
 * 数据格式：
 * - folders.json: 文件夹列表
 * - notes/index.json: 笔记 ID 列表
 * - notes/{id}.json: 单个笔记详情
 */
export function createNotesHandlers(pluginDataService: PluginDataService): PluginHandlers {
  const folderCrud = createCrudHandlers(pluginDataService, 'notes', 'folders');

  // 读取所有笔记（从独立文件中）
  async function readAllNotes(
    userId: string,
    encryptionKey: string
  ): Promise<Record<string, unknown>[]> {
    // 读取笔记 ID 列表
    const indexData = await pluginDataService.readPluginData(
      userId,
      'notes',
      'notes/index.json',
      encryptionKey
    );

    if (!indexData) return [];

    const noteIds = indexData as string[];
    const notes: Record<string, unknown>[] = [];

    for (const id of noteIds) {
      const noteData = await pluginDataService.readPluginData(
        userId,
        'notes',
        `notes/${id}.json`,
        encryptionKey
      );
      if (noteData) {
        notes.push(noteData as Record<string, unknown>);
      }
    }

    return notes;
  }

  // 保存所有笔记（到独立文件）
  async function saveAllNotes(
    userId: string,
    encryptionKey: string,
    notes: Record<string, unknown>[]
  ): Promise<void> {
    // 保存 index.json
    const noteIds = notes.map(n => n.id);
    await pluginDataService.writePluginData(
      userId,
      'notes',
      'notes/index.json',
      noteIds,
      encryptionKey
    );

    // 保存每个笔记文件
    for (const note of notes) {
      await pluginDataService.writePluginData(
        userId,
        'notes',
        `notes/${note.id}.json`,
        note,
        encryptionKey
      );
    }
  }

  const handlers: PluginHandlers = {
    ...Object.fromEntries(
      Object.entries(folderCrud).map(([key, handler]) => [
        `Folder${key.charAt(0).toUpperCase() + key.slice(1)}`,
        handler,
      ])
    ),

    // 获取笔记列表
    async getList(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        let notes = await readAllNotes(userId, encryptionKey);

        // 按文件夹过滤
        const folderId = params.folderId as string | undefined;
        if (folderId) {
          notes = notes.filter((n: Record<string, unknown>) => n.folderId === folderId);
        }

        const result = createPaginatedResult(notes, {
          offset: params.offset as number,
          count: params.count as number,
        });

        return { isSuccess: true, data: result };
      } catch (e) {
        return { isSuccess: false, message: `获取笔记失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 根据 ID 获取笔记
    async getById(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const notes = await readAllNotes(userId, encryptionKey);
        const note = notes.find((n: Record<string, unknown>) => n.id === params.id);

        if (!note) {
          return { isSuccess: false, message: '笔记不存在', code: 'NOT_FOUND' };
        }

        return { isSuccess: true, data: note };
      } catch (e) {
        return { isSuccess: false, message: `获取笔记失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 创建笔记
    async create(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const notes = await readAllNotes(userId, encryptionKey);
        const now = new Date().toISOString();

        const newNote = {
          ...params,
          id: params.id || generateUUID(),
          createdAt: now,
          updatedAt: now,
        };

        notes.push(newNote);
        await saveAllNotes(userId, encryptionKey, notes);

        return { isSuccess: true, data: newNote };
      } catch (e) {
        return { isSuccess: false, message: `创建笔记失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 更新笔记
    async update(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const notes = await readAllNotes(userId, encryptionKey);
        const index = notes.findIndex((n: Record<string, unknown>) => n.id === params.id);

        if (index === -1) {
          return { isSuccess: false, message: '笔记不存在', code: 'NOT_FOUND' };
        }

        const updatedNote = {
          ...notes[index],
          ...params,
          updatedAt: new Date().toISOString(),
        };
        notes[index] = updatedNote;

        await saveAllNotes(userId, encryptionKey, notes);
        return { isSuccess: true, data: updatedNote };
      } catch (e) {
        return { isSuccess: false, message: `更新笔记失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 删除笔记
    async delete(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const notes = await readAllNotes(userId, encryptionKey);
        const filtered = notes.filter((n: Record<string, unknown>) => n.id !== params.id);

        if (filtered.length === notes.length) {
          return { isSuccess: false, message: '笔记不存在', code: 'NOT_FOUND' };
        }

        await saveAllNotes(userId, encryptionKey, filtered);
        return { isSuccess: true, data: { id: params.id } };
      } catch (e) {
        return { isSuccess: false, message: `删除笔记失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 获取文件夹列表
    async getFolders(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      return folderCrud.getList(userId, encryptionKey, params);
    },

    async getFolderById(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      return folderCrud.getById(userId, encryptionKey, params);
    },

    async createFolder(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      return folderCrud.create(userId, encryptionKey, params);
    },

    async updateFolder(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      return folderCrud.update(userId, encryptionKey, params);
    },

    async deleteFolder(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      return folderCrud.delete(userId, encryptionKey, params);
    },

    // 移动笔记
    async moveNote(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const notes = await readAllNotes(userId, encryptionKey);
        const index = notes.findIndex((n: Record<string, unknown>) => n.id === params.id);

        if (index === -1) {
          return { isSuccess: false, message: '笔记不存在', code: 'NOT_FOUND' };
        }

        notes[index] = {
          ...notes[index],
          folderId: params.folderId,
          updatedAt: new Date().toISOString(),
        };

        await saveAllNotes(userId, encryptionKey, notes);
        return { isSuccess: true, data: notes[index] };
      } catch (e) {
        return { isSuccess: false, message: `移动笔记失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 获取文件夹的笔记
    async getFolderNotes(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const folderId = params.id;
        let notes = await readAllNotes(userId, encryptionKey);

        notes = notes.filter((n: Record<string, unknown>) => n.folderId === folderId);

        return { isSuccess: true, data: { data: notes, total: notes.length } };
      } catch (e) {
        return { isSuccess: false, message: `获取笔记失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 搜索笔记
    async search(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const { keyword, folderId } = params;
        let notes = await readAllNotes(userId, encryptionKey);

        if (folderId) {
          notes = notes.filter((n: Record<string, unknown>) => n.folderId === folderId);
        }
        if (keyword) {
          const kw = String(keyword).toLowerCase();
          notes = notes.filter(
            (n: Record<string, unknown>) =>
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

  // 定义 handler 到 hook 的映射
  const hookMappings: Record<string, { action: ActionType; entity?: string }> = {
    getList: { action: 'read', entity: 'Note' },
    getById: { action: 'read', entity: 'Note' },
    create: { action: 'create', entity: 'Note' },
    update: { action: 'update', entity: 'Note' },
    delete: { action: 'delete', entity: 'Note' },
    search: { action: 'read', entity: 'Note' },
  };

  return addHooksToHandlers('notes', handlers, hookMappings);
}
