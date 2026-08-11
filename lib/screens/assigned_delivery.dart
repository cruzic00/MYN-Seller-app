import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_icons_null_safety/flutter_icons_null_safety.dart';
import 'package:flutter_timer_countdown/flutter_timer_countdown.dart';
import 'package:myn_seller_app/custom/toast_component.dart';
import 'package:myn_seller_app/data_model/order_mini_response.dart';
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

import '../ui_elements/notification_card.dart';

class AssignedDelivery extends StatefulWidget {
  final bool show_back_button;

  AssignedDelivery({Key? key, this.show_back_button = false}) : super(key: key);

  @override
  _AssignedDeliveryState createState() => _AssignedDeliveryState();
}

class _AssignedDeliveryState extends State<AssignedDelivery> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  ScrollController _scrollController = ScrollController();
  ScrollController _xcrollController = ScrollController();
  List<Sortable> _datewiseSortList = Sortable.getDatewiseSortList();
  List<Sortable> _paymentTypeSortList = Sortable.getPaymentTypeSortList();
  Sortable? _selectedDate;
  Sortable? _selectedPaymentType;
  late List<DropdownMenuItem<Sortable>> _dropdownDatewiseSortItems;
  late List<DropdownMenuItem<Sortable>> _dropdownPaymentTypeSortItems;
  List<dynamic> _list = [];
  bool _isInitial = true;
  int _page = 1;
  int? _totalData = 0;
  bool _showLoadingContainer = false;
  String _defaultDateKey = '';
  String _defaultPaymentTypeKey = '';
  var _marked_ids = [];
  List<Order> deliveryPoints = [];
  Timer? _autoCancelTimer;
  Duration? _remainingTime;
  Timer? _timerDisplay;
  late ValueNotifier<Duration?> _remainingTimeNotifier;

  @override
  void initState() {
    super.initState();
    _remainingTimeNotifier = ValueNotifier<Duration?>(null);
    init();
    fetchData();
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
  void dispose() {
    _scrollController.dispose();
    _xcrollController.dispose();
    _remainingTimeNotifier.dispose();
    _autoCancelTimer?.cancel();
    _timerDisplay?.cancel();
    super.dispose();
  }

  void init() {
    _dropdownDatewiseSortItems = buildDropdownItems(_datewiseSortList);
    _dropdownPaymentTypeSortItems = buildDropdownItems(_paymentTypeSortList);
    initSortableDefaults();
  }

  void initSortableDefaults() {
    for (var item in _dropdownDatewiseSortItems) {
      if (item.value!.option_key == _defaultDateKey) {
        _selectedDate = item.value;
      }
    }
    for (var item in _dropdownPaymentTypeSortItems) {
      if (item.value!.option_key == _defaultPaymentTypeKey) {
        _selectedPaymentType = item.value;
      }
    }
    setState(() {});
  }

  List<dynamic> sortList(List<dynamic> list, Sortable? selectedDate,
      Sortable? selectedPaymentType) {
    return list.where((item) {
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

  List<DropdownMenuItem<Sortable>> buildDropdownItems(List list) {
    List<DropdownMenuItem<Sortable>> items = [];
    for (Sortable item in list as Iterable<Sortable>) {
      items.add(
        DropdownMenuItem(
          value: item,
          child: Text(item.name),
        ),
      );
    }
    return items;
  }

  Future<void> fetchData() async {
    var listResponse = await DeliveryRepository().getDeliveryListResponse(
        page: _page,
        type: "assigned",
        dateRange: _selectedDate?.option_key ?? '',
        paymentType: _selectedPaymentType?.option_key ?? '');
    _list.addAll(listResponse.orders!);
    deliveryPoints.addAll(getAvailableLocationOrders(listResponse.orders!));
    _isInitial = false;
    _totalData = listResponse.meta!.total;
    _showLoadingContainer = false;
    setState(() {});
  }

  List<Order> getAvailableLocationOrders(List<Order> orders) {
    List<Order> latLng = [];
    for (var element in orders) {
      if (element.location_available!) {
        latLng.add(element);
      }
    }
    return latLng;
  }

  void reset() {
    _list.clear();
    _marked_ids.clear();
    _isInitial = true;
    _page = 1;
    _totalData = 0;
    _showLoadingContainer = false;
    setState(() {});
  }

  void resetFilterKeys() {
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

  void onPop(value) {
    reset();
    resetFilterKeys();
    initSortableDefaults();
    fetchData();
  }

  void onConfirmMarkPicked(int orderId) async {
    var deliveryStatusChangeResponse = await DeliveryRepository()
        .getDeliveryStatusChangeResponse(status: "confirmed", orderId: orderId);

    if (deliveryStatusChangeResponse.result == true) {
      ToastComponent.showDialog(deliveryStatusChangeResponse.message,
          gravity: Toast.center, duration: Toast.lengthLong);
      _marked_ids.add(orderId);
      setState(() {});
    } else {
      ToastComponent.showDialog(deliveryStatusChangeResponse.message,
          gravity: Toast.center, duration: Toast.lengthLong, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    ToastContext().init(context);
    return SafeArea(
      child: Scaffold(
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
              child: buildLoadingContainer(),
            ),
          ],
        ),
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      toolbarHeight: 100,
      centerTitle: false,
      backgroundColor: Colors.white,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
      ),
      automaticallyImplyLeading: false,
      actions: [
        Container(),
      ],
      elevation: 0.0,
      titleSpacing: 0,
      flexibleSpace: Column(
        children: [buildTopAppBarContainer()],
      ),
    );
  }

  Container buildTopAppBarContainer() {
    return Container(
      child: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.arrow_back, color: MyTheme.dark_grey),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: MyTheme.blue,
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(
                "assets/sandclock.png",
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              "Assigned (${_totalData.toString()})",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: MyTheme.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Row buildSortDropdown(BuildContext context) {
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

  Widget buildList() {
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
          (_isInitial && sortedList.isEmpty)
              ? ShimmerHelper()
                  .buildListShimmer(item_count: 5, item_height: 100.0)
              : sortedList.isNotEmpty
                  ? ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: sortedList.length,
                      scrollDirection: Axis.vertical,
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: buildListItem(index, sortedList),
                        );
                      },
                    )
                  : _totalData == 0
                      ? Center(child: Text("No data is available"))
                      : Container(),
        ],
      ),
    );
  }

  Widget buildListItem(int index, List<dynamic> sortedList) {
    return Column(
      children: [
        InkWell(
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
              side: BorderSide(color: MyTheme.light_grey, width: 1.0),
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
                              color: MyTheme.blue,
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
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Payment Methods",
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
                            color: MyTheme.blue,
                          ),
                        ),
                        Text(
                          "Get Direction",
                          style: TextStyle(
                              color: MyTheme.blue,
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
                          color: MyTheme.blue,
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
          child: GestureDetector(
            onDoubleTap: () {
              NotificationService.NotificationSound(true);
              DoubleAlertCancellation(sortedList[index].id);
            },
            child: SliderButton(
              width: double.infinity,
              vibrationFlag: false,
              action: () async {
                NotificationService.NotificationSound(true);
                onConfirmMarkPicked(sortedList[index].id);
                return true;
              },
              shimmer: false,
              label: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Slide to Confirm",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: MyTheme.accent_color,
                        fontWeight: FontWeight.w500,
                        fontSize: 13),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Double Click to Cancel",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: MyTheme.red,
                            fontWeight: FontWeight.w500,
                            fontSize: 10),
                      ),
                      TimerCountdownWidget(
                        deliveryHistoryDate: DateTime.parse(
                            sortedList[index].delivery_history_date!),
                        orderId: sortedList[index].id,
                      )
                    ],
                  ),
                ],
              ),
              icon: Icon(
                Icons.done,
                size: 25,
                color: MyTheme.accent_color,
              ),
              buttonColor: MyTheme.soft_accent_color,
              backgroundColor: MyTheme.parrot_green_disabled,
            ),
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

  void DoubleAlertCancellation(int orderId) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              contentPadding: EdgeInsets.only(
                  top: 16.0, left: 2.0, right: 2.0, bottom: 2.0),
              content: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Text(
                  "Are you sure to cancel this order?",
                  maxLines: 3,
                  style: TextStyle(color: MyTheme.font_grey, fontSize: 14),
                ),
              ),
              actions: [
                MaterialButton(
                  child: Text(
                    "Close",
                    style: TextStyle(color: MyTheme.medium_grey),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                MaterialButton(
                    color: MyTheme.red,
                    child: Text(
                      "Confirm",
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                                contentPadding: EdgeInsets.only(
                                    top: 16.0,
                                    left: 2.0,
                                    right: 2.0,
                                    bottom: 2.0),
                                content: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 16.0),
                                  child: Text(
                                    "Are you sure to cancel this order? (Double Confirmation)",
                                    maxLines: 3,
                                    style: TextStyle(
                                        color: MyTheme.font_grey, fontSize: 14),
                                  ),
                                ),
                                actions: [
                                  MaterialButton(
                                    child: Text(
                                      "Close",
                                      style:
                                          TextStyle(color: MyTheme.medium_grey),
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                  ),
                                  MaterialButton(
                                      color: MyTheme.red,
                                      child: Text(
                                        "Confirm",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      onPressed: () {
                                        onConfirmCancel(orderId);
                                        Navigator.pop(context);
                                      }),
                                ],
                              ));
                    }),
              ],
            ));
  }

  void onConfirmCancel(int orderId) async {
    var cancelRequestResponse = await DeliveryRepository()
        .getDeliveryStatusChangeResponse(status: "cancelled", orderId: orderId);

    if (cancelRequestResponse.result == true) {
      ToastComponent.showDialog(cancelRequestResponse.message,
          gravity: Toast.center, duration: Toast.lengthLong);

      reset();
      fetchData();
    } else {
      ToastComponent.showDialog(cancelRequestResponse.message,
          gravity: Toast.center, duration: Toast.lengthLong, isError: true);
    }
  }
}

class TimerCountdownWidget extends StatelessWidget {
  final DateTime deliveryHistoryDate;
  final int orderId;

  TimerCountdownWidget(
      {required this.deliveryHistoryDate, required this.orderId});

  void cancelOrder(int orderId) async {
    try {
      var cancelResponse =
          await DeliveryRepository().getDeliveryStatusChangeResponse(
        status: "cancelled",
        orderId: orderId,
      );

      if (cancelResponse.result == true) {
        ToastComponent.showDialog(cancelResponse.message,
            gravity: Toast.center, duration: Toast.lengthLong);
        // reset();
        // fetchData();
      } else {
        throw Exception(cancelResponse.message);
      }
    } catch (error) {
      ToastComponent.showDialog("Error: ${error.toString()}",
          gravity: Toast.center, duration: Toast.lengthLong, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime deliveryDate = deliveryHistoryDate.toUtc();
    DateTime endTime = deliveryDate.add(Duration(minutes: 15));
    DateTime nowIST = DateTime.now().toUtc();
    Duration timeLeft = endTime.difference(nowIST);

    // Print the dates and times in IST
    print("Original Delivery Date (UTC): $deliveryHistoryDate");
    print("Delivery Date (UST): $deliveryDate");
    print("End Time (UST): $endTime");
    print("Time Left: $timeLeft");
    print("Current Time (UST): $nowIST");

    return !timeLeft.isNegative
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Waiting ",
                // "or Auto Cancel in ",
                style: TextStyle(
                  color: MyTheme.red,
                  fontSize: 10,
                ),
              ),
              TimerCountdown(
                format: CountDownTimerFormat.minutesSeconds,
                endTime: DateTime.now().add(timeLeft),
                onEnd: () {
                  // cancelOrder(orderId);
                },
                timeTextStyle: TextStyle(
                  color: MyTheme.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                colonsTextStyle: TextStyle(
                  color: MyTheme.red_disabled,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                spacerWidth: 2,
                enableDescriptions: false,
              ),
            ],
          )
        : Container();
  }
}
