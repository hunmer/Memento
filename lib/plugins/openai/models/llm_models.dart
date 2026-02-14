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
    models:
        (json['models'] as List)
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
        id: 'deepseek-v3.1',
        name: 'DeepSeek-V3.1',
        description:
            'Hybrid architecture model with thinking and non-thinking modes',
        url: 'https://huggingface.co/deepseek-ai/DeepSeek-V3.1',
        group: 'deepseek',
      ),
      LLMModel(
        id: 'deepseek-v3.2-exp',
        name: 'DeepSeek-V3.2-Exp',
        description: 'Experimental model with sparse attention for efficiency',
        url: 'https://huggingface.co/deepseek-ai/DeepSeek-V3.2-Exp',
        group: 'deepseek',
      ),
      LLMModel(
        id: 'deepseek-r1',
        name: 'DeepSeek-R1',
        description: 'Reasoning model series',
        url: 'https://www.deepseek.com/models',
        group: 'deepseek',
      ),
      LLMModel(
        id: 'deepseek-math-7b',
        name: 'DeepSeek-Math-7B',
        url:
            'https://huggingface.co/collections/deepseek-ai/deepseek-math-65f2962739da11599e441681',
        group: 'deepseek',
      ),
      LLMModel(
        id: 'deepseek-coder-1.3b',
        name: 'DeepSeek-Coder-1.3B',
        url:
            'https://huggingface.co/collections/deepseek-ai/deepseek-coder-65f295d7d8a0a29fe39b4ec4',
        group: 'deepseek',
      ),
      LLMModel(
        id: 'deepseek-coder-6.7b',
        name: 'DeepSeek-Coder-6.7B',
        url:
            'https://huggingface.co/collections/deepseek-ai/deepseek-coder-65f295d7d8a0a29fe39b4ec4',
        group: 'deepseek',
      ),
      LLMModel(
        id: 'deepseek-coder-7b',
        name: 'DeepSeek-Coder-7B',
        url:
            'https://huggingface.co/collections/deepseek-ai/deepseek-coder-65f295d7d8a0a29fe39b4ec4',
        group: 'deepseek',
      ),
      LLMModel(
        id: 'deepseek-coder-33b',
        name: 'DeepSeek-Coder-33B',
        url:
            'https://huggingface.co/collections/deepseek-ai/deepseek-coder-65f295d7d8a0a29fe39b4ec4',
        group: 'deepseek',
      ),
      LLMModel(
        id: 'deepseek-vl-1.3b',
        name: 'DeepSeek-VL-1.3B',
        url:
            'https://huggingface.co/collections/deepseek-ai/deepseek-vl-65f295948133d9cf92b706d3',
        group: 'deepseek',
      ),
      LLMModel(
        id: 'deepseek-vl-7b',
        name: 'DeepSeek-VL-7B',
        url:
            'https://huggingface.co/collections/deepseek-ai/deepseek-vl-65f295948133d9cf92b706d3',
        group: 'deepseek',
      ),
      LLMModel(
        id: 'deepseek-moe-16b',
        name: 'DeepSeek-MoE-16B',
        url:
            'https://huggingface.co/collections/deepseek-ai/deepseek-moe-65f29679f5cf26fe063686bf',
        group: 'deepseek',
      ),
    ],
  ),
  LLMModelGroup(
    id: 'qwen',
    name: 'Qwen',
    models: [
      LLMModel(
        id: 'qwen3-235b-a22b',
        name: 'Qwen3-235B-A22B',
        description: 'Hybrid model with thinking and non-thinking modes',
        url: 'https://qwenlm.github.io/blog/qwen3/',
        group: 'qwen',
      ),
      LLMModel(
        id: 'qwen-1.8b',
        name: 'Qwen-1.8B',
        url:
            'https://huggingface.co/collections/Qwen/qwen-65c0e50c3f1ab89cb8704144',
        group: 'qwen',
      ),
      LLMModel(
        id: 'qwen-7b',
        name: 'Qwen-7B',
        url:
            'https://huggingface.co/collections/Qwen/qwen-65c0e50c3f1ab89cb8704144',
        group: 'qwen',
      ),
      LLMModel(
        id: 'qwen-14b',
        name: 'Qwen-14B',
        url:
            'https://huggingface.co/collections/Qwen/qwen-65c0e50c3f1ab89cb8704144',
        group: 'qwen',
      ),
      LLMModel(
        id: 'qwen-72b',
        name: 'Qwen-72B',
        url:
            'https://huggingface.co/collections/Qwen/qwen-65c0e50c3f1ab89cb8704144',
        group: 'qwen',
      ),
    ],
  ),
  LLMModelGroup(
    id: 'meta',
    name: 'Meta',
    models: [
      LLMModel(
        id: 'llama-4-scout',
        name: 'Llama 4 Scout',
        description: '17B active parameters with 16 experts',
        url: 'https://ai.meta.com/blog/llama-4-multimodal-intelligence/',
        group: 'meta',
      ),
      LLMModel(
        id: 'llama-4-maverick',
        name: 'Llama 4 Maverick',
        description: '17B active parameters with 128 experts',
        url: 'https://ai.meta.com/blog/llama-4-multimodal-intelligence/',
        group: 'meta',
      ),
      LLMModel(
        id: 'llama-4-behemoth',
        name: 'Llama 4 Behemoth',
        description: '288B active parameters with 16 experts',
        url: 'https://ai.meta.com/blog/llama-4-multimodal-intelligence/',
        group: 'meta',
      ),
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
        id: 'mistral-medium-3',
        name: 'Mistral Medium 3',
        description: 'State-of-the-art performance at lower cost',
        url: 'https://mistral.ai/news/mistral-medium-3',
        group: 'mistral',
      ),
      LLMModel(
        id: 'codestral-22b',
        name: 'Codestral-22B',
        url: 'https://mistral.ai/news/codestral/',
        group: 'mistral',
      ),
      LLMModel(
        id: 'codestral-7b',
        name: 'Codestral-7B',
        url: 'https://mistral.ai/news/codestral/',
        group: 'mistral',
      ),
      LLMModel(
        id: 'minstral-3b',
        name: 'Ministral 3B',
        description: 'World’s best edge model',
        url: 'https://mistral.ai/technology/',
        group: 'mistral',
      ),
      LLMModel(
        id: 'minstral-8b',
        name: 'Ministral 8B',
        description: 'World’s best edge model',
        url: 'https://mistral.ai/technology/',
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
        id: 'gpt-5.1',
        name: 'GPT-5.1',
        description:
            'Balances intelligence and speed for agentic and coding tasks',
        url: 'https://openai.com/index/gpt-5-1-for-developers/',
        group: 'openai',
      ),
      LLMModel(
        id: 'o4-mini',
        name: 'O4-Mini',
        description: 'Optimized for fast, cost-efficient reasoning',
        url: 'https://openai.com/',
        group: 'openai',
      ),
      LLMModel(
        id: 'gpt-5',
        name: 'GPT-5',
        description: 'Unified model with dedicated reasoning',
        url: 'https://openai.com/',
        group: 'openai',
      ),
      LLMModel(
        id: 'gpt-4o',
        name: 'GPT-4o',
        description: 'Multi-modal flagship model',
        url: 'https://platform.openai.com/docs/models/gpt-4o',
        group: 'openai',
      ),
      LLMModel(
        id: 'gpt-4o-mini',
        name: 'GPT-4o Mini',
        description: 'Economic small intelligent model',
        url: 'https://platform.openai.com/docs/models/gpt-4o-mini',
        group: 'openai',
      ),
      LLMModel(
        id: 'gpt-4-turbo',
        name: 'GPT-4 Turbo',
        description: 'Optimized version of GPT-4',
        url: 'https://platform.openai.com/docs/models/gpt-4-turbo',
        group: 'openai',
      ),
    ],
  ),
  LLMModelGroup(
    id: 'anthropic',
    name: 'Anthropic',
    models: [
      LLMModel(
        id: 'claude-sonnet-4.5',
        name: 'Claude Sonnet 4.5',
        description: 'Best coding model, strongest for agents',
        url: 'https://www.anthropic.com/news/claude-sonnet-4-5',
        group: 'anthropic',
      ),
      LLMModel(
        id: 'claude-opus-4.1',
        name: 'Claude Opus 4.1',
        description: 'Upgrade on agentic tasks and coding',
        url: 'https://www.anthropic.com/news/claude-opus-4-1',
        group: 'anthropic',
      ),
      LLMModel(
        id: 'claude-3.5-sonnet',
        name: 'Claude 3.5 Sonnet',
        description: 'Latest Claude 3.5 model',
        url: 'https://www.anthropic.com/claude',
        group: 'anthropic',
      ),
      LLMModel(
        id: 'claude-3-opus',
        name: 'Claude 3 Opus',
        description: 'Most powerful Claude 3 model',
        url: 'https://www.anthropic.com/claude',
        group: 'anthropic',
      ),
      LLMModel(
        id: 'claude-3-sonnet',
        name: 'Claude 3 Sonnet',
        description: 'Balance performance and speed',
        url: 'https://www.anthropic.com/claude',
        group: 'anthropic',
      ),
      LLMModel(
        id: 'claude-3-haiku',
        name: 'Claude 3 Haiku',
        description: 'Fast lightweight model',
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
        id: 'gemini-3-pro',
        name: 'Gemini 3 Pro',
        description: 'Best for multimodal understanding',
        url: 'https://ai.google.dev/gemini-api/docs/models/gemini',
        group: 'google',
      ),
      LLMModel(
        id: 'gemini-2.5-pro',
        name: 'Gemini 2.5 Pro',
        description: 'State-of-the-art thinking model for complex problems',
        url: 'https://ai.google.dev/gemini-api/docs/models/gemini',
        group: 'google',
      ),
      LLMModel(
        id: 'gemini-2.5-flash',
        name: 'Gemini 2.5 Flash',
        description: 'Best price-performance for high volume tasks',
        url: 'https://ai.google.dev/gemini-api/docs/models/gemini',
        group: 'google',
      ),
      LLMModel(
        id: 'gemini-2.5-flash-lite',
        name: 'Gemini 2.5 Flash-Lite',
        description: 'Fastest model optimized for cost-efficiency',
        url: 'https://ai.google.dev/gemini-api/docs/models/gemini',
        group: 'google',
      ),
    ],
  ),
  LLMModelGroup(
    id: 'zhipu',
    name: '智谱 AI',
    models: [
      LLMModel(
        id: 'glm-4.5',
        name: 'GLM-4.5',
        description: 'Next generation with hybrid reasoning',
        url: 'https://open.bigmodel.cn/',
        group: 'zhipu',
      ),
      LLMModel(
        id: 'glm-4.5-air',
        name: 'GLM-4.5 Air',
        description: 'Lighter version for efficiency',
        url: 'https://open.bigmodel.cn/',
        group: 'zhipu',
      ),
      LLMModel(
        id: 'glm-4',
        name: 'GLM-4',
        description: 'Latest generation dialogue model',
        url: 'https://open.bigmodel.cn/',
        group: 'zhipu',
      ),
      LLMModel(
        id: 'glm-4-flash',
        name: 'GLM-4 Flash',
        description: 'Fast inference version',
        url: 'https://open.bigmodel.cn/',
        group: 'zhipu',
      ),
      LLMModel(
        id: 'codegeex-4',
        name: 'CodeGeeX-4',
        description: 'Code generation model',
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
        id: 'kimi-k2-thinking',
        name: 'Kimi K2 Thinking',
        description: 'Reasoning variant with agentic capabilities',
        url: 'https://www.moonshot.cn/',
        group: 'moonshot',
      ),
      LLMModel(
        id: 'moonshot-v1-8k',
        name: 'Moonshot v1 8K',
        description: 'Supports 8K context',
        url: 'https://www.moonshot.cn/',
        group: 'moonshot',
      ),
      LLMModel(
        id: 'moonshot-v1-32k',
        name: 'Moonshot v1 32K',
        description: 'Supports 32K context',
        url: 'https://www.moonshot.cn/',
        group: 'moonshot',
      ),
      LLMModel(
        id: 'moonshot-v1-128k',
        name: 'Moonshot v1 128K',
        description: 'Supports 128K long text',
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
        id: 'spark-4.0-turbo',
        name: 'Spark 4.0 Turbo',
        description: 'Latest Spark model with enhanced capabilities',
        url: 'https://xinghuo.xfyun.cn/',
        group: 'xfyun',
      ),
      LLMModel(
        id: 'spark-x1',
        name: 'Spark X1',
        description: 'Deep reasoning model trained on domestic hardware',
        url: 'https://xinghuo.xfyun.cn/',
        group: 'xfyun',
      ),
      LLMModel(
        id: 'spark-multilingual',
        name: 'Spark Multilingual',
        description: 'Supports multiple languages',
        url: 'https://xinghuo.xfyun.cn/',
        group: 'xfyun',
      ),
      LLMModel(
        id: 'spark-3.5',
        name: 'Spark 3.5',
        description: 'Latest Spark large model',
        url: 'https://xinghuo.xfyun.cn/',
        group: 'xfyun',
      ),
      LLMModel(
        id: 'spark-lite',
        name: 'Spark Lite',
        description: 'Lightweight Spark model',
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
        id: 'command-a-03-2025',
        name: 'Command A (03-2025)',
        description: 'Most performant model for tool use and multilingual',
        url: 'https://docs.cohere.com/docs/models',
        group: 'cohere',
      ),
      LLMModel(
        id: 'command-r7b-12-2024',
        name: 'Command R7B (12-2024)',
        description: 'Excels at RAG and tool use',
        url: 'https://docs.cohere.com/docs/models',
        group: 'cohere',
      ),
      LLMModel(
        id: 'command-a-translate-08-2025',
        name: 'Command A Translate (08-2025)',
        description: 'State-of-the-art machine translation',
        url: 'https://docs.cohere.com/docs/models',
        group: 'cohere',
      ),
      LLMModel(
        id: 'command-a-reasoning-08-2025',
        name: 'Command A Reasoning (08-2025)',
        description: 'First reasoning model for nuanced tasks',
        url: 'https://docs.cohere.com/docs/models',
        group: 'cohere',
      ),
      LLMModel(
        id: 'command-a-vision-07-2025',
        name: 'Command A Vision (07-2025)',
        description: 'Processes images for enterprise use cases',
        url: 'https://docs.cohere.com/docs/models',
        group: 'cohere',
      ),
    ],
  ),
  LLMModelGroup(
    id: 'alibaba-qwen',
    name: '阿里云通义千问',
    models: [
      LLMModel(
        id: 'qwen-max',
        name: 'Qwen Max',
        description: 'Flagship version',
        url: 'https://dashscope.aliyun.com/',
        group: 'alibaba-qwen',
      ),
      LLMModel(
        id: 'qwen-max-longcontext',
        name: 'Qwen Max LongContext',
        description: 'Supports super long text',
        url: 'https://dashscope.aliyun.com/',
        group: 'alibaba-qwen',
      ),
      LLMModel(
        id: 'qwen-turbo',
        name: 'Qwen Turbo',
        description: 'Fast version',
        url: 'https://dashscope.aliyun.com/',
        group: 'alibaba-qwen',
      ),
      LLMModel(
        id: 'qwen-plus',
        name: 'Qwen Plus',
        description: 'Enhanced version',
        url: 'https://dashscope.aliyun.com/',
        group: 'alibaba-qwen',
      ),
    ],
  ),
  LLMModelGroup(
    id: 'perplexity',
    name: 'Perplexity',
    models: [
      LLMModel(
        id: 'sonar',
        name: 'Sonar',
        description: 'Optimized for answer quality and user experience',
        url: 'https://www.perplexity.ai/',
        group: 'perplexity',
      ),
    ],
  ),
  LLMModelGroup(
    id: 'xai',
    name: 'xAI',
    models: [
      LLMModel(
        id: 'grok-4.1',
        name: 'Grok 4.1',
        description: 'Latest Grok model with enhanced capabilities',
        url: 'https://x.ai/',
        group: 'xai',
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
  LLMModelGroup(
    id: 'minimax',
    name: 'MiniMax',
    models: [
      LLMModel(
        id: 'abab6.5s-chat',
        name: 'abab6.5s-chat',
        description: 'MiniMax 最新对话模型，支持长上下文',
        url: 'https://www.minimaxi.com/',
        group: 'minimax',
      ),
      LLMModel(
        id: 'abab6.5-chat',
        name: 'abab6.5-chat',
        description: 'MiniMax 对话模型',
        url: 'https://www.minimaxi.com/',
        group: 'minimax',
      ),
      LLMModel(
        id: 'abab5.5-chat',
        name: 'abab5.5-chat',
        description: 'MiniMax 对话模型',
        url: 'https://www.minimaxi.com/',
        group: 'minimax',
      ),
      LLMModel(
        id: 'abab5.5s-chat',
        name: 'abab5.5s-chat',
        description: 'MiniMax 对话模型',
        url: 'https://www.minimaxi.com/',
        group: 'minimax',
      ),
    ],
  ),
];
