import 'dart:developer';
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myn_seller_app/custom/toast_component.dart';
import 'package:myn_seller_app/data_model/download_report_response.dart';
import 'package:myn_seller_app/my_theme.dart';
import 'package:myn_seller_app/repositories/download_report.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:toast/toast.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';

class DownloadReportScreen extends StatefulWidget {
  const DownloadReportScreen({Key? key}) : super(key: key);

  @override
  _DownloadReportScreenState createState() => _DownloadReportScreenState();
}

class _DownloadReportScreenState extends State<DownloadReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fromDateController = TextEditingController();
  final _toDateController = TextEditingController();
  final _dateFormat = DateFormat('yyyy-MM-dd');
  List<FileSystemEntity> _files = [];

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    final reportsDir = Directory(p.join(directory.path, 'Reports'));
    if (await reportsDir.exists()) {
      setState(() {
        _files = reportsDir.listSync();
      });
    }
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        controller.text = _dateFormat.format(picked);
      });
    }
    }

  Future<void> _submit() async {
    await Permission.storage.request();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final fromDate = DateTime.tryParse(_fromDateController.text);
    final toDate = DateTime.tryParse(_toDateController.text);

    if (fromDate == null || toDate == null || fromDate.isAfter(toDate)) {
      ToastComponent.showDialog(
        "The 'From' date must be before the 'To' date",
        gravity: Toast.center,
        duration: Toast.lengthLong,
      );
      return;
    }

    final formattedFromDate = _dateFormat.format(fromDate);
    final formattedToDate = _dateFormat.format(toDate);

    try {
      final data = await OrderRepository()
          .getOrderReports(formattedFromDate, formattedToDate);
      await _createAndSaveExcelFile(
          data.data, formattedFromDate, formattedToDate);
      await _loadFiles(); // Reload the file list after creating a new file
    } catch (e) {
      ToastComponent.showDialog(
        "Error fetching data: $e",
        gravity: Toast.center,
        duration: Toast.lengthLong,
      );
    }
  }

  Future<void> _createAndSaveExcelFile(
      List<Order> data, String fromDate, String toDate) async {
    var excel = Excel.createExcel();
    excel.rename('Sheet1', 'Report');
    Sheet sheetObject = excel['Report'];

    if (data.isNotEmpty) {
      sheetObject.appendRow([
        TextCellValue('Date of Purchase'),
        TextCellValue('Customer Name'),
        TextCellValue('Order ID'),
        TextCellValue('Mode of Payment'),
        TextCellValue('Seller Price'),
        TextCellValue('Tax Amount'),
        TextCellValue('Total Amount')
      ]);

      for (var item in data) {
        sheetObject.appendRow([
          TextCellValue(item.datePurchase),
          TextCellValue(item.customerName),
          TextCellValue(item.orderCode),
          TextCellValue(item.modePayment),
          DoubleCellValue(item.sellerPrice),
          DoubleCellValue(item.taxAmount),
          DoubleCellValue(item.totalPrice)
        ]);
      }
    }

    var fileBytes = excel.save();
    Directory appDocDir = await getApplicationDocumentsDirectory();
    final fileName = '${fromDate}-${toDate}.xlsx';
    final filePath = p.join(appDocDir.path, 'Reports', fileName);

    try {
      await Directory(p.join(appDocDir.path, 'Reports'))
          .create(recursive: true);
      final file = File(filePath);
      log(filePath);
      await file.writeAsBytes(fileBytes!);
      ToastComponent.showDialog(
        "Successfully Generated",
        gravity: Toast.center,
        duration: Toast.lengthLong,
      );
    } catch (error) {
      ToastComponent.showDialog(
        "Error saving file: $error",
        gravity: Toast.center,
        duration: Toast.lengthLong,
        isError: true,
      );
    }
  }

  Future<void> _viewFile(String filePath) async {
    if (!_isValidExcelFile(filePath)) {
      _showToast("This is not a valid Excel file");
      return;
    }

    final file = File(filePath);
    if (!await file.exists()) {
      _showToast("File does not exist");
      return;
    }

    await _openFile(filePath);
  }

  bool _isValidExcelFile(String filePath) {
    return filePath.toLowerCase().endsWith('.xlsx');
  }

  void _showToast(String message) {
    ToastComponent.showDialog(
      message,
      gravity: Toast.center,
      duration: Toast.lengthLong,
      isError: true,
    );
  }

  Future<void> _openFile(String filePath) async {
    try {
      final result = await OpenFile.open(filePath);
      if (result.type != ResultType.done) {
        _showToast("Unable to open the Excel file");
      }
    } catch (e) {
      print('Error opening file: $e');
      _showToast("Unable to open the Excel file");
    }
  }

  void _shareFile(String filePath) async {
    await Share.shareXFiles([XFile(filePath)]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0.0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.arrow_back, color: MyTheme.dark_grey),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: Text(
          "Download Report",
          style:
              TextStyle(color: MyTheme.font_grey, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Select the date range to download the report",
                    style: TextStyle(
                      fontSize: 16,
                      color: MyTheme.dark_grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _fromDateController,
                    onTap: () => _selectDate(context, _fromDateController),
                    decoration: InputDecoration(
                      labelText: 'From Date',
                      suffixIcon: IconButton(
                        icon: Icon(Icons.calendar_today),
                        onPressed: () =>
                            _selectDate(context, _fromDateController),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a valid date';
                      }
                      if (DateTime.tryParse(value) == null) {
                        return 'Invalid date format';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _toDateController,
                    onTap: () => _selectDate(context, _toDateController),
                    decoration: InputDecoration(
                      labelText: 'To Date',
                      suffixIcon: IconButton(
                        icon: Icon(Icons.calendar_today),
                        onPressed: () =>
                            _selectDate(context, _toDateController),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a valid date';
                      }
                      if (DateTime.tryParse(value) == null) {
                        return 'Invalid date format';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.download, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Download Report',
                              style: TextStyle(color: Colors.white)),
                        ],
                      ),
                      style: ButtonStyle(
                        backgroundColor:
                            WidgetStateProperty.all(MyTheme.accent_color),
                        padding: WidgetStateProperty.all(
                          EdgeInsets.symmetric(
                              vertical: 16 * 0.75, horizontal: 16 * 2.5),
                        ),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            Text(
              "Generated Reports:",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: MyTheme.dark_grey,
              ),
            ),
            SizedBox(height: 8),
            _files.length == 0
                ? Center(
                    child: Text(
                      "No Reports Available",
                      textAlign: TextAlign.center,
                    ),
                  )
                : Expanded(
                    child: ListView.builder(
                      itemCount: _files.length,
                      itemBuilder: (context, index) {
                        final file = _files[index];
                        return ListTile(
                          title: Text(p.basename(file.path)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.visibility,
                                    color: MyTheme.accent_color),
                                onPressed: () => _viewFile(file.path),
                              ),
                              IconButton(
                                icon: Icon(Icons.share,
                                    color: MyTheme.accent_color),
                                onPressed: () => _shareFile(file.path),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fromDateController.dispose();
    _toDateController.dispose();
    super.dispose();
  }
}
