import { PluginDataService } from '../../../services/pluginDataService';
import { PluginHandlers, PluginResult } from '../types';
import { generateUUID, createPaginatedResult } from '../utils';

/**
 * 创建 Goods 插件专用处理器
 *
 * 数据格式：
 * - warehouses.json: 仓库 ID 列表 {warehouses: ["id1", "id2"]}
 * - warehouse/{id}.json: 仓库详情 {warehouse: {...}}
 * - items.json: 物品列表 {items: [...]}
 */
export function createGoodsHandlers(pluginDataService: PluginDataService): PluginHandlers {
  // 读取所有仓库
  async function readAllWarehouses(
    userId: string,
    encryptionKey: string
  ): Promise<Record<string, unknown>[]> {
    const warehousesData = await pluginDataService.readPluginData(
      userId,
      'goods',
      'warehouses.json',
      encryptionKey
    );
    if (!warehousesData) return [];

    // 仓库 ID 列表
    const warehouseIds =
      (warehousesData as Record<string, unknown>)?.warehouses as string[] || [];

    const warehouses: Record<string, unknown>[] = [];
    for (const id of warehouseIds) {
      const warehouseData = await pluginDataService.readPluginData(
        userId,
        'goods',
        `warehouse/${id}.json`,
        encryptionKey
      );
      if (warehouseData && (warehouseData as Record<string, unknown>).warehouse) {
        warehouses.push(
          (warehouseData as Record<string, unknown>).warehouse as Record<string, unknown>
        );
      }
    }

    return warehouses;
  }

  // 读取所有物品
  async function readAllItems(
    userId: string,
    encryptionKey: string
  ): Promise<Record<string, unknown>[]> {
    const data = await pluginDataService.readPluginData(
      userId,
      'goods',
      'items.json',
      encryptionKey
    );
    if (!data) return [];
    return ((data as Record<string, unknown>)?.items as Record<string, unknown>[]) || [];
  }

  // 保存所有物品
  async function saveAllItems(
    userId: string,
    encryptionKey: string,
    items: Record<string, unknown>[]
  ): Promise<void> {
    await pluginDataService.writePluginData(
      userId,
      'goods',
      'items.json',
      { items },
      encryptionKey
    );
  }

  return {
    // 获取仓库列表
    async getWarehouses(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        const warehouses = await readAllWarehouses(userId, encryptionKey);
        return { isSuccess: true, data: { data: warehouses, total: warehouses.length } };
      } catch (e) {
        return { isSuccess: false, message: `获取仓库失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 获取物品列表
    async getList(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        let items = await readAllItems(userId, encryptionKey);

        // 按仓库过滤
        const warehouseId = params.warehouseId as string | undefined;
        if (warehouseId) {
          items = items.filter((i: Record<string, unknown>) => i.warehouseId === warehouseId);
        }

        const result = createPaginatedResult(items, {
          offset: params.offset as number,
          count: params.count as number,
        });

        return { isSuccess: true, data: result };
      } catch (e) {
        return { isSuccess: false, message: `获取物品失败: ${e}`, code: 'INTERNAL_ERROR' };
      }
    },

    // 根据 ID 获取
    async getById(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
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
    async create(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
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
    async update(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
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
    async delete(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
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
    async search(
      userId: string,
      encryptionKey: string,
      params: Record<string, unknown>
    ): Promise<PluginResult> {
      try {
        let items = await readAllItems(userId, encryptionKey);

        const { keyword, warehouseId } = params;

        if (warehouseId) {
          items = items.filter((i: Record<string, unknown>) => i.warehouseId === warehouseId);
        }
        if (keyword) {
          const kw = String(keyword).toLowerCase();
          items = items.filter(
            (i: Record<string, unknown>) =>
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
