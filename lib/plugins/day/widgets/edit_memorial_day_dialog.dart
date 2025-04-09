import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../models/memorial_day.dart';
import '../l10n/day_localizations.dart';

class EditMemorialDayDialog extends StatefulWidget {
  final MemorialDay? memorialDay;

  const EditMemorialDayDialog({
    super.key,
    this.memorialDay,
  });

  @override
  State<EditMemorialDayDialog> createState() => _EditMemorialDayDialogState();
}

class _EditMemorialDayDialogState extends State<EditMemorialDayDialog> with SingleTickerProviderStateMixin {
  late TextEditingController _titleController;
  late DateTime _selectedDate;
  late List<String> _notes;
  late Color _selectedColor;
  String? _backgroundImageUrl;
  late TabController _tabController;
  final ScrollController _horizontalScrollController = ScrollController();
  
  // 预定义的背景图片列表
  final List<String> _predefinedBackgroundImages = [
    'https://images.unsplash.com/photo-1506744038136-46273834b3fb', // 自然风景
    'https://images.unsplash.com/photo-1507525428034-b723cf961d3e', // 海滩
    'https://images.unsplash.com/photo-1519681393784-d120267933ba', // 星空
    'https://images.unsplash.com/photo-1554080353-a576cf803bda', // 山脉
    'https://images.unsplash.com/photo-1490750967868-88aa4486c946', // 花朵
    'https://images.unsplash.com/photo-1513151233558-d860c5398176', // 城市
    'https://images.unsplash.com/photo-1501785888041-af3ef285b470', // 日落
    'https://images.unsplash.com/photo-1515266591878-f93e32bc5937', // 雪景
    'https://images.unsplash.com/photo-1500964757637-c85e8a162699', // 田野
    'https://images.unsplash.com/photo-1532274402911-5a369e4c4bb5', // 森林
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.memorialDay?.title);
    _selectedDate = widget.memorialDay?.targetDate ?? DateTime.now();
    _notes = List.from(widget.memorialDay?.notes ?? []);
    _selectedColor = widget.memorialDay?.backgroundColor ?? Colors.blue[300]!;
    _backgroundImageUrl = widget.memorialDay?.backgroundImageUrl;
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _tabController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = DayLocalizations.of(context);

    return AlertDialog(
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.memorialDay == null
              ? localizations.addMemorialDay
              : localizations.editMemorialDay),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                icon: const Icon(Icons.info_outline),
                text: localizations.information,
              ),
              Tab(
                icon: const Icon(Icons.notes),
                text: localizations.notes,
              ),
              Tab(
                icon: const Icon(Icons.palette_outlined),
                text: localizations.appearance,
              ),
            ],
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.5,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildInformationTab(localizations),
            _buildNotesTab(localizations),
            _buildAppearanceTab(localizations),
          ],
        ),
      ),
      actions: [
        // 取消按钮
        TextButton(
          onPressed: () => Navigator.of(context).pop('cancel'),
          child: Text(localizations.cancel),
        ),
        // 删除按钮（仅编辑时显示）
        if (widget.memorialDay != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop('delete');
            },
            child: Text(
              localizations.delete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        // 保存按钮
        TextButton(
          onPressed: _save,
          child: Text(localizations.save),
        ),
      ],
    );
  }

  Widget _buildInformationTab(DayLocalizations localizations) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题输入
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: localizations.title,
              hintText: localizations.enterTitle,
            ),
            maxLength: 50,
          ),
          const SizedBox(height: 16),

          // 日期选择
          Row(
            children: [
              Text(localizations.targetDate),
              const SizedBox(width: 16),
              TextButton(
                onPressed: _selectDate,
                child: Text(_formatDate(_selectedDate)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesTab(DayLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView(
            children: [
              ..._buildNotesList(),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: _addNote,
          icon: const Icon(Icons.add),
          label: Text(localizations.addNote),
        ),
      ],
    );
  }

  Widget _buildAppearanceTab(DayLocalizations localizations) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 背景颜色选择
          Text(localizations.backgroundColor),
          const SizedBox(height: 8),
          _buildColorPicker(),
          const SizedBox(height: 16),

          // 背景图片选择
          Text(localizations.backgroundImage),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch, 
                  PointerDeviceKind.mouse,
                },
                // 自定义滚动行为，使鼠标滚轮可以水平滚动
                physics: const BouncingScrollPhysics(),
              ),
              child: MouseRegion(
                child: Scrollbar(
                  controller: _horizontalScrollController,
                  thumbVisibility: true,
                  child: ListView(
                    controller: _horizontalScrollController,
                    scrollDirection: Axis.horizontal,
                    children: [
                      // 上传按钮
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: InkWell(
                          onTap: () {
                            // TODO: 实现图片上传功能
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('图片上传功能即将推出')),
                            );
                          },
                          child: Container(
                            width: 80,
                            decoration: BoxDecoration(
                              border: Border.all(color: Theme.of(context).dividerColor),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined, size: 24),
                                  SizedBox(height: 4),
                                  Text('上传图片', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                
                      // 预定义图片列表
                            ..._predefinedBackgroundImages.map((imageUrl) => Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _backgroundImageUrl = imageUrl;
                              });
                            },
                            child: Container(
                              width: 80,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _backgroundImageUrl == imageUrl
                                      ? Theme.of(context).primaryColor
                                      : Theme.of(context).dividerColor,
                                  width: _backgroundImageUrl == imageUrl ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: NetworkImage('$imageUrl?w=200&h=200&fit=crop'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        )),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // 预览区域
          if (_backgroundImageUrl != null) ...[
            const SizedBox(height: 16),
            Text(localizations.preview),
            const SizedBox(height: 8),
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: _selectedColor,
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage('$_backgroundImageUrl?w=400&fit=crop'),
                  fit: BoxFit.cover,
                  onError: (_, __) {
                    setState(() {
                      // 图片加载失败时不显示图片
                      _backgroundImageUrl = null;
                    });
                  },
                ),
              ),
              child: Center(
                child: Text(
                  _titleController.text.isNotEmpty ? _titleController.text : '纪念日标题',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        offset: Offset(1, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildNotesList() {
    return _notes.asMap().entries.map((entry) {
      final index = entry.key;
      final note = entry.value;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: DayLocalizations.of(context).enterNote,
                ),
                controller: TextEditingController(text: note),
                onChanged: (value) {
                  _notes[index] = value;
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () {
                setState(() {
                  _notes.removeAt(index);
                });
              },
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildColorPicker() {
    final colors = [
      Colors.red[300]!,
      Colors.pink[300]!,
      Colors.purple[300]!,
      Colors.deepPurple[300]!,
      Colors.indigo[300]!,
      Colors.blue[300]!,
      Colors.lightBlue[300]!,
      Colors.cyan[300]!,
      Colors.teal[300]!,
      Colors.green[300]!,
      Colors.lightGreen[300]!,
      Colors.amber[300]!,
      Colors.orange[300]!,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: colors.map((color) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedColor = color;
            });
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: _selectedColor == color ? Colors.white : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                if (_selectedColor == color)
                  BoxShadow(
                  color: Color.fromRGBO(
                    color.r.round(),
                    color.g.round(),
                    color.b.round(),
                    0.5,
                  ),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _addNote() {
    setState(() {
      _notes.add('');
    });
  }

  void _save() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(DayLocalizations.of(context).titleRequired),
        ),
      );
      return;
    }

    final memorialDay = MemorialDay(
      id: widget.memorialDay?.id,
      title: _titleController.text.trim(),
      targetDate: _selectedDate,
      notes: _notes.where((note) => note.trim().isNotEmpty).toList(),
      backgroundColor: _selectedColor,
      backgroundImageUrl: _backgroundImageUrl,
    );

    Navigator.of(context).pop(memorialDay);
  }
}