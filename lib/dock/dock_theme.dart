// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:mira/tabbed/tabbed_view/lib/tabbed_view.dart';

class DockTheme {
  /// 创建自定义的TabbedViewThemeData
  static TabbedViewThemeData createCustomThemeData(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    const backgroundColor = Color(0xFFF5F5F5); // 浅灰背景色
    const cardColor = Color(0xFFFFFFFF); // 白色
    const inactiveColor = Color(0xFF9E9E9E); // 灰色
    const hoverColor = Color(0xFFE3F2FD); // 浅蓝色悬停

    Radius radius = Radius.circular(10.0);
    BorderRadiusGeometry? borderRadius = BorderRadius.only(
      topLeft: radius,
      topRight: radius,
    );

    // 创建完全自定义的主题，不基于任何预设主题
    final themeData = TabbedViewThemeData(
      // TabsArea 主题配置 - 标签区域
      tabsArea: TabsAreaThemeData(
        visible: true, // 显示标签区域
        // color: backgroundColor, // 背景色
        border: Border(bottom: BorderSide(color: primaryColor, width: 3)), // 描边
        initialGap: 0.0, // 初始间距
        middleGap: 0.0, // 标签间距
        minimalFinalGap: 0.0, // 最小结束间距
        gapBottomBorder: BorderSide.none, // 间距底部边框
        equalHeights: EqualHeights.none, // 高度相等设置
        // 按钮区域装饰
        buttonsAreaDecoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(4.0),
        ),
        buttonsAreaPadding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        buttonPadding: const EdgeInsets.all(4),
        buttonsGap: 4.0, // 按钮间距
        buttonsOffset: 4.0, // 按钮偏移
        buttonIconSize: 16.0, // 按钮图标大小
        // 按钮颜色配置
        normalButtonColor: inactiveColor, // 正常状态按钮颜色
        hoverButtonColor: primaryColor, // 悬停状态按钮颜色
        disabledButtonColor: Colors.black12, // 禁用状态按钮颜色
        // 按钮背景装饰
        normalButtonBackground: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(4.0),
        ),
        hoverButtonBackground: BoxDecoration(
          color: hoverColor,
          borderRadius: BorderRadius.circular(4.0),
        ),
        disabledButtonBackground: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4.0),
        ),

        // 菜单图标
        menuIcon: IconProvider.data(Icons.arrow_drop_down),
        dropColor: const Color.fromARGB(150, 33, 150, 243), // 拖拽覆盖颜色
      ),

      // Tab 主题配置 - 单个标签
      tab: TabThemeData(
        // 关闭图标
        closeIcon: IconProvider.data(Icons.close), // 关闭按钮大小通过 buttonIconSize 控制
        // 按钮颜色配置
        normalButtonColor: inactiveColor, // 正常状态文字/图标颜色
        hoverButtonColor: primaryColor.withOpacity(0.2), // 悬停状态颜色，减少透明度
        disabledButtonColor: Colors.black12, // 禁用状态颜色
        // 按钮背景装饰
        normalButtonBackground: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(8.0), // 圆角
          border: Border.all(color: Colors.transparent), // 取消描边
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        hoverButtonBackground: BoxDecoration(
          color: hoverColor,
          borderRadius: BorderRadius.circular(8.0), // 圆角
          border: Border.all(color: Colors.transparent), // 取消描边
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        disabledButtonBackground: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.0), // 圆角
          border: Border.all(color: Colors.transparent), // 取消描边
        ),

        buttonIconSize: 12.0, // 减少按钮图标大小（从16.0减少到12.0）
        verticalAlignment: VerticalAlignment.center, // 垂直对齐
        buttonPadding: const EdgeInsets.all(2), // 减少按钮内边距（从4减少到2）
        buttonsGap: 8.0, // 增加按钮间距（从4.0增加到8.0，增加文字和按钮之间的边距）
        // Tab 装饰
        // decoration: BoxDecoration(
        //   color: cardColor,
        //   borderRadius: BorderRadius.circular(8.0), // 圆角
        //   border: Border.all(color: Colors.transparent), // 取消描边
        // ),
        draggingDecoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.0), // 圆角
          border: Border.all(color: primaryColor, width: 2), // 拖拽时显示边框
        ),
        draggingOpacity: 0.7, // 拖拽透明度
        // 边框配置
        innerBottomBorder: null, // 取消内部底部边框
        innerTopBorder: null, // 取消内部顶部边框
        // 文字样式
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),

        // 内边距和外边距
        padding: EdgeInsets.fromLTRB(10, 4, 10, 4),
        paddingWithoutButton: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        buttonsOffset: 8,
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          color: primaryColor,
          borderRadius: borderRadius,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),

        // 状态主题配置
        selectedStatus: TabStatusThemeData(
          fontColor: Colors.white, // 激活状态文字颜色
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: borderRadius,
          ),
          // 激活状态下的尺寸调整
          padding: EdgeInsets.fromLTRB(12, 6, 12, 6), // 增加激活tab的内边距
        ),
        highlightedStatus: TabStatusThemeData(
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: borderRadius,
          ),
        ),
        disabledStatus: TabStatusThemeData(
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8.0), // 圆角
          ),
        ),
      ),

      // ContentArea 主题配置 - 内容区域
      contentArea: ContentAreaThemeData(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(8.0), // 内容区域圆角
          border: Border.all(color: Colors.transparent), // 取消描边
        ),
        padding: const EdgeInsets.all(0), // 内容区域内边距
        decorationNoTabsArea: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(8.0), // 无标签区域时使用圆角
          border: Border.all(color: Colors.transparent), // 取消描边
        ),
      ),

      // Menu 主题配置 - 下拉菜单
      menu: TabbedViewMenuThemeData(
        padding: const EdgeInsets.all(8), // 菜单内边距
        margin: const EdgeInsets.all(4), // 菜单外边距
        menuItemPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ), // 菜单项内边距
        textStyle: const TextStyle(fontSize: 14, color: Colors.white),
        border: Border.all(color: Colors.transparent), // 取消菜单描边
        color: primaryColor, // 菜单背景色
        blur: true, // 启用模糊效果
        ellipsisOverflowText: true, // 文字溢出省略号
        dividerThickness: 1.0, // 分隔线厚度
        maxWidth: 220, // 最大宽度
        dividerColor: Colors.grey.withOpacity(0.3), // 分隔线颜色
        hoverColor: hoverColor, // 悬停颜色
      ),
    );

    return themeData;
  }
}
