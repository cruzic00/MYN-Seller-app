import 'package:myn_seller_app/myn_palette.dart';
import 'package:myn_seller_app/my_theme.dart';
import 'package:myn_seller_app/screens/assigned_delivery.dart';
import 'package:myn_seller_app/screens/on_the_way_delivery.dart';
import 'package:myn_seller_app/screens/picked_delivery.dart';
import 'package:myn_seller_app/ui_sections/drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Pending extends StatefulWidget {
  Pending({Key? key, this.index = 0, this.show_back_button = false})
      : super(key: key);

  final int index;
  final bool show_back_button;

  @override
  _PendingState createState() => _PendingState();
}

class _PendingState extends State<Pending> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  late TabController _tabController;

  final List<Tab> myTabs = <Tab>[
    Tab(text: 'On the Way'),
    Tab(text: 'Confirmed'),
    Tab(text: 'Assigned'),
  ];

  final List<Widget> _children = [
    OnTheWayDelivery(),
    PickedDelivery(),
    AssignedDelivery(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        vsync: this, length: myTabs.length, initialIndex: widget.index);

    // Re-appear status bar in case it was not there in the previous page
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: myTabs.length,
      initialIndex: widget.index,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          centerTitle: true,
          leading: widget.show_back_button
              ? GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Icon(Icons.arrow_back,
                      size: 25, color: MyTheme.dark_grey),
                )
              : GestureDetector(
                  onTap: () {
                    _scaffoldKey.currentState!.openDrawer();
                  },
                  child: Icon(
                    Icons.menu,
                    size: 25,
                    color: MyTheme.font_grey,
                  ),
                ),
          title: Text(
            'All Orders',
            style: TextStyle(
              color: MyTheme.font_grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          systemOverlayStyle: MynPalette.overlayDark,
          bottom: TabBar(
            controller: _tabController,
            tabs: myTabs,
            indicatorColor: MyTheme.accent_color_2,
            labelColor: MyTheme.accent_color_2,
            unselectedLabelColor: Color.fromRGBO(153, 153, 153, 1),
          ),
        ),
        drawer: MainDrawer(),
        body: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: TabBarView(
            controller: _tabController,
            children: _children,
          ),
        ),
      ),
    );
  }
}
