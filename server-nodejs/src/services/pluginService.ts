import fs from 'fs';
import path from 'path';
import { v4 as uuidv4 } from 'uuid';
import AdmZip from 'adm-zip';
import {
  InstalledPlugin,
  PluginMetadata,
  PluginModule,
  PluginStatus,
  StoreConfig,
  StorePlugin,
  PluginPermissions,
} from '../types/plugin';
import { pluginEventEmitter } from './eventEmitter';

/** 插件目录名称 */
const PLUGINS_DIR = 'plugins';
/** 插件元信息文件名 */
const METADATA_FILE = 'metadata.json';
/** 插件入口文件名 */
const ENTRY_FILE = 'main.js';
/** 插件注册表文件名 */
const REGISTRY_FILE = 'plugin_registry.json';
/** 商店配置文件名 */
const STORE_CONFIG_FILE = 'store_config.json';

/**
 * 插件注册表结构
 */
interface PluginRegistry {
  plugins: Record<string, InstalledPlugin>;
  updatedAt: string;
}

/**
 * 插件管理服务
 *
 * 负责插件的安装、启用、禁用、卸载
 * 管理插件生命周期和钩子注册
 */
export class PluginService {
  private dataDir: string;
  private pluginsDir: string;
  private registryPath: string;
  private storeConfigPath: string;
  private registry: PluginRegistry;
  private loadedPlugins: Map<string, PluginModule> = new Map();
  private unsubscribers: Map<string, (() => void)[]> = new Map();

  constructor(dataDir: string) {
    this.dataDir = dataDir;
    this.pluginsDir = path.join(dataDir, PLUGINS_DIR);
    this.registryPath = path.join(dataDir, REGISTRY_FILE);
    this.storeConfigPath = path.join(dataDir, STORE_CONFIG_FILE);
    this.registry = { plugins: {}, updatedAt: new Date().toISOString() };
  }

  /**
   * 初始化服务
   */
  async initialize(): Promise<void> {
    // 确保插件目录存在
    if (!fs.existsSync(this.pluginsDir)) {
      fs.mkdirSync(this.pluginsDir, { recursive: true });
    }

    // 加载注册表
    await this.loadRegistry();

    // 自动加载已启用的插件
    for (const [uuid, plugin] of Object.entries(this.registry.plugins)) {
      if (plugin.status === 'enabled') {
        await this.loadPlugin(uuid);
      }
    }
  }

  // ==================== 插件管理 ====================

  /**
   * 获取已安装的插件列表
   */
  async getInstalledPlugins(): Promise<InstalledPlugin[]> {
    return Object.values(this.registry.plugins);
  }

  /**
   * 根据UUID获取插件
   */
  async getPluginByUUID(uuid: string): Promise<InstalledPlugin | null> {
    return this.registry.plugins[uuid] || null;
  }

  /**
   * 安装插件（从 ZIP 文件）
   */
  async installFromZip(zipBuffer: Buffer): Promise<InstalledPlugin> {
    const zip = new AdmZip(zipBuffer);
    const zipEntries = zip.getEntries();

    // 查找 metadata.json
    const metadataEntry = zipEntries.find(e =>
      e.entryName.endsWith(METADATA_FILE) && !e.entryName.includes('__MACOSX')
    );

    if (!metadataEntry) {
      throw new Error('无效的插件包：缺少 metadata.json');
    }

    // 解析元信息
    const metadataContent = zip.readAsText(metadataEntry);
    let metadata: PluginMetadata;
    try {
      metadata = JSON.parse(metadataContent);
    } catch {
      throw new Error('无效的 metadata.json 格式');
    }

    // 验证必需字段
    if (!metadata.uuid || !metadata.title || !metadata.version) {
      throw new Error('metadata.json 缺少必需字段：uuid, title, version');
    }

    // 检查是否已安装
    if (this.registry.plugins[metadata.uuid]) {
      throw new Error(`插件 ${metadata.title} 已安装`);
    }

    // 创建插件目录
    const pluginPath = path.join(this.pluginsDir, metadata.uuid);
    if (!fs.existsSync(pluginPath)) {
      fs.mkdirSync(pluginPath, { recursive: true });
    }

    // 解压文件
    for (const entry of zipEntries) {
      if (entry.isDirectory || entry.entryName.includes('__MACOSX')) continue;

      // 提取相对路径（处理可能的前缀目录）
      let relativePath = entry.entryName;
      const slashIndex = relativePath.indexOf('/');
      if (slashIndex > 0) {
        relativePath = relativePath.substring(slashIndex + 1);
      }

      if (relativePath) {
        const filePath = path.join(pluginPath, relativePath);
        const dir = path.dirname(filePath);
        if (!fs.existsSync(dir)) {
          fs.mkdirSync(dir, { recursive: true });
        }
        fs.writeFileSync(filePath, entry.getData());
      }
    }

    // 检查入口文件是否存在
    const entryPath = path.join(pluginPath, ENTRY_FILE);
    if (!fs.existsSync(entryPath)) {
      // 清理目录
      fs.rmSync(pluginPath, { recursive: true, force: true });
      throw new Error('无效的插件包：缺少 main.js 入口文件');
    }

    // 创建安装记录
    const installedPlugin: InstalledPlugin = {
      ...metadata,
      status: 'installed',
      pluginPath,
      installedAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    this.registry.plugins[metadata.uuid] = installedPlugin;
    await this.saveRegistry();

    return installedPlugin;
  }

  /**
   * 启用插件
   */
  async enablePlugin(uuid: string): Promise<void> {
    const plugin = this.registry.plugins[uuid];
    if (!plugin) {
      throw new Error('插件不存在');
    }

    if (plugin.status === 'enabled') {
      return; // 已启用
    }

    // 加载插件
    await this.loadPlugin(uuid);

    // 更新状态
    plugin.status = 'enabled';
    plugin.updatedAt = new Date().toISOString();
    await this.saveRegistry();
  }

  /**
   * 禁用插件
   */
  async disablePlugin(uuid: string): Promise<void> {
    const plugin = this.registry.plugins[uuid];
    if (!plugin) {
      throw new Error('插件不存在');
    }

    if (plugin.status !== 'enabled') {
      return; // 未启用
    }

    // 卸载插件代码
    await this.unloadPlugin(uuid);

    // 更新状态
    plugin.status = 'disabled';
    plugin.updatedAt = new Date().toISOString();
    await this.saveRegistry();
  }

  /**
   * 卸载插件
   */
  async uninstallPlugin(uuid: string): Promise<void> {
    const plugin = this.registry.plugins[uuid];
    if (!plugin) {
      throw new Error('插件不存在');
    }

    // 先禁用
    if (plugin.status === 'enabled') {
      await this.unloadPlugin(uuid);
    }

    // 删除文件
    if (fs.existsSync(plugin.pluginPath)) {
      fs.rmSync(plugin.pluginPath, { recursive: true, force: true });
    }

    // 从注册表移除
    delete this.registry.plugins[uuid];
    await this.saveRegistry();
  }

  // ==================== 插件商店 ====================

  /**
   * 获取商店配置
   */
  async getStoreConfig(): Promise<StoreConfig> {
    if (!fs.existsSync(this.storeConfigPath)) {
      return {
        storeURL: '',
        syncInterval: 0,
      };
    }

    const content = fs.readFileSync(this.storeConfigPath, 'utf8');
    return JSON.parse(content);
  }

  /**
   * 更新商店配置
   */
  async updateStoreConfig(config: Partial<StoreConfig>): Promise<StoreConfig> {
    const current = await this.getStoreConfig();
    const updated = { ...current, ...config };

    fs.writeFileSync(this.storeConfigPath, JSON.stringify(updated, null, 2), 'utf8');
    return updated;
  }

  /**
   * 从商店获取插件列表
   */
  async fetchStorePlugins(): Promise<StorePlugin[]> {
    const config = await this.getStoreConfig();

    if (!config.storeURL) {
      return [];
    }

    try {
      const response = await fetch(config.storeURL);
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }

      const data = await response.json() as StorePlugin[];
      const plugins = Array.isArray(data) ? data : [];

      // 更新同步时间
      await this.updateStoreConfig({
        lastSyncAt: new Date().toISOString(),
      });

      return plugins.map(p => ({ ...p, sourceURL: config.storeURL }));
    } catch (error) {
      console.error('获取商店插件失败:', error);
      throw new Error(`获取商店插件失败: ${error}`);
    }
  }

  /**
   * 从商店安装插件
   */
  async installFromStore(downloadURL: string): Promise<InstalledPlugin> {
    const response = await fetch(downloadURL);
    if (!response.ok) {
      throw new Error(`下载失败: HTTP ${response.status}`);
    }

    const buffer = Buffer.from(await response.arrayBuffer());
    return this.installFromZip(buffer);
  }

  // ==================== 权限检查 ====================

  /**
   * 检查插件是否有权限访问指定数据
   */
  checkPermission(
    plugin: InstalledPlugin,
    targetPluginId: string,
    operation: 'create' | 'read' | 'update' | 'delete',
  ): boolean {
    const perms = plugin.permissions;

    // 检查数据访问权限
    if (perms.dataAccess.length > 0 && !perms.dataAccess.includes(targetPluginId)) {
      return false;
    }

    // 检查操作权限
    if (!perms.operations.includes(operation)) {
      return false;
    }

    return true;
  }

  /**
   * 检查网络访问权限
   */
  checkNetworkAccess(plugin: InstalledPlugin): boolean {
    return plugin.permissions.networkAccess;
  }

  // ==================== 私有方法 ====================

  /**
   * 加载注册表
   */
  private async loadRegistry(): Promise<void> {
    if (fs.existsSync(this.registryPath)) {
      try {
        const content = fs.readFileSync(this.registryPath, 'utf8');
        this.registry = JSON.parse(content);
      } catch (error) {
        console.error('加载插件注册表失败:', error);
        this.registry = { plugins: {}, updatedAt: new Date().toISOString() };
      }
    }
  }

  /**
   * 保存注册表
   */
  private async saveRegistry(): Promise<void> {
    this.registry.updatedAt = new Date().toISOString();
    fs.writeFileSync(this.registryPath, JSON.stringify(this.registry, null, 2), 'utf8');
  }

  /**
   * 加载插件代码
   */
  private async loadPlugin(uuid: string): Promise<void> {
    const plugin = this.registry.plugins[uuid];
    if (!plugin) return;

    // 清除 require 缓存
    const entryPath = path.join(plugin.pluginPath, ENTRY_FILE);
    delete require.cache[require.resolve(entryPath)];

    try {
      // 加载 BasePlugin 基类
      const { BasePlugin } = require('../plugins/BasePlugin');

      // 加载插件模块（可能是工厂函数或直接模块）
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      let pluginModuleRaw: any = require(entryPath);

      // 如果导出的是工厂函数，则调用它并传入 BasePlugin
      if (typeof pluginModuleRaw === 'function') {
        pluginModuleRaw = pluginModuleRaw(BasePlugin);
      }

      const pluginModule: PluginModule = pluginModuleRaw;

      // 验证元信息匹配
      if (pluginModule.metadata?.uuid !== uuid) {
        throw new Error('插件元信息不匹配');
      }

      // 注册事件处理器
      if (pluginModule.handlers && plugin.events) {
        const unsubs = pluginEventEmitter.registerHandlers(
          plugin.events,
          pluginModule.handlers,
        );
        this.unsubscribers.set(uuid, unsubs);
      }

      // 调用 onLoad
      if (pluginModule.onLoad) {
        await pluginModule.onLoad();
      }

      // 调用 onEnable
      if (pluginModule.onEnable) {
        await pluginModule.onEnable();
      }

      this.loadedPlugins.set(uuid, pluginModule);
    } catch (error) {
      console.error(`加载插件 ${plugin.title} 失败:`, error);
      throw error;
    }
  }

  /**
   * 卸载插件代码
   */
  private async unloadPlugin(uuid: string): Promise<void> {
    const pluginModule = this.loadedPlugins.get(uuid);
    if (!pluginModule) return;

    try {
      // 调用 onDisable
      if (pluginModule.onDisable) {
        await pluginModule.onDisable();
      }

      // 调用 onUnload
      if (pluginModule.onUnload) {
        await pluginModule.onUnload();
      }

      // 取消事件订阅
      const unsubs = this.unsubscribers.get(uuid);
      if (unsubs) {
        unsubs.forEach(unsub => unsub());
        this.unsubscribers.delete(uuid);
      }

      this.loadedPlugins.delete(uuid);
    } catch (error) {
      console.error(`卸载插件失败:`, error);
    }
  }
}

/** 默认权限配置 */
export const DEFAULT_PERMISSIONS: PluginPermissions = {
  dataAccess: [],
  operations: ['read'],
  networkAccess: false,
};
