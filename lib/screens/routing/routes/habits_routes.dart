import 'package:flutter/material.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/screens/routing/route_definition.dart';
import 'package:Memento/screens/routing/route_helpers.dart';
import 'package:Memento/plugins/habits/habits_plugin.dart';
import 'package:Memento/plugins/habits/screens/habit_timer_selector_screen.dart';
import 'package:Memento/plugins/habits/screens/habits_weekly_config_screen.dart';
import 'package:Memento/plugins/habits/screens/habit_group_list_selector_screen.dart';
import 'package:Memento/plugins/habits/widgets/timer_dialog.dart';

/// Habits 插件路由注册表
class HabitsRoutes implements RouteRegistry {
  @override
  String get name => 'HabitsRoutes';

  @override
  List<RouteDefinition> get routes => [
        // Habits 主页面
        RouteDefinition(
          path: '/habits',
          handler: (settings) {
            String? habitId;
            if (settings.arguments is Map<String, dynamic>) {
              habitId = (settings.arguments as Map<String, dynamic>)['habitId'] as String?;
            }
            return RouteHelpers.createRoute(HabitsMainView(habitId: habitId));
          },
          description: '习惯管理主页面',
        ),
        RouteDefinition(
          path: 'habits',
          handler: (settings) {
            String? habitId;
            if (settings.arguments is Map<String, dynamic>) {
              habitId = (settings.arguments as Map<String, dynamic>)['habitId'] as String?;
            }
            return RouteHelpers.createRoute(HabitsMainView(habitId: habitId));
          },
          description: '习惯管理主页面（别名）',
        ),

        // 习惯计时器小组件配置界面
        RouteDefinition(
          path: '/habit_timer_selector',
          handler: (settings) {
            int? habitTimerWidgetId;

            if (settings.arguments is Map<String, dynamic>) {
              final args = settings.arguments as Map<String, dynamic>;
              final widgetIdValue = args['widgetId'];
              if (widgetIdValue is int) {
                habitTimerWidgetId = widgetIdValue;
              } else if (widgetIdValue is String) {
                habitTimerWidgetId = int.tryParse(widgetIdValue);
              }
            } else if (settings.arguments is int) {
              habitTimerWidgetId = settings.arguments as int;
            }

            return RouteHelpers.createRoute(
              HabitTimerSelectorScreen(widgetId: habitTimerWidgetId),
            );
          },
          description: '习惯计时器小组件配置界面',
        ),
        RouteDefinition(
          path: 'habit_timer_selector',
          handler: (settings) {
            int? habitTimerWidgetId;

            if (settings.arguments is Map<String, dynamic>) {
              final args = settings.arguments as Map<String, dynamic>;
              final widgetIdValue = args['widgetId'];
              if (widgetIdValue is int) {
                habitTimerWidgetId = widgetIdValue;
              } else if (widgetIdValue is String) {
                habitTimerWidgetId = int.tryParse(widgetIdValue);
              }
            } else if (settings.arguments is int) {
              habitTimerWidgetId = settings.arguments as int;
            }

            return RouteHelpers.createRoute(
              HabitTimerSelectorScreen(widgetId: habitTimerWidgetId),
            );
          },
          description: '习惯计时器小组件配置界面（别名）',
        ),

        // 习惯周视图小组件配置界面
        RouteDefinition(
          path: '/habits_weekly_config',
          handler: (settings) {
            int? habitsWeeklyWidgetId;

            if (settings.arguments is Map<String, dynamic>) {
              final args = settings.arguments as Map<String, dynamic>;
              final widgetIdValue = args['widgetId'];
              if (widgetIdValue is int) {
                habitsWeeklyWidgetId = widgetIdValue;
              } else if (widgetIdValue is String) {
                habitsWeeklyWidgetId = int.tryParse(widgetIdValue);
              }
            } else if (settings.arguments is int) {
              habitsWeeklyWidgetId = settings.arguments as int;
            }

            if (habitsWeeklyWidgetId == null) {
              return RouteHelpers.createErrorRoute('error', 'errorWidgetIdMissing');
            }

            return RouteHelpers.createRoute(
              HabitsWeeklyConfigScreen(widgetId: habitsWeeklyWidgetId),
            );
          },
          description: '习惯周视图小组件配置界面',
        ),
        RouteDefinition(
          path: 'habits_weekly_config',
          handler: (settings) {
            int? habitsWeeklyWidgetId;

            if (settings.arguments is Map<String, dynamic>) {
              final args = settings.arguments as Map<String, dynamic>;
              final widgetIdValue = args['widgetId'];
              if (widgetIdValue is int) {
                habitsWeeklyWidgetId = widgetIdValue;
              } else if (widgetIdValue is String) {
                habitsWeeklyWidgetId = int.tryParse(widgetIdValue);
              }
            } else if (settings.arguments is int) {
              habitsWeeklyWidgetId = settings.arguments as int;
            }

            if (habitsWeeklyWidgetId == null) {
              return RouteHelpers.createErrorRoute('error', 'errorWidgetIdMissing');
            }

            return RouteHelpers.createRoute(
              HabitsWeeklyConfigScreen(widgetId: habitsWeeklyWidgetId),
            );
          },
          description: '习惯周视图小组件配置界面（别名）',
        ),

        // 习惯分组列表小组件配置界面
        RouteDefinition(
          path: '/habit_group_list_selector',
          handler: (settings) {
            int? habitGroupListWidgetId;

            if (settings.arguments is Map<String, dynamic>) {
              final args = settings.arguments as Map<String, dynamic>;
              final widgetIdValue = args['widgetId'];
              if (widgetIdValue is int) {
                habitGroupListWidgetId = widgetIdValue;
              } else if (widgetIdValue is String) {
                habitGroupListWidgetId = int.tryParse(widgetIdValue);
              }
            } else if (settings.arguments is int) {
              habitGroupListWidgetId = settings.arguments as int;
            }

            return RouteHelpers.createRoute(
              HabitGroupListSelectorScreen(widgetId: habitGroupListWidgetId),
            );
          },
          description: '习惯分组列表小组件配置界面',
        ),
        RouteDefinition(
          path: 'habit_group_list_selector',
          handler: (settings) {
            int? habitGroupListWidgetId;

            if (settings.arguments is Map<String, dynamic>) {
              final args = settings.arguments as Map<String, dynamic>;
              final widgetIdValue = args['widgetId'];
              if (widgetIdValue is int) {
                habitGroupListWidgetId = widgetIdValue;
              } else if (widgetIdValue is String) {
                habitGroupListWidgetId = int.tryParse(widgetIdValue);
              }
            } else if (settings.arguments is int) {
              habitGroupListWidgetId = settings.arguments as int;
            }

            return RouteHelpers.createRoute(
              HabitGroupListSelectorScreen(widgetId: habitGroupListWidgetId),
            );
          },
          description: '习惯分组列表小组件配置界面（别名）',
        ),

        // 习惯计时器对话框（从小组件打开）
        RouteDefinition(
          path: '/habit_timer_dialog',
          handler: (settings) {
            String? habitId;

            if (settings.arguments is Map<String, dynamic>) {
              habitId = (settings.arguments as Map<String, dynamic>)['habitId'];
            } else if (settings.arguments is String) {
              habitId = settings.arguments as String;
            }

            if (habitId == null) {
              return RouteHelpers.createErrorRoute('error', 'errorHabitIdRequired');
            }

            final habitsPlugin = PluginManager.instance.getPlugin('habits') as HabitsPlugin?;
            if (habitsPlugin == null) {
              return RouteHelpers.createErrorRoute('error', 'errorHabitsPluginNotFound');
            }

            final habitController = habitsPlugin.getHabitController();
            final habits = habitController.getHabits();
            final habit = habits.cast<dynamic>().firstWhere(
              (h) => h.id == habitId,
              orElse: () => null,
            );

            if (habit == null) {
              return RouteHelpers.createErrorRoute(
                'error',
                'errorHabitNotFound',
                messageParam: habitId,
              );
            }

            return RouteHelpers.createRoute(
              Scaffold(
                backgroundColor: Colors.black.withOpacity(0.5),
                body: Center(
                  child: TimerDialog(
                    habit: habit,
                    controller: habitController,
                    initialTimerData: habitsPlugin.timerController.getTimerData(
                      habitId,
                    ),
                  ),
                ),
              ),
            );
          },
          description: '习惯计时器对话框',
        ),
        RouteDefinition(
          path: 'habit_timer_dialog',
          handler: (settings) {
            String? habitId;

            if (settings.arguments is Map<String, dynamic>) {
              habitId = (settings.arguments as Map<String, dynamic>)['habitId'];
            } else if (settings.arguments is String) {
              habitId = settings.arguments as String;
            }

            if (habitId == null) {
              return RouteHelpers.createErrorRoute('error', 'errorHabitIdRequired');
            }

            final habitsPlugin = PluginManager.instance.getPlugin('habits') as HabitsPlugin?;
            if (habitsPlugin == null) {
              return RouteHelpers.createErrorRoute('error', 'errorHabitsPluginNotFound');
            }

            final habitController = habitsPlugin.getHabitController();
            final habits = habitController.getHabits();
            final habit = habits.cast<dynamic>().firstWhere(
              (h) => h.id == habitId,
              orElse: () => null,
            );

            if (habit == null) {
              return RouteHelpers.createErrorRoute(
                'error',
                'errorHabitNotFound',
                messageParam: habitId,
              );
            }

            return RouteHelpers.createRoute(
              Scaffold(
                backgroundColor: Colors.black.withOpacity(0.5),
                body: Center(
                  child: TimerDialog(
                    habit: habit,
                    controller: habitController,
                    initialTimerData: habitsPlugin.timerController.getTimerData(
                      habitId,
                    ),
                  ),
                ),
              ),
            );
          },
          description: '习惯计时器对话框（别名）',
        ),
      ];
}
