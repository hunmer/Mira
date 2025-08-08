import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dock_item_config_base.dart';

/// 计数器组件配置对话框
class CounterConfig extends DockItemConfig {
  const CounterConfig({Key? key, required super.onConfirm}) : super(key: key);

  @override
  State<CounterConfig> createState() => _CounterConfigState();
}

class _CounterConfigState extends State<CounterConfig> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _initialValueController = TextEditingController();
  final _minValueController = TextEditingController();
  final _maxValueController = TextEditingController();
  final _stepController = TextEditingController();

  bool _showStepControls = true;
  bool _allowNegative = true;

  @override
  void initState() {
    super.initState();
    _nameController.text = 'Counter ${DateTime.now().millisecond}';
    _initialValueController.text = '0';
    _minValueController.text = '';
    _maxValueController.text = '';
    _stepController.text = '1';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _initialValueController.dispose();
    _minValueController.dispose();
    _maxValueController.dispose();
    _stepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Row(
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    size: 24,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '配置计数器组件',
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
                  hintText: '输入计数器的显示名称',
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

              // 初始值
              TextFormField(
                controller: _initialValueController,
                decoration: const InputDecoration(
                  labelText: '初始值',
                  hintText: '计数器的起始数值',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入初始值';
                  }
                  final intValue = int.tryParse(value);
                  if (intValue == null) {
                    return '请输入有效的整数';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 最小值和最大值
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minValueController,
                      decoration: const InputDecoration(
                        labelText: '最小值 (可选)',
                        hintText: '留空表示无限制',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return null;
                        final intValue = int.tryParse(value);
                        if (intValue == null) {
                          return '请输入有效的整数';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _maxValueController,
                      decoration: const InputDecoration(
                        labelText: '最大值 (可选)',
                        hintText: '留空表示无限制',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return null;
                        final intValue = int.tryParse(value);
                        if (intValue == null) {
                          return '请输入有效的整数';
                        }
                        // 检查最小值和最大值的关系
                        final minText = _minValueController.text.trim();
                        if (minText.isNotEmpty) {
                          final minValue = int.tryParse(minText);
                          if (minValue != null && intValue <= minValue) {
                            return '最大值必须大于最小值';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 步长设置
              TextFormField(
                controller: _stepController,
                decoration: const InputDecoration(
                  labelText: '步长',
                  hintText: '每次增减的数值',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入步长';
                  }
                  final intValue = int.tryParse(value);
                  if (intValue == null || intValue <= 0) {
                    return '步长必须是正整数';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 选项开关
              CheckboxListTile(
                title: const Text('显示步长控制按钮'),
                subtitle: const Text('显示 +1/-1 以外的快捷按钮'),
                value: _showStepControls,
                onChanged: (value) {
                  setState(() => _showStepControls = value ?? true);
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),

              CheckboxListTile(
                title: const Text('允许负数'),
                subtitle: const Text('是否允许计数器显示负数值'),
                value: _allowNegative,
                onChanged: (value) {
                  setState(() => _allowNegative = value ?? true);
                },
                controlAffinity: ListTileControlAffinity.leading,
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
    );
  }

  void _onConfirm() {
    if (!_formKey.currentState!.validate()) return;

    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final initialValue = int.parse(_initialValueController.text);
    final minValue =
        _minValueController.text.trim().isEmpty
            ? null
            : int.parse(_minValueController.text);
    final maxValue =
        _maxValueController.text.trim().isEmpty
            ? null
            : int.parse(_maxValueController.text);
    final step = int.parse(_stepController.text);

    final config = {
      'id': 'counter_$timestamp',
      'name': _nameController.text.trim(),
      'count': initialValue,
      'minValue': minValue,
      'maxValue': maxValue,
      'step': step,
      'showStepControls': _showStepControls,
      'allowNegative': _allowNegative,
    };

    widget.onConfirm(config);
    Navigator.of(context).pop();
  }
}

/// 计数器组件类型信息
class CounterTypeInfo {
  static const info = DockItemTypeInfo(
    type: 'counter',
    displayName: '计数器',
    description: '可增减数值的交互式计数器组件',
    icon: Icons.add_circle_outline,
    configBuilder: _buildConfig,
  );

  static Widget _buildConfig(
    BuildContext context,
    Function(Map<String, dynamic>) onConfirm,
  ) {
    return CounterConfig(onConfirm: onConfirm);
  }
}
