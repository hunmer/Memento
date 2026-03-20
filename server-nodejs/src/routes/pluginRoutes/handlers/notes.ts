import { PluginDataService } from '../../../services/pluginDataService';
import { PluginHandlers, PluginResult } from '../types';
import { createCrudHandlers } from '../crud';

/**
 * 创建 Notes 插件专用处理器
 */
export function createNotesHandlers(pluginDataService: PluginDataService): PluginHandlers {
  const crud = createCrudHandlers(pluginDataService, 'notes', 'notes');
  const folderCrud = createCrudHandlers(pluginDataService, 'notes', 'folders');

  return {
    ...crud,
    ...Object.fromEntries(
      Object.entries(folderCrud).map(([key, handler]) => [
        `Folder${key.charAt(0).toUpperCase() + key.slice(1)}`,
        handler,
      ])
    ),

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
        const data = await pluginDataService.readPluginData(
          userId,
          'notes',
          'data.json',
          encryptionKey
        );
        const notes: Record<string, unknown>[] =
          ((data as Record<string, unknown>)?.notes as Record<string, unknown>[]) || [];
        const index = notes.findIndex((n: Record<string, unknown>) => n.id === params.id);

        if (index === -1) {
          return { isSuccess: false, message: '笔记不存在', code: 'NOT_FOUND' };
        }

        notes[index] = {
          ...notes[index],
          folderId: params.folderId,
          updatedAt: new Date().toISOString(),
        };

        await pluginDataService.writePluginData(
          userId,
          'notes',
          'data.json',
          { notes, folders: (data as Record<string, unknown>)?.folders || [] },
          encryptionKey
        );

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
        const data = await pluginDataService.readPluginData(
          userId,
          'notes',
          'data.json',
          encryptionKey
        );
        let notes: Record<string, unknown>[] =
          ((data as Record<string, unknown>)?.notes as Record<string, unknown>[]) || [];

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
        const data = await pluginDataService.readPluginData(
          userId,
          'notes',
          'data.json',
          encryptionKey
        );
        let notes: Record<string, unknown>[] =
          ((data as Record<string, unknown>)?.notes as Record<string, unknown>[]) || [];

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
}
