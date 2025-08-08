import 'package:flutter/material.dart';
import 'package:mira/dock/examples/registerdWidgets/dynamic_widget.dart';
import '../widgets/dock_item_config_base.dart';

/// Dynamic Widget 配置对话框
class DynamicWidgetConfig extends DockItemConfig {
  const DynamicWidgetConfig({Key? key, required super.onConfirm})
    : super(key: key);

  @override
  State<DynamicWidgetConfig> createState() => _DynamicWidgetConfigState();
}

class _DynamicWidgetConfigState extends State<DynamicWidgetConfig> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String _selectedPreset = 'welcomeCard';
  final Map<String, String> _presets = {
    'welcomeCard': '欢迎卡片',
    'featureList': '功能列表',
    'counterExample': '计数器示例',
  };

  @override
  void initState() {
    super.initState();
    _nameController.text = 'Dynamic Widget ${DateTime.now().millisecond}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 700,
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
                    Icons.widgets,
                    size: 24,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '配置动态组件',
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
                  hintText: '输入动态组件的显示名称',
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

              // 预设选择
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '选择预设模板',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '选择一个预定义的组件模板',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),

                  ..._presets.entries
                      .map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: RadioListTile<String>(
                            value: entry.key,
                            groupValue: _selectedPreset,
                            onChanged: (value) {
                              setState(() => _selectedPreset = value!);
                            },
                            title: Text(entry.value),
                            subtitle: Text(_getPresetDescription(entry.key)),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ],
              ),
              const SizedBox(height: 20),

              // 预览区域
              Expanded(
                child: Card(
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
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(8),
                              child: DynamicWidget(
                                jsonData: _getPresetData(_selectedPreset),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
    );
  }

  String _getPresetDescription(String preset) {
    switch (preset) {
      case 'welcomeCard':
        return '带有图标和按钮的欢迎卡片';
      case 'featureList':
        return '展示功能特性的列表组件';
      case 'counterExample':
        return '交互式计数器演示';
      default:
        return '';
    }
  }

  Map<String, dynamic> _getPresetData(String preset) {
    switch (preset) {
      case 'welcomeCard':
        return DynamicWidgetPresets.welcomeCard;
      case 'featureList':
        return DynamicWidgetPresets.featureList;
      case 'counterExample':
        return DynamicWidgetPresets.counterExample;
      default:
        return DynamicWidgetPresets.welcomeCard;
    }
  }

  void _onConfirm() {
    if (!_formKey.currentState!.validate()) return;

    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    final config = {
      'id': 'dynamic_widget_$timestamp',
      'name': _nameController.text.trim(),
      'jsonData': _getPresetData(_selectedPreset),
      'preset': _selectedPreset,
    };

    widget.onConfirm(config);
    Navigator.of(context).pop();
  }
}

/// Dynamic Widget 组件类型信息
class DynamicWidgetTypeInfo {
  static const info = DockItemTypeInfo(
    type: 'dynamic_widget',
    displayName: '动态组件',
    description: '通过 JSON 配置动态构建的组件',
    icon: Icons.widgets,
    configBuilder: _buildConfig,
  );

  static Widget _buildConfig(
    BuildContext context,
    Function(Map<String, dynamic>) onConfirm,
  ) {
    return DynamicWidgetConfig(onConfirm: onConfirm);
  }
}
