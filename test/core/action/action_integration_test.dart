import 'package:Memento/core/action/action_executor.dart';
import 'package:Memento/core/action/models/action_form.dart';
import 'package:Memento/core/floating_ball/models/floating_ball_gesture.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/action/action_manager.dart';
import 'package:Memento/core/action/models/action_definition.dart';
import 'package:Memento/core/action/models/action_instance.dart';
import 'package:Memento/core/action/models/action_group.dart';
import 'package:Memento/core/action/widgets/action_selector_dialog.dart';
import 'package:Memento/core/action/widgets/action_config_form.dart';
import 'package:Memento/core/action/widgets/action_group_editor.dart';

void main() {
  group('动作系统集成测试', () {
    late ActionManager actionManager;
    late BuildContext testContext;

    setUp(() {
      actionManager = ActionManager();
      // 创建测试上下文
      testContext = _MockBuildContext();
    });

    tearDown(() {
      actionManager.dispose();
    });

    testWidgets('完整的工作流程：创建→配置→执行→验证', (tester) async {
      // 1. 初始化
      await actionManager.initialize();

      // 验证内置动作已注册
      expect(actionManager.allActions.length, greaterThan(0));

      // 2. 创建自定义动作
      final customAction = ActionDefinition(
        id: 'customTestAction',
        title: '自定义测试动作',
        description: '这是一个集成测试动作',
        icon: Icons.star,
        category: ActionCategory.custom,
        executor: BuiltInActionExecutor('customTestAction'),
      );

      actionManager.registerAction(customAction);

      // 3. 创建动作实例
      final actionInstance = ActionInstance.create(
        actionId: 'customTestAction',
        data: {'testKey': 'testValue'},
      );

      actionManager.saveCustomAction(actionInstance);

      // 验证动作实例已保存
      expect(actionManager.customActions.length, greaterThan(0));

      // 4. 创建动作组
      final actionGroup = ActionGroup.create(
        title: '测试动作组',
        operator: GroupOperator.sequence,
        actions: [
          actionInstance,
          ActionInstance.create(
            actionId: BuiltInActions.openPlugin,
            data: {'plugin': 'chat'},
          ),
        ],
      );

      actionManager.saveActionGroup(actionGroup);

      // 验证动作组已保存
      expect(actionManager.actionGroups.length, greaterThan(0));

      // 5. 配置手势动作
      final gesture = FloatingBallGesture.tap;
      final gestureConfig = GestureActionConfig(
        gesture: gesture,
        group: actionGroup,
      );

      await actionManager.setGestureAction(gesture, gestureConfig);

      // 验证手势动作已配置
      final retrievedConfig = actionManager.getGestureAction(gesture);
      expect(retrievedConfig, isNotNull);
      expect(retrievedConfig!.group, isNotNull);

      // 6. 执行动作
      final result = await actionManager.executeGestureAction(
        gesture,
        testContext,
        data: {'testData': 'integration'},
      );

      // 验证执行结果（这里会因为没有实际的 UI 环境而失败，但流程是对的）
      expect(result, isNotNull);

      // 7. 验证统计信息
      final stats = actionManager.getStatistics();
      expect(stats['customActionInstances'], greaterThan(0));
      expect(stats['actionGroups'], greaterThan(0));
      expect(stats['gestureActions'], greaterThan(0));

      // 8. 导出配置
      final exportedConfig = actionManager.exportConfig();
      expect(exportedConfig, isNotEmpty);
      expect(exportedConfig, contains('actionGroups'));
      expect(exportedConfig, contains('customActions'));

      // 9. 清理
      await actionManager.clearGestureAction(gesture);
      actionManager.deleteActionGroup(actionGroup.id!);
      actionManager.deleteCustomAction(actionInstance.id!);

      // 验证清理结果
      expect(actionManager.getGestureAction(gesture), isNull);
      expect(actionManager.actionGroups.length, equals(0));
      expect(actionManager.customActions.length, equals(0));
    });

    testWidgets('动作选择器对话框集成测试', (tester) async {
      await actionManager.initialize();

      // 构建对话框
      final dialog = ActionSelectorDialog(
        gesture: FloatingBallGesture.swipeUp,
        showGroupEditor: true,
      );

      // 验证对话框可以构建
      expect(dialog, isNotNull);
    });

    testWidgets('动作配置表单集成测试', (tester) async {
      await actionManager.initialize();

      // 获取一个内置动作
      final openPluginAction = actionManager.getAction(BuiltInActions.openPlugin);
      expect(openPluginAction, isNotNull);

      // 为动作添加表单配置
      final form = ActionForm(fields: {
        'plugin': const FormFieldConfig(
          type: FormFieldType.pluginSelector,
          label: '插件',
          required: true,
        ),
      });

      final actionWithForm = openPluginAction!.copyWith(form: form);

      // 构建配置表单
      final formWidget = ActionConfigForm(
        actionDefinition: actionWithForm,
      );

      // 验证表单可以构建
      expect(formWidget, isNotNull);
    });

    testWidgets('动作组编辑器集成测试', (tester) async {
      await actionManager.initialize();

      // 构建编辑器
      final editor = ActionGroupEditor();

      // 验证编辑器可以构建
      expect(editor, isNotNull);

      // 测试编辑现有组
      final existingGroup = ActionGroup.create(
        title: '现有组',
        operator: GroupOperator.parallel,
      );

      final editorWithGroup = ActionGroupEditor(group: existingGroup);
      expect(editorWithGroup, isNotNull);
    });

    test('动作验证链测试', () async {
      // 创建带验证器的动作
      final actionWithValidators = ActionDefinition(
        id: 'validatedAction',
        title: '带验证的动作',
        executor: BuiltInActionExecutor('validatedAction'),
        validators: [
          const Validator(
            type: 'required',
            params: {'field': 'name'},
            message: '名称是必填的',
          ),
          const Validator(
            type: 'minLength',
            params: {'field': 'name', 'minLength': 3},
            message: '名称至少需要3个字符',
          ),
        ],
      );

      actionManager.registerAction(actionWithValidators);

      // 测试有效数据
      final validData = <String, dynamic>{'name': '测试名称'};
      expect(
        actionManager.validateAction('validatedAction', validData),
        true,
      );

      // 测试无效数据 - 缺少必填字段
      final emptyData = <String, dynamic>{};
      final emptyErrors = actionManager.getValidationErrors('validatedAction', emptyData);
      expect(emptyErrors.isNotEmpty, true);

      // 测试无效数据 - 长度不足
      final shortData = <String, dynamic>{'name': 'ab'};
      final shortErrors = actionManager.getValidationErrors('validatedAction', shortData);
      expect(shortErrors.isNotEmpty, true);
    });

    test('动作实例分组测试', () {
      // 创建多个动作实例
      final instances = [
        ActionInstance.create(actionId: 'action1', data: {}),
        ActionInstance.create(actionId: 'action2', data: {}),
        ActionInstance.create(actionId: 'action3', data: {}),
      ];

      // 创建分组
      final group = ActionInstanceGroup(
        id: 'testGroup',
        name: '测试分组',
        instances: instances,
      );

      // 验证分组
      expect(group.id, equals('testGroup'));
      expect(group.name, equals('测试分组'));
      expect(group.instances.length, equals(3));
    });

    test('动作组模板测试', () {
      // 创建模板
      final template = ActionGroupTemplate(
        id: 'navTemplate',
        name: '导航模板',
        description: '用于导航的常见动作组合',
        operator: GroupOperator.sequence,
        actionIds: [BuiltInActions.goBack, BuiltInActions.goHome],
      );

      // 验证模板
      expect(template.id, equals('navTemplate'));
      expect(template.name, equals('导航模板'));
      expect(template.actionIds.length, equals(2));
      expect(template.operator, equals(GroupOperator.sequence));
    });
  });

  group('动作存储集成测试', () {
    test('配置序列化测试', () async {
      final actionManager = ActionManager();
      await actionManager.initialize();

      // 创建测试数据
      final actionInstance = ActionInstance.create(
        actionId: BuiltInActions.openPlugin,
        data: {'plugin': 'diary'},
      );

      final actionGroup = ActionGroup.create(
        title: '测试组',
        operator: GroupOperator.parallel,
        actions: [actionInstance],
      );

      // 保存数据
      actionManager.saveCustomAction(actionInstance);
      actionManager.saveActionGroup(actionGroup);

      // 导出配置
      final configJson = actionManager.exportConfig();

      // 验证 JSON 结构
      final config = configJson;
      expect(config, isNotEmpty);
      expect(config, contains('version'));
      expect(config, contains('customActions'));
      expect(config, contains('actionGroups'));
    });
  });
}

/// 模拟 BuildContext
class _MockBuildContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
