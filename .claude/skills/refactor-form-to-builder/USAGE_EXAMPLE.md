# Refactor Form to Builder - Usage Examples

实际使用示例，展示如何将不同类型的表单转换为 FormBuilderWrapper

## 示例 1: 用户注册表单

### Before

```dart
class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _selectedGender;
  DateTime? _birthDate;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _register() {
    if (_usernameController.text.isEmpty) {
      _showError('用户名不能为空');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('两次密码不一致');
      return;
    }
    if (!_agreeToTerms) {
      _showError('请同意服务条款');
      return;
    }

    // 注册逻辑...
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('用户注册')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: '用户名',
              prefixIcon: Icon(Icons.person),
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: '邮箱',
              prefixIcon: Icon(Icons.email),
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: '密码',
              prefixIcon: Icon(Icons.lock),
            ),
            obscureText: true,
          ),
          SizedBox(height: 16),
          TextField(
            controller: _confirmPasswordController,
            decoration: InputDecoration(
              labelText: '确认密码',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            obscureText: true,
          ),
          SizedBox(height: 16),
          DropdownButton<String>(
            value: _selectedGender,
            hint: Text('选择性别'),
            items: [
              DropdownMenuItem(value: 'male', child: Text('男')),
              DropdownMenuItem(value: 'female', child: Text('女')),
              DropdownMenuItem(value: 'other', child: Text('其他')),
            ],
            onChanged: (value) => setState(() => _selectedGender = value),
          ),
          SizedBox(height: 16),
          ListTile(
            title: Text('出生日期'),
            subtitle: Text(_birthDate != null
                ? '${_birthDate!.year}-${_birthDate!.month}-${_birthDate!.day}'
                : '选择日期'),
            trailing: Icon(Icons.calendar_today),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() => _birthDate = date);
              }
            },
          ),
          SizedBox(height: 16),
          CheckboxListTile(
            title: Text('我同意服务条款'),
            value: _agreeToTerms,
            onChanged: (value) => setState(() => _agreeToTerms = value ?? false),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _register,
            child: Text('注册'),
          ),
        ],
      ),
    );
  }
}
```

### After

```dart
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  void _register(BuildContext context, Map<String, dynamic> values) {
    // 自定义验证
    if (values['password'] != values['confirmPassword']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('两次密码不一致')),
      );
      return;
    }

    // 注册逻辑
    print('注册: $values');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('注册成功')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('用户注册')),
      body: FormBuilderWrapper(
        config: FormConfig(
          fields: [
            // 用户名
            FormFieldConfig(
              name: 'username',
              type: FormFieldType.text,
              labelText: '用户名',
              hintText: '请输入用户名',
              prefixIcon: Icons.person,
              required: true,
              validationMessage: '用户名不能为空',
            ),

            // 邮箱
            FormFieldConfig(
              name: 'email',
              type: FormFieldType.email,
              labelText: '邮箱',
              hintText: '请输入邮箱地址',
              prefixIcon: Icons.email,
              required: true,
              validationMessage: '请输入有效的邮箱地址',
            ),

            // 密码
            FormFieldConfig(
              name: 'password',
              type: FormFieldType.password,
              labelText: '密码',
              hintText: '请输入密码',
              prefixIcon: Icons.lock,
              required: true,
              validationMessage: '密码不能为空',
            ),

            // 确认密码
            FormFieldConfig(
              name: 'confirmPassword',
              type: FormFieldType.password,
              labelText: '确认密码',
              hintText: '请再次输入密码',
              prefixIcon: Icons.lock_outline,
              required: true,
              validationMessage: '请确认密码',
            ),

            // 性别
            FormFieldConfig(
              name: 'gender',
              type: FormFieldType.select,
              labelText: '性别',
              hintText: '请选择性别',
              required: true,
              items: const [
                DropdownMenuItem(value: 'male', child: Text('男')),
                DropdownMenuItem(value: 'female', child: Text('女')),
                DropdownMenuItem(value: 'other', child: Text('其他')),
              ],
            ),

            // 出生日期
            FormFieldConfig(
              name: 'birthDate',
              type: FormFieldType.date,
              labelText: '出生日期',
              hintText: '选择出生日期',
              extra: {
                'format': 'yyyy-MM-dd',
                'firstDate': DateTime(1900),
                'lastDate': DateTime.now(),
              },
            ),

            // 同意条款
            FormFieldConfig(
              name: 'agreeToTerms',
              type: FormFieldType.switchField,
              labelText: '我同意服务条款',
              initialValue: false,
              required: true,
              validationMessage: '请同意服务条款',
            ),
          ],
          submitButtonText: '注册',
          fieldSpacing: 16,
          onSubmit: (values) => _register(context, values),
        ),
      ),
    );
  }
}
```

## 示例 2: 商品编辑表单 (带 Picker)

### Before

```dart
class EditGoodsScreen extends StatefulWidget {
  final Goods? goods;

  const EditGoodsScreen({super.key, this.goods});

  @override
  _EditGoodsScreenState createState() => _EditGoodsScreenState();
}

class _EditGoodsScreenState extends State<EditGoodsScreen> {
  final _nameController = TextEditingController(text: widget.goods?.name ?? '');
  final _priceController = TextEditingController(text: widget.goods?.price.toString() ?? '');
  final _descController = TextEditingController(text: widget.goods?.description ?? '');
  String? _selectedCategory;
  List<String> _tags = widget.goods?.tags ?? [];
  IconData? _icon;
  Color _color = Colors.blue;
  String? _imageUrl;
  String? _location;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('编辑商品')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: '商品名称'),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _priceController,
            decoration: InputDecoration(labelText: '价格'),
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 16),
          TextField(
            controller: _descController,
            decoration: InputDecoration(labelText: '描述'),
            maxLines: 3,
          ),
          SizedBox(height: 16),
          DropdownButton<String>(
            value: _selectedCategory,
            hint: Text('选择分类'),
            items: [
              DropdownMenuItem(value: 'food', child: Text('食品')),
              DropdownMenuItem(value: 'clothes', child: Text('服装')),
              DropdownMenuItem(value: 'electronics', child: Text('电子产品')),
            ],
            onChanged: (v) => setState(() => _selectedCategory = v),
          ),
          SizedBox(height: 16),
          // 标签管理 (自定义复杂 UI)
          Text('标签'),
          Wrap(
            children: _tags.map((tag) => Chip(label: Text(tag))).toList(),
          ),
          SizedBox(height: 16),
          // 图标选择
          ListTile(
            leading: Icon(_icon ?? Icons.help),
            title: Text('选择图标'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () async {
              final result = await showDialog<IconData>(
                context: context,
                builder: (_) => IconPickerDialog(currentIcon: _icon),
              );
              if (result != null) setState(() => _icon = result);
            },
          ),
          SizedBox(height: 16),
          // 颜色选择
          ColorPickerSection(
            selectedColor: _color,
            onColorChanged: (c) => setState(() => _color = c),
          ),
          SizedBox(height: 16),
          // 图片选择
          ListTile(
            leading: _imageUrl != null ? Image.network(_imageUrl!) : Icon(Icons.image),
            title: Text('商品图片'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () async {
              final result = await showDialog<Map<String, dynamic>>(
                context: context,
                builder: (_) => ImagePickerDialog(
                  initialUrl: _imageUrl,
                  saveDirectory: 'goods',
                ),
              );
              if (result != null) setState(() => _imageUrl = result['url']);
            },
          ),
          SizedBox(height: 16),
          // 位置选择
          ListTile(
            leading: Icon(Icons.location_on),
            title: Text(_location ?? '选择位置'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () async {
              final result = await showDialog<String>(
                context: context,
                builder: (_) => LocationPicker(
                  isMobile: true,
                  onLocationSelected: (addr) => Navigator.pop(context, addr),
                ),
              );
              if (result != null) setState(() => _location = result);
            },
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // 保存逻辑
              Navigator.pop(context);
            },
            child: Text('保存'),
          ),
        ],
      ),
    );
  }
}
```

### After

```dart
class EditGoodsScreen extends StatelessWidget {
  final Goods? goods;

  const EditGoodsScreen({super.key, this.goods});

  void _save(BuildContext context, Map<String, dynamic> values) {
    print('保存商品: $values');
    Navigator.pop(context, values);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('编辑商品')),
      body: FormBuilderWrapper(
        config: FormConfig(
          fields: [
            // 商品名称
            FormFieldConfig(
              name: 'name',
              type: FormFieldType.text,
              labelText: '商品名称',
              hintText: '请输入商品名称',
              initialValue: goods?.name ?? '',
              required: true,
            ),

            // 价格
            FormFieldConfig(
              name: 'price',
              type: FormFieldType.number,
              labelText: '价格',
              hintText: '请输入价格',
              initialValue: goods?.price ?? 0.0,
            ),

            // 描述
            FormFieldConfig(
              name: 'description',
              type: FormFieldType.textArea,
              labelText: '描述',
              hintText: '请输入商品描述',
              initialValue: goods?.description ?? '',
              extra: {'minLines': 3, 'maxLines': 5},
            ),

            // 分类
            FormFieldConfig(
              name: 'category',
              type: FormFieldType.select,
              labelText: '分类',
              hintText: '选择商品分类',
              initialValue: goods?.category,
              required: true,
              items: const [
                DropdownMenuItem(value: 'food', child: Text('食品')),
                DropdownMenuItem(value: 'clothes', child: Text('服装')),
                DropdownMenuItem(value: 'electronics', child: Text('电子产品')),
              ],
            ),

            // 标签
            FormFieldConfig(
              name: 'tags',
              type: FormFieldType.tags,
              labelText: '标签',
              hintText: '添加标签',
              initialTags: goods?.tags ?? [],
            ),

            // 图标
            FormFieldConfig(
              name: 'icon',
              type: FormFieldType.iconPicker,
              labelText: '选择图标',
              initialValue: goods?.icon ?? Icons.shopping_bag,
            ),

            // 颜色
            FormFieldConfig(
              name: 'color',
              type: FormFieldType.color,
              labelText: '选择颜色',
              initialValue: goods?.color ?? Colors.blue,
            ),

            // 图片
            FormFieldConfig(
              name: 'image',
              type: FormFieldType.imagePicker,
              labelText: '商品图片',
              hintText: '选择商品图片',
              initialValue: goods?.imageUrl,
              extra: {
                'saveDirectory': 'goods',
                'enableCrop': true,
                'cropAspectRatio': 1.0,
              },
            ),

            // 位置
            FormFieldConfig(
              name: 'location',
              type: FormFieldType.locationPicker,
              labelText: '商品位置',
              hintText: '选择商品位置',
              initialValue: goods?.location,
            ),
          ],
          submitButtonText: '保存',
          showResetButton: true,
          fieldSpacing: 16,
          onSubmit: (values) => _save(context, values),
        ),
      ),
    );
  }
}
```

## 代码对比总结

| 项目 | Before | After | 减少 |
|-----|--------|-------|-----|
| 文件行数 | ~200 行 | ~100 行 | ~50% |
| 状态变量 | 10 个 | 0 个 | 100% |
| TextEditingController | 3 个 | 0 个 | 100% |
| dispose 代码 | ~10 行 | 0 行 | 100% |
| UI 样板代码 | ~100 行 | ~20 行 | ~80% |
| 验证代码 | 分散 | 统一 | - |

## 关键改进

1. **StatelessWidget**: 不再需要管理状态
2. **配置化**: 所有字段通过配置定义
3. **类型安全**: 提交时自动获取正确类型的值
4. **验证统一**: 必填字段验证自动处理
5. **重置免费**: 自动获得重置功能
6. **代码清晰**: 表单结构一目了然
