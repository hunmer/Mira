# Dock Insert Mode 功能

## 概述

为DockManager的`addTypedItem`方法添加了`insertMode`选项，支持两种插入模式：
1. **Auto模式** (`DockInsertMode.auto`) - 自动寻找最佳插入位置（默认行为）
2. **Choose模式** (`DockInsertMode.choose`) - 弹出界面让用户选择具体的插入位置

## 功能特性

### 1. 插入模式枚举

```dart
enum DockInsertMode {
  /// 自动模式：自动寻找最佳插入位置
  auto,
  /// 选择模式：弹出界面让用户选择插入位置
  choose,
}
```

### 2. 增强的addTypedItem方法

```dart
void addTypedItem({
  // ... 原有参数
  DockInsertMode insertMode = DockInsertMode.auto,
  BuildContext? context,
}) async
```

### 3. 智能位置选择对话框

当使用`DockInsertMode.choose`时，会显示一个对话框：
- **第一步**：选择目标容器（DockingTabs 或 DockingItem）
- **第二步**：选择具体的插入位置

#### 对于DockingTabs容器：
- 插入到第一个标签页
- 插入到最后一个标签页  
- 插入到特定标签页之后

#### 对于DockingItem容器：
- 插入到左侧
- 插入到右侧
- 插入到上方
- 插入到下方

## 使用示例

### 1. 自动模式（默认）

```dart
manager.addTypedItem(
  id: 'my_item',
  type: 'my_type',
  values: {...},
  targetArea: someArea,
  // insertMode: DockInsertMode.auto, // 默认值
);
```

### 2. 选择模式

```dart
manager.addTypedItem(
  id: 'my_item',
  type: 'my_type', 
  values: {...},
  targetArea: someArea,
  insertMode: DockInsertMode.choose,
  context: context, // 必须提供context用于显示对话框
);
```

### 3. LibraryDockItemRegistrar使用

```dart
// 自动模式
await LibraryDockItemRegistrar.addTab(
  library,
  tabId: 'tab_1',
  insertMode: DockInsertMode.auto,
);

// 选择模式
await LibraryDockItemRegistrar.addTab(
  library,
  tabId: 'tab_2', 
  insertMode: DockInsertMode.choose,
  context: context,
);
```

## UI界面集成

在`LibraryTabsView`中添加了两个按钮：

1. **打开素材库** (`Icons.library_add`) - 使用自动模式
2. **选择位置打开素材库** (`Icons.add_location_alt`) - 使用选择模式

## 对话框界面详情

### InsertLocationDialog组件
- 响应式设计，支持不同设备尺寸
- 清晰的步骤指示
- 直观的图标和描述
- 支持返回和取消操作

### 选择流程
1. **容器选择**：显示所有可用的DockingTabs和DockingItem
2. **位置选择**：根据选择的容器类型显示相应的位置选项
3. **确认插入**：点击位置按钮后自动关闭对话框并执行插入

## 技术实现

### 核心文件

1. **dock_insert_mode.dart** - 插入模式枚举定义
2. **insert_location_dialog.dart** - 位置选择对话框组件
3. **dock_manager.dart** - 增强的addTypedItem方法
4. **library_dock_item.dart** - 更新的LibraryDockItemRegistrar

### 数据流

```
用户操作 → 选择insertMode → 
  Auto: 使用原有逻辑自动选择位置 →
  Choose: 显示对话框 → 用户选择 → 返回InsertLocationResult →
插入到指定位置
```

## 向后兼容性

- 所有现有代码无需修改即可继续工作
- `insertMode`参数默认为`DockInsertMode.auto`
- 原有的自动位置选择逻辑保持不变

## 最佳实践

1. **提供context**：使用选择模式时必须提供有效的BuildContext
2. **错误处理**：用户可能会取消选择，需要妥善处理null返回值
3. **用户体验**：为不同的插入模式提供不同的UI提示

## 相关文件

- `d:\Mira\lib\dock\examples\dock_insert_mode.dart` - 插入模式枚举
- `d:\Mira\lib\dock\examples\dialog\insert_location_dialog.dart` - 选择对话框
- `d:\Mira\lib\dock\examples\dock_manager.dart` - DockManager增强
- `d:\Mira\lib\plugins\libraries\widgets\library_dock_item.dart` - LibraryDockItemRegistrar更新
- `d:\Mira\lib\plugins\libraries\widgets\library_tabs_view.dart` - UI集成示例
