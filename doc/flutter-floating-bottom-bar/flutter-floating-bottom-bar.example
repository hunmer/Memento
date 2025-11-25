import 'package:floating_bottom_bar/pages/infinite_list_page.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

void main() {
  runApp(
    MyApp(),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Floating Bottom Bar Demo',
      theme: ThemeData(
        colorSchemeSeed: Colors.yellow,
      ),
      debugShowCheckedModeBanner: false,
      home: MyHomePage(title: 'Flutter Floating Bottom Bar Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  late int currentPage;
  late TabController tabController;
  final List<Color> colors = [
    Colors.yellow,
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.pink,
  ];

  @override
  void initState() {
    currentPage = 0;
    tabController = TabController(length: 5, vsync: this);
    tabController.animation?.addListener(
      () {
        final value = tabController.animation!.value.round();
        if (value != currentPage && mounted) {
          changePage(value);
        }
      },
    );
    super.initState();
  }

  void changePage(int newPage) {
    setState(() {
      currentPage = newPage;
    });
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color unselectedColor = colors[currentPage].computeLuminance() < 0.5 ? Colors.black : Colors.white;
    final Color unselectedColorReverse = colors[currentPage].computeLuminance() < 0.5 ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: BottomBar(
        clip: Clip.none,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            TabBar(
              dividerColor: Colors.transparent,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              indicatorPadding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
              controller: tabController,
              indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(
                    color: currentPage <= 4 ? colors[currentPage] : unselectedColor,
                    width: 4,
                  ),
                  insets: EdgeInsets.fromLTRB(16, 0, 16, 8)),
              tabs: [
                SizedBox(
                  height: 55,
                  width: 40,
                  child: Center(
                      child: Icon(
                    Icons.home,
                    color: currentPage == 0 ? colors[0] : unselectedColor,
                  )),
                ),
                SizedBox(
                  height: 55,
                  width: 40,
                  child: Center(
                    child: Icon(
                      Icons.search,
                      color: currentPage == 1 ? colors[1] : unselectedColor,
                    ),
                  ),
                ),
                SizedBox(
                  height: 55,
                  width: 40,
                  child: Center(
                    child: Icon(
                      Icons.add,
                      color: currentPage == 2 ? colors[2] : unselectedColorReverse,
                    ),
                  ),
                ),
                SizedBox(
                  height: 55,
                  width: 40,
                  child: Center(
                    child: Icon(
                      Icons.favorite,
                      color: currentPage == 3 ? colors[3] : unselectedColor,
                    ),
                  ),
                ),
                SizedBox(
                  height: 55,
                  width: 40,
                  child: Center(
                    child: Icon(
                      Icons.settings,
                      color: currentPage == 4 ? colors[4] : unselectedColor,
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: -20,
              child: FloatingActionButton(
                elevation: 0,
                onPressed: () {},
                child: Icon(Icons.add),
              ),
            )
          ],
        ),
        fit: StackFit.expand,
        icon: (width, height) => Center(
          child: IconButton(
            padding: EdgeInsets.zero,
            onPressed: null,
            icon: Icon(
              Icons.arrow_upward_rounded,
              color: colors[currentPage],
              size: width,
            ),
          ),
        ),
        borderRadius: BorderRadius.circular(500),
        duration: Duration(milliseconds: 500),
        curve: Curves.decelerate,
        showIcon: true,
        width: MediaQuery.of(context).size.width * 0.8,
        barColor: colors[currentPage].computeLuminance() > 0.5 ? Colors.black : Colors.white,
        start: 3,
        end: 0,
        offset: 10,
        barAlignment: Alignment.bottomCenter,
        iconHeight: 30,
        iconWidth: 30,
        reverse: false,
        barDecoration: BoxDecoration(
          color: colors[currentPage],
          borderRadius: BorderRadius.circular(500),
        ),
        iconDecoration: BoxDecoration(
          color: unselectedColor,
          borderRadius: BorderRadius.circular(500),
        ),
        hideOnScroll: true,
        scrollOpposite: false,
        onBottomBarHidden: () {},
        onBottomBarShown: () {},
        body: (context, controller) => TabBarView(
          controller: tabController,
          dragStartBehavior: DragStartBehavior.down,
          physics: const BouncingScrollPhysics(),
          children: colors
              .map(
                (e) => InfiniteListPage(
                  key: ValueKey('infinite_list_key#${e.toString()}'),
                  controller: controller,
                  color: e,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
