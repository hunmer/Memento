/**
 * 数据同步日志记录器插件 (使用 BasePlugin 重构版)
 *
 * 监听所有插件数据变更并记录到日志
 *
 * 使用方式: 服务器加载插件时会传入 BasePlugin 类
 */

module.exports = function createPlugin(BasePlugin) {
  const path = require('path');

  class DataSyncLoggerPlugin extends BasePlugin {
    constructor() {
      super({
        uuid: 'data-sync-logger',
        title: '数据同步日志记录器',
        description: '监听所有插件数据变更并记录日志，用于调试和审计。',
        version: '2.0.0',
        author: 'Memento',
        website: 'https://github.com/memento/data-sync-logger',
        permissions: {
          dataAccess: [],
          operations: ['read'],
          networkAccess: false,
        },
        priority: 100,
        events: [
          'chat::*',
          'notes::*',
          'todo::*',
          'diary::*',
          'activity::*',
          'bill::*',
        ],
      });

      this._logFilePath = null;
    }

    async onPluginLoad() {
      // 设置日志文件路径
      this._logFilePath = this.getDataPath('sync.log');
      this.ensureDir(path.dirname(this._logFilePath));
      this.writeLog('插件已加载 (v2.0.0 - BasePlugin)');
    }

    async onPluginUnload() {
      this.writeLog('插件已卸载');
    }

    async onPluginEnable() {
      this.writeLog('插件已启用，开始监听数据变更');
    }

    async onPluginDisable() {
      this.writeLog('插件已禁用');
    }

    /**
     * 写入日志
     * @param {string} message 日志消息
     */
    writeLog(message) {
      this.log(message);
      if (this._logFilePath) {
        this.appendLog(this._logFilePath, message);
      }
    }

    /**
     * 创建日志记录处理器
     * @param {string} pluginId 插件 ID
     * @param {string} action 操作
     * @param {string} entity 实体
     * @returns {Object} { before, after } 处理器
     */
    createLogger(pluginId, action, entity) {
      return {
        before: async (ctx) => {
          this.writeLog(`[BEFORE] ${pluginId}::${action}${entity} - userId: ${ctx.userId}`);
          return ctx;
        },
        after: async (ctx) => {
          this.writeLog(`[AFTER] ${pluginId}::${action}${entity} - success: ${ctx.success}`);
        },
      };
    }

    // 定义事件处理器
    handlers = {};
  }

  // 初始化插件并注册处理器
  const plugin = new DataSyncLoggerPlugin();

  // 为各插件注册日志处理器
  const plugins = ['chat', 'notes', 'todo', 'diary', 'activity', 'bill'];
  const entities = {
    chat: 'Channel',
    notes: 'Note',
    todo: 'Task',
    diary: 'Entry',
    activity: 'Activity',
    bill: 'Bill',
  };
  const actions = ['create', 'update', 'delete'];

  for (const pluginId of plugins) {
    const entity = entities[pluginId];
    for (const action of actions) {
      const loggers = plugin.createLogger(pluginId, action, entity);
      plugin.onBefore(pluginId, action, entity, loggers.before);
      plugin.onAfter(pluginId, action, entity, loggers.after);
    }
  }

  return plugin.export();
};
