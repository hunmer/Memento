/**
 * 数据同步日志记录器插件
 *
 * 监听所有插件数据变更并记录到日志
 */

const fs = require('fs');
const path = require('path');

// 日志文件路径
let logFilePath = null;

/**
 * 写入日志
 */
function writeLog(message) {
  const timestamp = new Date().toISOString();
  const logLine = `[${timestamp}] ${message}\n`;
  if (logFilePath) {
    fs.appendFileSync(logFilePath, logLine, 'utf8');
  }
  console.log(`[DataSyncLogger] ${message}`);
}

/**
 * 插件元信息
 */
module.exports.metadata = {
  uuid: 'data-sync-logger',
  title: '数据同步日志记录器',
  author: 'Memento',
  description: '监听所有插件数据变更并记录日志，用于调试和审计。',
  version: '1.0.0',
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
};

/**
 * 插件加载时初始化
 */
module.exports.onLoad = async function() {
  // 设置日志文件路径
  const dataDir = process.env.DATA_DIR || './data';
  logFilePath = path.join(dataDir, 'plugins', 'data-sync-logger', 'sync.log');

  const logDir = path.dirname(logFilePath);
  if (!fs.existsSync(logDir)) {
    fs.mkdirSync(logDir, { recursive: true });
  }

  writeLog('插件已加载');
};

/**
 * 插件卸载时清理
 */
module.exports.onUnload = async function() {
  writeLog('插件已卸载');
};

/**
 * 插件启用时
 */
module.exports.onEnable = async function() {
  writeLog('插件已启用，开始监听数据变更');
};

/**
 * 插件禁用时
 */
module.exports.onDisable = async function() {
  writeLog('插件已禁用');
};

/**
 * 事件处理器
 */
module.exports.handlers = {
  // Chat 事件
  'chat::before:createChannel': async function(ctx) {
    writeLog(`[BEFORE] chat::createChannel - userId: ${ctx.userId}`);
    return ctx;
  },
  'chat::after:createChannel': async function(ctx) {
    writeLog(`[AFTER] chat::createChannel - success: ${ctx.success}`);
  },

  // Notes 事件
  'notes::before:createNote': async function(ctx) {
    writeLog(`[BEFORE] notes::createNote - userId: ${ctx.userId}`);
    return ctx;
  },
  'notes::after:createNote': async function(ctx) {
    writeLog(`[AFTER] notes::createNote - success: ${ctx.success}`);
  },

  // Todo 事件
  'todo::before:createTask': async function(ctx) {
    writeLog(`[BEFORE] todo::createTask - userId: ${ctx.userId}`);
    return ctx;
  },
  'todo::after:createTask': async function(ctx) {
    writeLog(`[AFTER] todo::createTask - success: ${ctx.success}`);
  },

  // Diary 事件
  'diary::before:createEntry': async function(ctx) {
    writeLog(`[BEFORE] diary::createEntry - userId: ${ctx.userId}`);
    return ctx;
  },
  'diary::after:createEntry': async function(ctx) {
    writeLog(`[AFTER] diary::createEntry - success: ${ctx.success}`);
  },

  // Activity 事件
  'activity::before:createActivity': async function(ctx) {
    writeLog(`[BEFORE] activity::createActivity - userId: ${ctx.userId}`);
    return ctx;
  },
  'activity::after:createActivity': async function(ctx) {
    writeLog(`[AFTER] activity::createActivity - success: ${ctx.success}`);
  },

  // Bill 事件
  'bill::before:createBill': async function(ctx) {
    writeLog(`[BEFORE] bill::createBill - userId: ${ctx.userId}`);
    return ctx;
  },
  'bill::after:createBill': async function(ctx) {
    writeLog(`[AFTER] bill::createBill - success: ${ctx.success}`);
  },
};
