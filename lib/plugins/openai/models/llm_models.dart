class LLMModel {
  final String id;
  final String name;
  final String group;

  const LLMModel({
    required this.id,
    required this.name,
    required this.group,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'group': group,
  };

  factory LLMModel.fromJson(Map<String, dynamic> json) => LLMModel(
    id: json['id'] as String,
    name: json['name'] as String,
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
        id: 'deepseek-v4',
        name: 'DeepSeek-V4',
        group: 'deepseek',
      ),
      LLMModel(
        id: 'deepseek-v3.2',
        name: 'DeepSeek-V3.2',
        group: 'deepseek',
      ),
      LLMModel(
        id: 'deepseek-v3',
        name: 'DeepSeek-V3',
        group: 'deepseek',
      ),
      LLMModel(
        id: 'deepseek-v3.1',
        name: 'DeepSeek-V3.1',
        group: 'deepseek',
      ),
      LLMModel(
        id: 'deepseek-v3.2-exp',
        name: 'DeepSeek-V3.2-Exp',
        group: 'deepseek',
      ),
      LLMModel(
        id: 'deepseek-r1',
        name: 'DeepSeek-R1',
        group: 'deepseek',
      ),
      LLMModel(
        id: 'deepseek-math-7b',
        name: 'DeepSeek-Math-7B',
        group: 'deepseek',
      ),
      LLMModel(
        id: 'deepseek-coder-1.3b',
        name: 'DeepSeek-Coder-1.3B',
        group: 'deepseek',
      ),
      LLMModel(
        id: 'deepseek-coder-6.7b',
        name: 'DeepSeek-Coder-6.7B',
        group: 'deepseek',
      ),
      LLMModel(
        id: 'deepseek-coder-7b',
        name: 'DeepSeek-Coder-7B',
        group: 'deepseek',
      ),
      LLMModel(
        id: 'deepseek-coder-33b',
        name: 'DeepSeek-Coder-33B',
        group: 'deepseek',
      ),
      LLMModel(
        id: 'deepseek-vl-1.3b',
        name: 'DeepSeek-VL-1.3B',
        group: 'deepseek',
      ),
      LLMModel(
        id: 'deepseek-vl-7b',
        name: 'DeepSeek-VL-7B',
        group: 'deepseek',
      ),
      LLMModel(
        id: 'deepseek-moe-16b',
        name: 'DeepSeek-MoE-16B',
        group: 'deepseek',
      ),
    ],
  ),
  LLMModelGroup(
    id: 'qwen',
    name: 'Qwen',
    models: [
      LLMModel(
        id: 'qwen3.5-235b',
        name: 'Qwen3.5-235B',
        group: 'qwen',
      ),
      LLMModel(
        id: 'qwen3.5-122b',
        name: 'Qwen3.5-122B',
        group: 'qwen',
      ),
      LLMModel(
        id: 'qwen3.5-72b',
        name: 'Qwen3.5-72B',
        group: 'qwen',
      ),
      LLMModel(
        id: 'qwen3.5-32b',
        name: 'Qwen3.5-32B',
        group: 'qwen',
      ),
      LLMModel(
        id: 'qwen3-max',
        name: 'Qwen3 Max',
        group: 'qwen',
      ),
      LLMModel(
        id: 'qwen3-235b-a22b',
        name: 'Qwen3-235B-A22B',
        group: 'qwen',
      ),
      LLMModel(
        id: 'qwen-1.8b',
        name: 'Qwen-1.8B',
        group: 'qwen',
      ),
      LLMModel(
        id: 'qwen-7b',
        name: 'Qwen-7B',
        group: 'qwen',
      ),
      LLMModel(
        id: 'qwen-14b',
        name: 'Qwen-14B',
        group: 'qwen',
      ),
      LLMModel(
        id: 'qwen-72b',
        name: 'Qwen-72B',
        group: 'qwen',
      ),
    ],
  ),
  LLMModelGroup(
    id: 'meta',
    name: 'Meta',
    models: [
      LLMModel(
        id: 'llama-4-405b',
        name: 'Llama 4 405B',
        group: 'meta',
      ),
      LLMModel(
        id: 'llama-4-70b',
        name: 'Llama 4 70B',
        group: 'meta',
      ),
      LLMModel(
        id: 'llama-4-family',
        name: 'Llama 4 Family',
        group: 'meta',
      ),
      LLMModel(
        id: 'llama-4-scout',
        name: 'Llama 4 Scout',
        group: 'meta',
      ),
      LLMModel(
        id: 'llama-4-maverick',
        name: 'Llama 4 Maverick',
        group: 'meta',
      ),
      LLMModel(
        id: 'llama-4-behemoth',
        name: 'Llama 4 Behemoth',
        group: 'meta',
      ),
      LLMModel(
        id: 'llama-3.2-1b',
        name: 'Llama 3.2-1B',
        group: 'meta',
      ),
      LLMModel(
        id: 'llama-3.2-3b',
        name: 'Llama 3.2-3B',
        group: 'meta',
      ),
      LLMModel(
        id: 'llama-3.2-11b',
        name: 'Llama 3.2-11B',
        group: 'meta',
      ),
      LLMModel(
        id: 'llama-3.2-90b',
        name: 'Llama 3.2-90B',
        group: 'meta',
      ),
      LLMModel(
        id: 'llama-3-8b',
        name: 'Llama 3-8B',
        group: 'meta',
      ),
      LLMModel(
        id: 'llama-3-70b',
        name: 'Llama 3-70B',
        group: 'meta',
      ),
    ],
  ),
  LLMModelGroup(
    id: 'mistral',
    name: 'Mistral AI',
    models: [
      LLMModel(
        id: 'mistral-large-3',
        name: 'Mistral Large 3',
        group: 'mistral',
      ),
      LLMModel(
        id: 'mistral-small-4',
        name: 'Mistral Small 4',
        group: 'mistral',
      ),
      LLMModel(
        id: 'mistral-large-2',
        name: 'Mistral Large 2',
        group: 'mistral',
      ),
      LLMModel(
        id: 'mistral-medium-3',
        name: 'Mistral Medium 3',
        group: 'mistral',
      ),
      LLMModel(
        id: 'codestral-22b',
        name: 'Codestral-22B',
        group: 'mistral',
      ),
      LLMModel(
        id: 'codestral-7b',
        name: 'Codestral-7B',
        group: 'mistral',
      ),
      LLMModel(
        id: 'minstral-3b',
        name: 'Ministral 3B',
        group: 'mistral',
      ),
      LLMModel(
        id: 'minstral-8b',
        name: 'Ministral 8B',
        group: 'mistral',
      ),
      LLMModel(
        id: 'mistral-7b',
        name: 'Mistral-7B',
        group: 'mistral',
      ),
      LLMModel(
        id: 'mixtral-8x7b',
        name: 'Mixtral-8x7B',
        group: 'mistral',
      ),
      LLMModel(
        id: 'mixtral-8x22b',
        name: 'Mixtral-8x22B',
        group: 'mistral',
      ),
    ],
  ),
  LLMModelGroup(
    id: 'openai',
    name: 'OpenAI',
    models: [
      LLMModel(
        id: 'gpt-5.4',
        name: 'GPT-5.4',
        group: 'openai',
      ),
      LLMModel(
        id: 'gpt-5.3',
        name: 'GPT-5.3',
        group: 'openai',
      ),
      LLMModel(
        id: 'gpt-5.3-codex',
        name: 'GPT-5.3 Codex',
        group: 'openai',
      ),
      LLMModel(
        id: 'gpt-5.2',
        name: 'GPT-5.2',
        group: 'openai',
      ),
      LLMModel(
        id: 'gpt-5.1',
        name: 'GPT-5.1',
        group: 'openai',
      ),
      LLMModel(
        id: 'o4-mini',
        name: 'O4-Mini',
        group: 'openai',
      ),
      LLMModel(
        id: 'gpt-5',
        name: 'GPT-5',
        group: 'openai',
      ),
      LLMModel(
        id: 'gpt-4o',
        name: 'GPT-4o',
        group: 'openai',
      ),
      LLMModel(
        id: 'gpt-4o-mini',
        name: 'GPT-4o Mini',
        group: 'openai',
      ),
      LLMModel(
        id: 'gpt-4-turbo',
        name: 'GPT-4 Turbo',
        group: 'openai',
      ),
    ],
  ),
  LLMModelGroup(
    id: 'anthropic',
    name: 'Anthropic',
    models: [
      LLMModel(
        id: 'claude-4.6-opus',
        name: 'Claude 4.6 Opus',
        group: 'anthropic',
      ),
      LLMModel(
        id: 'claude-4.6-sonnet',
        name: 'Claude 4.6 Sonnet',
        group: 'anthropic',
      ),
      LLMModel(
        id: 'claude-4.5-sonnet',
        name: 'Claude 4.5 Sonnet',
        group: 'anthropic',
      ),
      LLMModel(
        id: 'claude-4.5-haiku',
        name: 'Claude 4.5 Haiku',
        group: 'anthropic',
      ),
      LLMModel(
        id: 'claude-4-opus',
        name: 'Claude 4 Opus',
        group: 'anthropic',
      ),
      LLMModel(
        id: 'claude-sonnet-4.5',
        name: 'Claude Sonnet 4.5',
        group: 'anthropic',
      ),
      LLMModel(
        id: 'claude-opus-4.1',
        name: 'Claude Opus 4.1',
        group: 'anthropic',
      ),
      LLMModel(
        id: 'claude-3.5-sonnet',
        name: 'Claude 3.5 Sonnet',
        group: 'anthropic',
      ),
      LLMModel(
        id: 'claude-3-opus',
        name: 'Claude 3 Opus',
        group: 'anthropic',
      ),
      LLMModel(
        id: 'claude-3-sonnet',
        name: 'Claude 3 Sonnet',
        group: 'anthropic',
      ),
      LLMModel(
        id: 'claude-3-haiku',
        name: 'Claude 3 Haiku',
        group: 'anthropic',
      ),
    ],
  ),
  LLMModelGroup(
    id: 'google',
    name: 'Google',
    models: [
      LLMModel(
        id: 'gemini-3.1-pro',
        name: 'Gemini 3.1 Pro',
        group: 'google',
      ),
      LLMModel(
        id: 'gemini-3.1-flash',
        name: 'Gemini 3.1 Flash',
        group: 'google',
      ),
      LLMModel(
        id: 'gemini-3-family',
        name: 'Gemini 3 Family',
        group: 'google',
      ),
      LLMModel(
        id: 'gemini-3-pro',
        name: 'Gemini 3 Pro',
        group: 'google',
      ),
      LLMModel(
        id: 'gemini-2.5-pro',
        name: 'Gemini 2.5 Pro',
        group: 'google',
      ),
      LLMModel(
        id: 'gemini-2.5-flash',
        name: 'Gemini 2.5 Flash',
        group: 'google',
      ),
      LLMModel(
        id: 'gemini-2.5-flash-lite',
        name: 'Gemini 2.5 Flash-Lite',
        group: 'google',
      ),
    ],
  ),
  LLMModelGroup(
    id: 'zhipu',
    name: '智谱 AI',
    models: [
      LLMModel(
        id: 'glm-5',
        name: 'GLM-5',
        group: 'zhipu',
      ),
      LLMModel(
        id: 'glm-5-turbo',
        name: 'GLM-5 Turbo',
        group: 'zhipu',
      ),
      LLMModel(
        id: 'glm-4.7',
        name: 'GLM-4.7',
        group: 'zhipu',
      ),
      LLMModel(
        id: 'glm-4.6',
        name: 'GLM-4.6',
        group: 'zhipu',
      ),
      LLMModel(
        id: 'glm-4.5',
        name: 'GLM-4.5',
        group: 'zhipu',
      ),
      LLMModel(
        id: 'glm-4.5-air',
        name: 'GLM-4.5 Air',
        group: 'zhipu',
      ),
      LLMModel(
        id: 'glm-4',
        name: 'GLM-4',
        group: 'zhipu',
      ),
      LLMModel(
        id: 'glm-4-flash',
        name: 'GLM-4 Flash',
        group: 'zhipu',
      ),
      LLMModel(
        id: 'codegeex-4',
        name: 'CodeGeeX-4',
        group: 'zhipu',
      ),
    ],
  ),
  LLMModelGroup(
    id: 'moonshot',
    name: '月之暗面',
    models: [
      LLMModel(
        id: 'kimi-k2.5',
        name: 'Kimi K2.5',
        group: 'moonshot',
      ),
      LLMModel(
        id: 'kimi-k2',
        name: 'Kimi K2',
        group: 'moonshot',
      ),
      LLMModel(
        id: 'kimi-pro',
        name: 'Kimi Pro',
        group: 'moonshot',
      ),
      LLMModel(
        id: 'kimi-k2-thinking',
        name: 'Kimi K2 Thinking',
        group: 'moonshot',
      ),
      LLMModel(
        id: 'moonshot-v1-8k',
        name: 'Moonshot v1 8K',
        group: 'moonshot',
      ),
      LLMModel(
        id: 'moonshot-v1-32k',
        name: 'Moonshot v1 32K',
        group: 'moonshot',
      ),
      LLMModel(
        id: 'moonshot-v1-128k',
        name: 'Moonshot v1 128K',
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
        group: 'xfyun',
      ),
      LLMModel(
        id: 'spark-x1',
        name: 'Spark X1',
        group: 'xfyun',
      ),
      LLMModel(
        id: 'spark-multilingual',
        name: 'Spark Multilingual',
        group: 'xfyun',
      ),
      LLMModel(
        id: 'spark-3.5',
        name: 'Spark 3.5',
        group: 'xfyun',
      ),
      LLMModel(
        id: 'spark-lite',
        name: 'Spark Lite',
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
        group: 'cohere',
      ),
      LLMModel(
        id: 'command-r7b-12-2024',
        name: 'Command R7B (12-2024)',
        group: 'cohere',
      ),
      LLMModel(
        id: 'command-a-translate-08-2025',
        name: 'Command A Translate (08-2025)',
        group: 'cohere',
      ),
      LLMModel(
        id: 'command-a-reasoning-08-2025',
        name: 'Command A Reasoning (08-2025)',
        group: 'cohere',
      ),
      LLMModel(
        id: 'command-a-vision-07-2025',
        name: 'Command A Vision (07-2025)',
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
        group: 'alibaba-qwen',
      ),
      LLMModel(
        id: 'qwen-max-longcontext',
        name: 'Qwen Max LongContext',
        group: 'alibaba-qwen',
      ),
      LLMModel(
        id: 'qwen-turbo',
        name: 'Qwen Turbo',
        group: 'alibaba-qwen',
      ),
      LLMModel(
        id: 'qwen-plus',
        name: 'Qwen Plus',
        group: 'alibaba-qwen',
      ),
    ],
  ),
  LLMModelGroup(
    id: 'perplexity',
    name: 'Perplexity',
    models: [
      LLMModel(
        id: 'sonar-pro',
        name: 'Sonar Pro',
        group: 'perplexity',
      ),
      LLMModel(
        id: 'sonar',
        name: 'Sonar',
        group: 'perplexity',
      ),
      LLMModel(
        id: 'pplx-70b-online',
        name: 'PPLX 70B Online',
        group: 'perplexity',
      ),
    ],
  ),
  LLMModelGroup(
    id: 'xai',
    name: 'xAI',
    models: [
      LLMModel(
        id: 'grok-4.20',
        name: 'Grok 4.20',
        group: 'xai',
      ),
      LLMModel(
        id: 'grok-4.1',
        name: 'Grok 4.1',
        group: 'xai',
      ),
      LLMModel(
        id: 'grok-4',
        name: 'Grok 4',
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
        group: 'other',
      ),
      LLMModel(
        id: 'baichuan2-13b',
        name: 'Baichuan2-13B',
        group: 'other',
      ),
      LLMModel(
        id: 'internlm2-20b',
        name: 'InternLM2-20B',
        group: 'other',
      ),
      LLMModel(
        id: 'phi-3',
        name: 'Phi-3',
        group: 'other',
      ),
      LLMModel(
        id: 'gemma-7b',
        name: 'Gemma-7B',
        group: 'other',
      ),
    ],
  ),
  LLMModelGroup(
    id: 'minimax',
    name: 'MiniMax',
    models: [
      LLMModel(
        id: 'MiniMax-M2.7',
        name: 'MiniMax-M2.7',
        group: 'minimax',
      ),
      LLMModel(
        id: 'MiniMax-M2-her',
        name: 'MiniMax-M2-HER',
        group: 'minimax',
      ),
      LLMModel(
        id: 'MiniMax-M1-80k',
        name: 'MiniMax-M1-80K',
        group: 'minimax',
      ),
      LLMModel(
        id: 'MiniMax-M2.5',
        name: 'MiniMax-M2.5',
        group: 'minimax',
      ),
      LLMModel(
        id: 'MiniMax-M2.5-highspeed',
        name: 'MiniMax-M2.5-highspeed',
        group: 'minimax',
      ),
      LLMModel(
        id: 'MiniMax-M2.1',
        name: 'MiniMax-M2.1',
        group: 'minimax',
      ),
      LLMModel(
        id: 'MiniMax-M2.1-highspeed',
        name: 'MiniMax-M2.1-highspeed',
        group: 'minimax',
      ),
      LLMModel(
        id: 'MiniMax-M2',
        name: 'MiniMax-M2',
        group: 'minimax',
      ),
      LLMModel(
        id: 'abab6.5s-chat',
        name: 'abab6.5s-chat',
        group: 'minimax',
      ),
      LLMModel(
        id: 'abab6.5-chat',
        name: 'abab6.5-chat',
        group: 'minimax',
      ),
      LLMModel(
        id: 'abab5.5-chat',
        name: 'abab5.5-chat',
        group: 'minimax',
      ),
      LLMModel(
        id: 'abab5.5s-chat',
        name: 'abab5.5s-chat',
        group: 'minimax',
      ),
    ],
  ),
];
