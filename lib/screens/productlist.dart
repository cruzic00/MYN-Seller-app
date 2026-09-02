import 'package:myn_seller_app/myn_palette.dart';
import 'dart:async';

import 'package:empty_widget_fork/empty_widget_fork.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:myn_seller_app/app_localizations.dart';
import 'package:myn_seller_app/helpers/root_scaffold.dart';
import 'package:myn_seller_app/helpers/tab_events.dart';
import 'package:myn_seller_app/helpers/shimmer_helper.dart';
import 'package:myn_seller_app/my_theme.dart';
import 'package:myn_seller_app/repositories/product_repository.dart';
import 'package:myn_seller_app/screens/menu_scan.dart';
import 'package:myn_seller_app/screens/myn_product_detail.dart';
import 'package:myn_seller_app/ui_elements/product_card.dart';

class CategoryProducts extends StatefulWidget {
  CategoryProducts({Key? key, this.show_back_button = false}) : super(key: key);

  final bool show_back_button;

  @override
  _CategoryProductsState createState() => _CategoryProductsState();
}

class _CategoryProductsState extends State<CategoryProducts>
    with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  ScrollController _scrollController = ScrollController();
  ScrollController _xcrollController = ScrollController();
  TextEditingController _searchController = TextEditingController();

  List<dynamic> _productList = [];
  bool _isInitial = true;
  int _page = 1;
  int? _totalData = 0;
  bool _showLoadingContainer = false;

  StreamSubscription<int>? _tabEvents;

  String? selectedValue;
  List<String> items = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    fetchData();

    // Approving an image or editing a price happens in the web panel, not here.
    // The tab stays mounted for the life of the app, so without these two the
    // grid kept showing whatever it loaded on first open — a "Waiting approval"
    // badge stayed up long after the image had been approved.
    _tabEvents = TabEvents.stream.listen((index) {
      if (index == 2 && mounted) _silentRefresh();
    });

    _xcrollController.addListener(() {
      if (_xcrollController.position.pixels ==
          _xcrollController.position.maxScrollExtent) {
        setState(() {
          _page++;
        });
        _showLoadingContainer = true;
        fetchData();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _silentRefresh();
  }

  void fetchData() async {
    var productResponse =
        await ProductRepository().getCategoryProducts(page: _page);
    if (!mounted) return;
    _productList.addAll(productResponse.products!);
    _isInitial = false;
    _totalData = productResponse.meta!.total;
    _showLoadingContainer = false;

    setState(() {});
  }

  /// Refetches without emptying the grid first.
  ///
  /// reset() blanks the list, which drops the seller back to a shimmer every
  /// time they switch tabs. Here the old rows stay on screen until the new ones
  /// land, so a background refresh is invisible unless something actually
  /// changed.
  Future<void> _silentRefresh() async {
    try {
      final response = await ProductRepository().getCategoryProducts(page: 1);
      if (!mounted) return;
      setState(() {
        _productList = List<dynamic>.from(response.products ?? const []);
        _totalData = response.meta?.total ?? _productList.length;
        _isInitial = false;
        _page = 1;
        _showLoadingContainer = false;
      });
    } catch (_) {
      // A failed background refresh leaves what is already on screen; the
      // seller can still pull to refresh and see the error path.
    }
  }

  void reset() {
    _productList.clear();
    _isInitial = true;
    _totalData = 0;
    _searchController.text = "";
    _page = 1;
    _showLoadingContainer = false;
    setState(() {});
  }

  Future<void> _onRefresh() async {
    reset();
    fetchData();
  }

  Future<void> search(String searchText) async {
    setState(() {
      _productList.clear();
      _isInitial = true;
      _showLoadingContainer = true;
    });

    if (searchText.isEmpty) {
      fetchData();
    } else {
      var searchResponse =
          await ProductRepository().getCategoryProducts(name: searchText);
      setState(() {
        _productList.addAll(searchResponse.products!);
        _isInitial = false;
        _showLoadingContainer = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabEvents?.cancel();
    _scrollController.dispose();
    _xcrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: Colors.white,
            appBar: buildAppBar(context),
            floatingActionButton: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'scan_menu',
                  label: Text(
                    'Scan Menu',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: Colors.white,
                  foregroundColor: MyTheme.accent_color,
                  icon: Icon(Icons.document_scanner_outlined, size: 20),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => MenuScanScreen()),
                    ).then((added) {
                      // Refresh so newly scanned items appear immediately.
                      if (added == true) reset();
                    });
                  },
                ),
                SizedBox(height: 10),
                FloatingActionButton.extended(
                  heroTag: 'add_product',
                  label: Text(
                    'Add',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: MyTheme.accent_color,
                  icon: Icon(Icons.add, color: Colors.white, size: 20),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => MynProductDetail.create()),
                    ).then((added) {
                      // The new item only exists on the server; refetch so it
                      // appears without the seller pulling to refresh.
                      if (added == true) _onRefresh();
                    });
                  },
                ),
              ],
            ),
            body: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SearchBar(
                      elevation: WidgetStateProperty.all(2),
                      controller: _searchController,
                      trailing: [
                        IconButton(
                          icon: Icon(Icons.refresh, color: MyTheme.dark_grey),
                          onPressed: () {
                            reset();
                            fetchData();
                          },
                        ),
                      ],
                      onSubmitted: (txt) {
                        search(txt);
                      },
                      hintText: "Search Products",
                    ),
                  ),
                ),
                Positioned(
                  child: buildProductList(),
                  top: 75,
                  bottom: 0,
                  left: 0,
                  right: 0,
                ),
                Align(
                    alignment: Alignment.bottomCenter,
                    child: buildLoadingContainer())
              ],
            )));
  }

  Container buildLoadingContainer() {
    return Container(
      height: _showLoadingContainer ? 36 : 0,
      width: double.infinity,
      color: Colors.white,
      child: Center(
        child: Text(_totalData == _productList.length
            ? AppLocalizations.of(context)!.common_no_more_products
            : AppLocalizations.of(context)!.common_loading_more_products),
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      systemOverlayStyle: MynPalette.overlayDark,
      centerTitle: true,
      title: Text(
        "Products",
        style: TextStyle(color: MyTheme.font_grey, fontWeight: FontWeight.bold),
      ),
      elevation: widget.show_back_button ? null : 0,
      leading: widget.show_back_button
          ? IconButton(
              icon: Icon(Icons.arrow_back, color: MyTheme.dark_grey),
              onPressed: () => Navigator.of(context).pop(),
            )
          : GestureDetector(
              onTap: () {
                openRootDrawer();
              },
              child: Icon(
                Icons.menu,
                size: 25,
                color: MyTheme.font_grey,
              ),
            ),
    );
  }

  buildProductList() {
    if (_isInitial && _productList.length == 0) {
      return SingleChildScrollView(
          child: ShimmerHelper()
              .buildProductGridShimmer(scontroller: _scrollController));
    } else if (_productList.length > 0) {
      return RefreshIndicator(
        color: MyTheme.accent_color,
        backgroundColor: Colors.white,
        displacement: 0,
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          controller: _xcrollController,
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          child: GridView.builder(
            // 2
            addAutomaticKeepAlives: true,
            itemCount: _productList.length,
            controller: _scrollController,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 1000
                    ? 4
                    : MediaQuery.of(context).size.width > 600
                        ? 3
                        : 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.74),
            // Bottom clears the floating nav bar and the gesture inset so the
            // last row of cards is reachable.
            padding: EdgeInsets.fromLTRB(
                8, 8, 8, 100 + MediaQuery.of(context).padding.bottom),
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemBuilder: (context, index) {
              // 3
              return ProductCard(
                  id: _productList[index].id,
                  mongo_id: _productList[index].mongo_id,
                  image: _productList[index].thumbnail_image,
                  image_status: _productList[index].image_status,
                  name: _productList[index].name,
                  stroked_price: _productList[index].stroked_price,
                  seller_price: _productList[index].seller_price,
                  has_discount: _productList[index].has_discount,
                  is_active: _productList[index].is_active,
                  // A save on the detail screen pops true; refetch so the edited
                  // name, price and status show here straight away.
                  onChanged: _onRefresh);
            },
          ),
        ),
      );
    } else if (_totalData == 0) {
      return GestureDetector(
        child: Center(
          child: Container(
            height: 550,
            width: 350,
            child: EmptyWidget(
                image: 'assets/app_logo.png',
                packageImage: null,
                title: "No Data Found",
                subTitle: '',
                titleTextStyle: Theme.of(context)
                    .typography
                    .dense
                    .headlineSmall
                    ?.copyWith(color: Color(0xff9da9c7)),
                subtitleTextStyle: Theme.of(context)
                    .typography
                    .dense
                    .bodyLarge
                    ?.copyWith(color: Color(0xffabb8d6))),
          ),
        ),
      );
    } else {
      return Container(); // should never be happening
    }
  }
}
