/// Timer 插件 - 服务端 Repository 实现
library;

import 'package:shared_models/shared_models.dart';
import '../services/plugin_data_service.dart';

class ServerTimerRepository implements ITimerRepository {
  final PluginDataService dataService;
  final String userId;

  static const String _pluginId = 'timer';

  ServerTimerRepository({
    required this.dataService,
    required this.userId,
  });

  // ============ 内部方法 ============

  Future<List<TimerTaskDto>> _readAllTasks() async {
    final data = await dataService.readPluginData(
      userId,
      _pluginId,
      'tasks.json',
    );
    if (data == null) return [];

    final tasks = data['tasks'] as List<dynamic>? ?? [];
    return tasks
        .map((e) => TimerTaskDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveAllTasks(List<TimerTaskDto> tasks) async {
    await dataService.writePluginData(
      userId,
      _pluginId,
      'tasks.json',
      {'tasks': tasks.map((t) => t.toJson()).toList()},
    );
  }

  Future<List<TimerItemDto>> _readAllTimerItems() async {
    final data = await dataService.readPluginData(
      userId,
      _pluginId,
      'timer_items.json',
    );
    if (data == null) return [];

    final items = data['timerItems'] as List<dynamic>? ?? [];
    return items
        .map((e) => TimerItemDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveAllTimerItems(List<TimerItemDto> items) async {
    await dataService.writePluginData(
      userId,
      _pluginId,
      'timer_items.json',
      {'timerItems': items.map((i) => i.toJson()).toList()},
    );
  }

  // ============ 任务操作实现 ============

  @override
  Future<Result<List<TimerTaskDto>>> getTimerTasks(
      {PaginationParams? pagination}) async {
    try {
      var tasks = await _readAllTasks();

      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          tasks,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(tasks);
    } catch (e) {
      return Result.failure('获取任务列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<TimerTaskDto?>> getTimerTaskById(String id) async {
    try {
      final tasks = await _readAllTasks();
      final task = tasks.where((t) => t.id == id).firstOrNull;
      return Result.success(task);
    } catch (e) {
      return Result.failure('获取任务失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<TimerTaskDto>> createTimerTask(TimerTaskDto task) async {
    try {
      final tasks = await _readAllTasks();
      tasks.add(task);
      await _saveAllTasks(tasks);
      return Result.success(task);
    } catch (e) {
      return Result.failure('创建任务失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<TimerTaskDto>> updateTimerTask(
      String id, TimerTaskDto task) async {
    try {
      final tasks = await _readAllTasks();
      final index = tasks.indexWhere((t) => t.id == id);

      if (index == -1) {
        return Result.failure('任务不存在', code: ErrorCodes.notFound);
      }

      tasks[index] = task;
      await _saveAllTasks(tasks);
      return Result.success(task);
    } catch (e) {
      return Result.failure('更新任务失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteTimerTask(String id) async {
    try {
      final tasks = await _readAllTasks();
      final initialLength = tasks.length;
      tasks.removeWhere((t) => t.id == id);

      if (tasks.length == initialLength) {
        return Result.failure('任务不存在', code: ErrorCodes.notFound);
      }

      await _saveAllTasks(tasks);

      // 同时删除相关的计时器项
      final items = await _readAllTimerItems();
      items.removeWhere((item) => item.id.startsWith('${id}_'));
      await _saveAllTimerItems(items);

      return Result.success(true);
    } catch (e) {
      return Result.failure('删除任务失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<TimerTaskDto>>> searchTimerTasks(
      TimerTaskQuery query) async {
    try {
      var tasks = await _readAllTasks();

      if (query.group != null) {
        tasks = tasks.where((task) => task.group == query.group).toList();
      }

      if (query.isRunning != null) {
        tasks =
            tasks.where((task) => task.isRunning == query.isRunning).toList();
      }

      if (query.pagination != null && query.pagination!.hasPagination) {
        final paginated = PaginationUtils.paginate(
          tasks,
          offset: query.pagination!.offset,
          count: query.pagination!.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(tasks);
    } catch (e) {
      return Result.failure('搜索任务失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 计时器项操作实现 ============

  @override
  Future<Result<List<TimerItemDto>>> getTimerItems(String taskId,
      {PaginationParams? pagination}) async {
    try {
      var items = await _readAllTimerItems();
      // 根据任务 ID 过滤计时器项（任务 ID 作为前缀）
      items = items.where((item) => item.id.startsWith('${taskId}_')).toList();

      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          items,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(items);
    } catch (e) {
      return Result.failure('获取计时器项列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<TimerItemDto?>> getTimerItemById(String id) async {
    try {
      final items = await _readAllTimerItems();
      final item = items.where((i) => i.id == id).firstOrNull;
      return Result.success(item);
    } catch (e) {
      return Result.failure('获取计时器项失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<TimerItemDto>> createTimerItem(TimerItemDto item) async {
    try {
      final items = await _readAllTimerItems();
      items.add(item);
      await _saveAllTimerItems(items);
      return Result.success(item);
    } catch (e) {
      return Result.failure('创建计时器项失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<TimerItemDto>> updateTimerItem(
      String id, TimerItemDto item) async {
    try {
      final items = await _readAllTimerItems();
      final index = items.indexWhere((i) => i.id == id);

      if (index == -1) {
        return Result.failure('计时器项不存在', code: ErrorCodes.notFound);
      }

      items[index] = item;
      await _saveAllTimerItems(items);
      return Result.success(item);
    } catch (e) {
      return Result.failure('更新计时器项失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteTimerItem(String id) async {
    try {
      final items = await _readAllTimerItems();
      final initialLength = items.length;
      items.removeWhere((i) => i.id == id);

      if (items.length == initialLength) {
        return Result.failure('计时器项不存在', code: ErrorCodes.notFound);
      }

      await _saveAllTimerItems(items);
      return Result.success(true);
    } catch (e) {
      return Result.failure('删除计时器项失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 统计操作实现 ============

  @override
  Future<Result<int>> getTotalTaskCount() async {
    try {
      final tasks = await _readAllTasks();
      return Result.success(tasks.length);
    } catch (e) {
      return Result.failure('获取任务总数失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<int>> getRunningTaskCount() async {
    try {
      final tasks = await _readAllTasks();
      final count = tasks.where((t) => t.isRunning).length;
      return Result.success(count);
    } catch (e) {
      return Result.failure('获取运行任务数失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<int>> getTaskCountByGroup(String group) async {
    try {
      final tasks = await _readAllTasks();
      final count = tasks.where((t) => t.group == group).length;
      return Result.success(count);
    } catch (e) {
      return Result.failure('获取分组任务数失败: $e', code: ErrorCodes.serverError);
    }
  }
}
