import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:json_dynamic_widget/json_dynamic_widget.dart';

/// JSON 动态 UI 测试页面
/// 用于快速测试和预览 json_dynamic_widget 配置
class JsonDynamicTestScreen extends StatefulWidget {
  const JsonDynamicTestScreen({super.key});

  @override
  State<JsonDynamicTestScreen> createState() => _JsonDynamicTestScreenState();
}

class _JsonDynamicTestScreenState extends State<JsonDynamicTestScreen> {
  final TextEditingController _jsonController = TextEditingController();
  final JsonWidgetRegistry _registry = JsonWidgetRegistry.instance;
  String? _errorMessage;

  // 预设示例 JSON 模板
  final List<JsonTemplate> _templates = [
    JsonTemplate(
      name: '简单容器',
      description: '包含文本和按钮的容器',
      json: '''
{
  "type": "container",
  "args": {
    "padding": {
      "type": "edgeInsets",
      "args": {"all": 20.0}
    },
    "decoration": {
      "type": "boxDecoration",
      "args": {
        "color": "#E3F2FD",
        "borderRadius": {
          "type": "borderRadius",
          "args": {"all": {"radius": 12.0}}
        }
      }
    },
    "child": {
      "type": "column",
      "args": {
        "mainAxisSize": "min",
        "crossAxisAlignment": "center",
        "children": [
          {
            "type": "text",
            "args": {
              "data": "Hello, Dynamic Widget!",
              "style": {
                "fontSize": 20.0,
                "fontWeight": "bold",
                "color": "#1976D2"
              }
            }
          },
          {
            "type": "sizedBox",
            "args": {"height": 16.0}
          },
          {
            "type": "elevatedButton",
            "args": {
              "child": {
                "type": "text",
                "args": {"data": "点击我"}
              },
              "onPressed": {}
            }
          }
        ]
      }
    }
  }
}
'''
    ),
    JsonTemplate(
      name: '列表卡片',
      description: '带图标的列表项',
      json: '''
{
  "type": "card",
  "args": {
    "margin": {
      "type": "edgeInsets",
      "args": {"all": 8.0}
    },
    "child": {
      "type": "listTile",
      "args": {
        "leading": {
          "type": "icon",
          "args": {
            "icon": "star",
            "color": "#FFC107",
            "size": 32.0
          }
        },
        "title": {
          "type": "text",
          "args": {
            "data": "卡片标题",
            "style": {
              "fontSize": 18.0,
              "fontWeight": "bold"
            }
          }
        },
        "subtitle": {
          "type": "text",
          "args": {"data": "这是卡片的描述信息"}
        },
        "trailing": {
          "type": "icon",
          "args": {
            "icon": "chevron_right",
            "color": "#757575"
          }
        }
      }
    }
  }
}
'''
    ),
    JsonTemplate(
      name: '表单输入',
      description: '包含输入框和开关的表单',
      json: '''
{
  "type": "container",
  "args": {
    "padding": {
      "type": "edgeInsets",
      "args": {"all": 16.0}
    },
    "child": {
      "type": "column",
      "args": {
        "mainAxisSize": "min",
        "children": [
          {
            "type": "textFormField",
            "args": {
              "decoration": {
                "labelText": "用户名",
                "hintText": "请输入用户名",
                "border": "outline"
              }
            }
          },
          {
            "type": "sizedBox",
            "args": {"height": 16.0}
          },
          {
            "type": "textFormField",
            "args": {
              "decoration": {
                "labelText": "密码",
                "hintText": "请输入密码",
                "border": "outline"
              },
              "obscureText": true
            }
          },
          {
            "type": "sizedBox",
            "args": {"height": 16.0}
          },
          {
            "type": "switchListTile",
            "args": {
              "title": {
                "type": "text",
                "args": {"data": "记住我"}
              },
              "value": false
            }
          }
        ]
      }
    }
  }
}
'''
    ),
    JsonTemplate(
      name: '网格布局',
      description: '使用 Wrap 实现的网格',
      json: '''
{
  "type": "wrap",
  "args": {
    "spacing": 8.0,
    "runSpacing": 8.0,
    "children": [
      {
        "type": "chip",
        "args": {
          "label": {
            "type": "text",
            "args": {"data": "标签 1"}
          },
          "backgroundColor": "#E3F2FD"
        }
      },
      {
        "type": "chip",
        "args": {
          "label": {
            "type": "text",
            "args": {"data": "标签 2"}
          },
          "backgroundColor": "#F3E5F5"
        }
      },
      {
        "type": "chip",
        "args": {
          "label": {
            "type": "text",
            "args": {"data": "标签 3"}
          },
          "backgroundColor": "#E8F5E9"
        }
      },
      {
        "type": "chip",
        "args": {
          "label": {
            "type": "text",
            "args": {"data": "标签 4"}
          },
          "backgroundColor": "#FFF3E0"
        }
      }
    ]
  }
}
'''
    ),
    JsonTemplate(
      name: '复杂布局',
      description: '组合使用多种组件',
      json: '''
{
  "type": "container",
  "args": {
    "padding": {
      "type": "edgeInsets",
      "args": {"all": 16.0}
    },
    "child": {
      "type": "column",
      "args": {
        "mainAxisSize": "min",
        "crossAxisAlignment": "stretch",
        "children": [
          {
            "type": "container",
            "args": {
              "padding": {
                "type": "edgeInsets",
                "args": {"all": 16.0}
              },
              "decoration": {
                "type": "boxDecoration",
                "args": {
                  "gradient": {
                    "type": "linearGradient",
                    "args": {
                      "colors": ["#2196F3", "#1976D2"],
                      "begin": "topLeft",
                      "end": "bottomRight"
                    }
                  },
                  "borderRadius": {
                    "type": "borderRadius",
                    "args": {"all": {"radius": 12.0}}
                  }
                }
              },
              "child": {
                "type": "column",
                "args": {
                  "mainAxisSize": "min",
                  "children": [
                    {
                      "type": "text",
                      "args": {
                        "data": "欢迎使用",
                        "style": {
                          "fontSize": 24.0,
                          "fontWeight": "bold",
                          "color": "#FFFFFF"
                        }
                      }
                    },
                    {
                      "type": "sizedBox",
                      "args": {"height": 8.0}
                    },
                    {
                      "type": "text",
                      "args": {
                        "data": "JSON 动态 UI 测试工具",
                        "style": {
                          "fontSize": 16.0,
                          "color": "#E3F2FD"
                        }
                      }
                    }
                  ]
                }
              }
            }
          },
          {
            "type": "sizedBox",
            "args": {"height": 16.0}
          },
          {
            "type": "row",
            "args": {
              "mainAxisAlignment": "spaceAround",
              "children": [
                {
                  "type": "column",
                  "args": {
                    "mainAxisSize": "min",
                    "children": [
                      {
                        "type": "icon",
                        "args": {
                          "icon": "favorite",
                          "color": "#E91E63",
                          "size": 32.0
                        }
                      },
                      {
                        "type": "sizedBox",
                        "args": {"height": 4.0}
                      },
                      {
                        "type": "text",
                        "args": {"data": "收藏"}
                      }
                    ]
                  }
                },
                {
                  "type": "column",
                  "args": {
                    "mainAxisSize": "min",
                    "children": [
                      {
                        "type": "icon",
                        "args": {
                          "icon": "share",
                          "color": "#2196F3",
                          "size": 32.0
                        }
                      },
                      {
                        "type": "sizedBox",
                        "args": {"height": 4.0}
                      },
                      {
                        "type": "text",
                        "args": {"data": "分享"}
                      }
                    ]
                  }
                },
                {
                  "type": "column",
                  "args": {
                    "mainAxisSize": "min",
                    "children": [
                      {
                        "type": "icon",
                        "args": {
                          "icon": "settings",
                          "color": "#757575",
                          "size": 32.0
                        }
                      },
                      {
                        "type": "sizedBox",
                        "args": {"height": 4.0}
                      },
                      {
                        "type": "text",
                        "args": {"data": "设置"}
                      }
                    ]
                  }
                }
              ]
            }
          }
        ]
      }
    }
  }
}
'''
    ),
  ];

  @override
  void initState() {
    super.initState();
    // 默认加载第一个模板
    if (_templates.isNotEmpty) {
      _jsonController.text = _templates.first.json.trim();
    }
  }

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  // 解析 JSON 并构建 Widget
  JsonWidgetData? _buildJsonWidget(String jsonString) {
    try {
      final dynamic jsonData = json.decode(jsonString);
      setState(() {
        _errorMessage = null;
      });
      return JsonWidgetData.fromDynamic(jsonData, registry: _registry);
    } catch (e) {
      setState(() {
        _errorMessage = '解析错误: $e';
      });
      return null;
    }
  }

  // 显示预览对话框
  void _showPreviewDialog() {
    final jsonString = _jsonController.text.trim();
    if (jsonString.isEmpty) {
      _showErrorSnackBar('请输入 JSON 配置');
      return;
    }

    final widgetData = _buildJsonWidget(jsonString);
    if (widgetData == null) {
      _showErrorSnackBar(_errorMessage ?? '解析失败');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 600,
            maxHeight: 700,
          ),
          child: Column(
            children: [
              // 标题栏
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.preview,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'UI 预览',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              // 预览内容
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: widgetData.build(context: context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 加载模板
  void _loadTemplate(JsonTemplate template) {
    setState(() {
      _jsonController.text = template.json.trim();
      _errorMessage = null;
    });
    _showSuccessSnackBar('已加载模板: ${template.name}');
  }

  // 显示模板选择对话框
  void _showTemplateDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.snippet_folder,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '选择模板',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              // 模板列表
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _templates.length,
                  itemBuilder: (context, index) {
                    final template = _templates[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text('${index + 1}'),
                      ),
                      title: Text(template.name),
                      subtitle: Text(template.description),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.of(context).pop();
                        _loadTemplate(template);
                      },
                    );
                  },
                ),
              ),
              // 关闭按钮
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 清空编辑器
  void _clearEditor() {
    setState(() {
      _jsonController.clear();
      _errorMessage = null;
    });
  }

  // 格式化 JSON
  void _formatJson() {
    try {
      final jsonString = _jsonController.text.trim();
      if (jsonString.isEmpty) {
        _showErrorSnackBar('请输入 JSON 配置');
        return;
      }

      final dynamic jsonData = json.decode(jsonString);
      const encoder = JsonEncoder.withIndent('  ');
      final formatted = encoder.convert(jsonData);

      setState(() {
        _jsonController.text = formatted;
        _errorMessage = null;
      });
      _showSuccessSnackBar('格式化成功');
    } catch (e) {
      _showErrorSnackBar('格式化失败: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JSON 动态 UI 测试'),
        actions: [
          IconButton(
            onPressed: _showTemplateDialog,
            icon: const Icon(Icons.snippet_folder),
            tooltip: '选择模板',
          ),
          IconButton(
            onPressed: _formatJson,
            icon: const Icon(Icons.format_align_left),
            tooltip: '格式化',
          ),
          IconButton(
            onPressed: _clearEditor,
            icon: const Icon(Icons.clear),
            tooltip: '清空',
          ),
        ],
      ),
      body: Column(
        children: [
          // JSON 编辑器
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _errorMessage != null
                      ? Colors.red
                      : Theme.of(context).colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // 编辑器标题
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.code,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'JSON 配置编辑器',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 编辑器内容
                  Expanded(
                    child: TextField(
                      controller: _jsonController,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                      decoration: const InputDecoration(
                        hintText: '在此输入或粘贴 JSON 配置...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                      onChanged: (value) {
                        // 实时验证
                        if (value.trim().isNotEmpty) {
                          _buildJsonWidget(value);
                        }
                      },
                    ),
                  ),
                  // 错误信息
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          // 操作按钮
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _showTemplateDialog,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('加载模板'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: _showPreviewDialog,
                  icon: const Icon(Icons.visibility),
                  label: const Text('预览效果'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// JSON 模板数据类
class JsonTemplate {
  final String name;
  final String description;
  final String json;

  const JsonTemplate({
    required this.name,
    required this.description,
    required this.json,
  });
}
