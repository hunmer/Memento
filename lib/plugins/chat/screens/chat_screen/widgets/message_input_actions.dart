import 'package:flutter/material.dart';

class MessageInputAction {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  MessageInputAction({
    required this.title,
    required this.icon,
    required this.onTap,
  });
}

class MessageInputActionsDrawer extends StatelessWidget {
  final List<MessageInputAction> actions;

  const MessageInputActionsDrawer({
    Key? key,
    required this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.only(
        top: 16.0 + MediaQuery.of(context).padding.top,
        bottom: 16.0 + MediaQuery.of(context).padding.bottom,
        left: 16.0,
        right: 16.0,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '选择操作',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24.0),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.8,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 24.0,
              ),
              itemCount: actions.length,
              itemBuilder: (context, index) => _buildActionItem(context, actions[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(BuildContext context, MessageInputAction action) {
    return InkWell(
      onTap: () {
        Navigator.pop(context); // 关闭抽屉
        action.onTap();
      },
      borderRadius: BorderRadius.circular(12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60.0,
            height: 60.0,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Icon(
              action.icon,
              color: Theme.of(context).colorScheme.primary,
              size: 28.0,
            ),
          ),
          const SizedBox(height: 12.0),
          Text(
            action.title,
            style: TextStyle(
              fontSize: 14.0,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[300]
                  : Colors.grey[700],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// 预定义的操作列表
List<MessageInputAction> getDefaultMessageInputActions(BuildContext context) {
  return [
    MessageInputAction(
      title: '文本样式',
      icon: Icons.text_fields,
      onTap: () {
        // 文本样式功能
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('文本样式功能待实现')),
        );
      },
    ),
    MessageInputAction(
      title: '文件',
      icon: Icons.attach_file,
      onTap: () {
        // 文件功能
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('文件功能待实现')),
        );
      },
    ),
    MessageInputAction(
      title: '图片',
      icon: Icons.image,
      onTap: () {
        // 图片功能
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('图片功能待实现')),
        );
      },
    ),
    MessageInputAction(
      title: '视频',
      icon: Icons.videocam,
      onTap: () {
        // 视频功能
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('视频功能待实现')),
        );
      },
    ),
  ];
}