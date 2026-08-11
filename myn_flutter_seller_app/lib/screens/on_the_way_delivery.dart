import 'package:flutter/material.dart';
import 'package:flutter_icons_null_safety/flutter_icons_null_safety.dart';
import 'package:myn_seller_app/custom/toast_component.dart';
import 'package:myn_seller_app/helpers/shimmer_helper.dart';
import 'package:myn_seller_app/helpers/sortable.dart';
import 'package:myn_seller_app/my_theme.dart';
import 'package:myn_seller_app/other_config.dart';
import 'package:myn_seller_app/repositories/delivery_repository.dart';
import 'package:myn_seller_app/screens/order_details.dart';
import 'package:myn_seller_app/screens/single_order_map.dart';
import 'package:myn_seller_app/ui_sections/drawer.dart';
import 'package:slider_button/slider_button.dart';
import 'package:toast/toast.dart';

class OnTheWayDelivery extends StatefulWidget {
  OnTheWayDelivery({
    Key? key,
    this.show_back_button = false,
  }) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final bool show_back_button;

  @override
  _OnTheWayDeliveryState createState() => _OnTheWayDeliveryState();
}

class _OnTheWayDeliveryState extends State<OnTheWayDelivery> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  ScrollController _scrollController = ScrollController();
  ScrollController _xcrollController = ScrollController();

  List<Sortable> _datewiseSortList = Sortable.getDatewiseSortList();
  List<Sortable> _paymentTypeSortList = Sortable.getPaymentTypeSortList();

  Sortable? _selectedDate;
  Sortable? _selectedPaymentType;

  late List<DropdownMenuItem<Sortable>> _dropdownDatewiseSortItems;
  late List<DropdownMenuItem<Sortable>> _dropdownPaymentTypeSortItems;

  //init

  List<dynamic> _list = [];
  bool _isInitial = true;
  int _page = 1;
  int? _totalData = 0;
  bool _showLoadingContainer = false;

  String _defaultDateKey = '';
  String _defaultPaymentTypeKey = '';
  var _marked_ids = [];

  @override
  void initState() {
    // TODO: implement initState
    init();
    super.initState();

    fetchData();

    _xcrollController.addListener(() {
      //print("position: " + _xcrollController.position.pixels.toString());
      //print("max: " + _xcrollController.position.maxScrollExtent.toString());

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

  init() {
    _dropdownDatewiseSortItems = buildDropdownItems(_datewiseSortList);

    _dropdownPaymentTypeSortItems = buildDropdownItems(_paymentTypeSortList);

    initSortableDefaults();
  }

  initSortableDefaults() {
    for (int x = 0; x < _dropdownDatewiseSortItems.length; x++) {
      if (_dropdownDatewiseSortItems[x].value!.option_key == _defaultDateKey) {
        _selectedDate = _dropdownDatewiseSortItems[x].value;
      }
    }

    for (int x = 0; x < _dropdownPaymentTypeSortItems.length; x++) {
      if (_dropdownPaymentTypeSortItems[x].value!.option_key ==
          _defaultPaymentTypeKey) {
        _selectedPaymentType = _dropdownPaymentTypeSortItems[x].value;
      }
    }

    setState(() {});
  }

  List<dynamic> sortList(List<dynamic> list, Sortable? selectedDate,
      Sortable? selectedPaymentType) {
    return list.where((item) {
      // Filter by date
      if (selectedDate != null && selectedDate.option_key.isNotEmpty) {
        switch (selectedDate.option_key) {
          case 'today':
            return item.date == DateTime.now().toString().split(' ')[0];
          case 'this_week':
            final today = DateTime.now();
            final startOfWeek =
                today.subtract(Duration(days: today.weekday - 1));
            final endOfWeek = startOfWeek.add(Duration(days: 6));
            final itemDate = DateTime.tryParse(item.date!);
            if (itemDate == null) return false;
            return itemDate.isAfter(startOfWeek) &&
                itemDate.isBefore(endOfWeek);
          case 'this_month':
            final today = DateTime.now();
            final startOfMonth = DateTime(today.year, today.month, 1);
            final endOfMonth = startOfMonth
                .add(Duration(days: 32))
                .subtract(Duration(days: startOfMonth.day));
            final itemDate = DateTime.tryParse(item.date!);
            if (itemDate == null) return false;
            return itemDate.isAfter(startOfMonth) &&
                itemDate.isBefore(endOfMonth);
          default:
            return true;
        }
      }

      // Filter by payment type
      if (selectedPaymentType != null &&
          selectedPaymentType.option_key.isNotEmpty) {
        switch (selectedPaymentType.option_key) {
          case 'cash_on_delivery':
            return item.payment_type == 'Cash On Delivery';
          case 'non_cod_payment':
            return item.payment_type != 'Cash On Delivery';
          default:
            return true;
        }
      }

      return true;
    }).toList();
  }

  List<DropdownMenuItem<Sortable>> buildDropdownItems(List _paymentStatusList) {
    List<DropdownMenuItem<Sortable>> items = [];
    for (Sortable item in _paymentStatusList as Iterable<Sortable>) {
      items.add(
        DropdownMenuItem(
          value: item,
          child: Text(item.name),
        ),
      );
    }
    return items;
  }

  fetchData() async {
    var listResponse = await DeliveryRepository().getDeliveryListResponse(
        page: _page,
        type: "on_the_way",
        dateRange: _selectedDate!.option_key,
        paymentType: _selectedPaymentType!.option_key);
    //print("or:"+orderResponse.toJson().toString());
    _list.addAll(listResponse.orders!);
    _isInitial = false;
    _totalData = listResponse.meta!.total;
    _showLoadingContainer = false;
    setState(() {});
  }

  reset() {
    _list.clear();
    _marked_ids.clear();
    _isInitial = true;
    _page = 1;
    _totalData = 0;
    _showLoadingContainer = false;
    setState(() {});
  }

  resetFilterKeys() {
    _defaultDateKey = '';
    _defaultPaymentTypeKey = '';

    setState(() {});
  }

  Future<void> _onRefresh() async {
    reset();
    resetFilterKeys();
    initSortableDefaults();
    fetchData();
  }

  onPop(value) {
    reset();
    resetFilterKeys();
    initSortableDefaults();
    fetchData();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _scrollController.dispose();
    _xcrollController.dispose();
    super.dispose();
  }

  onConfirmMarkDelivered(order_id) async {
    var deliveryStatusChangeResponse = await DeliveryRepository()
        .getDeliveryStatusChangeResponse(
            status: "delivered", orderId: order_id);

    if (deliveryStatusChangeResponse.result == true) {
      ToastComponent.showDialog(deliveryStatusChangeResponse.message,
          gravity: Toast.center, duration: Toast.lengthLong);
      _marked_ids.add(order_id);
      setState(() {});
    } else {
      ToastComponent.showDialog(deliveryStatusChangeResponse.message,
          gravity: Toast.center, duration: Toast.lengthLong, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: widget.show_back_button ? buildAppBar(context) : null,
        key: _scaffoldKey,
        drawer: MainDrawer(),
        body: Stack(
          children: [
            RefreshIndicator(
              color: MyTheme.accent_color,
              backgroundColor: Colors.white,
              onRefresh: _onRefresh,
              displacement: 0,
              child: CustomScrollView(
                controller: _xcrollController,
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  SliverList(
                    delegate: SliverChildListDelegate([
                      buildList(),
                      Container(
                        height: 100,
                      )
                    ]),
                  )
                ],
              ),
            ),
            Align(
                alignment: Alignment.bottomCenter,
                child: buildLoadingContainer())
          ],
        ));
  }

  buildAppBar(BuildContext context) {
    return AppBar(
        centerTitle: false,
        toolbarHeight: 99,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0.0,
        titleSpacing: 0,
        flexibleSpace: Column(
          children: [buildTopAppBarContainer()],
        ));
  }

  Container buildTopAppBarContainer() {
    return Container(
      child: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
                icon: Icon(Icons.arrow_back, color: MyTheme.dark_grey),
                onPressed: () {
                  return Navigator.of(context).pop();
                }),
          ),
          Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: MyTheme.red,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(
                  "assets/human_run.png",
                  color: Colors.white,
                ),
              )),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              "On The Way (${_totalData.toString()})",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: MyTheme.red,
                  fontWeight: FontWeight.w600),
            ),
          )
        ],
      ),
    );
  }

  buildSortDropdown(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Icon(FontAwesome.calendar, color: MyTheme.font_grey, size: 20),
        SizedBox(width: 8),
        DropdownButtonHideUnderline(
          child: DropdownButton(
            dropdownColor: Colors.white,
            value: _selectedDate,
            items: _dropdownDatewiseSortItems,
            onChanged: (value) {
              setState(() {
                _selectedDate = value;
              });
            },
          ),
        ),
        SizedBox(width: 8),
        Icon(FontAwesome.filter, color: MyTheme.font_grey, size: 20),
        SizedBox(width: 8),
        DropdownButtonHideUnderline(
          child: DropdownButton(
            dropdownColor: Colors.white,
            value: _selectedPaymentType,
            items: _dropdownPaymentTypeSortItems,
            onChanged: (value) {
              setState(() {
                _selectedPaymentType = value;
              });
            },
          ),
        ),
      ],
    );
  }

  buildList() {
    List<dynamic> sortedList =
        sortList(_list, _selectedDate, _selectedPaymentType);
    setState(() {
      _totalData = sortedList.length;
    });
    return SingleChildScrollView(
        child: Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        buildSortDropdown(context),
        (_isInitial && sortedList.length == 0)
            ? ShimmerHelper()
                .buildListShimmer(item_count: 5, item_height: 100.0)
            : sortedList.length > 0
                ? ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: sortedList.length,
                    scrollDirection: Axis.vertical,
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      return Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: buildListItem(index, sortedList));
                    },
                  )
                : _totalData == 0
                    ? Center(child: Text("No data is available"))
                    : Container(),
      ],
    ));
  }

  buildListItem(int index, List<dynamic> sortedList) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return OrderDetails(
                id: sortedList[index].id,
                show_additional_section: true,
              );
            })).then((value) {
              onPop(value);
            });
          },
          child: Card(
            shape: RoundedRectangleBorder(
              side: new BorderSide(color: MyTheme.light_grey, width: 1.0),
              borderRadius: BorderRadius.circular(8.0),
            ),
            elevation: 0.0,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Order Code",
                            style: TextStyle(
                                color: MyTheme.font_grey,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        Text(
                          sortedList[index].code,
                          style: TextStyle(
                              color: MyTheme.red,
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      children: [
                        Text(sortedList[index].date,
                            style: TextStyle(
                                color: MyTheme.font_grey, fontSize: 13)),
                        Spacer(),
                        Text(
                          sortedList[index].grand_total,
                          style: TextStyle(
                              color: MyTheme.red,
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        )
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Payment Status",
                          style: TextStyle(
                              color: MyTheme.font_grey,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                        Row(
                          children: [
                            Text(
                              sortedList[index].payment_type,
                              style: TextStyle(
                                  color: MyTheme.font_grey, fontSize: 13),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: buildPaymentStatusCheckContainer(
                                  sortedList[index].payment_status),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        OtherConfig.USE_GOOGLE_MAP
            ? Padding(
                padding: const EdgeInsets.only(
                    left: 4.0, right: 4.0, top: 4.0, bottom: 4.0),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                      border:
                          Border.all(color: MyTheme.textfield_grey, width: 1),
                      borderRadius:
                          const BorderRadius.all(Radius.circular(6.0))),
                  child: MaterialButton(
                    minWidth: (MediaQuery.of(context).size.width - 36) / 2,
                    //height: 50,
                    color: MyTheme.white,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(6.0))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: Icon(
                            Icons.location_on,
                            size: 20,
                            color: MyTheme.red,
                          ),
                        ),
                        Text(
                          "Get Direction",
                          style: TextStyle(
                              color: MyTheme.red,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    onPressed: () {
                      if (!sortedList[index].location_available) {
                        ToastComponent.showDialog("Location not available",
                            gravity: Toast.center,
                            duration: Toast.lengthLong,
                            isError: true);
                        return;
                      }
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                        return SingleOrderMap(
                          order: sortedList[index],
                          color: MyTheme.red,
                        );
                      })).then((value) {
                        onPop(value);
                      });
                    },
                  ),
                ),
              )
            : Container(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SliderButton(
            width: double.infinity,
            vibrationFlag: false,
            action: () async {
              onConfirmMarkDelivered(sortedList[index].id);
              return true;
            },
            shimmer: false,
            label: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Slide to Confirm (Delivered)",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: MyTheme.accent_color,
                      fontWeight: FontWeight.w500,
                      fontSize: 13),
                ),
              ],
            ),
            icon: Icon(
              Icons.done_all_sharp,
              size: 25,
              color: MyTheme.accent_color,
            ),
            buttonColor: MyTheme.soft_accent_color,
            backgroundColor: MyTheme.parrot_green_disabled,
          ),
        ),
      ],
    );
  }

  Container buildPaymentStatusCheckContainer(String? payment_status) {
    return Container(
      height: 16,
      width: 16,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          color: payment_status == "paid" ? Colors.green : Colors.red),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Icon(
            payment_status == "paid" ? FontAwesome.check : FontAwesome.times,
            color: Colors.white,
            size: 10),
      ),
    );
  }

  Container buildCheckContainer() {
    return Container(
      height: 18,
      width: 18,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          color: MyTheme.parrot_green),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Icon(FontAwesome.check, color: Colors.white, size: 12),
      ),
    );
  }

  Container buildLoadingContainer() {
    List<dynamic> sortedList =
        sortList(_list, _selectedDate, _selectedPaymentType);
    return Container(
      height: _showLoadingContainer ? 36 : 0,
      width: double.infinity,
      color: Colors.white,
      child: Center(
        child: Text(_totalData == sortedList.length
            ? "No More Items"
            : "Loading More Items ..."),
      ),
    );
  }
}
