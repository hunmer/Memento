import 'package:flutter/material.dart';

/// OpenAI插件本地化接口
abstract class OpenAILocalizations {
  static OpenAILocalizations of(BuildContext context) {
    final localizations = Localizations.of<OpenAILocalizations>(
      context,
      OpenAILocalizations,
    );
    if (localizations == null) {
      throw FlutterError('No OpenAILocalizations found in context');
    }
    return localizations;
  }

  /// 获取默认本地化实例（中文），用于没有BuildContext的场景
  static OpenAILocalizations get defaultLocalizations =>
      OpenAILocalizationsZh();

  String get pluginName;
  String get pluginDescription;
  String get totalAgents;
  String get defaultAgentName;
  String get defaultAgentDescription;
  String get defaultSystemPrompt;
  String get generalTag;
  String get qaTag;
  String get suggestionsTag;
  String get initDefaultAgent;
  String get errorReadingAgents;

  // Tab titles
  String get form;
  String get output;
  String get noResponseYet;

  String get systemRole;
  String get userRole;
  String get assistantRole;
  String get addPrompt;
  String get promptTypeLabel;
  String get contentLabel;

  // Agent Edit Screen
  String get createAgent;
  String get editAgent;
  String get cloneAgent;
  String get deleteAgent;
  String get saveAgent;
  String get agentName;
  String get enterAgentName;
  String get pleaseEnterName;
  String get serviceProvider;
  String get pleaseSelectProvider;
  String get updateConfig;
  String get useDefaultConfig;
  String get keepCurrentConfig;
  String get updateConfigConfirm;
  String get configUpdated;
  String get undoAction;
  String get description;
  String get enterDescription;
  String get pleaseEnterDescription;
  String get systemPrompt;
  String get enterSystemPrompt;
  String get pleaseEnterSystemPrompt;
  String get baseUrl;
  String get enterBaseUrl;
  String get pleaseEnterBaseUrl;
  String get model;
  String get enterModel;
  String get searchModel;
  String get headers;
  String get enterHeaders;
  String get tags;
  String get enterTag;
  String get testAgent;
  String get avatar;
  String get deleteAgentConfirm;
  String get deleteAgentMessage;
  String get cancel;
  String get delete;
  String get agentDeleted;
  String get deleteFailed;
  String get agentCloned;
  String get cloneFailed;
  String get copy;
  String get errorSavingAgent;
  String get testAgentTitle;
  String get enterTestText;
  String get testError;
  String get loadingProviders;
  String get loadProvidersError;

  // Agent List Screen
  String get agentListTitle;
  String get toolsTitle;
  String get agentsTab;
  String get toolsTab;

  // Model List Screen
  String get modelManagement;
  String get noModelsFound;
  String get cannotLoadModels;
  String get loadModelsFailed;
  String get addModelFailed;
  String get updateModelFailed;
  String get deleteModelFailed;
  String get confirmDelete;
  String get confirmDeleteModel;
  String get addModel;
  String get editModel;
  String get modelId;
  String get modelIdExample;
  String get pleaseEnterModelId;
  String get modelName;
  String get modelNameExample;
  String get pleaseEnterModelName;
  String get modelGroup;
  String get pleaseSelectModelGroup;
  String get save;

  // Test Service
  String get lastInputLoadFailed;
  String get testInput;
  String get loadLastInput;
  String get clearInput;
  String get selectImage;
  String get noImageSelected;
  String get selectedImage;
  String get imageLoadFailed;
  String get testResponse;
  String get close;
  String get previewImages;
  String get errorDetails;
  String get checkItems;
  String get apiKeyConfig;
  String get networkConnection;
  String get serviceEndpoint;

  // Plugin Analysis Form
  String get pluginAnalysis;
  String get confirm;
  String get selectAgent;
  String get pleaseSelectAgentFirst;
  String get pleaseEnterPrompt;
  String get sendingFailed;
  String get noAgentSelected;
  String get selectAgentTooltip;
  String get prompt;
  String get addAnalysisMethod;
  String get agentResponse;
  String get sendRequest;

  String get filterAgents;

  String get apply;

  String get selectAnalysisMethod;

  String get noToolsAvailable;

  String get confirmDeleteProviderTitle;

  get confirmDeleteProviderMessage;

  String get providerSettingsTitle;

  get addProviderTooltip;

  String get noProvidersConfigured;

  String get addProviderButton;

  String get modelManagementDescription;
}

/// 中文实现
class OpenAILocalizationsZh implements OpenAILocalizations {
  @override
  String get pluginName => 'AI 助手';

  @override
  String get pluginDescription => 'AI 助手插件，支持多种大语言模型服务商';

  @override
  String get pluginAnalysis => '插件分析';

  @override
  String get form => '表单';

  @override
  String get output => '输出';

  @override
  String get noResponseYet => '暂无响应';

  @override
  String get confirm => '确认';

  @override
  String get selectAgent => '选择智能体';

  @override
  String get noAgentSelected => '未选择智能体';

  @override
  String get selectAgentTooltip => '选择智能体';

  @override
  String get prompt => '提示词';

  @override
  String get addAnalysisMethod => '添加分析方法';

  @override
  String get agentResponse => '智能体响应:';

  @override
  String get sendRequest => '发送请求';

  @override
  String get pleaseSelectAgentFirst => '请先选择智能体';

  @override
  String get pleaseEnterPrompt => '请输入提示词';

  @override
  String get sendingFailed => '发送失败: ';

  @override
  String get totalAgents => '智能体总数';

  @override
  String get defaultAgentName => '通用助手';

  @override
  String get defaultAgentDescription => '一个友好的AI助手，可以帮助回答各种问题和完成各种任务。';

  @override
  String get defaultSystemPrompt =>
      '你是一个乐于助人的AI助手，擅长回答问题并提供有用的建议。请用友好的语气与用户交流。';

  @override
  String get generalTag => '通用';

  @override
  String get qaTag => '问答';

  @override
  String get suggestionsTag => '建议';

  @override
  String get initDefaultAgent => '已初始化默认智能体';

  @override
  String get errorReadingAgents => '读取智能体数据出错';

  @override
  String get createAgent => '创建智能体';

  @override
  String get editAgent => '编辑智能体';

  @override
  String get cloneAgent => '克隆智能体';

  @override
  String get deleteAgent => '删除智能体';

  @override
  String get saveAgent => '保存';

  @override
  String get agentName => '名称';

  @override
  String get enterAgentName => '输入智能体名称';

  @override
  String get pleaseEnterName => '请输入名称';

  @override
  String get serviceProvider => '服务商';

  @override
  String get pleaseSelectProvider => '请选择服务商';

  @override
  String get updateConfig => '更新配置';

  @override
  String get useDefaultConfig => '使用默认配置';

  @override
  String get keepCurrentConfig => '保持当前配置';

  @override
  String get updateConfigConfirm => '是否要使用该服务商的默认配置更新当前设置？';

  @override
  String get configUpdated => '已更新为服务商默认配置';

  @override
  String get undoAction => '撤销';

  @override
  String get description => '描述';

  @override
  String get enterDescription => '输入智能体描述';

  @override
  String get pleaseEnterDescription => '请输入描述';

  @override
  String get systemPrompt => '系统提示词';

  @override
  String get enterSystemPrompt => '输入系统提示词';

  @override
  String get pleaseEnterSystemPrompt => '请输入系统提示词';

  @override
  String get baseUrl => '基础URL';

  @override
  String get enterBaseUrl => '输入API调用的基础URL';

  @override
  String get pleaseEnterBaseUrl => '请输入基础URL';

  @override
  String get model => '模型';

  @override
  String get enterModel => '输入模型名称（如：gpt-3.5-turbo）';

  @override
  String get searchModel => '搜索模型';

  @override
  String get headers => '请求头';

  @override
  String get enterHeaders => '输入请求头（每行一个，格式：key: value）';

  @override
  String get tags => '标签';

  @override
  String get enterTag => '输入标签';

  @override
  String get testAgent => '测试智能体';

  @override
  String get avatar => '头像';

  @override
  String get deleteAgentConfirm => '删除智能体';

  @override
  String get deleteAgentMessage => '确定要删除这个智能体吗？此操作不可撤销。';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get agentDeleted => '智能体已删除';

  @override
  String get deleteFailed => '删除失败';

  @override
  String get agentCloned => '智能体已复制';

  @override
  String get cloneFailed => '复制失败';

  @override
  String get copy => '复制';

  @override
  String get errorSavingAgent => '保存智能体时出错';

  @override
  String get testAgentTitle => '测试';

  @override
  String get enterTestText => '请输入测试文本...';

  @override
  String get testError => '测试过程中出错';

  @override
  String get loadingProviders => '加载中...';

  @override
  String get loadProvidersError => '加载服务商失败';

  @override
  String get agentListTitle => 'AI 助手';

  @override
  String get toolsTitle => '工具';

  @override
  String get agentsTab => '智能体';

  @override
  String get toolsTab => '工具';

  @override
  String get modelManagement => '模型管理';

  @override
  String get noModelsFound => '没有找到匹配的模型';

  @override
  String get cannotLoadModels => '无法加载模型列表';

  @override
  String get loadModelsFailed => '加载模型失败';

  @override
  String get addModelFailed => '添加模型失败';

  @override
  String get updateModelFailed => '更新模型失败';

  @override
  String get deleteModelFailed => '删除模型失败';

  @override
  String get confirmDelete => '确认删除';

  @override
  String get confirmDeleteModel => '确定要删除模型 {modelName} 吗？';

  @override
  String get addModel => '添加模型';

  @override
  String get editModel => '编辑模型';

  @override
  String get modelId => '模型ID';

  @override
  String get modelIdExample => '例如: gpt-4';

  @override
  String get pleaseEnterModelId => '请输入模型ID';

  @override
  String get modelName => '模型名称';

  @override
  String get modelNameExample => '例如: GPT-4';

  @override
  String get pleaseEnterModelName => '请输入模型名称';

  @override
  String get modelGroup => '模型组';

  @override
  String get pleaseSelectModelGroup => '请选择模型组';

  @override
  String get save => '保存';

  @override
  String get lastInputLoadFailed => '加载上次输入失败';

  @override
  String get testInput => '测试输入';

  @override
  String get loadLastInput => '加载上次输入';

  @override
  String get clearInput => '清空输入';

  @override
  String get selectImage => '选择图片';

  @override
  String get noImageSelected => '未选择图片';

  @override
  String get selectedImage => '已选择';

  @override
  String get imageLoadFailed => '图片加载失败';

  @override
  String get testResponse => '测试响应';

  @override
  String get close => '关闭';

  @override
  String get previewImages => '预览图片';

  @override
  String get errorDetails => '详细信息';

  @override
  String get checkItems => '请检查';

  @override
  String get apiKeyConfig => 'API密钥是否正确配置';

  @override
  String get networkConnection => '网络连接是否正常';

  @override
  String get serviceEndpoint => '服务端点是否可访问';

  @override
  String get systemRole => '系统';

  @override
  String get userRole => '用户';

  @override
  String get assistantRole => 'AI';

  @override
  String get addPrompt => '添加Prompt';
  @override
  String get promptTypeLabel => 'Prompt类型';
  @override
  String get contentLabel => '内容';

  @override
  String get filterAgents => '筛选智能体';

  @override
  String get apply => '应用';

  @override
  String get selectAnalysisMethod => '选择分析方法';

  @override
  String get noToolsAvailable => '没有可用工具';

  @override
  String get addProviderButton => "Add Provider";

  @override
  get addProviderTooltip => "Add new AI provider";

  @override
  get confirmDeleteProviderMessage =>
      "Are you sure you want to delete this provider?";

  @override
  String get confirmDeleteProviderTitle => "Confirm Delete";

  @override
  String get noProvidersConfigured => "No providers configured";

  @override
  String get providerSettingsTitle => "Provider Settings";

  @override
  String get modelManagementDescription => '管理大语言模型列表';
}

/// 英文实现
class OpenAILocalizationsEn implements OpenAILocalizations {
  @override
  String get pluginAnalysis => 'Plugin Analysis';

  @override
  String get form => 'Form';

  @override
  String get output => 'Output';

  @override
  String get noResponseYet => 'No response yet';

  @override
  String get confirm => 'Confirm';

  @override
  String get selectAgent => 'Select Agent';

  @override
  String get pleaseSelectAgentFirst => 'Please select an agent first';

  @override
  String get pleaseEnterPrompt => 'Please enter a prompt';

  @override
  String get sendingFailed => 'Sending failed: ';

  @override
  String get noAgentSelected => 'No agent selected';

  @override
  String get selectAgentTooltip => 'Select an agent';

  @override
  String get prompt => 'Prompt';

  @override
  String get addAnalysisMethod => 'Add Analysis Method';

  @override
  String get agentResponse => 'Agent Response';

  @override
  String get sendRequest => 'Send Request';

  @override
  String get pluginName => 'AI Assistant';

  @override
  String get pluginDescription =>
      'AI assistant plugin supporting multiple LLM providers';

  @override
  String get totalAgents => 'Total Agents';

  @override
  String get defaultAgentName => 'General Assistant';

  @override
  String get defaultAgentDescription =>
      'A friendly AI assistant that can help answer various questions and complete various tasks.';

  @override
  String get defaultSystemPrompt =>
      'You are a helpful AI assistant who excels at answering questions and providing useful suggestions. Please communicate with users in a friendly tone.';

  @override
  String get generalTag => 'General';

  @override
  String get qaTag => 'Q&A';

  @override
  String get suggestionsTag => 'Suggestions';

  @override
  String get initDefaultAgent => 'Default agent initialized';

  @override
  String get errorReadingAgents => 'Error reading agents data';

  @override
  String get createAgent => 'Create Agent';

  @override
  String get editAgent => 'Edit Agent';

  @override
  String get cloneAgent => 'Clone Agent';

  @override
  String get deleteAgent => 'Delete Agent';

  @override
  String get saveAgent => 'Save';

  @override
  String get agentName => 'Name';

  @override
  String get enterAgentName => 'Enter agent name';

  @override
  String get pleaseEnterName => 'Please enter a name';

  @override
  String get serviceProvider => 'Service Provider';

  @override
  String get pleaseSelectProvider => 'Please select a service provider';

  @override
  String get updateConfig => 'Update Configuration';

  @override
  String get useDefaultConfig => 'Use Default Config';

  @override
  String get keepCurrentConfig => 'Keep Current Config';

  @override
  String get updateConfigConfirm =>
      'Do you want to update the current settings with this provider\'s default configuration?';

  @override
  String get configUpdated => 'Updated to provider default configuration';

  @override
  String get undoAction => 'Undo';

  @override
  String get description => 'Description';

  @override
  String get enterDescription => 'Enter agent description';

  @override
  String get pleaseEnterDescription => 'Please enter a description';

  @override
  String get systemPrompt => 'System Prompt';

  @override
  String get enterSystemPrompt => 'Enter system prompt';

  @override
  String get pleaseEnterSystemPrompt => 'Please enter a system prompt';

  @override
  String get baseUrl => 'Base URL';

  @override
  String get enterBaseUrl => 'Enter base URL for API calls';

  @override
  String get pleaseEnterBaseUrl => 'Please enter a base URL';

  @override
  String get model => 'Model';

  @override
  String get enterModel => 'Enter model name (e.g. gpt-3.5-turbo)';

  @override
  String get searchModel => 'Search Model';

  @override
  String get headers => 'Headers';

  @override
  String get enterHeaders => 'Enter headers (one per line, format: key: value)';

  @override
  String get tags => 'Tags';

  @override
  String get enterTag => 'Enter a tag';

  @override
  String get testAgent => 'Test Agent';

  @override
  String get avatar => 'Avatar';

  @override
  String get deleteAgentConfirm => 'Delete Agent';

  @override
  String get deleteAgentMessage =>
      'Are you sure you want to delete this agent? This action cannot be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get agentDeleted => 'Agent deleted';

  @override
  String get deleteFailed => 'Delete failed';

  @override
  String get agentCloned => 'Agent cloned';

  @override
  String get cloneFailed => 'Clone failed';

  @override
  String get copy => 'Copy';

  @override
  String get errorSavingAgent => 'Error saving agent';

  @override
  String get testAgentTitle => 'Test';

  @override
  String get enterTestText => 'Please enter test text...';

  @override
  String get testError => 'Error during test';

  @override
  String get loadingProviders => 'Loading...';

  @override
  String get loadProvidersError => 'Error loading providers';

  @override
  String get agentListTitle => 'AI Assistant';

  @override
  String get toolsTitle => 'Tools';

  @override
  String get agentsTab => 'Agents';

  @override
  String get toolsTab => 'Tools';

  @override
  String get modelManagement => 'Model Management';

  @override
  String get noModelsFound => 'No matching models found';

  @override
  String get cannotLoadModels => 'Cannot load model list';

  @override
  String get loadModelsFailed => 'Failed to load models';

  @override
  String get addModelFailed => 'Failed to add model';

  @override
  String get updateModelFailed => 'Failed to update model';

  @override
  String get deleteModelFailed => 'Failed to delete model';

  @override
  String get confirmDelete => 'Confirm Delete';

  @override
  String get confirmDeleteModel =>
      'Are you sure you want to delete model {modelName}?';

  @override
  String get addModel => 'Add Model';

  @override
  String get editModel => 'Edit Model';

  @override
  String get modelId => 'Model ID';

  @override
  String get modelIdExample => 'e.g. gpt-4';

  @override
  String get pleaseEnterModelId => 'Please enter model ID';

  @override
  String get modelName => 'Model Name';

  @override
  String get modelNameExample => 'e.g. GPT-4';

  @override
  String get pleaseEnterModelName => 'Please enter model name';

  @override
  String get modelGroup => 'Model Group';

  @override
  String get pleaseSelectModelGroup => 'Please select a model group';

  @override
  String get save => 'Save';

  @override
  String get lastInputLoadFailed => 'Failed to load last input';

  @override
  String get testInput => 'Test Input';

  @override
  String get loadLastInput => 'Load Last Input';

  @override
  String get clearInput => 'Clear Input';

  @override
  String get selectImage => 'Select Image';

  @override
  String get noImageSelected => 'No image selected';

  @override
  String get selectedImage => 'Selected';

  @override
  String get imageLoadFailed => 'Image load failed';

  @override
  String get testResponse => 'Test Response';

  @override
  String get close => 'Close';

  @override
  String get previewImages => 'Preview Images';

  @override
  String get errorDetails => 'Error Details';

  @override
  String get checkItems => 'Please check';

  @override
  String get apiKeyConfig => 'If the API key is correctly configured';

  @override
  String get networkConnection => 'If the network connection is normal';

  @override
  String get serviceEndpoint => 'If the service endpoint is accessible';

  @override
  String get systemRole => 'System';

  @override
  String get userRole => 'User';

  @override
  String get assistantRole => 'Assistant';

  @override
  String get addPrompt => 'Add Prompt';
  @override
  String get promptTypeLabel => 'Prompt Type';
  @override
  String get contentLabel => 'Content';

  @override
  String get filterAgents => 'Filter Agents';

  @override
  String get apply => 'Apply';

  @override
  String get selectAnalysisMethod => 'Select Analysis Method';

  @override
  String get noToolsAvailable => 'No Tools Available';

  @override
  String get addProviderButton => "添加提供商";

  @override
  get addProviderTooltip => "添加新的AI提供商";

  @override
  get confirmDeleteProviderMessage => "确定要删除此提供商吗？";

  @override
  String get confirmDeleteProviderTitle => "确认删除";

  @override
  String get noProvidersConfigured => "未配置任何提供商";

  @override
  String get providerSettingsTitle => "提供商设置";

  @override
  String get modelManagementDescription => 'Manage large language models';
}

/// 本地化代理
class OpenAILocalizationsDelegate
    extends LocalizationsDelegate<OpenAILocalizations> {
  const OpenAILocalizationsDelegate();

  /// 提供静态访问的代理实例
  static const OpenAILocalizationsDelegate delegate =
      OpenAILocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh'].contains(locale.languageCode);
  }

  @override
  Future<OpenAILocalizations> load(Locale locale) async {
    switch (locale.languageCode) {
      case 'zh':
        return OpenAILocalizationsZh();
      case 'en':
      default:
        return OpenAILocalizationsEn();
    }
  }

  @override
  bool shouldReload(OpenAILocalizationsDelegate old) => false;
}

/// 提供全局访问的代理实例（兼容性保留，推荐使用 OpenAILocalizationsDelegate.delegate）
const openAILocalizationsDelegate = OpenAILocalizationsDelegate.delegate;
