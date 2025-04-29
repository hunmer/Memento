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
];