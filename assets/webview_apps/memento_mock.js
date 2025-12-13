/**
 * Memento JavaScript Bridge Mock
 * 用于开发测试的独立模拟环境
 *
 * 基于 lib/plugins/webview/screens/webview_browser_screen.dart 中的
 * _createMementoUserScript 函数创建
 */

(function() {
  'use strict';

  // 1. 注入基础命名空间
  if (typeof window.Memento !== 'undefined') {
    console.warn('[Memento Mock] Memento already exists, skipping initialization');
    return;
  }

  window.Memento = {
    version: '1.0.0',
    plugins: {},
    system: {},
    storage: {},
    _ready: false,
    _readyCallbacks: []
  };

  /**
   * Memento ready 回调机制
   * @param {Function} callback - 回调函数
   */
  window.Memento.ready = function(callback) {
    if (window.Memento._ready) {
      try {
        callback();
      } catch(e) {
        console.error('[Memento Mock] Ready callback error:', e);
      }
    } else {
      window.Memento._readyCallbacks.push(callback);
    }
  };

  // 2. 注入插件代理
  window.Memento.plugins = new Proxy({}, {
    get: function(target, pluginId) {
      if (pluginId === 'ui' || typeof pluginId === 'symbol') {
        return target[pluginId];
      }

      if (!target[pluginId]) {
        target[pluginId] = new Proxy({}, {
          get: function(_, methodName) {
            if (typeof methodName === 'symbol') return undefined;

            return function(params) {
              // 模拟插件调用
              console.log(`[Memento Mock] Plugin call: ${pluginId}.${methodName}`, params);

              // 返回一个 Promise，模拟异步调用
              return Promise.resolve({
                success: true,
                data: {
                  pluginId: pluginId,
                  method: methodName,
                  params: params,
                  timestamp: Date.now()
                }
              });
            };
          }
        });
      }
      return target[pluginId];
    }
  });

  // 3. 注入系统 API 代理
  var systemMethods = [
    'getCurrentTime',
    'getDeviceInfo',
    'getAppInfo',
    'formatDate',
    'getTimestamp',
    'getCustomDate'
  ];

  systemMethods.forEach(function(methodName) {
    window.Memento.system[methodName] = function(params) {
      console.log(`[Memento Mock] System call: ${methodName}`, params);

      // 模拟不同系统 API 的返回值
      switch (methodName) {
        case 'getCurrentTime':
          return Promise.resolve(new Date().toISOString());
        case 'getDeviceInfo':
          return Promise.resolve({
            platform: navigator.platform,
            userAgent: navigator.userAgent,
            language: navigator.language,
            screenResolution: `${screen.width}x${screen.height}`,
            viewportSize: `${window.innerWidth}x${window.innerHeight}`,
            timezone: Intl.DateTimeFormat().resolvedOptions().timeZone
          });
        case 'getAppInfo':
          return Promise.resolve({
            version: '1.0.0',
            buildNumber: '100',
            bundleId: 'com.example.memento'
          });
        case 'formatDate':
          const date = params?.date ? new Date(params.date) : new Date();
          const format = params?.format || 'YYYY-MM-DD HH:mm:ss';
          const year = date.getFullYear();
          const month = String(date.getMonth() + 1).padStart(2, '0');
          const day = String(date.getDate()).padStart(2, '0');
          const hours = String(date.getHours()).padStart(2, '0');
          const minutes = String(date.getMinutes()).padStart(2, '0');
          const seconds = String(date.getSeconds()).padStart(2, '0');
          return Promise.resolve(format
            .replace('YYYY', year)
            .replace('MM', month)
            .replace('DD', day)
            .replace('HH', hours)
            .replace('mm', minutes)
            .replace('ss', seconds));
        case 'getTimestamp':
          return Promise.resolve(Date.now());
        case 'getCustomDate':
          const days = params?.days || 0;
          const dateObj = new Date();
          dateObj.setDate(dateObj.getDate() + days);
          return Promise.resolve(dateObj.toISOString());
        default:
          return Promise.resolve({ method: methodName, params: params });
      }
    };
  });

  // 4. 注入 UI API 代理
  var uiApi = {
    toast: function(message, options) {
      console.log('[Memento Mock] UI Toast:', message, options);

      // 模拟 toast 显示
      const toast = document.createElement('div');
      toast.style.cssText = `
        position: fixed;
        top: 20px;
        left: 50%;
        transform: translateX(-50%);
        background: rgba(0, 0, 0, 0.8);
        color: white;
        padding: 12px 24px;
        border-radius: 8px;
        font-size: 14px;
        z-index: 999999;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
        max-width: 80%;
        text-align: center;
      `;
      toast.textContent = message;

      document.body.appendChild(toast);

      // 自动隐藏
      setTimeout(() => {
        toast.style.transition = 'opacity 0.3s';
        toast.style.opacity = '0';
        setTimeout(() => {
          if (toast.parentNode) {
            toast.parentNode.removeChild(toast);
          }
        }, 300);
      }, options?.duration || 3000);

      return Promise.resolve({ success: true });
    },
    alert: function(message, options) {
      console.log('[Memento Mock] UI Alert:', message, options);
      // 使用浏览器的 alert 作为简单实现
      alert(message);
      return Promise.resolve({ success: true });
    },
    dialog: function(options) {
      console.log('[Memento Mock] UI Dialog:', options);

      // 创建一个简单的模态对话框
      const dialog = document.createElement('div');
      dialog.style.cssText = `
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background: rgba(0, 0, 0, 0.5);
        display: flex;
        align-items: center;
        justify-content: center;
        z-index: 999999;
      `;

      const content = document.createElement('div');
      content.style.cssText = `
        background: white;
        padding: 24px;
        border-radius: 12px;
        max-width: 400px;
        width: 90%;
        box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
      `;

      content.innerHTML = `
        <h3 style="margin: 0 0 12px 0; font-size: 18px; font-weight: 600;">
          ${options?.title || 'Dialog'}
        </h3>
        <p style="margin: 0 0 20px 0; font-size: 14px; color: #666; line-height: 1.5;">
          ${options?.message || ''}
        </p>
        <div style="display: flex; gap: 12px; justify-content: flex-end;">
          ${options?.showCancel ? `
            <button id="cancel-btn" style="
              padding: 8px 16px;
              border: 1px solid #ddd;
              background: white;
              border-radius: 6px;
              cursor: pointer;
              font-size: 14px;
            ">Cancel</button>
          ` : ''}
          <button id="ok-btn" style="
            padding: 8px 16px;
            background: #007AFF;
            color: white;
            border: none;
            border-radius: 6px;
            cursor: pointer;
            font-size: 14px;
          ">OK</button>
        </div>
      `;

      dialog.appendChild(content);
      document.body.appendChild(dialog);

      return new Promise((resolve) => {
        content.querySelector('#ok-btn').onclick = () => {
          document.body.removeChild(dialog);
          resolve({ success: true, action: 'ok' });
        };

        const cancelBtn = content.querySelector('#cancel-btn');
        if (cancelBtn) {
          cancelBtn.onclick = () => {
            document.body.removeChild(dialog);
            resolve({ success: false, action: 'cancel' });
          };
        }

        // 点击背景关闭
        dialog.onclick = (e) => {
          if (e.target === dialog) {
            document.body.removeChild(dialog);
            resolve({ success: false, action: 'dismiss' });
          }
        };
      });
    }
  };

  window.Memento.plugins.ui = uiApi;
  window.Memento.ui = uiApi;

  // 5. 注入 Storage API 代理（使用 localStorage 实现持久化存储）
  var STORAGE_PREFIX = 'MementoMock_';
  var storageApi = {
    read: function(key) {
      console.log(`[Memento Mock] Storage read: ${key}`);

      try {
        const prefixedKey = STORAGE_PREFIX + key;
        const value = localStorage.getItem(prefixedKey);

        if (value === null) {
          return Promise.resolve(null);
        }

        // 尝试解析 JSON
        try {
          const parsed = JSON.parse(value);
          return Promise.resolve(parsed);
        } catch (e) {
          return Promise.resolve(value);
        }
      } catch (e) {
        console.error('[Memento Mock] Storage read error:', e);
        return Promise.resolve(null);
      }
    },
    write: function(key, value) {
      console.log(`[Memento Mock] Storage write: ${key}`, value);

      // 转换为 JSON 字符串存储
      try {
        const prefixedKey = STORAGE_PREFIX + key;
        const jsonValue = JSON.stringify(value);
        localStorage.setItem(prefixedKey, jsonValue);
        return Promise.resolve(true);
      } catch (e) {
        console.error('[Memento Mock] Storage write error:', e);
        return Promise.resolve(false);
      }
    },
    delete: function(key) {
      console.log(`[Memento Mock] Storage delete: ${key}`);

      try {
        const prefixedKey = STORAGE_PREFIX + key;
        localStorage.removeItem(prefixedKey);
        return Promise.resolve(true);
      } catch (e) {
        console.error('[Memento Mock] Storage delete error:', e);
        return Promise.resolve(false);
      }
    },
    clear: function() {
      console.log('[Memento Mock] Storage clear');

      try {
        // 只清除 Memento Mock 相关的键
        var keys = Object.keys(localStorage);
        keys.forEach(function(key) {
          if (key.startsWith(STORAGE_PREFIX)) {
            localStorage.removeItem(key);
          }
        });
        return Promise.resolve(true);
      } catch (e) {
        console.error('[Memento Mock] Storage clear error:', e);
        return Promise.resolve(false);
      }
    },
    keys: function() {
      try {
        var keys = Object.keys(localStorage);
        var mementoKeys = [];
        keys.forEach(function(key) {
          if (key.startsWith(STORAGE_PREFIX)) {
            mementoKeys.push(key.substring(STORAGE_PREFIX.length));
          }
        });
        return Promise.resolve(mementoKeys);
      } catch (e) {
        console.error('[Memento Mock] Storage keys error:', e);
        return Promise.resolve([]);
      }
    }
  };

  window.Memento.storage = storageApi;

  // 6. 添加辅助方法
  window.Memento.utils = {
    // 日志记录
    log: function(...args) {
      console.log('[Memento]', ...args);
    },
    // 错误记录
    error: function(...args) {
      console.error('[Memento Error]', ...args);
    },
    // 警告记录
    warn: function(...args) {
      console.warn('[Memento Warning]', ...args);
    },
    // 获取存储状态
    getStorageState: function() {
      try {
        var keys = Object.keys(localStorage);
        var state = {};
        keys.forEach(function(key) {
          if (key.startsWith(STORAGE_PREFIX)) {
            var value = localStorage.getItem(key);
            try {
              state[key.substring(STORAGE_PREFIX.length)] = JSON.parse(value);
            } catch (e) {
              state[key.substring(STORAGE_PREFIX.length)] = value;
            }
          }
        });
        return state;
      } catch (e) {
        console.error('[Memento Mock] getStorageState error:', e);
        return {};
      }
    },
    // 重置存储
    resetStorage: function() {
      return storageApi.clear().then(function() {
        console.log('[Memento Mock] Storage reset');
        return true;
      });
    }
  };

  // 标记准备完成并触发回调
  window.Memento._ready = true;
  if (window.Memento._readyCallbacks) {
    window.Memento._readyCallbacks.forEach(function(cb) {
      try {
        cb();
      } catch(e) {
        console.error('[Memento Mock] Ready callback error:', e);
      }
    });
    window.Memento._readyCallbacks = [];
  }

  // 打印初始化完成信息
  console.log('%c[Memento] JS Bridge Mock loaded successfully', 'color: #4CAF50; font-weight: bold; font-size: 12px;');
  console.log('%cVersion: ' + window.Memento.version, 'color: #666;');
  console.log('%cAvailable APIs:', 'color: #666;');
  console.log('  - Memento.plugins.<pluginName>.<method>()');
  console.log('  - Memento.system.<methodName>()');
  console.log('  - Memento.ui.toast(), Memento.ui.alert(), Memento.ui.dialog()');
  console.log('  - Memento.storage.read(), write(), delete()');
  console.log('  - Memento.utils for debugging utilities');

  // 导出到全局，便于调试
  if (typeof module !== 'undefined' && module.exports) {
    module.exports = window.Memento;
  }
})();
