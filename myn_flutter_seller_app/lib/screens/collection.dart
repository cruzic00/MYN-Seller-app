import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_icons_null_safety/flutter_icons_null_safety.dart';
import 'package:myn_seller_app/data_model/earning_or_collection_response.dart';
import 'package:myn_seller_app/helpers/shimmer_helper.dart';
import 'package:myn_seller_app/my_theme.dart';
import 'package:myn_seller_app/repositories/delivery_repository.dart';
import 'package:myn_seller_app/screens/order_details.dart';
import 'package:myn_seller_app/helpers/sortable.dart';

class Collection extends StatefulWidget {
  Collection({
    Key? key,
    this.show_back_button = false,
  }) : super(key: key);

  final bool show_back_button;
  @override
  CollectionState createState() => CollectionState();
}

class CollectionState extends State<Collection> {
  bool _sortAscending = true;
  int? _sortColumnIndex;
  late List<Datum> _data = [];
  bool _isInitial = true;
  int _page = 1;
  int? _totalData = 0;
  bool _showLoadingContainer = false;

  String _today_date = ". . .";
  String _yesterday_date = ". . .";
  String _today_collection = ". . .";
  String _yesterday_collection = ". . .";
  String _today_earning = ". . .";
  String _yesterday_earning = ". . .";

  List<Sortable> _datewiseSortList = Sortable.getDatewiseSortList();
  List<Sortable> _paymentTypeSortList = Sortable.getPaymentTypeSortList();

  Sortable? _selectedDate;
  Sortable? _selectedPaymentType;

  late List<DropdownMenuItem<Sortable>> _dropdownDatewiseSortItems;
  late List<DropdownMenuItem<Sortable>> _dropdownPaymentTypeSortItems;

  String _defaultDateKey = '';
  String _defaultPaymentTypeKey = '';

  @override
  void initState() {
    super.initState();
    fetchAll();
    initSortDropdowns();
  }

  fetchAll() {
    setState(() {
      _showLoadingContainer = true;
    });
    fetchSummary();
    _fetchData();
  }

  fetchSummary() async {
    var collectionSummaryResponse =
        await DeliveryRepository().getCollectionSummaryResponse();
    var earningSummaryResponse =
        await DeliveryRepository().getEarningSummaryResponse();

    setState(() {
      _today_date = collectionSummaryResponse.today_date?.toString() ?? ". . .";
      _yesterday_date =
          collectionSummaryResponse.yesterday_date?.toString() ?? ". . .";
      _today_collection =
          collectionSummaryResponse.today_collection?.toString() ?? ". . .";
      _yesterday_collection =
          collectionSummaryResponse.yesterday_collection?.toString() ?? ". . .";
      _today_earning =
          earningSummaryResponse.today_earning?.toString() ?? ". . .";
      _yesterday_earning =
          earningSummaryResponse.yesterday_earning?.toString() ?? ". . .";
    });
  }

  void initSortDropdowns() {
    _dropdownDatewiseSortItems = buildDropdownItems(_datewiseSortList);
    _dropdownPaymentTypeSortItems = buildDropdownItems(_paymentTypeSortList);
    initSortableDefaults();
  }

  void initSortableDefaults() {
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

  List<DropdownMenuItem<Sortable>> buildDropdownItems(
      List<Sortable> sortableList) {
    return sortableList.map((Sortable item) {
      return DropdownMenuItem(
        value: item,
        child: Text(item.name),
      );
    }).toList();
  }

  Future<void> _fetchData() async {
    var listResponse =
        await DeliveryRepository().getCollectionResponse(page: _page);
    setState(() {
      _data = listResponse.data ?? [];
      _isInitial = false;
      _totalData = listResponse.meta?.total;
      _showLoadingContainer = false;
    });
  }

  void _sort<T>(Comparable<T> Function(Datum d) getField, int columnIndex,
      bool ascending) {
    _data.sort((a, b) {
      final aValue = getField(a);
      final bValue = getField(b);
      return ascending
          ? Comparable.compare(aValue, bValue)
          : Comparable.compare(bValue, aValue);
    });
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  List<Datum> sortList(
      List<Datum> list, Sortable? selectedDate, Sortable? selectedPaymentType) {
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
            final itemDate = DateTime.tryParse(item.purchaseDate ?? '');
            if (itemDate == null) return false;
            return itemDate.isAfter(startOfWeek) &&
                itemDate.isBefore(endOfWeek);
          case 'this_month':
            final today = DateTime.now();
            final startOfMonth = DateTime(today.year, today.month, 1);
            final endOfMonth = startOfMonth
                .add(Duration(days: 32))
                .subtract(Duration(days: startOfMonth.day));
            final itemDate = DateTime.tryParse(item.purchaseDate ?? '');
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
            return item.paymentType == 'Cash On Delivery';
          case 'non_cod_payment':
            return item.paymentType != 'Cash On Delivery';
          default:
            return true;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    List<Datum> sortedData =
        sortList(_data, _selectedDate, _selectedPaymentType);

    double totalTax =
        sortedData.fold(0.0, (sum, item) => sum + (item.totalTax ?? 0));
    double totalSellerPrice = sortedData.fold(
        0.0,
        (sum, item) =>
            sum + (double.tryParse(item.totalSellerPrice ?? '0') ?? 0));
    double totalAmount = totalSellerPrice + totalTax;

    return SafeArea(
      child: Scaffold(
        appBar: buildAppBar(context),
        body: Column(
          children: [
            Expanded(
              child: _isInitial
                  ? ShimmerHelper().buildListShimmer(item_count: 20)
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: DataTable2(
                        headingRowColor: WidgetStateProperty.resolveWith(
                            (states) => Colors.transparent),
                        columnSpacing: 12,
                        horizontalMargin: 12,
                        border: TableBorder(
                          left: BorderSide(color: Colors.black.withAlpha(5)),
                          right: BorderSide(color: Colors.black.withAlpha(5)),
                          verticalInside:
                              BorderSide(color: Colors.black.withAlpha(10)),
                          horizontalInside:
                              BorderSide(color: Colors.black.withAlpha(10)),
                        ),
                        bottomMargin: 10,
                        minWidth: 900,
                        sortColumnIndex: _sortColumnIndex,
                        sortAscending: _sortAscending,
                        columns: [
                          DataColumn2(
                            label: const Text('No.'),
                            size: ColumnSize.S,
                          ),
                          DataColumn2(
                            label: const Text('Order Code'),
                            size: ColumnSize.M,
                            onSort: (columnIndex, ascending) => _sort<String>(
                                (d) => d.orderCode ?? '',
                                columnIndex,
                                ascending),
                          ),
                          DataColumn2(
                            label: const Text('Purchase Date'),
                            size: ColumnSize.L,
                            onSort: (columnIndex, ascending) => _sort<String>(
                                (d) => d.purchaseDate ?? '',
                                columnIndex,
                                ascending),
                          ),
                          DataColumn2(
                            label: const Text('Products'),
                            size: ColumnSize.M,
                          ),
                          DataColumn2(
                            label: const Text('Payment Type'),
                            size: ColumnSize.L,
                            onSort: (columnIndex, ascending) => _sort<String>(
                                (d) => d.paymentType ?? '',
                                columnIndex,
                                ascending),
                          ),
                          DataColumn2(
                            label: const Text('Seller Price'),
                            size: ColumnSize.M,
                            numeric: true,
                            onSort: (columnIndex, ascending) => _sort<num>(
                                (d) =>
                                    double.tryParse(
                                        d.totalSellerPrice ?? '0') ??
                                    0,
                                columnIndex,
                                ascending),
                          ),
                          DataColumn2(
                            label: const Text('Total Tax'),
                            size: ColumnSize.M,
                            numeric: true,
                            onSort: (columnIndex, ascending) => _sort<num>(
                                (d) => d.totalTax ?? 0, columnIndex, ascending),
                          ),
                          DataColumn2(
                            label: const Text('Total Amount'),
                            size: ColumnSize.M,
                            numeric: true,
                            onSort: (columnIndex, ascending) => _sort<num>(
                                (d) =>
                                    (double.tryParse(
                                            d.totalSellerPrice ?? '0') ??
                                        0) +
                                    (d.totalTax ?? 0),
                                columnIndex,
                                ascending),
                          ),
                        ],
                        rows: List<DataRow>.generate(
                          sortedData.length + 1,
                          (index) {
                            if (index == sortedData.length) {
                              // Summary row
                              return DataRow2(
                                color:
                                    WidgetStateProperty.all(Colors.grey[200]),
                                cells: [
                                  DataCell(Text('Total',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                                  DataCell(Text('')),
                                  DataCell(Text('')),
                                  DataCell(Text('')),
                                  DataCell(Text('')),
                                  DataCell(Text(
                                      totalSellerPrice.toStringAsFixed(2),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                                  DataCell(Text(totalTax.toStringAsFixed(2),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                                  DataCell(Text(totalAmount.toStringAsFixed(2),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                                ],
                              );
                            }

                            var item = sortedData[index];
                            int productInfoLength = item.productInfo
                                    ?.map((p) => p.name)
                                    .join(', ')
                                    .length ??
                                0;
                            double baseHeight = 60.0; // Base height for rows
                            double additionalHeight =
                                (productInfoLength / 40).ceil() *
                                    20.0; // Add 20 height per 40 characters
                            double rowHeight = baseHeight + additionalHeight;
                            return DataRow2(
                              specificRowHeight: rowHeight,
                              cells: [
                                DataCell(Text('${index + 1}')),
                                DataCell(
                                  Text(item.orderCode ?? ''),
                                  onTap: () {
                                    if (item.orderCode != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              OrderDetails(id: item.orderId!),
                                        ),
                                      );
                                    }
                                  },
                                ),
                                DataCell(Text(item.purchaseDate ?? '')),
                                DataCell(
                                  Text(
                                    item.productInfo
                                            ?.map((p) => p.name)
                                            .join(', ') ??
                                        '',
                                  ),
                                ),
                                DataCell(Text(item.paymentType ?? '')),
                                DataCell(Text(item.totalSellerPrice ?? '0.00')),
                                DataCell(Text(
                                    item.totalTax?.toStringAsFixed(2) ??
                                        '0.00')),
                                DataCell(Text(((double.tryParse(
                                                item.totalSellerPrice ?? '0') ??
                                            0) +
                                        (item.totalTax ?? 0))
                                    .toStringAsFixed(2))),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      surfaceTintColor: Colors.white,
      automaticallyImplyLeading: false,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.arrow_back, color: MyTheme.dark_grey),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      title: Text(
        "Collection",
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
        ),
      ),
    );
  }

  Widget buildBottomAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: MyTheme.red,
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  ),
                  constraints: BoxConstraints(maxWidth: 600.0, minWidth: 200.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 4.0, bottom: 16.0),
                          child: Text(
                            "Today",
                            style:
                                TextStyle(color: Colors.white, fontSize: 14.0),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2.0),
                          child: Text(
                            _today_collection,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(_today_date,
                            style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 12.0), // Add spacing between containers
                Container(
                  decoration: BoxDecoration(
                    color: MyTheme.grey_153,
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  ),
                  constraints: BoxConstraints(maxWidth: 600.0, minWidth: 200.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 4.0, bottom: 16.0),
                          child: Text(
                            "Yesterday",
                            style:
                                TextStyle(color: Colors.white, fontSize: 14.0),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2.0),
                          child: Text(
                            _yesterday_collection,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(_yesterday_date,
                            style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSortDropdown(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Icon(FontAwesome.calendar, color: MyTheme.font_grey, size: 20),
        SizedBox(width: 8),
        DropdownButtonHideUnderline(
          child: DropdownButton<Sortable>(
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
          child: DropdownButton<Sortable>(
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
}
