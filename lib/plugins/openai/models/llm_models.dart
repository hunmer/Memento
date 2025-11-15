class LLMModel {
  final String id;
  final String name;
  final String? description;
  final String? url;
  final String group;

  const LLMModel({
    required this.id,
    required this.name,
    this.description,
    this.url,
    required this.group,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'url': url,
        'group': group,
      };

  factory LLMModel.fromJson(Map<String, dynamic> json) => LLMModel(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        url: json['url'] as String?,
        group: json['group'] as String,
      );
}

class LLMModelGroup {
  final String id;
  final String name;
  final List<LLMModel> models;

  const LLMModelGroup({
    required this.id,
    required this.name,
    required this.models,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'models': models.map((e) => e.toJson()).toList(),
      };

  factory LLMModelGroup.fromJson(Map<String, dynamic> json) => LLMModelGroup(
        id: json['id'] as String,
        name: json['name'] as String,
        models: (json['models'] as List)
            .map((e) => LLMModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// 预定义的大模型列表
final llmModelGroups = [
  LLMModelGroup(
    id: 'deepseek',
    name: 'DeepSeek',
    models: [
      LLMModel(
        id: 'deepseek-math-7b',
        name: 'DeepSeek-Math-7B',
        url: 'https://huggingface.co/collections/deepseek-ai/deepseek-math-65f2962739da11599e441681',
        group: 'deepseek',
      ),
      LLMModel(
        id: 'deepseek-coder-1.3b',
        name: 'DeepSeek-Coder-1.3B',
        url: 'https://huggingface.co/collections/deepseek-ai/deepseek-coder-65f295d7d8a0a29fe39b4ec4',
        group: 'deepseek',
      ),
      LLMModel(
        id: 'deepseek-coder-6.7b',
        name: 'DeepSeek-Coder-6.7B',
        url: 'https://huggingface.co/collections/deepseek-ai/deepseek-coder-65f295d7d8a0a29fe39b4ec4',
        group: 'deepseek',
      ),
      LLMModel(
        id: 'deepseek-coder-7b',
        name: 'DeepSeek-Coder-7B',
        url: 'https://huggingface.co/collections/deepseek-ai/deepseek-coder-65f295d7d8a0a29fe39b4ec4',
        group: 'deepseek',
      ),
      LLMModel(
        id: 'deepseek-coder-33b',
        name: 'DeepSeek-Coder-33B',
        url: 'https://huggingface.co/collections/deepseek-ai/deepseek-coder-65f295d7d8a0a29fe39b4ec4',
        group: 'deepseek',
      ),
      LLMModel(
        id: 'deepseek-vl-1.3b',
        name: 'DeepSeek-VL-1.3B',
        url: 'https://huggingface.co/collections/deepseek-ai/deepseek-vl-65f295948133d9cf92b706d3',
        group: 'deepseek',
      ),
      LLMModel(
        id: 'deepseek-vl-7b',
        name: 'DeepSeek-VL-7B',
        url: 'https://huggingface.co/collections/deepseek-ai/deepseek-vl-65f295948133d9cf92b706d3',
        group: 'deepseek',
      ),
      LLMModel(
        id: 'deepseek-moe-16b',
        name: 'DeepSeek-MoE-16B',
        url: 'https://huggingface.co/collections/deepseek-ai/deepseek-moe-65f29679f5cf26fe063686bf',
        group: 'deepseek',
      ),
    ],
  ),
  LLMModelGroup(
    id: 'qwen',
    name: 'Qwen',
    models: [
      LLMModel(
        id: 'qwen-1.8b',
        name: 'Qwen-1.8B',
        url: 'https://huggingface.co/collections/Qwen/qwen-65c0e50c3f1ab89cb8704144',
        group: 'qwen',
      ),
      LLMModel(
        id: 'qwen-7b',
        name: 'Qwen-7B',
        url: 'https://huggingface.co/collections/Qwen/qwen-65c0e50c3f1ab89cb8704144',
        group: 'qwen',
      ),
      LLMModel(
        id: 'qwen-14b',
        name: 'Qwen-14B',
        url: 'https://huggingface.co/collections/Qwen/qwen-65c0e50c3f1ab89cb8704144',
        group: 'qwen',
      ),
      LLMModel(
        id: 'qwen-72b',
        name: 'Qwen-72B',
        url: 'https://huggingface.co/collections/Qwen/qwen-65c0e50c3f1ab89cb8704144',
        group: 'qwen',
      ),
      LLMModel(
        id: 'qwen1.5-0.5b',
        name: 'Qwen1.5-0.5B',
        url: 'https://qwenlm.github.io/blog/qwen1.5/',
        group: 'qwen',
      ),
      LLMModel(
        id: 'qwen1.5-1.8b',
        name: 'Qwen1.5-1.8B',
        url: 'https://qwenlm.github.io/blog/qwen1.5/',
        group: 'qwen',
      ),
    ],
  ),
  LLMModelGroup(
    id: 'meta',
    name: 'Meta',
    models: [
      LLMModel(
        id: 'llama-3.2-1b',
        name: 'Llama 3.2-1B',
        url: 'https://llama.meta.com/',
        group: 'meta',
      ),
      LLMModel(
        id: 'llama-3.2-3b',
        name: 'Llama 3.2-3B',
        url: 'https://llama.meta.com/',
        group: 'meta',
      ),
      LLMModel(
        id: 'llama-3.2-11b',
        name: 'Llama 3.2-11B',
        url: 'https://llama.meta.com/',
        group: 'meta',
      ),
      LLMModel(
        id: 'llama-3.2-90b',
        name: 'Llama 3.2-90B',
        url: 'https://llama.meta.com/',
        group: 'meta',
      ),
      LLMModel(
        id: 'llama-3-8b',
        name: 'Llama 3-8B',
        url: 'https://llama.meta.com/llama3/',
        group: 'meta',
      ),
      LLMModel(
        id: 'llama-3-70b',
        name: 'Llama 3-70B',
        url: 'https://llama.meta.com/llama3/',
        group: 'meta',
      ),
    ],
  ),
  LLMModelGroup(
    id: 'mistral',
    name: 'Mistral AI',
    models: [
      LLMModel(
        id: 'codestral-7b',
        name: 'Codestral-7B',
        url: 'https://mistral.ai/news/codestral/',
        group: 'mistral',
      ),
      LLMModel(
        id: 'codestral-22b',
        name: 'Codestral-22B',
        url: 'https://mistral.ai/news/codestral/',
        group: 'mistral',
      ),
      LLMModel(
        id: 'mistral-7b',
        name: 'Mistral-7B',
        url: 'https://mistral.ai/news/announcing-mistral-7b/',
        group: 'mistral',
      ),
      LLMModel(
        id: 'mixtral-8x7b',
        name: 'Mixtral-8x7B',
        url: 'https://mistral.ai/news/mixtral-of-experts/',
        group: 'mistral',
      ),
      LLMModel(
        id: 'mixtral-8x22b',
        name: 'Mixtral-8x22B',
        url: 'https://mistral.ai/news/mixtral-8x22b/',
        group: 'mistral',
      ),
    ],
  ),
  LLMModelGroup(
    id: 'openai',
    name: 'OpenAI',
    models: [
      LLMModel(
        id: 'gpt-3.5-turbo',
        name: 'GPT-3.5 Turbo',
        description: '最新的 GPT-3.5 模型，快速且经济',
        url: 'https://platform.openai.com/docs/models/gpt-3-5-turbo',
        group: 'openai',
      ),
      LLMModel(
        id: 'gpt-3.5-turbo-16k',
        name: 'GPT-3.5 Turbo 16K',
        description: '扩展上下文版本，支持 16K tokens',
        url: 'https://platform.openai.com/docs/models/gpt-3-5-turbo',
        group: 'openai',
      ),
      LLMModel(
        id: 'gpt-4',
        name: 'GPT-4',
        description: '最先进的 GPT-4 模型',
        url: 'https://platform.openai.com/docs/models/gpt-4',
        group: 'openai',
      ),
      LLMModel(
        id: 'gpt-4-turbo',
        name: 'GPT-4 Turbo',
        description: 'GPT-4 的优化版本，更快更便宜',
        url: 'https://platform.openai.com/docs/models/gpt-4-turbo',
        group: 'openai',
      ),
      LLMModel(
        id: 'gpt-4-turbo-preview',
        name: 'GPT-4 Turbo Preview',
        description: 'GPT-4 Turbo 预览版',
        url: 'https://platform.openai.com/docs/models/gpt-4-turbo',
        group: 'openai',
      ),
      LLMModel(
        id: 'gpt-4o',
        name: 'GPT-4o',
        description: '多模态旗舰模型，支持文本和视觉',
        url: 'https://platform.openai.com/docs/models/gpt-4o',
        group: 'openai',
      ),
      LLMModel(
        id: 'gpt-4o-mini',
        name: 'GPT-4o Mini',
        description: '经济实惠的小型智能模型',
        url: 'https://platform.openai.com/docs/models/gpt-4o-mini',
        group: 'openai',
      ),
      LLMModel(
        id: 'o1',
        name: 'O1',
        description: '推理模型，擅长复杂问题解决',
        url: 'https://platform.openai.com/docs/models/o1',
        group: 'openai',
      ),
      LLMModel(
        id: 'o1-mini',
        name: 'O1 Mini',
        description: '快速推理模型',
        url: 'https://platform.openai.com/docs/models/o1',
        group: 'openai',
      ),
    ],
  ),
  LLMModelGroup(
    id: 'anthropic',
    name: 'Anthropic',
    models: [
      LLMModel(
        id: 'claude-3-opus',
        name: 'Claude 3 Opus',
        description: '最强大的 Claude 3 模型',
        url: 'https://www.anthropic.com/claude',
        group: 'anthropic',
      ),
      LLMModel(
        id: 'claude-3-sonnet',
        name: 'Claude 3 Sonnet',
        description: '平衡性能和速度',
        url: 'https://www.anthropic.com/claude',
        group: 'anthropic',
      ),
      LLMModel(
        id: 'claude-3-haiku',
        name: 'Claude 3 Haiku',
        description: '快速响应的轻量级模型',
        url: 'https://www.anthropic.com/claude',
        group: 'anthropic',
      ),
      LLMModel(
        id: 'claude-3.5-sonnet',
        name: 'Claude 3.5 Sonnet',
        description: '最新的 Claude 3.5 模型',
        url: 'https://www.anthropic.com/claude',
        group: 'anthropic',
      ),
      LLMModel(
        id: 'claude-2.1',
        name: 'Claude 2.1',
        description: '支持 200K 上下文',
        url: 'https://www.anthropic.com/claude',
        group: 'anthropic',
      ),
      LLMModel(
        id: 'claude-2',
        name: 'Claude 2',
        description: '第二代 Claude 模型',
        url: 'https://www.anthropic.com/claude',
        group: 'anthropic',
      ),
    ],
  ),
  LLMModelGroup(
    id: 'google',
    name: 'Google',
    models: [
      LLMModel(
        id: 'gemini-1.5-pro',
        name: 'Gemini 1.5 Pro',
        description: '支持 2M 上下文的旗舰模型',
        url: 'https://deepmind.google/technologies/gemini/',
        group: 'google',
      ),
      LLMModel(
        id: 'gemini-1.5-flash',
        name: 'Gemini 1.5 Flash',
        description: '快速响应的轻量级模型',
        url: 'https://deepmind.google/technologies/gemini/',
        group: 'google',
      ),
      LLMModel(
        id: 'gemini-1.0-pro',
        name: 'Gemini 1.0 Pro',
        description: '第一代 Gemini Pro 模型',
        url: 'https://deepmind.google/technologies/gemini/',
        group: 'google',
      ),
      LLMModel(
        id: 'gemini-1.0-ultra',
        name: 'Gemini 1.0 Ultra',
        description: '最强大的 Gemini 1.0 模型',
        url: 'https://deepmind.google/technologies/gemini/',
        group: 'google',
      ),
      LLMModel(
        id: 'gemini-pro-vision',
        name: 'Gemini Pro Vision',
        description: '支持多模态的视觉模型',
        url: 'https://deepmind.google/technologies/gemini/',
        group: 'google',
      ),
    ],
  ),
  LLMModelGroup(
    id: 'zhipu',
    name: '智谱 AI',
    models: [
      LLMModel(
        id: 'glm-4',
        name: 'GLM-4',
        description: '最新一代对话模型',
        url: 'https://open.bigmodel.cn/',
        group: 'zhipu',
      ),
      LLMModel(
        id: 'glm-4-air',
        name: 'GLM-4 Air',
        description: '性价比优化版本',
        url: 'https://open.bigmodel.cn/',
        group: 'zhipu',
      ),
      LLMModel(
        id: 'glm-4-flash',
        name: 'GLM-4 Flash',
        description: '快速推理版本',
        url: 'https://open.bigmodel.cn/',
        group: 'zhipu',
      ),
      LLMModel(
        id: 'glm-3-turbo',
        name: 'GLM-3 Turbo',
        description: '第三代优化模型',
        url: 'https://open.bigmodel.cn/',
        group: 'zhipu',
      ),
      LLMModel(
        id: 'chatglm-turbo',
        name: 'ChatGLM Turbo',
        description: '对话优化模型',
        url: 'https://open.bigmodel.cn/',
        group: 'zhipu',
      ),
      LLMModel(
        id: 'codegeex-4',
        name: 'CodeGeeX-4',
        description: '代码生成模型',
        url: 'https://codegeex.cn/',
        group: 'zhipu',
      ),
    ],
  ),
  LLMModelGroup(
    id: 'moonshot',
    name: '月之暗面',
    models: [
      LLMModel(
        id: 'moonshot-v1-8k',
        name: 'Moonshot v1 8K',
        description: '支持 8K 上下文',
        url: 'https://www.moonshot.cn/',
        group: 'moonshot',
      ),
      LLMModel(
        id: 'moonshot-v1-32k',
        name: 'Moonshot v1 32K',
        description: '支持 32K 上下文',
        url: 'https://www.moonshot.cn/',
        group: 'moonshot',
      ),
      LLMModel(
        id: 'moonshot-v1-128k',
        name: 'Moonshot v1 128K',
        description: '支持 128K 长文本',
        url: 'https://www.moonshot.cn/',
        group: 'moonshot',
      ),
    ],
  ),
  LLMModelGroup(
    id: 'xfyun',
    name: '讯飞星火',
    models: [
      LLMModel(
        id: 'spark-3.5',
        name: 'Spark 3.5',
        description: '最新的星火大模型',
        url: 'https://xinghuo.xfyun.cn/',
        group: 'xfyun',
      ),
      LLMModel(
        id: 'spark-3.0',
        name: 'Spark 3.0',
        description: '第三代星火模型',
        url: 'https://xinghuo.xfyun.cn/',
        group: 'xfyun',
      ),
      LLMModel(
        id: 'spark-2.0',
        name: 'Spark 2.0',
        description: '第二代星火模型',
        url: 'https://xinghuo.xfyun.cn/',
        group: 'xfyun',
      ),
      LLMModel(
        id: 'spark-lite',
        name: 'Spark Lite',
        description: '轻量级星火模型',
        url: 'https://xinghuo.xfyun.cn/',
        group: 'xfyun',
      ),
    ],
  ),
  LLMModelGroup(
    id: 'cohere',
    name: 'Cohere',
    models: [
      LLMModel(
        id: 'command-r-plus',
        name: 'Command R+',
        description: '最强大的 Command 模型',
        url: 'https://cohere.com/',
        group: 'cohere',
      ),
      LLMModel(
        id: 'command-r',
        name: 'Command R',
        description: 'RAG 优化模型',
        url: 'https://cohere.com/',
        group: 'cohere',
      ),
      LLMModel(
        id: 'command',
        name: 'Command',
        description: '通用指令模型',
        url: 'https://cohere.com/',
        group: 'cohere',
      ),
      LLMModel(
        id: 'command-light',
        name: 'Command Light',
        description: '轻量级指令模型',
        url: 'https://cohere.com/',
        group: 'cohere',
      ),
    ],
  ),
  LLMModelGroup(
    id: 'alibaba-qwen',
    name: '阿里云通义千问',
    models: [
      LLMModel(
        id: 'qwen-turbo',
        name: 'Qwen Turbo',
        description: '通义千问快速版本',
        url: 'https://dashscope.aliyun.com/',
        group: 'alibaba-qwen',
      ),
      LLMModel(
        id: 'qwen-plus',
        name: 'Qwen Plus',
        description: '通义千问增强版本',
        url: 'https://dashscope.aliyun.com/',
        group: 'alibaba-qwen',
      ),
      LLMModel(
        id: 'qwen-max',
        name: 'Qwen Max',
        description: '通义千问旗舰版本',
        url: 'https://dashscope.aliyun.com/',
        group: 'alibaba-qwen',
      ),
      LLMModel(
        id: 'qwen-max-longcontext',
        name: 'Qwen Max LongContext',
        description: '支持超长文本的版本',
        url: 'https://dashscope.aliyun.com/',
        group: 'alibaba-qwen',
      ),
    ],
  ),
  LLMModelGroup(
    id: 'other',
    name: '其他模型',
    models: [
      LLMModel(
        id: 'yi-34b',
        name: 'Yi-34B',
        description: '零一万物 34B 模型',
        url: 'https://www.01.ai/',
        group: 'other',
      ),
      LLMModel(
        id: 'baichuan2-13b',
        name: 'Baichuan2-13B',
        description: '百川智能 13B 模型',
        url: 'https://www.baichuan-ai.com/',
        group: 'other',
      ),
      LLMModel(
        id: 'internlm2-20b',
        name: 'InternLM2-20B',
        description: '书生·浦语 20B 模型',
        url: 'https://internlm.intern-ai.org.cn/',
        group: 'other',
      ),
      LLMModel(
        id: 'phi-3',
        name: 'Phi-3',
        description: 'Microsoft 小型语言模型',
        url: 'https://azure.microsoft.com/en-us/products/phi-3',
        group: 'other',
      ),
      LLMModel(
        id: 'gemma-7b',
        name: 'Gemma-7B',
        description: 'Google 开源模型',
        url: 'https://ai.google.dev/gemma',
        group: 'other',
      ),
    ],
  ),
];