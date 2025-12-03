import 'package:Memento/core/action/models/action_form.dart';
import 'package:Memento/core/action/models/action_group.dart';
import 'package:Memento/core/floating_ball/models/floating_ball_gesture.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/action/action_manager.dart';
import 'package:Memento/core/action/models/action_definition.dart';
import 'package:Memento/core/action/models/action_instance.dart';
import 'package:Memento/core/action/action_executor.dart';

void main() {
  group('ActionManager', () {
    late ActionManager actionManager;

    setUp(() {
      actionManager = ActionManager();
    });

    tearDown(() {
      actionManager.dispose();
    });

    test('应该初始化并注册内置动作', () async {
      await actionManager.initialize();

      expect(actionManager.allActions.length, greaterThan(0));
      expect(actionManager.getBuiltInActions().length, greaterThan(0));
    });

    test('应该能够注册和获取自定义动作', () {
      final testAction = ActionDefinition(
        id: 'testAction',
        title: '测试动作',
        description: '这是一个测试动作',
        icon: Icons.star,
        category: ActionCategory.custom,
        executor: BuiltInActionExecutor('testAction'),
      );

      actionManager.registerAction(testAction);

      expect(actionManager.hasAction('testAction'), true);
      expect(actionManager.getAction('testAction'), equals(testAction));
    });

    test('应该能够注销动作', () {
      actionManager.registerAction(ActionDefinition(
        id: 'toRemove',
        title: '待删除动作',
        executor: BuiltInActionExecutor('toRemove'),
      ));

      expect(actionManager.hasAction('toRemove'), true);

      actionManager.unregisterAction('toRemove');

      expect(actionManager.hasAction('toRemove'), false);
    });

    test('应该能够按分类获取动作', () async {
      await actionManager.initialize();

      final navigationActions = actionManager.getActionsByCategory(
        ActionCategory.navigation,
      );

      expect(navigationActions.length, greaterThan(0));
      for (final action in navigationActions) {
        expect(
          action.category,
          equals(ActionCategory.navigation),
        );
      }
    });

    test('应该能够验证动作参数', () {
      final testAction = ActionDefinition(
        id: 'testWithForm',
        title: '带表单的动作',
        executor: BuiltInActionExecutor('testWithForm'),
        form: ActionForm(fields: {
          'name': const FormFieldConfig(
            type: FormFieldType.text,
            label: '名称',
            required: true,
          ),
        }),
      );

      actionManager.registerAction(testAction);

      // 测试有效的参数
      expect(
        actionManager.validateAction('testWithForm', {'name': '测试'}),
        true,
      );

      // 测试无效的参数（缺少必填字段）
      expect(
        actionManager.validateAction('testWithForm', {}),
        false,
      );
    });

    test('应该能够创建和获取手势动作配置', () async {
      await actionManager.initialize();

      final gesture = FloatingBallGesture.tap;
      final actionInstance = ActionInstance.create(
        actionId: BuiltInActions.openPlugin,
        data: {'plugin': 'chat'},
      );

      final config = GestureActionConfig(
        gesture: gesture,
        singleAction: actionInstance,
      );

      await actionManager.setGestureAction(gesture, config);

      final retrievedConfig = actionManager.getGestureAction(gesture);
      expect(retrievedConfig, isNotNull);
      expect(retrievedConfig!.singleAction, isNotNull);
      expect(
        retrievedConfig.singleAction!.actionId,
        equals(BuiltInActions.openPlugin),
      );
    });

    test('应该能够清除手势动作配置', () async {
      await actionManager.initialize();

      final gesture = FloatingBallGesture.swipeUp;
      final config = GestureActionConfig(
        gesture: gesture,
        singleAction: ActionInstance.create(
          actionId: BuiltInActions.goBack,
        ),
      );

      await actionManager.setGestureAction(gesture, config);
      expect(actionManager.getGestureAction(gesture), isNotNull);

      await actionManager.clearGestureAction(gesture);
      expect(actionManager.getGestureAction(gesture), isNull);
    });

    test('应该返回正确的统计信息', () async {
      await actionManager.initialize();

      final Map<String, dynamic> stats = actionManager.getStatistics();

      expect(stats.containsKey('totalActions'), true);
      expect(stats.containsKey('builtInActions'), true);
      expect(stats.containsKey('customActions'), true);
      expect(stats.containsKey('actionGroups'), true);
      expect(stats.containsKey('customActionInstances'), true);
      expect(stats.containsKey('gestureActions'), true);

      expect(stats['builtInActions'], greaterThan(0));
    });

    test('应该能够导出配置', () async {
      await actionManager.initialize();

      final exportedConfig = actionManager.exportConfig();

      expect(exportedConfig, isNotEmpty);
      expect(exportedConfig, contains('version'));
      expect(exportedConfig, contains('actions'));
    });

    test('应该能够处理不存在的动作', () {
      expect(
        () => actionManager.hasAction('nonExistentAction'),
        false,
      );
    });

    test('应该能够注册多个动作', () {
      final actions = [
        ActionDefinition(
          id: 'action1',
          title: '动作1',
          executor: BuiltInActionExecutor('action1'),
        ),
        ActionDefinition(
          id: 'action2',
          title: '动作2',
          executor: BuiltInActionExecutor('action2'),
        ),
        ActionDefinition(
          id: 'action3',
          title: '动作3',
          executor: BuiltInActionExecutor('action3'),
        ),
      ];

      actionManager.registerActions(actions);

      expect(actionManager.hasAction('action1'), true);
      expect(actionManager.hasAction('action2'), true);
      expect(actionManager.hasAction('action3'), true);
    });
  });

  group('ActionInstance', () {
    test('应该能够创建动作实例', () {
      final instance = ActionInstance.create(
        actionId: 'testAction',
        data: {'key': 'value'},
      );

      expect(instance.id, isNotNull);
      expect(instance.actionId, equals('testAction'));
      expect(instance.data, equals({'key': 'value'}));
      expect(instance.enabled, true);
    });

    test('应该能够更新执行统计', () {
      final instance = ActionInstance.create(
        actionId: 'testAction',
      );

      final updated = instance.updateExecution(
        success: true,
        executionTime: 100,
      );

      expect(updated.executionCount, equals(1));
      expect(updated.successCount, equals(1));
      expect(updated.failureCount, equals(0));
      expect(updated.averageExecutionTime, equals(100));
    });

    test('应该能够启用/禁用动作', () {
      final instance = ActionInstance.create(
        actionId: 'testAction',
      );

      final disabled = instance.setEnabled(false);
      expect(disabled.enabled, false);
      expect(disabled.status, equals(ActionInstanceStatus.disabled));

      final enabled = disabled.setEnabled(true);
      expect(enabled.enabled, true);
      expect(enabled.status, equals(ActionInstanceStatus.enabled));
    });
  });

  group('ActionGroup', () {
    test('应该能够创建动作组', () {
      final group = ActionGroup.create(
        title: '测试组',
        operator: GroupOperator.sequence,
        actions: [
          ActionInstance.create(actionId: 'action1'),
          ActionInstance.create(actionId: 'action2'),
        ],
      );

      expect(group.id, isNotNull);
      expect(group.title, equals('测试组'));
      expect(group.operator, equals(GroupOperator.sequence));
      expect(group.actionCount, equals(2));
    });

    test('应该能够添加和移除动作', () {
      final group = ActionGroup.create(
        title: '测试组',
        operator: GroupOperator.sequence,
      );

      final action1 = ActionInstance.create(actionId: 'action1');
      final action2 = ActionInstance.create(actionId: 'action2');

      final withActions = group
          .addAction(action1)
          .addAction(action2);

      expect(withActions.actionCount, equals(2));

      final withoutAction1 = withActions.removeAction('action1');
      expect(withoutAction1.actionCount, equals(1));

      final cleared = withoutAction1.clearActions();
      expect(cleared.actionCount, equals(0));
    });

    test('应该能够更新执行统计', () {
      final group = ActionGroup.create(
        title: '测试组',
        operator: GroupOperator.sequence,
        actions: [
          ActionInstance.create(actionId: 'action1'),
        ],
      );

      final updated = group.updateExecution(
        success: true,
        executionTime: 200,
      );

      expect(updated.executionCount, equals(1));
      expect(updated.successCount, equals(1));
      expect(updated.failureCount, equals(0));
      expect(updated.averageExecutionTime, equals(200));
    });
  });
}
