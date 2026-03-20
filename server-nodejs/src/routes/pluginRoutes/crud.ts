import { PluginDataService } from '../../services/pluginDataService';
import { PluginHandlers, PluginResult } from './types';
import { generateUUID, createPaginatedResult } from './utils';

/**
 * 创建通用 CRUD 处理器
 *
 * 适用于简单的数据存储场景，数据格式为 {resourceName: [...items]}
 */
export function createCrudHandlers(
  pluginDataService: PluginDataService,
  pluginId: string,
  resourceName: string,
  dataFile: string = 'data.json'
): PluginHandlers {
  return {
    // 获取列表
    async getList(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const data = await pluginDataService.readPluginData(
          userId,
          pluginId,
          dataFile,
          encryptionKey
        );
        let items: Record<string, unknown>[] = Array.isArray(data)
          ? data
          : ((data as Record<string, unknown>)?.[resourceName] as Record<string, unknown>[]) ||
            [];

        const result = createPaginatedResult(items, {
          offset: params.offset as number,
          count: params.count as number,
        });

        return {
          isSuccess: true,
          data: result,
        };
      } catch (e) {
        return { isSuccess: false, message: `读取数据失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 根据 ID 获取
    async getById(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const data = await pluginDataService.readPluginData(
          userId,
          pluginId,
          dataFile,
          encryptionKey
        );
        const items: Record<string, unknown>[] = Array.isArray(data)
          ? data
          : ((data as Record<string, unknown>)?.[resourceName] as Record<string, unknown>[]) ||
            [];
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
    async create(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const data = await pluginDataService.readPluginData(
          userId,
          pluginId,
          dataFile,
          encryptionKey
        );
        const items: Record<string, unknown>[] = Array.isArray(data)
          ? [...data]
          : [
              ...(((data as Record<string, unknown>)?.[resourceName] as Record<string, unknown>[]) ||
                []),
            ];

        const now = new Date().toISOString();
        const newItem = {
          ...params,
          id: params.id || generateUUID(),
          createdAt: now,
          updatedAt: now,
        };

        items.push(newItem);

        await pluginDataService.writePluginData(
          userId,
          pluginId,
          dataFile,
          { [resourceName]: items },
          encryptionKey
        );

        return { isSuccess: true, data: newItem };
      } catch (e) {
        return { isSuccess: false, message: `创建失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 更新
    async update(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const data = await pluginDataService.readPluginData(
          userId,
          pluginId,
          dataFile,
          encryptionKey
        );
        const items: Record<string, unknown>[] = Array.isArray(data)
          ? [...data]
          : [
              ...(((data as Record<string, unknown>)?.[resourceName] as Record<string, unknown>[]) ||
                []),
            ];
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

        await pluginDataService.writePluginData(
          userId,
          pluginId,
          dataFile,
          { [resourceName]: items },
          encryptionKey
        );

        return { isSuccess: true, data: updatedItem };
      } catch (e) {
        return { isSuccess: false, message: `更新失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 删除
    async delete(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const data = await pluginDataService.readPluginData(
          userId,
          pluginId,
          dataFile,
          encryptionKey
        );
        const items: Record<string, unknown>[] = Array.isArray(data)
          ? [...data]
          : [
              ...(((data as Record<string, unknown>)?.[resourceName] as Record<string, unknown>[]) ||
                []),
            ];
        const index = items.findIndex((i: Record<string, unknown>) => i.id === params.id);

        if (index === -1) {
          return { isSuccess: false, message: '项目不存在', code: 'NOT_FOUND' };
        }

        items.splice(index, 1);
        await pluginDataService.writePluginData(
          userId,
          pluginId,
          dataFile,
          { [resourceName]: items },
          encryptionKey
        );

        return { isSuccess: true, data: { id: params.id } };
      } catch (e) {
        return { isSuccess: false, message: `删除失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },
  };
}
