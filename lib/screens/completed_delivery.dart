import 'package:myn_seller_app/myn_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_icons_null_safety/flutter_icons_null_safety.dart';
import 'package:myn_seller_app/helpers/shimmer_helper.dart';
import 'package:myn_seller_app/helpers/sortable.dart';
import 'package:myn_seller_app/my_theme.dart';
import 'package:myn_seller_app/repositories/delivery_repository.dart';
import 'package:myn_seller_app/screens/order_details.dart';

class CompletedDelivery extends StatefulWidget {
  CompletedDelivery({Key? key, this.show_back_button = false})
      : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final bool show_back_button;

  @override
  _CompletedDeliveryState createState() => _CompletedDeliveryState();
}

class _CompletedDeliveryState extends State<CompletedDelivery> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  ScrollController _scrollController = ScrollController();
  ScrollController _xcrollController = ScrollController();

  List<Sortable> _datewiseSortList = Sortable.getDatewiseSortList();
  List<Sortable> _paymentTypeSortList = Sortable.getPaymentTypeSortList();

  Sortable? _selectedDate;
  Sortable? _selectedPaymentType;

  List<DropdownMenuItem<Sortable>>? _dropdownDatewiseSortItems;
  List<DropdownMenuItem<Sortable>>? _dropdownPaymentTypeSortItems;

  //init

  List<dynamic> _list = [];
  bool _isInitial = true;
  int _page = 1;
  int? _totalData = 0;
  bool _showLoadingContainer = false;

  String _defaultDateKey = '';
  String _defaultPaymentTypeKey = '';

  @override
  void initState() {
    init();
    super.initState();

    fetchData();

    _xcrollController.addListener(() {
      if (_xcrollController.position.pixels ==
          _xcrollController.position.maxScrollExtent) {
        setState(() {
          _page++;
          _showLoadingContainer = true;
        });

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
    for (int x = 0; x < _dropdownDatewiseSortItems!.length; x++) {
      if (_dropdownDatewiseSortItems![x].value!.option_key == _defaultDateKey) {
        _selectedDate = _dropdownDatewiseSortItems![x].value;
      }
    }

    for (int x = 0; x < _dropdownPaymentTypeSortItems!.length; x++) {
      if (_dropdownPaymentTypeSortItems![x].value!.option_key ==
          _defaultPaymentTypeKey) {
        _selectedPaymentType = _dropdownPaymentTypeSortItems![x].value;
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
    setState(() {
      _showLoadingContainer = true;
    });
    try {
      var listResponse = await DeliveryRepository().getDeliveryListResponse(
          page: _page,
          type: "completed",
          dateRange: _selectedDate!.option_key,
          paymentType: _selectedPaymentType!.option_key);
      setState(() {
        _list.addAll(listResponse.orders ?? []);
        _isInitial = false;
        _totalData = listResponse.meta?.total;
        _showLoadingContainer = false;
      });
    } catch (e) {
      // Handle error
      setState(() {
        _showLoadingContainer = false;
      });
    }

    setState(() {});
  }

  reset() {
    _list.clear();
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
          // bottomNavigationBar: buildBottomNavBar(context),
          body: Stack(
            children: [
              buildList(),
              Align(
                alignment: Alignment.bottomCenter,
                child: buildLoadingContainer(),
              ),
            ],
          )),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      toolbarHeight: 100,
      centerTitle: true,
      leading: Builder(
        builder: (context) => IconButton(
            icon: Icon(Icons.arrow_back, color: MyTheme.dark_grey),
            onPressed: () {
              return Navigator.of(context).pop();
            }),
      ),
      title: Text(
        "Completed Delivery",
        style: TextStyle(color: MyTheme.font_grey, fontWeight: FontWeight.bold),
      ),
      surfaceTintColor: Colors.white,
      systemOverlayStyle: MynPalette.overlayDark,
      automaticallyImplyLeading: false,
      elevation: 0.0,
      titleSpacing: 0,
      bottom: PreferredSize(
          preferredSize: Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: buildSortDropdown(context),
          )),
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
                              color: MyTheme.parrot_green,
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
                              color: MyTheme.parrot_green,
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
        Padding(
          padding: const EdgeInsets.only(
              left: 4.0, right: 4.0, top: 4.0, bottom: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
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
                    color: MyTheme.parrot_green_disabled,
                    splashColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(6.0))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: Icon(
                            Icons.done,
                            size: 14,
                            color: MyTheme.white,
                          ),
                        ),
                        Text(
                          "Delivered",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    onPressed: () {
                      //onPressedLogin();
                    },
                  ),
                ),
              ),
            ],
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

// buildBottomNavBar(
//   BuildContext context,
// ) {
//   return Builder(builder: (BuildContext context) {
//     return BottomAppBar(
//       padding: EdgeInsets.zero,
//       child: Container(
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             MaterialButton(
//               splashColor: Colors.transparent,
//               minWidth: MediaQuery.of(context).size.width / 2 - .5,
//               height: 50,
//               color: MyTheme.parrot_green,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(0.0),
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.only(right: 8.0),
//                     child: Container(
//                         height: 16,
//                         width: 16,
//                         child: Image.asset(
//                           "assets/delivery_moving.png",
//                           color: Colors.white,
//                         )),
//                   ),
//                   Text(
//                     "Completed Order",
//                     style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600),
//                   ),
//                 ],
//               ),
//               onPressed: () {},
//             ),
//             SizedBox(
//               width: 1,
//             ),
//             MaterialButton(
//               minWidth: MediaQuery.of(context).size.width / 2 - .5,
//               height: 50,
//               color: MyTheme.red,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(0.0),
//               ),
//               child: Row(
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.only(right: 8.0),
//                     child: Container(
//                         height: 14,
//                         width: 14,
//                         child: Image.asset(
//                           "assets/clock.png",
//                           color: Colors.white,
//                         )),
//                   ),
//                   Text(
//                     "Pending Order",
//                     style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600),
//                   ),
//                 ],
//               ),
//               onPressed: () {
//                 Navigator.push(context, MaterialPageRoute(builder: (context) {
//                   return Pending();
//                 })).then((value) {
//                   onPop(value);
//                 });
//               },
//             )
//           ],
//         ),
//       ),
//     );
//   });
// }
// }
