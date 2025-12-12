import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dart_date/dart_date.dart';
import 'platform/js_engine_interface.dart';
import 'platform/js_engine_factory.dart';
import 'platform/mobile_js_engine.dart';
import 'js_ui_handlers.dart';
import 'package:Memento/core/plugin_base.dart';
import 'package:Memento/core/data_filter/field_filter_service.dart';
import 'package:Memento/core/event/event_manager.dart';
import 'package:Memento/core/event/item_event_args.dart';

/// 延迟注册的插件信息
class PendingPluginRegistration {
  final PluginBase plugin;
  final Map<String, Function> apis;

  PendingPluginRegistration({required this.plugin, required this.apis});
}

/// 延迟执行的脚本信息
class _PendingScript {
  final String code;
  final String? description;
  final Completer<JSResult> completer;

  _PendingScript({
    required this.code,
    this.description,
    required this.completer,
  });
}

/// 全局 JS 桥接管理器
class JSBridgeManager {
  static JSBridgeManager? _instance;
  static JSBridgeManager get instance {
    _instance ??= JSBridgeManager._();
    return _instance!;
  }

  JSBridgeManager._();

  JSEngine? _engine;
  bool _initialized = false;
  final Map<String, PluginBase> _registeredPlugins = {};

  // 工具调用上下文管理
  final Map<String, Map<String, dynamic>> _toolCallContexts = {};
  String? _currentToolCallId;
  int _currentStepIndex = -1;

  // 事件队列管理 - 存储待传递给 JavaScript 的事件
  final Map<String, List<Map<String, dynamic>>> _eventQueue = {};

  // 延迟注册队列 - 存储等待 JS Bridge 初始化完成后注册的插件
  final List<PendingPluginRegistration> _pendingRegistrations = [];

  // 延迟执行队列 - 存储等待 JS Bridge 初始化完成后执行的脚本
  final List<_PendingScript> _pendingScripts = [];

  /// 初始化 JS 引擎
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _engine = JSEngineFactory.create();
      await _engine!.initialize();

      // 注册全局 API
      await _registerGlobalAPI();

      _initialized = true;
      print('JS Bridge 初始化成功');

      // 处理延迟注册的插件
      await _processPendingRegistrations();

      // 处理延迟执行的脚本
      await _processPendingScripts();
    } catch (e) {
      print('JS Bridge 初始化失败: $e');
      _initialized = false;
    }
  }

  /// 检查是否支持
  bool get isSupported => _initialized && _engine != null;

  /// 注册 UI 处理器（Toast/Alert/Dialog）
  ///
  /// 必须在有 BuildContext 的情况下调用，通常在 UI 组件初始化时调用
  void registerUIHandlers(BuildContext context) {
    if (!_initialized || _engine == null) {
      print('警告: JS Bridge 未初始化，无法注册 UI 处理器');
      return;
    }

    // 只有 MobileJSEngine 需要注册 UI 处理器
    if (_engine is MobileJSEngine) {
      final handlers = JSUIHandlers(context);
      handlers.register(_engine as MobileJSEngine);
      print('✓ UI 处理器已注册 (Toast/Alert/Dialog)');
    } else {
      print('跳过 UI 处理器注册 (Web 平台)');
    }
  }

  /// 注册插件分析处理器（由 OpenAI 插件调用）
  ///
  /// 用于在 JS 中调用 callPluginAnalysis() 时执行插件的数据分析方法
  void registerPluginAnalysisHandler(
    Future<String> Function(String methodName, Map<String, dynamic> params)
    handler,
  ) {
    if (!_initialized || _engine == null) {
      print('警告: JS Bridge 未初始化，无法注册插件分析处理器');
      return;
    }

    // 只有 MobileJSEngine 支持插件分析
    if (_engine is MobileJSEngine) {
      (_engine as MobileJSEngine).setPluginAnalysisHandler(handler);
      print('✓ 插件分析处理器已注册');
    } else {
      print('跳过插件分析处理器注册 (Web 平台)');
    }
  }

  /// 处理延迟注册的插件
  Future<void> _processPendingRegistrations() async {
    if (_pendingRegistrations.isEmpty) return;

    print('正在处理 ${_pendingRegistrations.length} 个延迟注册的插件...');

    final registrations = List<PendingPluginRegistration>.from(_pendingRegistrations);
    _pendingRegistrations.clear();

    for (final registration in registrations) {
      try {
        await _doRegisterPlugin(registration.plugin, registration.apis);
        print('✓ 延迟注册成功: ${registration.plugin.id}');
      } catch (e) {
        print('✗ 延迟注册失败: ${registration.plugin.id} - $e');
      }
    }

    print('所有延迟注册已完成');
  }

  /// 处理延迟执行的脚本
  Future<void> _processPendingScripts() async {
    if (_pendingScripts.isEmpty) return;

    print('正在处理 ${_pendingScripts.length} 个延迟执行的脚本...');

    final scripts = List<_PendingScript>.from(_pendingScripts);
    _pendingScripts.clear();

    for (final script in scripts) {
      try {
        final result = await _engine!.evaluate(script.code);
        script.completer.complete(result);
        print('✓ 延迟脚本执行成功: ${script.description ?? '(未命名)'}');
      } catch (e) {
        script.completer.complete(JSResult.error(e.toString()));
        print('✗ 延迟脚本执行失败: ${script.description ?? '(未命名)'} - $e');
      }
    }

    print('所有延迟脚本已处理');
  }

  /// 执行实际的插件注册（拆分出来以便复用）
  Future<void> _doRegisterPlugin(
    PluginBase plugin,
    Map<String, Function> apis,
  ) async {
    _registeredPlugins[plugin.id] = plugin;

    // 为每个插件创建命名空间
    // 使用 globalThis 确保跨平台兼容性（Web/QuickJS）
    await _engine!.evaluateDirect('''
      (function() {
        // 确保全局命名空间存在
        if (typeof globalThis.Memento === 'undefined') {
          globalThis.Memento = {
            version: '1.0.0',
            plugins: {}
          };
        }

        // 创建插件命名空间
        globalThis.Memento.plugins.${plugin.id} = {};

        // 兼容浏览器环境
        if (typeof window !== 'undefined') {
          window.Memento = globalThis.Memento;
        }
      })();
    ''');

    // 注册 API
    for (var entry in apis.entries) {
      final apiName = entry.key;
      final dartFunction = entry.value;

      // 包装函数：直接返回原始结果或 Future
      // 集成字段过滤器，支持 mode/fields/excludeFields 参数
      dynamic wrappedFunction([
        dynamic a,
        dynamic b,
        dynamic c,
        dynamic d,
        dynamic e,
      ]) {
        try {
          final args = [a, b, c, d, e].where((arg) => arg != null).toList();

          // 如果没有参数，传递一个空的 Map（插件方法通常期望 Map<String, dynamic> params）
          // 如果有一个参数且是 Map，直接传递
          // 否则传递空 Map（期望 JavaScript 调用时传递对象参数）
          final Map<String, dynamic> paramsMap;
          if (args.isEmpty) {
            paramsMap = {};
          } else if (args.length == 1 && args[0] is Map<String, dynamic>) {
            paramsMap = args[0] as Map<String, dynamic>;
          } else {
            paramsMap = {};
          }

          // 提取过滤参数（避免传递给底层方法）
          final originalParams = Map<String, dynamic>.from(paramsMap);
          final cleanedParams = FieldFilterService.cleanParams(paramsMap);

          // 直接调用 Dart 函数并返回（可能是同步值或 Future）
          final result = Function.apply(dartFunction, [cleanedParams]);

          // 如果是 Future，包装为返回序列化结果的 Future
          if (result is Future) {
            return result
                .then((awaitedResult) {
                  // 应用字段过滤器
                  final filtered = FieldFilterService.filterFromParams(
                    awaitedResult,
                    originalParams,
                  );
                  return _serializeResult(filtered);
                })
                .catchError((e) {
                  print('JS API Error [${plugin.id}.$apiName]: $e');
                  return jsonEncode({'error': e.toString()});
                });
          }

          // 同步结果：应用过滤器后序列化
          final filtered = FieldFilterService.filterFromParams(
            result,
            originalParams,
          );
          return _serializeResult(filtered);
        } catch (e) {
          print('JS API Error [${plugin.id}.$apiName]: $e');
          return jsonEncode({'error': e.toString()});
        }
      }

      // 注册包装后的函数
      await _engine!.registerFunction(
        'Memento_${plugin.id}_$apiName',
        wrappedFunction,
      );

      // 在插件命名空间下创建代理
      // 直接返回内层 Promise，不使用 await（避免事件循环阻塞）
      // 自动将 JSON 字符串解析为对象
      await _engine!.evaluateDirect('''
        (function() {
          var namespace = globalThis.Memento;

          // 返回 Promise 并自动解析 JSON 返回值
          namespace.plugins.${plugin.id}.$apiName = function() {
            var args = Array.prototype.slice.call(arguments);
            // 调用底层函数并自动解析 JSON 字符串
            return Memento_${plugin.id}_$apiName.apply(null, args).then(function(result) {
              // 如果返回值是字符串，尝试解析为 JSON
              if (typeof result === 'string') {
                try {
                  return JSON.parse(result);
                } catch (e) {
                  // 解析失败，返回原始字符串
                  return result;
                }
              }
              return result;
            });
          };
        })();
      ''');
    }
  }

  /// 注册插件的 JS API
  Future<void> registerPlugin(
    PluginBase plugin,
    Map<String, Function> apis,
  ) async {
    // 如果尚未初始化，先加入延迟注册队列
    if (!_initialized || _engine == null) {
      print('[${plugin.id}] JS Bridge 未初始化，添加到延迟注册队列');
      _pendingRegistrations.add(
        PendingPluginRegistration(plugin: plugin, apis: apis),
      );
      return;
    }

    // 如果已初始化，直接注册
    await _doRegisterPlugin(plugin, apis);
  }

  /// 执行 JS 代码
  Future<JSResult> evaluate(String code) async {
    if (!_initialized || _engine == null) {
      return JSResult.error('JS Bridge not initialized');
    }
    return await _engine!.evaluate(code);
  }

  /// 执行 JS 代码（如果未初始化则加入延迟队列）
  ///
  /// 与 [evaluate] 不同，此方法在 JS Bridge 未初始化时不会立即返回错误，
  /// 而是将脚本加入延迟执行队列，等待初始化完成后自动执行。
  Future<JSResult> evaluateWhenReady(String code, {String? description}) async {
    // 如果已初始化，直接执行
    if (_initialized && _engine != null) {
      return await _engine!.evaluate(code);
    }

    // 否则加入延迟执行队列
    print('[JSBridge] JS Bridge 未初始化，脚本加入延迟队列: ${description ?? '(未命名)'}');
    final completer = Completer<JSResult>();
    _pendingScripts.add(_PendingScript(
      code: code,
      description: description,
      completer: completer,
    ));
    return completer.future;
  }

  /// 注册全局 API
  Future<void> _registerGlobalAPI() async {
    if (_engine == null) return;

    // 注册全局命名空间（使用 globalThis 确保跨平台）
    await _engine!.evaluateDirect('''
      (function() {
        // 确保全局命名空间存在
        if (typeof globalThis.Memento === 'undefined') {
          globalThis.Memento = {
            version: '1.0.0',
            plugins: {},
            system: {}
          };
        }

        // 兼容浏览器环境
        if (typeof window !== 'undefined') {
          window.Memento = globalThis.Memento;
        }
      })();
    ''');

    // 注册系统级 API
    await _registerSystemAPIs();

    // 注册事件系统 API
    await _registerEventAPIs();

    // 注册工具调用 API
    await _registerToolCallAPIs();
  }

  /// 注册系统级 API（时间、设备信息等）
  Future<void> _registerSystemAPIs() async {
    if (_engine == null) return;

    // 1. 获取当前时间
    await _engine!.registerFunction('Memento_system_getCurrentTime', ([
      dynamic a,
    ]) async {
      try {
        final now = DateTime.now();
        final weekdayNames = ['一', '二', '三', '四', '五', '六', '日'];

        final timeInfo = {
          'timestamp': now.millisecondsSinceEpoch,
          'datetime': now.toIso8601String(),
          'year': now.year,
          'month': now.month,
          'day': now.day,
          'hour': now.hour,
          'minute': now.minute,
          'second': now.second,
          'weekday': now.weekday,
          'weekdayName': weekdayNames[now.weekday - 1],
        };

        return jsonEncode(timeInfo);
      } catch (e) {
        return jsonEncode({'error': e.toString()});
      }
    });

    // 2. 获取设备信息
    await _engine!.registerFunction('Memento_system_getDeviceInfo', ([
      dynamic a,
    ]) async {
      try {
        // 导入 device_info_plus 包以获取详细设备信息
        // 这里先返回基础信息，后续可以扩展
        final deviceInfo = {
          'platform': _getPlatformName(),
          'platformVersion': 'Unknown',
          'deviceModel': 'Unknown',
          'isPhysicalDevice': true,
        };

        return jsonEncode(deviceInfo);
      } catch (e) {
        return jsonEncode({'error': e.toString()});
      }
    });

    // 3. 获取应用信息
    await _engine!.registerFunction('Memento_system_getAppInfo', ([
      dynamic a,
    ]) async {
      try {
        // 导入 package_info_plus 包以获取详细应用信息
        // 这里先返回基础信息
        final appInfo = {
          'appName': 'Memento',
          'version': '1.0.0',
          'buildNumber': '1',
          'packageName': 'github.hunmer.memento',
        };

        return jsonEncode(appInfo);
      } catch (e) {
        return jsonEncode({'error': e.toString()});
      }
    });

    // 4. 格式化日期时间
    await _engine!.registerFunction('Memento_system_formatDate', ([
      dynamic a,
      dynamic b,
    ]) async {
      try {
        final dateInput = a;
        final format = b ?? 'yyyy-MM-dd HH:mm:ss';

        DateTime dateTime;
        if (dateInput is num) {
          dateTime = DateTime.fromMillisecondsSinceEpoch(dateInput.toInt());
        } else if (dateInput is String) {
          dateTime = DateTime.parse(dateInput);
        } else {
          throw Exception('Invalid date input type');
        }

        final formatted = _formatDateTime(dateTime, format.toString());
        return formatted;
      } catch (e) {
        return jsonEncode({'error': e.toString()});
      }
    });

    // 5. 获取当前时间戳
    await _engine!.registerFunction('Memento_system_getTimestamp', ([
      dynamic a,
    ]) async {
      try {
        return DateTime.now().millisecondsSinceEpoch;
      } catch (e) {
        return jsonEncode({'error': e.toString()});
      }
    });

    // 6. 获取自定义日期（解决时区问题的核心 API）
    await _engine!.registerFunction('Memento_system_getCustomDate', ([
      dynamic options,
    ]) async {
      try {
        // 解析参数
        Map<String, dynamic> opts = {};
        if (options is String) {
          opts = jsonDecode(options);
        } else if (options is Map) {
          opts = Map<String, dynamic>.from(options);
        }

        // 默认从当前时间开始
        DateTime date = DateTime.now();

        // 处理基准日期
        if (opts['baseDate'] != null) {
          final baseDate = opts['baseDate'];
          if (baseDate is num) {
            date = DateTime.fromMillisecondsSinceEpoch(baseDate.toInt());
          } else if (baseDate is String) {
            date = DateTime.parse(baseDate);
          }
        }

        // 处理时区
        String timezone = opts['timezone']?.toString() ?? 'local';
        if (timezone == 'UTC') {
          date = date.toUtc();
        } else {
          date = date.toLocal();
        }

        // 处理增加时间
        if (opts['add'] != null) {
          final add = Map<String, dynamic>.from(opts['add'] as Map);
          date = date.add(
            Duration(
              days: (add['days'] as num?)?.toInt() ?? 0,
              hours: (add['hours'] as num?)?.toInt() ?? 0,
              minutes: (add['minutes'] as num?)?.toInt() ?? 0,
              seconds: (add['seconds'] as num?)?.toInt() ?? 0,
              milliseconds: (add['milliseconds'] as num?)?.toInt() ?? 0,
            ),
          );
        }

        // 处理减少时间
        if (opts['subtract'] != null) {
          final sub = Map<String, dynamic>.from(opts['subtract'] as Map);
          date = date.subtract(
            Duration(
              days: (sub['days'] as num?)?.toInt() ?? 0,
              hours: (sub['hours'] as num?)?.toInt() ?? 0,
              minutes: (sub['minutes'] as num?)?.toInt() ?? 0,
              seconds: (sub['seconds'] as num?)?.toInt() ?? 0,
              milliseconds: (sub['milliseconds'] as num?)?.toInt() ?? 0,
            ),
          );
        }

        // 处理相对位置（使用 dart_date 扩展方法）
        String? position = opts['relativePosition']?.toString();
        if (position != null) {
          switch (position) {
            case 'startOfDay':
              date = date.startOfDay;
              break;
            case 'endOfDay':
              date = date.endOfDay;
              break;
            case 'startOfHour':
              date = date.startOfHour;
              break;
            case 'endOfHour':
              date = date.endOfHour;
              break;
            case 'startOfMinute':
              date = date.startOfMinute;
              break;
            case 'endOfMinute':
              date = date.endOfMinute;
              break;
            case 'startOfMonth':
              date = date.startOfMonth;
              break;
            case 'endOfMonth':
              date = date.endOfMonth;
              break;
            case 'startOfWeek':
              date = date.startOfWeek;
              break;
            case 'endOfWeek':
              date = date.endOfWeek;
              break;
            case 'startOfYear':
              date = date.startOfYear;
              break;
            case 'endOfYear':
              date = date.endOfYear;
              break;
          }
        }

        // 处理返回格式
        String format = opts['format']?.toString() ?? 'object';
        final weekdayNames = ['一', '二', '三', '四', '五', '六', '日'];

        if (format == 'timestamp') {
          return date.millisecondsSinceEpoch;
        } else if (format == 'iso') {
          return date.toIso8601String();
        } else if (format == 'text') {
          // 使用 dart_date 的 timeago 功能
          return date.timeago();
        } else if (format == 'object') {
          // 返回完整对象（默认）
          return jsonEncode({
            'timestamp': date.millisecondsSinceEpoch,
            'datetime': date.toIso8601String(),
            'year': date.year,
            'month': date.month,
            'day': date.day,
            'hour': date.hour,
            'minute': date.minute,
            'second': date.second,
            'millisecond': date.millisecond,
            'weekday': date.weekday,
            'weekdayName': weekdayNames[date.weekday - 1],
          });
        } else {
          // 自定义格式字符串
          return date.format(format);
        }
      } catch (e) {
        return jsonEncode({'error': e.toString()});
      }
    });

    // 在 JS 中创建系统 API 代理
    await _engine!.evaluateDirect('''
      (function() {
        var namespace = globalThis.Memento;

        // 辅助函数：自动解析 JSON 字符串结果
        function parseResult(result) {
          if (typeof result === 'string') {
            try {
              return JSON.parse(result);
            } catch (e) {
              return result;
            }
          }
          return result;
        }

        namespace.system.getCurrentTime = function() {
          return Memento_system_getCurrentTime().then(parseResult);
        };

        namespace.system.getDeviceInfo = function() {
          return Memento_system_getDeviceInfo().then(parseResult);
        };

        namespace.system.getAppInfo = function() {
          return Memento_system_getAppInfo().then(parseResult);
        };

        namespace.system.formatDate = function(dateInput, format) {
          return Memento_system_formatDate(dateInput, format).then(parseResult);
        };

        namespace.system.getTimestamp = function() {
          return Memento_system_getTimestamp();
        };

        // 获取自定义日期（推荐使用，解决时区问题）
        namespace.system.getCustomDate = function(options) {
          return Memento_system_getCustomDate(options ? JSON.stringify(options) : '{}').then(parseResult);
        };

        // 获取位置信息
        namespace.system.getLocation = function(mode) {
          // 使用 flutter.getLocation 获取位置
          return flutter.getLocation(mode);
        };

        // 创建 UI 插件命名空间，将 flutter.* 方法代理到 Memento.plugins.ui.*
        namespace.plugins.ui = {
          toast: function(message, options) {
            return flutter.toast(message, options);
          },
          alert: function(message, options) {
            return flutter.alert(message, options);
          },
          dialog: function(options) {
            return flutter.dialog(options);
          }
        };
      })();
    ''');
  }

  /// 注册事件系统 API
  Future<void> _registerEventAPIs() async {
    if (_engine == null) return;

    // 1. events.on - 订阅事件
    await _engine!.registerFunction('Memento_events_on', ([
      dynamic a,
      dynamic b,
    ]) async {
      try {
        final eventName = a as String?;
        // b 是 JavaScript 函数,无法直接传递到 Dart
        // 这里需要使用回调机制

        if (eventName == null || eventName.isEmpty) {
          throw Exception('on() 需要提供事件名称参数');
        }

        // 先声明订阅 ID 变量
        late String subscriptionId;

        // 生成唯一的订阅 ID
        subscriptionId = EventManager.instance.subscribe(
          eventName,
          (args) {
            // 将事件参数序列化并传递给 JavaScript
            final eventData = {
              'eventName': args.eventName,
              'whenOccurred': args.whenOccurred.toIso8601String(),
              'data': args is ItemEventArgs
                  ? {
                      'itemId': args.itemId,
                      'title': args.title,
                      'action': args.action,
                    }
                  : {},
            };

            // 调用 JavaScript 回调
            // 注意: 这里需要通过事件队列机制来触发 JS 回调
            // 当前实现仅返回订阅 ID,实际回调需要在 JS 端轮询事件队列
            _eventQueue.putIfAbsent(subscriptionId, () => []).add(eventData);
          },
        );

        return subscriptionId;
      } catch (e) {
        print('[Events API] on 失败: $e');
        return jsonEncode({'error': e.toString()});
      }
    });

    // 2. events.off - 取消订阅
    await _engine!.registerFunction('Memento_events_off', ([
      dynamic a,
    ]) async {
      try {
        final subscriptionId = a as String?;

        if (subscriptionId == null || subscriptionId.isEmpty) {
          throw Exception('off() 需要提供订阅 ID 参数');
        }

        // 使用 EventManager 的 unsubscribeById 方法
        final success = EventManager.instance.unsubscribeById(subscriptionId);

        // 清理事件队列
        _eventQueue.remove(subscriptionId);

        return jsonEncode({'success': success});
      } catch (e) {
        print('[Events API] off 失败: $e');
        return jsonEncode({'error': e.toString()});
      }
    });

    // 3. events.getEvents - 获取队列中的事件
    await _engine!.registerFunction('Memento_events_getEvents', ([
      dynamic a,
    ]) async {
      try {
        final subscriptionId = a as String?;

        if (subscriptionId == null || subscriptionId.isEmpty) {
          throw Exception('getEvents() 需要提供订阅 ID 参数');
        }

        final events = _eventQueue[subscriptionId] ?? [];
        _eventQueue[subscriptionId] = []; // 清空队列

        return jsonEncode(events);
      } catch (e) {
        print('[Events API] getEvents 失败: $e');
        return jsonEncode({'error': e.toString()});
      }
    });

    // 在 JS 中创建事件 API 代理
    await _engine!.evaluateDirect('''
      (function() {
        var namespace = globalThis.Memento;

        // 创建 events 命名空间
        namespace.events = {
          _subscriptions: {},
          _pollingIntervals: {}
        };

        // on - 订阅事件
        namespace.events.on = function(eventName, handler) {
          if (!eventName || typeof handler !== 'function') {
            throw new Error('on(eventName, handler) 需要事件名称和处理函数');
          }

          // 调用 Dart 端注册订阅
          return Memento_events_on(eventName).then(function(subscriptionId) {
            if (typeof subscriptionId === 'string' && subscriptionId.startsWith('sub_')) {
              // 保存订阅信息
              namespace.events._subscriptions[subscriptionId] = {
                eventName: eventName,
                handler: handler
              };

              // 启动轮询(每500ms检查一次新事件)
              namespace.events._pollingIntervals[subscriptionId] = setInterval(function() {
                Memento_events_getEvents(subscriptionId).then(function(result) {
                  var events = typeof result === 'string' ? JSON.parse(result) : result;
                  if (Array.isArray(events)) {
                    events.forEach(function(event) {
                      try {
                        handler(event);
                      } catch (e) {
                        console.error('事件处理函数错误:', e);
                      }
                    });
                  }
                });
              }, 500);

              return subscriptionId;
            } else {
              throw new Error('订阅失败: ' + subscriptionId);
            }
          });
        };

        // off - 取消订阅
        namespace.events.off = function(subscriptionId) {
          if (!subscriptionId) {
            throw new Error('off(subscriptionId) 需要订阅 ID');
          }

          // 停止轮询
          if (namespace.events._pollingIntervals[subscriptionId]) {
            clearInterval(namespace.events._pollingIntervals[subscriptionId]);
            delete namespace.events._pollingIntervals[subscriptionId];
          }

          // 移除订阅信息
          delete namespace.events._subscriptions[subscriptionId];

          // 调用 Dart 端取消订阅
          return Memento_events_off(subscriptionId).then(function(result) {
            if (typeof result === 'string') {
              try {
                return JSON.parse(result);
              } catch (e) {
                return result;
              }
            }
            return result;
          });
        };
      })();
    ''');
  }

  /// 注册工具调用 API（步骤间结果传递）
  Future<void> _registerToolCallAPIs() async {
    if (_engine == null) return;

    // 1. setResult - 设置结果
    await _engine!.registerFunction('Memento_toolCall_setResult', ([
      dynamic a,
    ]) async {
      try {
        final params = a as Map<String, dynamic>?;
        if (params == null) {
          throw Exception('setResult 需要参数对象 {id?, value}');
        }

        final id = params['id'] as String?;
        final value = params['value'];

        if (value == null) {
          throw Exception('setResult 需要提供 value 参数');
        }

        setToolCallResult(id, value);
        return jsonEncode({'success': true});
      } catch (e) {
        print('[ToolCall API] setResult 失败: $e');
        return jsonEncode({'error': e.toString()});
      }
    });

    // 2. getResult - 获取结果
    await _engine!.registerFunction('Memento_toolCall_getResult', ([
      dynamic a,
    ]) async {
      try {
        final params = a as Map<String, dynamic>?;
        if (params == null) {
          throw Exception('getResult 需要参数对象 {id?, step?, default?}');
        }

        final id = params['id'] as String?;
        final step = params['step'] as int?;
        final defaultValue = params['default'];

        final result = getToolCallResult(id, step, defaultValue);

        // 序列化结果
        return _serializeResult(result);
      } catch (e) {
        print('[ToolCall API] getResult 失败: $e');
        return jsonEncode({'error': e.toString()});
      }
    });

    // 在 JS 中创建 toolCall API 代理
    await _engine!.evaluateDirect('''
      (function() {
        var namespace = globalThis.Memento;

        // 创建 toolCall 命名空间
        namespace.toolCall = {};

        // setResult API
        namespace.toolCall.setResult = function(params) {
          if (!params || typeof params !== 'object') {
            throw new Error('setResult 需要参数对象 {id?, value}');
          }
          return Memento_toolCall_setResult(params).then(function(result) {
            if (typeof result === 'string') {
              try {
                return JSON.parse(result);
              } catch (e) {
                return result;
              }
            }
            return result;
          });
        };

        // getResult API
        namespace.toolCall.getResult = function(params) {
          if (!params || typeof params !== 'object') {
            throw new Error('getResult 需要参数对象 {id?, step?, default?}');
          }
          return Memento_toolCall_getResult(params).then(function(result) {
            if (typeof result === 'string') {
              try {
                return JSON.parse(result);
              } catch (e) {
                return result;
              }
            }
            return result;
          });
        };

        // getCurrentStep - 获取当前步骤索引（只读）
        namespace.toolCall.getCurrentStep = function() {
          // 这个值由 Dart 端在执行时设置，这里只是占位
          return -1;
        };
      })();
    ''');
  }

  /// 获取平台名称
  String _getPlatformName() {
    if (kIsWeb) return 'web';

    // 使用 Platform 类判断平台
    try {
      // 需要导入 dart:io 并使用条件导入
      return 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }

  /// 格式化日期时间
  String _formatDateTime(DateTime dateTime, String format) {
    final weekdayNames = ['一', '二', '三', '四', '五', '六', '日'];

    String result = format;

    // 替换占位符
    result = result.replaceAll(
      'yyyy',
      dateTime.year.toString().padLeft(4, '0'),
    );
    result = result.replaceAll('MM', dateTime.month.toString().padLeft(2, '0'));
    result = result.replaceAll('dd', dateTime.day.toString().padLeft(2, '0'));
    result = result.replaceAll('HH', dateTime.hour.toString().padLeft(2, '0'));
    result = result.replaceAll(
      'hh',
      (dateTime.hour % 12).toString().padLeft(2, '0'),
    );
    result = result.replaceAll(
      'mm',
      dateTime.minute.toString().padLeft(2, '0'),
    );
    result = result.replaceAll(
      'ss',
      dateTime.second.toString().padLeft(2, '0'),
    );
    result = result.replaceAll('E', weekdayNames[dateTime.weekday - 1]);

    return result;
  }

  /// 序列化结果
  String _serializeResult(dynamic result) {
    if (result == null) {
      return 'null';
    } else if (result is String) {
      // 如果已经是 JSON 字符串，直接返回
      try {
        jsonDecode(result);
        return result;
      } catch (e) {
        // 不是 JSON，包装成字符串
        return jsonEncode(result);
      }
    } else if (result is bool || result is num) {
      return result.toString();
    } else {
      // 对象或列表，序列化为 JSON
      try {
        return jsonEncode(result);
      } catch (e) {
        return jsonEncode({'error': 'Failed to serialize result: $e'});
      }
    }
  }

  /// 获取已注册的插件
  PluginBase? getPlugin(String id) => _registeredPlugins[id];

  /// 获取所有已注册的插件 ID
  List<String> get registeredPluginIds => _registeredPlugins.keys.toList();

  // ==================== 工具调用上下文管理 ====================

  /// 初始化工具调用上下文
  void initToolCallContext(String toolCallId) {
    _toolCallContexts[toolCallId] = {};
    print('[JSBridge] 初始化工具调用上下文: $toolCallId');
  }

  /// 清除工具调用上下文
  void clearToolCallContext(String toolCallId) {
    _toolCallContexts.remove(toolCallId);
    if (_currentToolCallId == toolCallId) {
      _currentToolCallId = null;
      _currentStepIndex = -1;
    }
    print('[JSBridge] 清除工具调用上下文: $toolCallId');
  }

  /// 设置当前执行上下文（工具调用ID和步骤索引）
  void setCurrentExecution(String toolCallId, int stepIndex) {
    _currentToolCallId = toolCallId;
    _currentStepIndex = stepIndex;
  }

  /// 在工具调用上下文中设置结果
  ///
  /// 从 JavaScript 中调用: await Memento.toolCall.setResult({id: 'myKey', value: {...}})
  /// 从 Dart 中调用: jsBridge.setToolCallResult('myKey', value)
  void setToolCallResult(String? id, dynamic value) {
    if (_currentToolCallId == null) {
      throw Exception('没有活动的工具调用上下文');
    }

    final context = _toolCallContexts[_currentToolCallId];
    if (context == null) {
      throw Exception('工具调用上下文不存在: $_currentToolCallId');
    }

    // 使用自定义 ID 或当前步骤索引作为键
    final key = id ?? 'step_$_currentStepIndex';
    context[key] = value;
    print('[JSBridge] 设置结果: $key = $value');
  }

  /// 从工具调用上下文中获取结果
  ///
  /// 从 JavaScript 中调用:
  /// - await Memento.toolCall.getResult({id: 'myKey'})
  /// - await Memento.toolCall.getResult({step: 0})
  /// - await Memento.toolCall.getResult({id: 'myKey', default: {}})
  /// 从 Dart 中调用: jsBridge.getToolCallResult('myKey', null, defaultValue)
  dynamic getToolCallResult(String? id, int? step, dynamic defaultValue) {
    if (_currentToolCallId == null) {
      if (defaultValue != null) {
        return defaultValue;
      }
      throw Exception('没有活动的工具调用上下文');
    }

    final context = _toolCallContexts[_currentToolCallId];
    if (context == null) {
      if (defaultValue != null) {
        return defaultValue;
      }
      throw Exception('工具调用上下文不存在: $_currentToolCallId');
    }

    // 优先使用 ID，其次使用步骤索引
    String key;
    if (id != null) {
      key = id;
    } else if (step != null) {
      key = 'step_$step';
    } else {
      throw Exception('必须提供 id 或 step 参数');
    }

    // 获取结果，如果不存在则返回默认值
    final result = context[key];
    if (result == null && defaultValue != null) {
      return defaultValue;
    }

    print('[JSBridge] 获取结果: $key = $result');
    return result;
  }

  /// 释放资源
  Future<void> dispose() async {
    if (_initialized && _engine != null) {
      await _engine!.dispose();
      _registeredPlugins.clear();
      _initialized = false;
      _engine = null;
    }
  }
}
