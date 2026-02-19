修改总结                                                               
                                                            
  1. HomeWidgetSize.fromCategory 工厂方法                                
                                                                         
  根据 SizeCategory 创建对应的 size 实例：                               
  - mini/small → SmallSize (1x1)
  - medium → MediumSize (2x1)
  - large → LargeSize (2x2)
  - xlarge → Wide2Size (4x2)

  2. CommonWidgetBuilder.build 方法增强

  现在会检查 props 中的 _pixelCategory，如果存在则使用它创建有效的
  size，而不是使用基于网格占比的原始 size。

  工作流程

  窗口大小变化
      ↓
  HomeCard.didChangeDependencies 检测到变化
      ↓
  计算 _pixelCategory 并注入 config
      ↓
  CommonWidgetBuilder.build 读取 _pixelCategory
      ↓
  创建 effectiveSize = HomeWidgetSize.fromCategory(pixelCategory)
      ↓
  NewsCardWidget 收到 effectiveSize (如 SmallSize)
      ↓
  widget.size is SmallSize 判断为 true，隐藏头条区域