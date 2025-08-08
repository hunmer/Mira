import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dock_item_config_base.dart';

/// 文本组件配置对话框
class TextConfig extends DockItemConfig {
  const TextConfig({Key? key, required super.onConfirm}) : super(key: key);

  @override
  State<TextConfig> createState() => _TextConfigState();
}

class _TextConfigState extends State<TextConfig> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _textController = TextEditingController();
  final _fontSizeController = TextEditingController();

  Color _textColor = Colors.black;
  FontWeight _fontWeight = FontWeight.normal;
  TextAlign _textAlign = TextAlign.center;
  bool _wordWrap = true;
  int _maxLines = 0; // 0 表示无限制

  @override
  void initState() {
    super.initState();
    _nameController.text = 'Text ${DateTime.now().millisecond}';
    _textController.text = 'Sample Text';
    _fontSizeController.text = '16';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _textController.dispose();
    _fontSizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题
                Row(
                  children: [
                    Icon(
                      Icons.text_fields,
                      size: 24,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '配置文本组件',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 组件名称
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '组件名称',
                    hintText: '输入文本组件的显示名称',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '请输入组件名称';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 文本内容
                TextFormField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    labelText: '文本内容',
                    hintText: '输入要显示的文本',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '请输入文本内容';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 字体大小和颜色
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _fontSizeController,
                        decoration: const InputDecoration(
                          labelText: '字体大小',
                          hintText: '输入字体大小 (像素)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*'),
                          ),
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '请输入字体大小';
                          }
                          final doubleValue = double.tryParse(value);
                          if (doubleValue == null || doubleValue <= 0) {
                            return '请输入有效的字体大小';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('文字颜色'),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _showColorPicker,
                          child: Container(
                            width: 60,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _textColor,
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 字体粗细
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('字体粗细'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<FontWeight>(
                      value: _fontWeight,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: FontWeight.w300,
                          child: Text('细体 (300)'),
                        ),
                        DropdownMenuItem(
                          value: FontWeight.normal,
                          child: Text('正常 (400)'),
                        ),
                        DropdownMenuItem(
                          value: FontWeight.w500,
                          child: Text('中等 (500)'),
                        ),
                        DropdownMenuItem(
                          value: FontWeight.w600,
                          child: Text('半粗 (600)'),
                        ),
                        DropdownMenuItem(
                          value: FontWeight.bold,
                          child: Text('粗体 (700)'),
                        ),
                        DropdownMenuItem(
                          value: FontWeight.w800,
                          child: Text('特粗 (800)'),
                        ),
                        DropdownMenuItem(
                          value: FontWeight.w900,
                          child: Text('最粗 (900)'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(
                          () => _fontWeight = value ?? FontWeight.normal,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 文本对齐
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('文本对齐'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<TextAlign>(
                      value: _textAlign,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: TextAlign.left,
                          child: Text('左对齐'),
                        ),
                        DropdownMenuItem(
                          value: TextAlign.center,
                          child: Text('居中'),
                        ),
                        DropdownMenuItem(
                          value: TextAlign.right,
                          child: Text('右对齐'),
                        ),
                        DropdownMenuItem(
                          value: TextAlign.justify,
                          child: Text('两端对齐'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _textAlign = value ?? TextAlign.center);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 最大行数
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: '最大行数',
                    hintText: '输入 0 表示无限制',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*')),
                  ],
                  initialValue: _maxLines.toString(),
                  onChanged: (value) {
                    final intValue = int.tryParse(value);
                    if (intValue != null) {
                      _maxLines = intValue;
                    }
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '请输入最大行数';
                    }
                    final intValue = int.tryParse(value);
                    if (intValue == null || intValue < 0) {
                      return '请输入有效的行数';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 换行选项
                CheckboxListTile(
                  title: const Text('自动换行'),
                  subtitle: const Text('当文本过长时是否自动换行'),
                  value: _wordWrap,
                  onChanged: (value) {
                    setState(() => _wordWrap = value ?? true);
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),

                const SizedBox(height: 24),

                // 预览
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '预览效果',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _textController.text.isEmpty
                                ? 'Sample Text'
                                : _textController.text,
                            style: TextStyle(
                              fontSize:
                                  double.tryParse(_fontSizeController.text) ??
                                  16,
                              color: _textColor,
                              fontWeight: _fontWeight,
                            ),
                            textAlign: _textAlign,
                            maxLines: _maxLines == 0 ? null : _maxLines,
                            overflow:
                                _wordWrap
                                    ? TextOverflow.visible
                                    : TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _onConfirm,
                      child: const Text('确认'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showColorPicker() {
    final colors = [
      Colors.black,
      Colors.white,
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.yellow,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.cyan,
      Colors.grey,
      Colors.brown,
      Colors.indigo,
      Colors.teal,
      Colors.lime,
    ];

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('选择颜色'),
            content: Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  colors
                      .map(
                        (color) => GestureDetector(
                          onTap: () {
                            setState(() => _textColor = color);
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              border: Border.all(
                                color:
                                    _textColor == color
                                        ? Colors.blue
                                        : Colors.grey,
                                width: _textColor == color ? 3 : 1,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
    );
  }

  void _onConfirm() {
    if (!_formKey.currentState!.validate()) return;

    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final fontSize = double.parse(_fontSizeController.text);

    final config = {
      'id': 'text_$timestamp',
      'name': _nameController.text.trim(),
      'text': _textController.text.trim(),
      'fontSize': fontSize,
      'fontWeight': _fontWeight.index,
      'textColor': _textColor.value,
      'textAlign': _textAlign.index,
      'maxLines': _maxLines == 0 ? null : _maxLines,
      'wordWrap': _wordWrap,
    };

    widget.onConfirm(config);
    Navigator.of(context).pop();
  }
}

/// 文本组件类型信息
class TextTypeInfo {
  static const info = DockItemTypeInfo(
    type: 'text',
    displayName: '文本组件',
    description: '显示自定义文本内容的组件',
    icon: Icons.text_fields,
    configBuilder: _buildConfig,
  );

  static Widget _buildConfig(
    BuildContext context,
    Function(Map<String, dynamic>) onConfirm,
  ) {
    return TextConfig(onConfirm: onConfirm);
  }
}
