import 'package:flutter/material.dart';
import 'package:flutter_icons_null_safety/flutter_icons_null_safety.dart';
import 'package:myn_seller_app/helpers/shimmer_helper.dart';
import 'package:myn_seller_app/helpers/sortable.dart';
import 'package:myn_seller_app/my_theme.dart';
import 'package:myn_seller_app/repositories/delivery_repository.dart';

class Earnings extends StatefulWidget {
  Earnings({
    Key? key,
    this.show_back_button = false,
  }) : super(key: key);

  final bool show_back_button;

  @override
  _EarningsState createState() => _EarningsState();
}

class _EarningsState extends State<Earnings> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

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
  String _today_date = ". . .";
  String _yesterday_date = ". . .";
  String _today_earning = ". . .";
  String _yesterday_earning = ". . .";

  String _defaultDateKey = '';
  String _defaultPaymentTypeKey = '';

  @override
  void initState() {
    super.initState();
    init();
    fetchAll();

    _xcrollController.addListener(() {
      if (_xcrollController.position.pixels ==
          _xcrollController.position.maxScrollExtent) {
        setState(() {
          _page++;
          _showLoadingContainer = true;
        });
        fetchList();
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
            return item.purchaseDate == DateTime.now().toString().split(' ')[0];
          case 'this_week':
            final today = DateTime.now();
            final startOfWeek =
                today.subtract(Duration(days: today.weekday - 1));
            final endOfWeek = startOfWeek.add(Duration(days: 6));
            final itemDate = DateTime.tryParse(item.purchaseDate!);
            if (itemDate == null) return false;
            return itemDate.isAfter(startOfWeek) &&
                itemDate.isBefore(endOfWeek);
          case 'this_month':
            final today = DateTime.now();
            final startOfMonth = DateTime(today.year, today.month, 1);
            final endOfMonth = startOfMonth
                .add(Duration(days: 32))
                .subtract(Duration(days: startOfMonth.day));
            final itemDate = DateTime.tryParse(item.purchaseDate!);
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
            return item.paymentType == 'cash_on_delivery';
          case 'non_cod_payment':
            return item.paymentType != 'cash_on_delivery';
          default:
            return true;
        }
      }

      return true;
    }).toList();
  }

  List<DropdownMenuItem<Sortable>> buildDropdownItems(
      List<Sortable> sortableList) {
    List<DropdownMenuItem<Sortable>> items = [];
    for (Sortable item in sortableList) {
      items.add(
        DropdownMenuItem(
          value: item,
          child: Text(item.name),
        ),
      );
    }
    return items;
  }

  fetchAll() {
    setState(() {
      _showLoadingContainer = true;
    });
    fetchSummary();
    fetchList();
    setState(() {
      _showLoadingContainer = false;
    });
  }

  fetchSummary() async {
    var earningSummaryResponse =
        await DeliveryRepository().getEarningSummaryResponse();

    setState(() {
      _today_date = earningSummaryResponse.today_date?.toString() ?? ". . .";
      _yesterday_date =
          earningSummaryResponse.yesterday_date?.toString() ?? ". . .";
      _today_earning =
          earningSummaryResponse.today_earning?.toString() ?? ". . .";
      _yesterday_earning =
          earningSummaryResponse.yesterday_earning?.toString() ?? ". . .";
    });
  }

  fetchList() async {
    var listResponse = await DeliveryRepository().getEarningResponse(
      page: _page,
    );

    setState(() {
      _list.addAll(listResponse.data ?? []);
      _isInitial = false;
      _totalData = listResponse.meta?.total ?? 0;
    });
  }

  reset() {
    setState(() {
      _list.clear();
      _isInitial = true;
      _page = 1;
      _totalData = 0;
      _showLoadingContainer = false;

      _today_date = ". . .";
      _yesterday_date = ". . .";
      _today_earning = ". . .";
      _yesterday_earning = ". . .";
    });
  }

  resetFilterKeys() {
    setState(() {
      _defaultDateKey = '';
      _defaultPaymentTypeKey = '';
    });
  }

  Future<void> _onRefresh() async {
    reset();
    resetFilterKeys();
    initSortableDefaults();
    fetchAll();
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
          backgroundColor: Colors.white,
          appBar: buildAppBar(context),
          key: _scaffoldKey,
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
                        buildLoadingContainer(),
                        // Moved to the end of the list
                        Container(
                          height: 100,
                        )
                      ]),
                    )
                  ],
                ),
              ),
            ],
          )),
    );
  }

  buildBottomAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              constraints: BoxConstraints(minWidth: 200),
              decoration: BoxDecoration(
                  color: MyTheme.blue,
                  borderRadius: BorderRadius.all(Radius.circular(8))),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0, bottom: 16.0),
                      child: Text(
                        "Today",
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2.0),
                      child: Text(
                        _today_earning,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      _today_date,
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 16,
            ),
            Container(
              constraints: BoxConstraints(minWidth: 200),
              decoration: BoxDecoration(
                  color: MyTheme.grey_153,
                  borderRadius: BorderRadius.all(Radius.circular(8))),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0, bottom: 16.0),
                      child: Text(
                        "Yesterday",
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2.0),
                      child: Text(
                        _yesterday_earning,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      _yesterday_date,
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  buildAppBar(BuildContext context) {
    return AppBar(
      centerTitle: true,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      automaticallyImplyLeading: false,
      leading: Builder(
        builder: (context) => IconButton(
            icon: Icon(Icons.arrow_back, color: MyTheme.dark_grey),
            onPressed: () {
              return Navigator.of(context).pop();
            }),
      ),
      title: Text(
        "Earnings",
        style: TextStyle(color: MyTheme.dark_grey, fontWeight: FontWeight.bold),
      ),
      elevation: 0,
      titleSpacing: 0,
      bottom: PreferredSize(
          preferredSize: Size.fromHeight(190),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              children: [
                buildBottomAppBar(context),
                buildSortDropdown(context),
              ],
            ),
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
        Card(
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
                  child: Text(
                    sortedList[index].orderCode ?? "",
                    style: TextStyle(
                        color: MyTheme.grey_153,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    children: [
                      Text(
                        sortedList[index].purchaseDate ?? "",
                        style:
                            TextStyle(color: MyTheme.font_grey, fontSize: 13),
                      ),
                      Spacer(),
                      Text(
                        sortedList[index].earning ?? "",
                        style: TextStyle(
                            color: MyTheme.blue,
                            fontSize: 14,
                            fontWeight: FontWeight.w600),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Container buildPaymentStatusCheckContainer(String payment_status) {
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
