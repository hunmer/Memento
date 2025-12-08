import 'core_localizations.dart';

/// Core module English localization
class CoreLocalizationsEn extends CoreLocalizations {
  @override
  String get starting => 'Starting...';

  @override
  String get inputJavaScriptCode => 'Input JavaScript Code';

  @override
  String get cancel => 'Cancel';

  @override
  String get execute => 'Execute';

  @override
  String get save => 'Save';

  @override
  String get executionResult => 'Execution Result';

  @override
  String executionStatus(bool success) => 'Execution Status: ${success ? "Success" : "Failed"}';

  @override
  String get outputData => 'Output Data:';

  @override
  String get errorMessage => 'Error Message:';

  @override
  String get close => 'Close';

  @override
  String get inputFloatingBallJavaScriptCode => 'Input Floating Ball JavaScript Code';

  @override
  String get configMigration => 'Configuration Migration';

  @override
  String get migrating => 'Migrating...';

  @override
  String get startMigration => 'Start Migration';

  @override
  String get notSelected => 'Not Selected';

  @override
  String get selectColor => 'Select Color';

  @override
  String get iconSelectorNotImplemented => 'Icon Selector (Not Implemented)';

  @override
  String get sequentialExecution => 'Sequential Execution';

  @override
  String get parallelExecution => 'Parallel Execution';

  @override
  String get conditionalExecution => 'Conditional Execution';

  @override
  String get executeAllActions => 'Execute All Actions';

  @override
  String get executeAnyAction => 'Execute Any Action';

  @override
  String get executeFirstOnly => 'Execute First Only';

  @override
  String get executeLastOnly => 'Execute Last Only';

  @override
  String get addAction => 'Add Action';

  @override
  String get edit => 'Edit';

  @override
  String get moveUp => 'Move Up';

  @override
  String get moveDown => 'Move Down';

  @override
  String get delete => 'Delete';

  @override
  String get clearSettings => 'Clear Settings';

  @override
  String get confirm => 'Confirm';

  @override
  String get noActionsFound => 'No actions found';

  @override
  String get confirmDelete => 'Confirm Delete';

  @override
  String confirmDeleteButton(String title) => 'Are you sure to delete button "$title"?';

  @override
  String get floatingButtonManager => 'Floating Button Manager';

  @override
  String get addFirstButton => 'Add First Button';

  @override
  String get clearIconImage => 'Clear Icon/Image';

  @override
  String confirmClearIconImage() => 'Are you sure to clear the current icon and image settings?';

  @override
  String get clear => 'Clear';

  @override
  String get selectIcon => 'Select Icon';

  @override
  String get routeError => 'Route Error';

  @override
  String routeNotFound(String routeName) => 'Route not found: $routeName';

  @override
  String get createActionGroup => 'Create Action Group';

  @override
  String get pleaseAddAtLeastOneAction => 'Please add at least one action';

  @override
  String get singleAction => 'Single Action';

  @override
  String get actionGroup => 'Action Group';

  @override
  String get customAction => 'Custom';

  @override
  String get noActionGroups => 'No Action Groups';

  @override
  String get noCustomActions => 'No Custom Actions';

  @override
  String get selectAction => 'Select Action';

  @override
  String get searchActions => 'Search actions...';

  @override
  String get actionConfig => 'Action Configuration';

  @override
  String get noDescription => 'No Description';

  @override
  String actionsCount(int count) => '$count actions';

  @override
  String get editActionGroup => 'Edit Action Group';

  @override
  String get createActionGroupTitle => 'Create Action Group';

  @override
  String get basicInfo => 'Basic Information';

  @override
  String get groupTitle => 'Group Title';

  @override
  String get enterActionGroupTitle => 'Enter action group title';

  @override
  String get pleaseEnterGroupTitle => 'Please enter group title';

  @override
  String get groupDescription => 'Group Description';

  @override
  String get enterActionGroupDescription => 'Enter action group description (optional)';

  @override
  String get executionConfig => 'Execution Configuration';

  @override
  String get operator => 'Operator';

  @override
  String get selectExecutionMethod => 'Select execution method';

  @override
  String get executionMode => 'Execution Mode';

  @override
  String get selectExecutionMode => 'Select execution mode';

  @override
  String get priority => 'Priority';

  @override
  String get priorityDescription => 'Higher numbers have higher priority';

  @override
  String get actionList => 'Action List';

  @override
  String get noActionsAdded => 'No actions added, click the button above to add';
}
