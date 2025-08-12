import 'package:flutter/material.dart';

/// 文本组件配置对话框
class TextConfigDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onConfirm;

  const TextConfigDialog({super.key, required this.onConfirm});

  @override
  State<TextConfigDialog> createState() => _TextConfigDialogState();
}

class _TextConfigDialogState extends State<TextConfigDialog> {
  final _nameController = TextEditingController();
  final _textController = TextEditingController();
  String _name = '文本组件';
  String _text = 'Hello World';
  double _fontSize = 18;
  String _fontWeight = 'normal';
  Color _textColor = Colors.black;

  final List<String> _fontWeights = [
    'normal',
    'bold',
    'w100',
    'w200',
    'w300',
    'w400',
    'w500',
    'w600',
    'w700',
    'w800',
    'w900',
  ];
  final List<Color> _presetColors = [
    Colors.black,
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.grey,
  ];

  @override
  void initState() {
    super.initState();
    _nameController.text = _name;
    _textController.text = _text;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _textController.dispose();
    super.dispose();
  }

  String _colorToHex(Color color) {
    // ignore: deprecated_member_use
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  FontWeight _getFontWeight() {
    switch (_fontWeight) {
      case 'bold':
        return FontWeight.bold;
      case 'w100':
        return FontWeight.w100;
      case 'w200':
        return FontWeight.w200;
      case 'w300':
        return FontWeight.w300;
      case 'w400':
        return FontWeight.w400;
      case 'w500':
        return FontWeight.w500;
      case 'w600':
        return FontWeight.w600;
      case 'w700':
        return FontWeight.w700;
      case 'w800':
        return FontWeight.w800;
      case 'w900':
        return FontWeight.w900;
      default:
        return FontWeight.normal;
    }
  }

  void _onConfirm() {
    final values = {
      'text': _text.isEmpty ? 'No text' : _text,
      'name': _name.isEmpty ? '文本组件' : _name,
      'fontSize': _fontSize,
      'fontWeight': _fontWeight,
      'color': _colorToHex(_textColor),
    };
    widget.onConfirm(values);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.text_fields, color: Colors.green),
                const SizedBox(width: 8),
                Text('添加文本组件', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 24),

            // 组件名称
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '组件名称',
                hintText: '请输入组件显示名称',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
              ),
              onChanged: (value) {
                setState(() {
                  _name = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // 文本内容
            TextField(
              controller: _textController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '文本内容',
                hintText: '请输入要显示的文本内容',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.text_snippet),
              ),
              onChanged: (value) {
                setState(() {
                  _text = value;
                });
              },
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                // 字体大小
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '字体大小: ${_fontSize.toInt()}',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      Slider(
                        value: _fontSize,
                        min: 8,
                        max: 48,
                        divisions: 40,
                        onChanged: (value) {
                          setState(() {
                            _fontSize = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // 字体粗细
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _fontWeight,
                    decoration: const InputDecoration(
                      labelText: '字体粗细',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        _fontWeights.map((weight) {
                          return DropdownMenuItem(
                            value: weight,
                            child: Text(weight),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _fontWeight = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 颜色选择
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('文本颜色', style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children:
                      _presetColors.map((color) {
                        final isSelected = _textColor == color;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _textColor = color;
                            });
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color:
                                    isSelected
                                        ? Colors.blue
                                        : Colors.grey[300]!,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child:
                                isSelected
                                    ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    )
                                    : null,
                          ),
                        );
                      }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 预览
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '预览',
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      _text.isEmpty ? 'No text' : _text,
                      style: TextStyle(
                        fontSize: _fontSize,
                        fontWeight: _getFontWeight(),
                        color: _textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 操作按钮
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
                  child: const Text('确认添加'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
