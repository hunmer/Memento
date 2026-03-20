/**
 * BasePlugin - 插件公用基类
 *
 * 提供插件开发常用功能封装，减少样板代码
 *
 * 使用示例:
 * ```javascript
 * const { BasePlugin } = require('./BasePlugin');
 *
 * class MyPlugin extends BasePlugin {
 *   constructor() {
 *     super({
 *       uuid: 'my-plugin',
 *       title: '我的插件',
 *       description: '插件描述',
 *       version: '1.0.0',
 *       author: 'Author',
 *     });
 *   }
 *
 *   onPluginLoad() {
 *     this.log('插件加载完成');
 *   }
 *
 *   handlers = {
 *     'chat::before:createChannel': async (ctx) => {
 *       this.log('即将创建频道');
 *       return ctx;
 *     },
 *   };
 * }
 *
 * module.exports = new MyPlugin().export();
 * ```
 */

/**
 * 默认权限配置
 */
const DEFAULT_PERMISSIONS = {
  dataAccess: [],
  operations: ['read'],
  networkAccess: false,
};

/**
 * BasePlugin 基类
 */
class BasePlugin {
  /** 插件元信息 */
  metadata;

  /** 日志前缀 */
  _logPrefix;

  /** 数据目录 */
  _dataDir;

  /**
   * 构造函数
   * @param {Object} config 插件配置
   * @param {string} config.uuid 插件唯一标识
   * @param {string} config.title 插件标题
   * @param {string} config.description 插件描述
   * @param {string} config.version 插件版本
   * @param {string} config.author 作者
   * @param {string} [config.website] 网站
   * @param {Object} [config.permissions] 权限配置
   * @param {number} [config.priority] 优先级
   * @param {string[]} [config.events] 订阅的事件列表
   */
  constructor(config) {
    this.metadata = {
      uuid: config.uuid,
      title: config.title,
      description: config.description,
      version: config.version,
      author: config.author,
      website: config.website,
      permissions: {
        ...DEFAULT_PERMISSIONS,
        ...config.permissions,
      },
      priority: config.priority || 50,
      events: config.events || [],
    };

    this._logPrefix = `[${config.title}]`;
    this._dataDir = process.env.DATA_DIR || './data';
  }

  // ==================== 日志工具 ====================

  /**
   * 输出日志
   * @param {string} message 日志消息
   * @param {...any} args 额外参数
   */
  log(message, ...args) {
    console.log(`${this._logPrefix} ${message}`, ...args);
  }

  /**
   * 输出警告日志
   * @param {string} message 警告消息
   * @param {...any} args 额外参数
   */
  warn(message, ...args) {
    console.warn(`${this._logPrefix} ${message}`, ...args);
  }

  /**
   * 输出错误日志
   * @param {string} message 错误消息
   * @param {...any} args 额外参数
   */
  error(message, ...args) {
    console.error(`${this._logPrefix} ${message}`, ...args);
  }

  // ==================== 生命周期钩子 ====================

  /**
   * 插件加载时调用（子类重写）
   */
  async onPluginLoad() {
    this.log('插件已加载');
  }

  /**
   * 插件卸载时调用（子类重写）
   */
  async onPluginUnload() {
    this.log('插件已卸载');
  }

  /**
   * 插件启用时调用（子类重写）
   */
  async onPluginEnable() {
    this.log('插件已启用');
  }

  /**
   * 插件禁用时调用（子类重写）
   */
  async onPluginDisable() {
    this.log('插件已禁用');
  }

  // ==================== 事件处理 ====================

  /**
   * 事件处理器映射（子类重写）
   *
   * 键格式: `{pluginId}::{timing}:{action}{entity}`
   * 例如: 'chat::before:createChannel', 'notes::after:createNote'
   */
  handlers = {};

  /**
   * 快速订阅 before 事件
   * @param {string} pluginId 插件 ID
   * @param {string} action 操作类型 (create/read/update/delete)
   * @param {string} entity 实体名称
   * @param {Function} handler 处理函数
   * @returns {string} 事件名称
   */
  onBefore(pluginId, action, entity, handler) {
    const eventName = `${pluginId}::before:${action}${entity}`;
    this.handlers[eventName] = handler;
    return eventName;
  }

  /**
   * 快速订阅 after 事件
   * @param {string} pluginId 插件 ID
   * @param {string} action 操作类型 (create/read/update/delete)
   * @param {string} entity 实体名称
   * @param {Function} handler 处理函数
   * @returns {string} 事件名称
   */
  onAfter(pluginId, action, entity, handler) {
    const eventName = `${pluginId}::after:${action}${entity}`;
    this.handlers[eventName] = handler;
    return eventName;
  }

  /**
   * 批量订阅插件的所有 before 事件
   * @param {string} pluginId 插件 ID
   * @param {Function} handler 统一处理函数
   */
  subscribeAllBefore(pluginId, handler) {
    const actions = ['create', 'read', 'update', 'delete'];
    for (const action of actions) {
      this.onBefore(pluginId, action, 'Item', handler);
    }
  }

  /**
   * 批量订阅插件的所有 after 事件
   * @param {string} pluginId 插件 ID
   * @param {Function} handler 统一处理函数
   */
  subscribeAllAfter(pluginId, handler) {
    const actions = ['create', 'read', 'update', 'delete'];
    for (const action of actions) {
      this.onAfter(pluginId, action, 'Item', handler);
    }
  }

  // ==================== 工具方法 ====================

  /**
   * 获取插件数据目录
   * @param {...string} paths 子路径
   * @returns {string} 完整路径
   */
  getDataPath(...paths) {
    const path = require('path');
    return path.join(this._dataDir, 'plugins', this.metadata.uuid, ...paths);
  }

  /**
   * 确保目录存在
   * @param {string} dirPath 目录路径
   */
  ensureDir(dirPath) {
    const fs = require('fs');
    if (!fs.existsSync(dirPath)) {
      fs.mkdirSync(dirPath, { recursive: true });
    }
  }

  /**
   * 读取 JSON 文件
   * @param {string} filePath 文件路径
   * @param {*} defaultValue 默认值
   * @returns {*} 文件内容
   */
  readJson(filePath, defaultValue = null) {
    const fs = require('fs');
    try {
      if (fs.existsSync(filePath)) {
        const content = fs.readFileSync(filePath, 'utf8');
        return JSON.parse(content);
      }
    } catch (e) {
      this.error(`读取文件失败: ${filePath}`, e);
    }
    return defaultValue;
  }

  /**
   * 写入 JSON 文件
   * @param {string} filePath 文件路径
   * @param {*} data 数据
   * @param {boolean} pretty 是否美化输出
   */
  writeJson(filePath, data, pretty = true) {
    const fs = require('fs');
    const dir = require('path').dirname(filePath);
    this.ensureDir(dir);
    const content = pretty ? JSON.stringify(data, null, 2) : JSON.stringify(data);
    fs.writeFileSync(filePath, content, 'utf8');
  }

  /**
   * 追加日志到文件
   * @param {string} filePath 日志文件路径
   * @param {string} message 日志消息
   */
  appendLog(filePath, message) {
    const fs = require('fs');
    const dir = require('path').dirname(filePath);
    this.ensureDir(dir);
    const timestamp = new Date().toISOString();
    const logLine = `[${timestamp}] ${message}\n`;
    fs.appendFileSync(filePath, logLine, 'utf8');
  }

  // ==================== 导出 ====================

  /**
   * 导出插件模块
   * @returns {Object} 插件模块对象
   */
  export() {
    return {
      metadata: this.metadata,
      onLoad: () => this.onPluginLoad(),
      onUnload: () => this.onPluginUnload(),
      onEnable: () => this.onPluginEnable(),
      onDisable: () => this.onPluginDisable(),
      handlers: this.handlers,
    };
  }
}

module.exports = { BasePlugin };
