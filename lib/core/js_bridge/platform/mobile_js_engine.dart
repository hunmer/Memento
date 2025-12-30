// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter_js/flutter_js.dart';
import 'js_engine_interface.dart';
import '../js_tool_registry.dart';
import 'package:Memento/plugins/agent_chat/models/tool_config.dart';
import 'package:Memento/plugins/agent_chat/services/tool_config_manager.dart';
import 'package:Memento/plugins/agent_chat/services/tool_service.dart';
import 'package:Memento/core/app_initializer.dart'; // 用于访问 globalStorage

class MobileJSEngine implements JSEngine {
  late JavascriptRuntime _runtime;
  bool _initialized = false;
  final Map<String, Function> _registeredFunctions = {};

  // UI 回调函数（由外部注入，用于显示 Toast/Alert/Dialog）
  Function(String message, String duration, String gravity)? _onToast;
  Future<bool> Function(
    String message, {
    String? title,
    String? confirmText,
    String? cancelText,
    bool showCancel,
  })?
  _onAlert;
  Future<dynamic> Function(
    String? title,
    String? content,
    List<Map<String, dynamic>> actions,
  )?
  _onDialog;

  // 插件分析回调函数（由 OpenAI 插件注入）
  Future<String> Function(String methodName, Map<String, dynamic> params)?
  _onPluginAnalysis;

  // Location 回调函数（用于获取位置）
  Future<Map<String, dynamic>?> Function(String mode)? _onLocation;

  @override
  bool get isSupported => true; // Android/iOS/Desktop 都支持

  /// 设置 Toast 回调
  void setToastHandler(Function(String, String, String) handler) {
    _onToast = handler;
  }

  /// 设置 Alert 回调
  void setAlertHandler(
    Future<bool> Function(
      String, {
      String? title,
      String? confirmText,
      String? cancelText,
      bool showCancel,
    })
    handler,
  ) {
    _onAlert = handler;
  }

  /// 设置 Dialog 回调
  void setDialogHandler(
    Future<dynamic> Function(String?, String?, List<Map<String, dynamic>>)
    handler,
  ) {
    _onDialog = handler;
  }

  /// 设置插件分析回调
  void setPluginAnalysisHandler(
    Future<String> Function(String, Map<String, dynamic>) handler,
  ) {
    _onPluginAnalysis = handler;
  }

  /// 设置 Location 回调
  void setLocationHandler(
    Future<Map<String, dynamic>?> Function(String) handler,
  ) {
    _onLocation = handler;
  }

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    _runtime = getJavascriptRuntime();
    _initialized = true;

    // 注入全局辅助函数和结果存储（直接执行，不通过 evaluate）
    _runtime.evaluate('''
      // 初始化全局结果存储
      if (!globalThis.__EVAL_RESULTS__) {
        globalThis.__EVAL_RESULTS__ = {};
      }

      // 初始化待处理调用存储（用于不依赖 setTimeout 的 Promise）
      if (!globalThis.__PENDING_CALLS__) {
        globalThis.__PENDING_CALLS__ = {};
      }

      if (!globalThis.__DART_RESULTS__) {
        globalThis.__DART_RESULTS__ = {};
      }

      // 定义 console 对象
      var console = {
        log: function() {
          var args = Array.prototype.slice.call(arguments);
          var message = args.map(function(arg) {
            if (typeof arg === 'object') {
              return JSON.stringify(arg);
            }
            return String(arg);
          }).join(' ');
          // 包装成 JSON 对象以避免 FormatException
          sendMessage('_dartLog', JSON.stringify({ message: message }));
          return undefined;  // 明确返回 undefined
        },
        error: function() {
          var args = Array.prototype.slice.call(arguments);
          var message = args.map(function(arg) {
            if (typeof arg === 'object') {
              return JSON.stringify(arg);
            }
            return String(arg);
          }).join(' ');
          // 包装成 JSON 对象以避免 FormatException
          sendMessage('_dartError', JSON.stringify({ message: message }));
          return undefined;  // 明确返回 undefined
        }
      };

      // 定义 flutter 对象，提供原生 UI 交互 API
      var flutter = {
        // Toast 提示
        toast: function(message, options) {
          var callId = Date.now() + '_' + Math.floor(Math.random() * 1000000);
          var resultKey = '_flutterToast_callback_' + callId;

          var config = {
            message: String(message),
            duration: (options && options.duration) || 'short',
            gravity: (options && options.gravity) || 'bottom'
          };

          sendMessage('_flutterToast', JSON.stringify({ callId: callId, config: config }));

          // Toast 不需要返回值，但为了一致性返回 Promise
          return Promise.resolve();
        },

        // Alert 对话框
        alert: function(message, options) {
          var callId = Date.now() + '_' + Math.floor(Math.random() * 1000000);
          var resultKey = '_flutterAlert_callback_' + callId;

          var config = {
            message: String(message),
            title: (options && options.title) || null,
            confirmText: (options && options.confirmText) || null,
            cancelText: (options && options.cancelText) || null,
            showCancel: (options && options.showCancel) || false
          };

          sendMessage('_flutterAlert', JSON.stringify({ callId: callId, config: config }));

          // 标记此 Promise 正在等待
          if (!globalThis.__PENDING_CALLS__) {
            globalThis.__PENDING_CALLS__ = {};
          }
          globalThis.__PENDING_CALLS__[resultKey] = {
            resolve: null,
            reject: null,
            timestamp: Date.now()
          };

          return new Promise(function(resolve, reject) {
            globalThis.__PENDING_CALLS__[resultKey].resolve = resolve;
            globalThis.__PENDING_CALLS__[resultKey].reject = reject;
          });
        },

        // Dialog 自定义对话框
        dialog: function(options) {
          var callId = Date.now() + '_' + Math.floor(Math.random() * 1000000);
          var resultKey = '_flutterDialog_callback_' + callId;

          var config = {
            title: (options && options.title) || null,
            content: (options && options.content) || null,
            actions: (options && options.actions) || []
          };

          sendMessage('_flutterDialog', JSON.stringify({ callId: callId, config: config }));

          // 标记此 Promise 正在等待
          if (!globalThis.__PENDING_CALLS__) {
            globalThis.__PENDING_CALLS__ = {};
          }
          globalThis.__PENDING_CALLS__[resultKey] = {
            resolve: null,
            reject: null,
            timestamp: Date.now()
          };

          return new Promise(function(resolve, reject) {
            globalThis.__PENDING_CALLS__[resultKey].resolve = resolve;
            globalThis.__PENDING_CALLS__[resultKey].reject = reject;
          });
        },

        // Location 获取位置
        getLocation: function(mode) {
          var callId = Date.now() + '_' + Math.floor(Math.random() * 1000000);
          var resultKey = '_flutterLocation_callback_' + callId;

          var config = {
            mode: mode || 'manual'  // 默认为 manual 模式
          };

          sendMessage('_flutterLocation', JSON.stringify({ callId: callId, config: config }));

          // 标记此 Promise 正在等待
          if (!globalThis.__PENDING_CALLS__) {
            globalThis.__PENDING_CALLS__ = {};
          }
          globalThis.__PENDING_CALLS__[resultKey] = {
            resolve: null,
            reject: null,
            timestamp: Date.now()
          };

          return new Promise(function(resolve, reject) {
            globalThis.__PENDING_CALLS__[resultKey].resolve = resolve;
            globalThis.__PENDING_CALLS__[resultKey].reject = reject;
          });
        }
      };

      // 定义 callPluginAnalysis 全局函数（用于工具调用）
      globalThis.callPluginAnalysis = function(methodName, params) {
        var callId = Date.now() + '_' + Math.floor(Math.random() * 1000000);
        var resultKey = '_callPluginAnalysis_callback_' + callId;

        var config = {
          methodName: String(methodName),
          params: params || {}
        };

        sendMessage('_callPluginAnalysis', JSON.stringify({ callId: callId, config: config }));

        // 标记此 Promise 正在等待
        if (!globalThis.__PENDING_CALLS__) {
          globalThis.__PENDING_CALLS__ = {};
        }
        globalThis.__PENDING_CALLS__[resultKey] = {
          resolve: null,
          reject: null,
          timestamp: Date.now()
        };

        return new Promise(function(resolve, reject) {
          globalThis.__PENDING_CALLS__[resultKey].resolve = resolve;
          globalThis.__PENDING_CALLS__[resultKey].reject = reject;
        });
      };
    ''');

    // 设置消息处理器（QuickJS 期望返回 undefined 而不是 null）
    _runtime.onMessage('_dartLog', (dynamic data) {
      try {
        // 从 JSON 对象中提取消息
        final message = data is Map ? data['message'] : data.toString();
        print('[JS] $message');
      } catch (e) {
        print('[JS] (解析失败) $data');
      }
      // 不返回任何值（自动返回 undefined）
    });

    _runtime.onMessage('_dartError', (dynamic data) {
      try {
        // 从 JSON 对象中提取消息
        final message = data is Map ? data['message'] : data.toString();
        print('[JS Error] $message');
      } catch (e) {
        print('[JS Error] (解析失败) $data');
      }
      // 不返回任何值（自动返回 undefined）
    });

    // Toast 处理器
    _runtime.onMessage('_flutterToast', (dynamic data) {
      try {
        final config = data['config'];
        final message = config['message'] as String;
        // duration 可以是字符串 ('short', 'long') 或数字 (毫秒数)
        final durationValue = config['duration'];
        final duration =
            durationValue is String ? durationValue : durationValue.toString();
        final gravity = config['gravity'] as String;

        print(
          '[JS Bridge] Toast: $message (duration: $duration, gravity: $gravity)',
        );

        // 调用 Flutter Toast（需要在 UI 线程执行）
        _showToast(message, duration, gravity);
      } catch (e) {
        print('[JS Bridge] Toast 错误: $e');
      }
    });

    // Alert 处理器
    _runtime.onMessage('_flutterAlert', (dynamic data) {
      try {
        final callId = data['callId'];
        final config = data['config'];
        final message = config['message'] as String;
        final title = config['title'] as String?;
        final confirmText = config['confirmText'] as String?;
        final cancelText = config['cancelText'] as String?;
        final showCancel = config['showCancel'] as bool? ?? false;

        print('[JS Bridge] Alert: $message (showCancel: $showCancel)');

        // 调用 Flutter Alert 对话框
        _showAlert(
          callId,
          message,
          title: title,
          confirmText: confirmText,
          cancelText: cancelText,
          showCancel: showCancel,
        );
      } catch (e) {
        print('[JS Bridge] Alert 错误: $e');
      }
    });

    // Dialog 处理器
    _runtime.onMessage('_flutterDialog', (dynamic data) {
      try {
        final callId = data['callId'];
        final config = data['config'];
        final title = config['title'] as String?;
        final content = config['content'] as String?;
        final actions = (config['actions'] as List<dynamic>?) ?? [];

        print('[JS Bridge] Dialog: $title (${actions.length} actions)');

        // 调用 Flutter Dialog
        _showDialog(
          callId,
          title: title,
          content: content,
          actions: actions.cast<Map<String, dynamic>>(),
        );
      } catch (e) {
        print('[JS Bridge] Dialog 错误: $e');
      }
    });

    // 插件分析处理器
    _runtime.onMessage('_callPluginAnalysis', (dynamic data) {
      try {
        final callId = data['callId'];
        final config = data['config'];
        final methodName = config['methodName'] as String;
        final params = config['params'] as Map<String, dynamic>? ?? {};

        print('[JS Bridge] 调用插件分析: $methodName');

        // 调用插件分析方法
        _callPluginAnalysis(callId, methodName, params);
      } catch (e) {
        print('[JS Bridge] 插件分析错误: $e');
        // 返回错误
        _returnPluginAnalysisResult(data['callId'], null, error: '调用失败: $e');
      }
    });

    // Location 处理器
    _runtime.onMessage('_flutterLocation', (dynamic data) {
      try {
        final callId = data['callId'];
        final config = data['config'];
        final mode = config['mode'] as String? ?? 'manual';

        print('[JS Bridge] Location: mode=$mode');

        // 调用 Flutter Location 选择器
        _showLocation(callId, mode);
      } catch (e) {
        print('[JS Bridge] Location 错误: $e');
      }
    });

    // 扩展 memento 对象，添加工具注册功能
    await _extendMementoWithToolRegistration();
  }

  /// 扩展 memento 对象，添加工具注册和存储功能
  Future<void> _extendMementoWithToolRegistration() async {
    // 1. 创建 memento 对象和 tools 命名空间，同时支持大小写两种命名
    await evaluateDirect('''
      (function() {
        // 创建小写命名空间
        globalThis.memento = globalThis.memento || {};
        globalThis.memento.tools = globalThis.memento.tools || {};

        // 确保大写 Memento 存在
        globalThis.Memento = globalThis.Memento || { version: '1.0.0', plugins: {}, system: {} };

        // 将 tools 命名空间同步到大写 Memento（共享同一个对象）
        globalThis.Memento.tools = globalThis.memento.tools;

        // 兼容浏览器环境
        if (typeof window !== 'undefined') {
          window.memento = globalThis.memento;
          window.Memento = globalThis.Memento;
        }
      })();
    ''');

    // 2. 添加 registerTool 方法
    await evaluateDirect('''
      globalThis.memento.registerTool = function(config) {
        if (config && config.id) {
          globalThis.memento.tools[config.id] = function(params) {
            try {
              var toolCode = config.code || '';
              var toolParams = params || {};
              var executionId = Date.now() + '_' + Math.floor(Math.random() * 1000000);
              globalThis.__EVAL_RESULTS__ = globalThis.__EVAL_RESULTS__ || {};
              globalThis.__EVAL_RESULTS__[executionId] = null;
              var wrappedCode = '(async function() {' +
                'var params = arguments[0];' +
                'var setResult = arguments[1];' +
                'try {' +
                  'var __result__ = await (async function() {' + toolCode + '})();' +
                  'setResult(__result__);' +
                  'return __result__;' +
                '} catch (error) { setResult({ error: error.toString() }); }' +
                '})';
              var executor = eval(wrappedCode);
              return executor(toolParams, function(result) {
                globalThis.__EVAL_RESULTS__[executionId] = result;
              }).then(function() {
                return globalThis.__EVAL_RESULTS__[executionId];
              });
            } catch (e) {
              return Promise.reject(new Error('工具执行失败: ' + e.toString()));
            }
          };
        }
        if (typeof __DART_TOOL_REGISTRY__ !== 'undefined') {
          try {
            __DART_TOOL_REGISTRY__(JSON.stringify(config));
            return { success: true, toolId: config.id, message: '工具已提交注册: ' + config.id };
          } catch (e) {
            return { success: false, error: e.toString(), toolId: config.id };
          }
        } else {
          return { success: false, error: 'Dart 工具注册器未初始化', toolId: config.id };
        }
      };
    ''');

    // 3. 添加 listTools 方法
    await evaluateDirect('''
      globalThis.memento.listTools = function() {
        if (typeof __DART_GET_TOOLS__ !== 'undefined') {
          try {
            var toolsJson = __DART_GET_TOOLS__();
            return { success: true, tools: JSON.parse(toolsJson || '[]') };
          } catch (e) {
            return { success: false, error: e.toString(), tools: [] };
          }
        }
        return { success: true, tools: [] };
      };
    ''');

    // 4. 添加 storage 命名空间（内存存储 + 文件存储能力）
    await evaluateDirect('''
      globalThis.memento.storage = {
        _data: {},
        read: function(key) { return this._data[key] || null; },
        write: function(key, value) { this._data[key] = value; return { success: true, key: key }; },
        delete: function(key) { delete this._data[key]; return { success: true, key: key }; },
        exists: function(key) { return key in this._data; },
        keys: function() { return Object.keys(this._data); },
        clear: function() { this._data = {}; return { success: true }; },

        // 卡片数据文件读写（基于 cardId）
        readCardData: function(cardId) {
          console.log('[readCardData] 开始读取: ' + cardId);
          if (typeof __DART_STORAGE_READ_CARD_DATA__ !== 'undefined') {
            return __DART_STORAGE_READ_CARD_DATA__(cardId).then(function(result) {
              console.log('[readCardData] Dart 返回类型: ' + typeof result);
              console.log('[readCardData] Dart 返回值: ' + (typeof result === 'string' ? result.substring(0, 100) : JSON.stringify(result)));
              // Dart 返回的是 JSON 字符串，需要解析
              if (result === 'null' || result === null || result === undefined) {
                console.log('[readCardData] 返回 null');
                return null;
              }
              if (typeof result === 'string') {
                try {
                  var parsed = JSON.parse(result);
                  console.log('[readCardData] 解析成功，类型: ' + typeof parsed);
                  return parsed;
                } catch (e) {
                  console.error('[readCardData] JSON 解析失败:', e);
                  return null;
                }
              }
              console.log('[readCardData] 直接返回对象');
              return result;
            });
          }
          console.log('[readCardData] Dart 函数未定义');
          return Promise.resolve(null);
        },
        writeCardData: function(cardId, data) {
          if (typeof __DART_STORAGE_WRITE_CARD_DATA__ !== 'undefined') {
            return __DART_STORAGE_WRITE_CARD_DATA__(JSON.stringify({ cardId: cardId, data: data })).then(function(result) {
              if (typeof result === 'string') {
                try {
                  return JSON.parse(result);
                } catch (e) {
                  return { success: false, error: 'JSON parse error' };
                }
              }
              return result;
            });
          }
          return Promise.resolve({ success: false, error: 'Storage not initialized' });
        }
      };
    ''');

    // 5. 同步别名到大写 Memento 命名空间
    await evaluateDirect('''
      (function() {
        // 同步 registerTool、listTools、storage 到大写 Memento
        if (globalThis.Memento) {
          globalThis.Memento.registerTool = globalThis.memento.registerTool;
          globalThis.Memento.listTools = globalThis.memento.listTools;
          globalThis.Memento.storage = globalThis.memento.storage;
        }
      })();
    ''');

    // 注册 Dart 回调函数，供 JS 调用
    await _registerDartCallbacks();
  }

  /// 注册 Dart 回调函数，供 JS 调用
  Future<void> _registerDartCallbacks() async {
    // 注册工具的 Dart 回调
    await registerFunction('__DART_TOOL_REGISTRY__', (String configJson) async {
      try {
        final config = jsonDecode(configJson);
        final tool = JSToolConfig.fromJson(config);
        JSToolRegistry().registerTool(tool);

        // 确保 ToolConfigManager 已初始化
        if (!ToolConfigManager.instance.isInitialized) {
          print('[ToolRegistry] ToolConfigManager 未初始化，等待初始化...');
          await ToolConfigManager.instance.initialize();
          print('[ToolRegistry] ✓ ToolConfigManager 初始化完成');
        }

        // 同时在 ToolConfigManager 中添加该工具，使用 'js_tools' 作为插件ID
        final jsToolConfig = ToolConfig(
          title: tool.name,
          description: tool.description,
          parameters: tool.parameters,
          examples: tool.examples,
          returns: ToolReturns(
            type: 'object',
            description: 'JS工具执行结果',
          ),
          enabled: true,
        );

        // 使用 try-catch 避免初始化失败影响工具注册
        try {
          await ToolConfigManager.instance.addTool(
            'js_tools',
            tool.id,
            jsToolConfig,
          );
          print('✓ JS工具已添加到工具管理页面: ${tool.id} (${tool.parameters.length}个参数, ${tool.examples.length}个示例)');

          // 刷新 ToolService 缓存，确保工具列表保持最新
          await ToolService.refreshCache();
        } catch (e) {
          print('❌ 添加JS工具到ToolConfigManager失败: $e');
        }

        return 'true';
      } catch (e) {
        print('❌ 注册工具失败: $e');
        return 'false';
      }
    });

    // 获取工具列表的 Dart 回调
    await registerFunction('__DART_GET_TOOLS__', () {
      final tools = JSToolRegistry().getAllTools();
      return jsonEncode(tools.map((t) => t.toJson()).toList());
    });

    // 读取卡片数据文件的 Dart 回调
    await registerFunction('__DART_STORAGE_READ_CARD_DATA__', (String cardId) async {
      try {
        // 卡片数据存储路径：webview/{cardId}/data.json
        final path = 'webview/$cardId/data.json';
        print('[Storage] 读取卡片数据: $path');

        final data = await globalStorage.read(path);
        if (data != null) {
          print('[Storage] ✓ 卡片数据读取成功: $cardId');
          // 直接返回数据对象，registerFunction 会自动 JSON 序列化
          return data;
        }
        print('[Storage] 卡片数据不存在: $cardId');
        return null;
      } catch (e) {
        print('[Storage] ✗ 读取卡片数据失败: $e');
        return {'error': e.toString()};
      }
    });

    // 写入卡片数据文件的 Dart 回调
    await registerFunction('__DART_STORAGE_WRITE_CARD_DATA__', (String paramsJson) async {
      try {
        final params = jsonDecode(paramsJson);
        final cardId = params['cardId'] as String;
        final data = params['data'];

        // 卡片数据存储路径：webview/{cardId}/data.json
        final path = 'webview/$cardId/data.json';
        print('[Storage] 写入卡片数据: $path');

        await globalStorage.write(path, data);
        print('[Storage] ✓ 卡片数据写入成功: $cardId');
        // 直接返回对象，registerFunction 会自动 JSON 序列化
        return {'success': true, 'cardId': cardId};
      } catch (e) {
        print('[Storage] ✗ 写入卡片数据失败: $e');
        return {'success': false, 'error': e.toString()};
      }
    });
  }

  @override
  Future<void> evaluateDirect(String code) async {
    // 直接执行代码，不包装，不等待结果（用于注册函数等操作）
    final result = _runtime.evaluate(code);
    // 检查是否有错误
    if (result.isError) {
      print('[MobileJSEngine] evaluateDirect 错误: ${result.stringResult}');
    }
  }

  @override
  Future<JSResult> evaluate(String code) async {
    try {
      print('[JS Debug] ========== 开始执行代码 ==========');

      // 生成唯一的执行 ID
      final executionId =
          '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';

      // 包装用户代码：提供 setResult 函数并自动捕获返回值
      final wrappedCode = '''
        (async function() {

          // 定义 setResult 函数，用户可以显式设置返回值
          globalThis.setResult = function(value) {
            if (typeof value === 'object' && value !== null) {
              globalThis.__EVAL_RESULTS__['$executionId'] = JSON.stringify(value);
            } else if (value === undefined) {
              globalThis.__EVAL_RESULTS__['$executionId'] = 'undefined';
            } else {
              globalThis.__EVAL_RESULTS__['$executionId'] = String(value);
            }
          };

          try {
            // 执行用户代码并等待完成
            var result = await (async function() {
              $code
            })();

            // 如果用户没有调用 setResult，自动设置结果
            if (!globalThis.__EVAL_RESULTS__['$executionId']) {
              globalThis.setResult(result);
            }
          } catch (error) {
            console.error('[Wrapper] 执行错误:', error);
            // 保存错误信息
            globalThis.__EVAL_RESULTS__['$executionId'] = 'Error: ' + error.toString();
          } finally {
            // 清理 setResult 函数
            delete globalThis.setResult;
          }
        })();
      ''';

      // 执行包装后的代码
      await _runtime.evaluateAsync(wrappedCode);
      // 初始处理：密集执行微任务并处理待处理调用
      for (int i = 0; i < 50; i++) {
        // 处理待处理的 Promise 调用
        _runtime.evaluate('''
          (function() {
            var pendingKeys = Object.keys(globalThis.__PENDING_CALLS__ || {});
            var resultKeys = Object.keys(globalThis.__DART_RESULTS__ || {});

            for (var i = 0; i < pendingKeys.length; i++) {
              var key = pendingKeys[i];
              var pending = globalThis.__PENDING_CALLS__[key];

              if (key in globalThis.__DART_RESULTS__) {
                var resultJson = globalThis.__DART_RESULTS__[key];
                delete globalThis.__DART_RESULTS__[key];
                delete globalThis.__PENDING_CALLS__[key];

                try {
                  var parsed = JSON.parse(resultJson);
                  if (parsed && parsed.error) {
                    pending.reject(new Error(parsed.error));
                  } else {
                    pending.resolve(parsed);
                  }
                } catch (e) {
                  pending.resolve(resultJson);
                }
              }
            }
          })();
        ''');

        _runtime.executePendingJob();
        await Future.delayed(Duration(milliseconds: 10));
      }

      // 轮询结果（最多等待 5 秒）
      String? resultStr;
      int retryCount = 0;
      const maxRetries = 100; // 100 * 50ms = 5 秒

      while (retryCount < maxRetries) {
        // 1. 处理待处理的 Promise 调用（不依赖 setTimeout）
        _runtime.evaluate('''
          (function() {
            var keys = Object.keys(globalThis.__PENDING_CALLS__ || {});

            for (var i = 0; i < keys.length; i++) {
              var key = keys[i];
              var pending = globalThis.__PENDING_CALLS__[key];

              // 检查 Dart 是否已返回结果 (使用 in 操作符避免 falsy 值问题)
              if (key in globalThis.__DART_RESULTS__) {
                var resultJson = globalThis.__DART_RESULTS__[key];
                delete globalThis.__DART_RESULTS__[key];
                delete globalThis.__PENDING_CALLS__[key];

                try {
                  var parsed = JSON.parse(resultJson);
                  if (parsed && parsed.error) {
                    pending.reject(new Error(parsed.error));
                  } else {
                    pending.resolve(parsed);
                  }
                } catch (e) {
                  pending.resolve(resultJson);
                }
              }
            }
          })();
        ''');

        // 2. 持续处理微任务队列
        for (int i = 0; i < 20; i++) {
          _runtime.executePendingJob();
        }

        // 3. 给 Dart 事件循环时间
        await Future.delayed(Duration(milliseconds: 50));

        // 4. 检查用户代码的结果是否已准备好
        try {
          // 先检查键是否存在
          final existsCode = "'$executionId' in globalThis.__EVAL_RESULTS__";
          final existsResult = _runtime.evaluate(existsCode);
          final exists = existsResult.stringResult;

          if (exists == 'true') {
            // 键存在，读取值
            final checkCode = "globalThis.__EVAL_RESULTS__['$executionId']";
            final checkResult = _runtime.evaluate(checkCode);
            resultStr = checkResult.stringResult;
            print('[JS Debug] 第 ${retryCount + 1} 次轮询，获取到结果: ' + resultStr);
            break;
          }

          // 每 10 次输出调试信息
          if (retryCount % 10 == 0 && retryCount > 0) {
            print('[JS Debug] 第 $retryCount 次轮询，结果尚未准备好...');
          }
        } catch (e) {
          // 结果还未准备好，继续等待
          if (retryCount % 20 == 0 && retryCount > 0) {
            print('[JS Debug] 轮询异常: $e');
          }
        }

        retryCount++;
      }

      // 清理结果存储
      try {
        _runtime.evaluate(
          "delete globalThis.__EVAL_RESULTS__['$executionId'];",
        );
      } catch (e) {
        // 忽略清理错误
      }
      // 处理超时
      if (resultStr == null) {
        return JSResult.error('执行超时：代码未在 5 秒内返回结果');
      }

      // 检查错误
      if (resultStr.startsWith('Error:')) {
        return JSResult.error(resultStr);
      }

      // 处理 undefined
      if (resultStr == 'undefined') {
        return JSResult.success(null);
      }

      // 尝试解析 JSON
      try {
        final decoded = jsonDecode(resultStr);
        return JSResult.success(decoded);
      } catch (e) {
        // 不是 JSON，返回原始字符串
        return JSResult.success(resultStr);
      }
    } catch (e) {
      print('[JS Debug] !!!!! evaluate 异常 !!!!!: $e');
      return JSResult.error(e.toString());
    }
  }

  @override
  Future<void> setGlobal(String name, dynamic value) async {
    String jsValue;
    if (value is String) {
      jsValue = "'${value.replaceAll("'", "\\'")}'";
    } else if (value is Map || value is List) {
      jsValue = jsonEncode(value);
    } else {
      jsValue = value.toString();
    }

    await evaluateDirect('globalThis.$name = $jsValue;');
  }

  @override
  Future<dynamic> getGlobal(String name) async {
    final result = await evaluate(name);
    return result.success ? result.result : null;
  }

  @override
  Future<void> registerFunction(String name, Function dartFunction) async {
    _registeredFunctions[name] = dartFunction;

    // flutter_js 的 sendMessage/onMessage 不支持异步返回值
    // 使用回调模式：JS 调用 Dart → Dart 处理 → Dart 通过另一个 sendMessage 返回结果

    // 为每个函数创建唯一的回调频道
    String callbackChannel = '${name}_callback';

    // 注册 JS 函数（返回 Promise）
    // 注意：__DART_RESULTS__ 已在 initialize 中创建
    // QuickJS 的 setTimeout 不可靠，改用标记 + 外部轮询
    final code = '''
      var $name = function() {
        var args = Array.prototype.slice.call(arguments);

        // 生成唯一 ID（使用整数避免小数点）
        var callId = Date.now() + '_' + Math.floor(Math.random() * 1000000);
        var resultKey = '${callbackChannel}_' + callId;

        // 调用 Dart 函数（立即触发）
        sendMessage('$name', JSON.stringify({ callId: callId, args: args }));

        // 标记此 Promise 正在等待，供外部轮询
        if (!globalThis.__PENDING_CALLS__) {
          globalThis.__PENDING_CALLS__ = {};
        }

        if (!globalThis.__DART_RESULTS__) {
          globalThis.__DART_RESULTS__ = {};
        }
        globalThis.__PENDING_CALLS__[resultKey] = {
          resolve: null,
          reject: null,
          timestamp: Date.now()
        };

        // 返回 Promise（resolve/reject 由外部轮询触发）
        return new Promise(function(resolve, reject) {
          globalThis.__PENDING_CALLS__[resultKey].resolve = resolve;
          globalThis.__PENDING_CALLS__[resultKey].reject = reject;
        });
      };
    ''';

    // 使用 evaluateDirect 注册函数（不需要等待结果）
    await evaluateDirect(code);

    // 注册 Dart 端处理器
    _runtime.onMessage(name, (dynamic data) {
      try {
        print('[JS Bridge] 调用函数: $name, 数据: $data');

        final callId = data['callId'];
        final args = data['args'] as List<dynamic>?;

        // 调用 Dart 函数
        final result = Function.apply(dartFunction, args ?? []);
        print('[JS Bridge] 结果类型: ${result.runtimeType}');

        // 辅助函数：将结果写入全局变量
        void setJsResult(String jsonResult) {
          final resultKey = '${callbackChannel}_$callId';

          try {
            _runtime.evaluate(
              'if (!globalThis.__DART_RESULTS__) { globalThis.__DART_RESULTS__ = {}; }',
            );

            // 将 jsonResult 作为 JS 字符串传递（再次 JSON 编码以添加引号和转义）
            // 这样 JS 端可以正确 JSON.parse
            final jsStringValue = jsonEncode(jsonResult);
            _runtime.evaluate('globalThis.__TEMP_RESULT__ = $jsStringValue;');

            // 然后移动到目标位置
            _runtime.evaluate(
              "globalThis.__DART_RESULTS__['$resultKey'] = globalThis.__TEMP_RESULT__; "
              "delete globalThis.__TEMP_RESULT__;",
            );

            print('[JS Bridge] ✓ 结果已写入: $resultKey');
          } catch (e) {
            print('[JS Bridge] ✗ 写入失败: $e');
            print('[JS Bridge] JSON 内容: $jsonResult');
          }
        }

        // 处理结果（同步或异步）
        if (result is Future) {
          result
              .then((value) {
                // 总是 JSON 编码,确保在 JavaScript 中能正确解析
                final jsonResult = jsonEncode(value);
                print('[JS Bridge] Future 结果: $jsonResult');
                setJsResult(jsonResult);
              })
              .catchError((e) {
                print('[JS Bridge] Future 错误: $e');
                final errorJson = jsonEncode({'error': e.toString()});
                setJsResult(errorJson);
              });
        } else {
          // 总是 JSON 编码,确保在 JavaScript 中能正确解析
          final jsonResult = jsonEncode(result);
          print('[JS Bridge] 同步结果: $jsonResult');
          setJsResult(jsonResult);
        }
      } catch (e) {
        print('[JS Bridge] 错误: $e');
        // 发送错误给 JS
        final errorJson = jsonEncode({'error': e.toString()});
        final callId = data['callId'];
        final resultKey = '${callbackChannel}_$callId';

        try {
          // 同样需要作为 JS 字符串传递
          final jsStringValue = jsonEncode(errorJson);
          _runtime.evaluate('globalThis.__TEMP_RESULT__ = $jsStringValue;');
          _runtime.evaluate(
            "globalThis.__DART_RESULTS__['$resultKey'] = globalThis.__TEMP_RESULT__; "
            "delete globalThis.__TEMP_RESULT__;",
          );
        } catch (writeError) {
          print('[JS Bridge] 写入错误失败: $writeError');
        }
      }
    });
  }

  @override
  Future<void> dispose() async {
    // flutter_js 不需要显式释放
    _registeredFunctions.clear();
    _initialized = false;
  }

  // ==================== UI 显示方法 ====================

  /// 显示 Toast
  void _showToast(String message, String duration, String gravity) {
    if (_onToast != null) {
      _onToast!(message, duration, gravity);
    } else {
      print('[JS Bridge] Toast 未设置处理器: $message');
    }
  }

  /// 显示 Alert 对话框
  Future<void> _showAlert(
    String callId,
    String message, {
    String? title,
    String? confirmText,
    String? cancelText,
    bool showCancel = false,
  }) async {
    if (_onAlert != null) {
      try {
        final confirmed = await _onAlert!(
          message,
          title: title,
          confirmText: confirmText,
          cancelText: cancelText,
          showCancel: showCancel,
        );

        // 将结果返回给 JavaScript
        final resultKey = '_flutterAlert_callback_$callId';
        final resultJson = jsonEncode({'confirmed': confirmed});

        _runtime.evaluate(
          'if (!globalThis.__DART_RESULTS__) { globalThis.__DART_RESULTS__ = {}; }',
        );
        // 将 JSON 字符串存储，JavaScript 端会用 JSON.parse 解析
        _runtime.evaluate(
          'globalThis.__DART_RESULTS__["$resultKey"] = ${jsonEncode(resultJson)};',
        );

        print('[JS Bridge] Alert 结果已返回: $resultJson');
      } catch (e) {
        print('[JS Bridge] Alert 执行错误: $e');
      }
    } else {
      print('[JS Bridge] Alert 未设置处理器');
    }
  }

  /// 显示自定义 Dialog
  Future<void> _showDialog(
    String callId, {
    String? title,
    String? content,
    required List<Map<String, dynamic>> actions,
  }) async {
    if (_onDialog != null) {
      try {
        final result = await _onDialog!(title, content, actions);

        // 将结果返回给 JavaScript
        final resultKey = '_flutterDialog_callback_$callId';
        // 序列化结果（保持 JSON 字符串格式，稍后在 JS 端解析）
        final resultJson = jsonEncode(result);

        _runtime.evaluate(
          'if (!globalThis.__DART_RESULTS__) { globalThis.__DART_RESULTS__ = {}; }',
        );
        // 将 JSON 字符串存储，JavaScript 端会用 JSON.parse 解析
        _runtime.evaluate(
          'globalThis.__DART_RESULTS__["$resultKey"] = ${jsonEncode(resultJson)};',
        );

        print('[JS Bridge] Dialog 结果已返回: $resultJson');
      } catch (e) {
        print('[JS Bridge] Dialog 执行错误: $e');
      }
    } else {
      print('[JS Bridge] Dialog 未设置处理器');
    }
  }

  /// 显示 Location 选择器
  Future<void> _showLocation(String callId, String mode) async {
    if (_onLocation != null) {
      try {
        final result = await _onLocation!(mode);

        // 将结果返回给 JavaScript
        final resultKey = '_flutterLocation_callback_$callId';
        final resultJson = jsonEncode(result);

        _runtime.evaluate(
          'if (!globalThis.__DART_RESULTS__) { globalThis.__DART_RESULTS__ = {}; }',
        );
        // 将 JSON 字符串存储，JavaScript 端会用 JSON.parse 解析
        _runtime.evaluate(
          'globalThis.__DART_RESULTS__["$resultKey"] = ${jsonEncode(resultJson)};',
        );

        print('[JS Bridge] Location 结果已返回: $resultJson');
      } catch (e) {
        print('[JS Bridge] Location 执行错误: $e');
        // 返回错误
        final resultKey = '_flutterLocation_callback_$callId';
        final errorJson = jsonEncode({'error': e.toString()});

        _runtime.evaluate(
          'if (!globalThis.__DART_RESULTS__) { globalThis.__DART_RESULTS__ = {}; }',
        );
        // 将 JSON 字符串存储，JavaScript 端会用 JSON.parse 解析
        _runtime.evaluate(
          'globalThis.__DART_RESULTS__["$resultKey"] = ${jsonEncode(errorJson)};',
        );
      }
    } else {
      print('[JS Bridge] Location 未设置处理器');
      // 返回错误
      final resultKey = '_flutterLocation_callback_$callId';
      final errorJson = jsonEncode({'error': '未设置处理器'});

      _runtime.evaluate(
        'if (!globalThis.__DART_RESULTS__) { globalThis.__DART_RESULTS__ = {}; }',
      );
      // 将 JSON 字符串存储，JavaScript 端会用 JSON.parse 解析
      _runtime.evaluate(
        'globalThis.__DART_RESULTS__["$resultKey"] = ${jsonEncode(errorJson)};',
      );
    }
  }

  /// 调用插件分析方法
  Future<void> _callPluginAnalysis(
    String callId,
    String methodName,
    Map<String, dynamic> params,
  ) async {
    if (_onPluginAnalysis != null) {
      try {
        final result = await _onPluginAnalysis!(methodName, params);

        // 将结果返回给 JavaScript
        _returnPluginAnalysisResult(callId, result);
      } catch (e) {
        print('[JS Bridge] 插件分析执行错误: $e');
        _returnPluginAnalysisResult(callId, null, error: e.toString());
      }
    } else {
      print('[JS Bridge] 插件分析未设置处理器');
      _returnPluginAnalysisResult(callId, null, error: '未设置处理器');
    }
  }

  /// 返回插件分析结果给 JavaScript
  void _returnPluginAnalysisResult(
    String callId,
    String? result, {
    String? error,
  }) {
    try {
      final resultKey = '_callPluginAnalysis_callback_$callId';

      String resultJson;
      if (error != null) {
        resultJson = jsonEncode({'error': error});
      } else {
        // result 可能已经是 JSON 字符串，直接使用
        resultJson = result ?? 'null';
      }

      _runtime.evaluate(
        'if (!globalThis.__DART_RESULTS__) { globalThis.__DART_RESULTS__ = {}; }',
      );
      // 将 JSON 字符串存储，JavaScript 端会用 JSON.parse 解析
      _runtime.evaluate(
        'globalThis.__DART_RESULTS__["$resultKey"] = ${jsonEncode(resultJson)};',
      );

      print(
        '[JS Bridge] 插件分析结果已返回: ${resultJson.substring(0, resultJson.length > 100 ? 100 : resultJson.length)}...',
      );
    } catch (e) {
      print('[JS Bridge] 返回插件分析结果错误: $e');
    }
  }
}
