import 'package:flutter/material.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/utils/theme_color.dart';
import 'package:ox_common/utils/widget_tool.dart';

class RelaySelectableTabBar extends StatelessWidget {
  final List<String> tabs;
  final List<String>? tabTips;
  final RelaySelectableController controller;

  const RelaySelectableTabBar({
    Key? key,
    required this.tabs,
    required this.controller,
    this.tabTips,
  })  : assert(tabTips == null || tabs.length == tabTips.length, 'tabs and tabTips must have the same length'),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: controller.currentIndex,
        builder: (context, value, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  for (int index = 0; index < tabs.length; index++)
                    _buildTabItem(tabs[index], index),
                ],
              ),
              if (tabTips != null) _buildTabTips().setPaddingOnly(top: 10.px)
            ],
          );
        });
  }

  Widget _buildTabItem(String tab, int index) {
    final selected = controller.currentIndex.value == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => controller.currentIndex.value = index,
        child: Container(
          height: 40.px,
          margin: EdgeInsets.only(right: index % 2 == 0 ? 12.px : 0),
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: 24.px, vertical: 10.px),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.px),
            color: ThemeColor.color180,
          ),
          child: Text(
            tab,
            style: TextStyle(
              fontSize: 14.px,
              fontWeight: FontWeight.w600,
              color: selected ? ThemeColor.color0 : ThemeColor.color100,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabTips() {
    final tips = tabTips?[controller.currentIndex.value] ?? '';
    return Text(
      tips,
      style: TextStyle(
        fontSize: 12.px,
        fontWeight: FontWeight.w400,
        color: ThemeColor.color100,
      ),
    );
  }
}

class RelaySelectableController {
  ValueNotifier<int> currentIndex = ValueNotifier<int>(0);
}
