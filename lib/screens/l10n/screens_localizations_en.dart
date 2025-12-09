import 'dart:ui';

import 'screens_localizations.dart';

class ScreensLocalizationsEn extends ScreensLocalizations {
  const ScreensLocalizationsEn() : super(const Locale('en'));

  // route.dart
  @override
  String get error => 'Error';
  @override
  String get errorWidgetIdMissing => 'Error: widgetId parameter is missing';
  @override
  String get errorHabitIdRequired => 'Error: habitId is required';
  @override
  String get errorHabitsPluginNotFound => 'Error: HabitsPlugin not found';
  @override
  String errorHabitNotFound(String id) => 'Error: Habit not found with id: $id';

  // floating_widget_screen
  @override
  String get floatingBallSettings => 'Floating Ball Settings';
  @override
  String get requestPermission => 'Request Permission';
  @override
  String get floatingBallConfig => 'Floating Ball Configuration';
  @override
  String get customizeFloatingBallAppearanceBehavior => 'Customize the appearance and behavior of the floating ball';
  @override
  String get selectImageAsFloatingBall => 'Select image as floating ball';
  @override
  String get sizeColon => 'Size: ';
  @override
  String ballSizeDp(int size) => '${size}dp';
  @override
  String get snapThresholdColon => 'Snap Threshold: ';
  @override
  String snapThresholdPx(int threshold) => '${threshold}px';
  @override
  String get autoRestoreFloatingBallState => 'Auto restore floating ball state';
  @override
  String get buttonCountColon => 'Button Count: ';
  @override
  String buttonCount(int count) => '$count buttons';
  @override
  String get manageFloatingButtons => 'Manage Floating Buttons';
  @override
  String get currentPosition => 'Current Position';

  // home_screen
  @override
  String get createNewFolder => 'Create New Folder';
  @override
  String get addWidget => 'Add Widget';
  @override
  String get saveCurrentLayout => 'Save Current Layout';
  @override
  String get manageLayouts => 'Manage Layouts';
  @override
  String get themeSettings => 'Theme Settings';
  @override
  String get gridSettings => 'Grid Settings';
  @override
  String get clearLayout => 'Clear Layout';
  @override
  String get confirmClear => 'Confirm Clear';
  @override
  String get confirmClearAllWidgets => 'Are you sure you want to clear all widgets? This action cannot be undone.';
  @override
  String get cancel => 'Cancel';
  @override
  String get confirm => 'Confirm';
  @override
  String get adjustSize => 'Adjust Size';
  @override
  String get delete => 'Delete';
  @override
  String get selectWidgetSize => 'Select Widget Size';
  @override
  String get confirmDelete => 'Confirm Delete';
  @override
  String confirmDeleteItem(String itemName) => 'Are you sure you want to delete "$itemName"?';
  @override
  String get moveToFolder => 'Move to Folder';
  @override
  String get topDisplay => 'Top Display';
  @override
  String get centerDisplay => 'Center Display';
  @override
  String get complete => 'Complete';
  @override
  String get clearFilterConditions => 'Clear filter conditions';

  // background_settings_page
  @override
  String get globalBackgroundSettings => 'Global Background Settings';
  @override
  String get selectImage => 'Select Image';
  @override
  String get fillMode => 'Fill Mode';
  @override
  String get cover => 'Cover';
  @override
  String get contain => 'Contain';
  @override
  String get fill => 'Fill';
  @override
  String get fitWidth => 'Fit Width';
  @override
  String get fitHeight => 'Fit Height';
  @override
  String get none => 'None';
  @override
  String get scaleDown => 'Scale Down';
  @override
  String get blurLevel => 'Blur Level';
  @override
  String get save => 'Save';
  @override
  String get globalBackgroundImage => 'Global Background Image';

  // create_folder_dialog
  @override
  String get selectIcon => 'Select Icon';
  @override
  String get selectColor => 'Select Color';
  @override
  String get create => 'Create';

  // folder_dialog
  @override
  String get folderHasBeenDeleted => 'Folder has been deleted';
  @override
  String get moveOutOfFolder => 'Move out of folder';
  @override
  String get confirmDeleteThisItem => 'Are you sure you want to delete this item?';
  @override
  String get moveFromHomePage => 'Move from home page';
  @override
  String moveIn(int count) => 'Move in ($count)';
  @override
  String get editFolder => 'Edit Folder';

  // home_card
  @override
  String get cannotOpenPlugin => 'Cannot open plugin';

  // home_grid
  @override
  String get quickCreateLayout => 'Quick Create Layout';
  @override
  String get selectLayoutTemplate => 'Select a layout template to get started quickly:';
  @override
  String get dragToFolder => 'Drag to folder';
  @override
  String dragItemToFolder(String item, String folder) => 'Drag "$item" to folder "$folder"';
  @override
  String get pleaseSelectAction => 'Please select an action:';
  @override
  String get replacePosition => 'Replace Position';
  @override
  String get addToFolder => 'Add to Folder';

  // layout_manager_dialog
  @override
  String get renameLayout => 'Rename Layout';
  @override
  String confirmDeleteLayout(String layoutName) => 'Are you sure you want to delete layout "$layoutName"? This action cannot be undone.';
  @override
  String get layoutManagement => 'Layout Management';
  @override
  String layoutInfo(int items, int columns) => '$items widgets · $columns columns grid';
  @override
  String get switchToThisLayout => 'Switch to this layout';
  @override
  String get rename => 'Rename';
  @override
  String get close => 'Close';

  // layout_type_selector
  @override
  String get emptyLayout => 'Empty Layout';
  @override
  String get emptyLayoutDescription => 'Blank layout without any widgets';
  @override
  String get all1x1Widgets => 'All 1x1 Widgets';
  @override
  String get all1x1WidgetsDescription => 'Add all widgets supporting 1x1 size';
  @override
  String get all2x2Widgets => 'All 2x2 Widgets';
  @override
  String get all2x2WidgetsDescription => 'Add all widgets supporting 2x2 size';

  // widget_settings_dialog
  @override
  String get oneColumn => 'One Column';
  @override
  String get twoColumns => 'Two Columns';
  @override
  String get backgroundImage => 'Background Image';
  @override
  String get alreadySet => 'Already Set';
  @override
  String get notSet => 'Not Set';
  @override
  String get iconColor => 'Icon Color';
  @override
  String get customized => 'Customized';
  @override
  String get useDefault => 'Use Default';
  @override
  String get backgroundColor => 'Background Color';
  @override
  String get effectWhenNoBackgroundImage => 'Effective when no background image';
  @override
  String get customColorWithTransparency => 'Custom color (with transparency support)';

  // intent_test_screen
  @override
  String get quickRegisterIntent => 'Quick Register Intent';
  @override
  String get selectPresetIntentType => 'Select a preset Intent type for quick registration';
  @override
  String get mementoTest => 'Memento Test (memento:///test)';
  @override
  String get mementoComplete => 'Memento Complete (memento://app.example.com/open)';
  @override
  String get customApp => 'Custom App (myapp://custom.host)';
  @override
  String get intentTest => 'Intent Test';
  @override
  String get quickRegister => 'Quick Register';
  @override
  String bulletScheme(String scheme) => '• $scheme';

  // js_console
  @override
  String get jsConsole => 'JS Console';
  @override
  String get loadingExamples => 'Loading examples...';
  @override
  String get noAvailableExamples => 'No available examples';
  @override
  String get selectExampleFile => 'Select example file: ';
  @override
  String get allExamples => 'All Examples';

  // json_dynamic_test
  @override
  String get jsonDynamicUITest => 'JSON Dynamic UI Test';
  @override
  String get loadFile => 'Load File';
  @override
  String get previewEffect => 'Preview Effect';
  @override
  String get uiPreview => 'UI Preview';

  // notification_test
  @override
  String get notificationTestPage => 'Notification Test Page';
  @override
  String get test => 'Test';

  // settings_screen
  @override
  String get testJavaScriptAPI => 'Test JavaScript API functionality';
  @override
  String get jsonDynamicWidgetTest => 'JSON Dynamic Widget Test';
  @override
  String get testAndPreviewDynamicUI => 'Test and preview dynamic UI components';
  @override
  String get superCupertinoNavigationTest => 'Super Cupertino Navigation Test';
  @override
  String get testIOSStyleNavigation => 'Test iOS style navigation bar component';
  @override
  String get notificationTest => 'Notification Test';
  @override
  String get manageSystemFloatingBall => 'Manage system-level floating ball functionality';
  @override
  String get testDynamicIntentAndDeepLink => 'Test dynamic Intent registration and deep linking';

  // base_settings_controller
  @override
  String get selectLanguage => 'Select Language';
  @override
  String get chinese => 'Chinese';
  @override
  String get english => 'English';

  // super_cupertino_test_screen
  @override
  String get superCupertinoTest => 'Super Cupertino Test';
  @override
  String get fruitList => 'Fruit List';
  @override
  String fruitIndex(int index) => 'This is the ${index + 1}th fruit';

  // Additional messages
  @override
  String get floatingBallStarted => 'Floating ball started';
  @override
  String get floatingBallStopped => 'Floating ball stopped';
  @override
  String get pleaseEnterLayoutName => 'Please enter layout name';
  @override
  String get notificationPermissionGranted => 'Notification permission granted';
  @override
  String get notificationPermissionDenied => 'Notification permission denied';
  @override
  String get saveSuccess => 'Saved successfully';
  @override
  String get allWidgetsCleared => 'All widgets cleared';
  @override
  String layoutSaved(String name) => 'Layout "$name" saved';
  @override
  String get saveFailed => 'Save failed';
  @override
  String get noImage => 'No image';
  @override
  String get imageLoadFailed => 'Failed to load image';
  @override
  String get pleaseSelectImage => 'Please select an image';
  @override
  String get copySuccess => 'Copy successful';
  @override
  String get copiedToClipboard => 'Copied to clipboard';
  @override
  String get sendNotification => 'Send notification';
  @override
  String get notificationSent => 'Notification sent';
  @override
  String get noTestSchemeAvailable => 'No test scheme available';
  @override
  String get widgetSettings => 'Widget Settings';
  @override
  String itemCount(int count) => '$count items';
  @override
  String layoutBackgroundSettings(String layoutName) =>
      '$layoutName - Background Settings';
  @override
  String get layoutBackgroundSettingsTitle => 'Layout Background Settings';
  @override
  String get addWidgets => 'Add Widgets';
  @override
  String get clear => 'Clear';
  @override
  String get newLayout => 'New Layout';

  // Additional floating ball messages
  @override
  String get permissionGranted => 'Permission granted';
  @override
  String get permissionDenied => 'Permission denied';
  @override
  String get floatingBallStatus => 'Floating Ball Status';
  @override
  String get running => 'Running';
  @override
  String get stopped => 'Stopped';
  @override
  String get floatingWindowPermission => 'Floating Window Permission';
  @override
  String get granted => 'Granted';
  @override
  String get notGranted => 'Not Granted';
  @override
  String get floatingBallSwitch => 'Floating Ball Switch';
  @override
  String get clickToStop => 'Click to Stop';
  @override
  String get clickToStart => 'Click to Start';
  @override
  String get autoHideInApp => 'Auto Hide In App';
  @override
  String get autoHideInAppDescription => 'Auto hide overlay floating ball in app';
  @override
  String clickedButton(String buttonName) => 'Clicked: $buttonName';
  @override
  String xPositionYPosition(double x, double y) => 'X: ${x.toStringAsFixed(0)}, Y: ${y.toStringAsFixed(0)}';

  // Additional home screen messages
  @override
  String confirmDeleteSelectedItems(int count) => 'Are you sure you want to delete the selected $count items?';
  @override
  String widgetSize(int width, int height) => '${width}x${height}';
  @override
  String get smallSize => 'Small (Icon)';
  @override
  String get mediumSize => 'Medium (Horizontal Card)';
  @override
  String get largeSize => 'Large (Square Card)';
  @override
  String get noLayoutName => 'No layout name';
  @override
  String get quickCreateLayoutDescription => 'Select a layout template to get started quickly:';
  @override
  String get createNewLayout => 'Create New Layout';
  @override
  String get inputLayoutName => 'Please enter layout name';
  @override
  String get layoutName => 'Layout Name';
  @override
  String get layoutNameHint => 'e.g., Work Layout, Entertainment Layout';
  @override
  String get deleted => 'deleted';
  @override
  String itemsDeleted(int count) => 'Deleted $count items';
  @override
  String get noAvailableFolders => 'No available folders, please create a folder first';
  @override
  String itemsMovedToFolder(int count) => 'Moved $count items to folder';
  @override
  String get gridSize => 'Grid Size';
  @override
  String get gridSizeDescription => 'Select the number of columns for the home grid (1-10)';
  @override
  String gridColumns(int count) => '$count columns';
  @override
  String get displayPosition => 'Display Position';
  @override
  String get displayPositionDescription => 'Choose the alignment of widgets on the screen';
  @override
  String get backgroundImageSet => 'Background image set';
  @override
  String get backgroundImageNotSet => 'Background image not set';
  @override
  String get customBackgroundImage => 'Custom background image set';
  @override
  String get useGlobalBackgroundImage => 'Using global background image';

  // create_folder_dialog
  @override
  String get folderName => 'Folder Name';
  @override
  String get enterFolderName => 'Enter folder name';
  @override
  String get pleaseEnterFolderName => 'Please enter folder name';
  @override
  String folderCreated(String name) => 'Folder created: $name';

  // background_settings_page
  @override
  String get widgetOverallOpacity => 'Widget Overall Opacity';
  @override
  String get widgetOverallOpacityDescription => 'Adjust the opacity of the entire widget (including text and content)';
  @override
  String get backgroundColorOpacity => 'Background Color Opacity';
  @override
  String get backgroundColorOpacityDescription => 'Adjust only the background color opacity, does not affect text';
  @override
  String get layoutBackgroundSettingsDescription => 'Set background images for each layout individually, priority higher than global background image';
  @override
  String get noSavedLayouts => 'No saved layouts';
  @override
  String get saveLayoutFirst => 'Please save a layout on the home page first';
  @override
  String get clearUseGlobalBackground => 'Clear (Use Global Background)';
  @override
  String get customBackgroundHasPriority => 'Individually set background images have priority over global background images';
  @override
  String get zeroPercentFullyTransparent => '0% (Fully Transparent)';
  @override
  String get oneHundredPercentOpaque => '100% (Opaque)';

  // folder_dialog
  @override
  String get folderIsEmpty => 'The folder is empty';
  @override
  String get selectItemsToMoveToFolder => 'Select items to move to folder';
  @override
  String get movedToHomePage => 'Moved to home page';
  @override
  String get folderUpdated => 'Folder updated';
  @override
  String get clickToAddContent => 'Click the + button above to add content';
  @override
  String get noItemsOnHome => 'No items available on home page to move';

  // home_grid
  @override
  String get noWidgetsYet => 'No widgets yet';
  @override
  String get quickLayout => 'Quick Layout';
  @override
  String get component => 'Widget';
  @override
  String get item => 'Item';
  @override
  String get clickPlusToAdd => 'Click the + button in the top right to add';
  @override
  String get loadLayoutFailed => 'Failed to load layout';
  @override
  String get switchedToLayout => 'Switched to';
  @override
  String get switchFailed => 'Failed to switch';
  @override
  String get saveFirstLayoutHint => 'Click "Save Current Layout" in the top right menu to create your first layout configuration';

  // layout_manager_dialog
  @override
  String get renameSuccess => 'Rename successful';
  @override
  String get deleteSuccess => 'Delete successful';

@override
  String get presetColors => 'Preset Colors';
  @override
  String get quickSelectPresetColors => 'Quick Select Preset Colors';
}