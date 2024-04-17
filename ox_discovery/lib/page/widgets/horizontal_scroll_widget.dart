import 'package:chatcore/chat-core.dart';
import 'package:flutter/cupertino.dart';
import 'package:ox_common/utils/adapt.dart';
import 'package:ox_common/utils/theme_color.dart';

import '../../utils/moment_widgets_utils.dart';

class HorizontalScrollWidget extends StatefulWidget {
  final NoteDB noteDB;
  const HorizontalScrollWidget({super.key,required this.noteDB});

  @override
  _HorizontalScrollWidgetState createState() => _HorizontalScrollWidgetState();
}

class _HorizontalScrollWidgetState extends State<HorizontalScrollWidget> {
  int _currentPage = 0;
  final PageController _pageController = PageController(initialPage: 0);

  @override
  Widget build(BuildContext context) {
    return Container(
      // color: ThemeColor.red,
      height: 290.px,
      child: Column(
        children: <Widget>[
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: <Widget>[
                MomentWidgetsUtils.quoteMoment(),
                MomentWidgetsUtils.quoteMoment(),
                MomentWidgetsUtils.quoteMoment(),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(3, (int index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 10,
                  width: (index == _currentPage) ? 30 : 10,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: (index == _currentPage)
                        ? ThemeColor.color100
                        : ThemeColor.color100.withOpacity(0.5),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
