import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myn_seller_app/app_config.dart';
import 'package:myn_seller_app/custom/input_decorations.dart';
import 'package:myn_seller_app/custom/toast_component.dart';
import 'package:myn_seller_app/helpers/shared_value_helper.dart';
import 'package:myn_seller_app/my_theme.dart';
import 'package:myn_seller_app/repositories/product_repository.dart';
import 'package:toast/toast.dart';

class ProductAdd extends StatefulWidget {
  @override
  _ProductAddState createState() => _ProductAddState();
}

class _ProductAddState extends State<ProductAdd> {
  final ScrollController _mainScrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _unitPriceController = TextEditingController();
  final TextEditingController _purchasePriceController = TextEditingController();
  final TextEditingController _gstController = TextEditingController();
  final TextEditingController _hsnCodeController = TextEditingController();
  final TextEditingController _currentStockController = TextEditingController();

  String? _selectedCategory;
  List<String> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      var productCategoryResponse = await ProductRepository().getCategoryList();

      if (productCategoryResponse == null || productCategoryResponse['data'] == null) {
        throw Exception('Invalid response from server');
      }

      if (productCategoryResponse['data'].isEmpty) {
        throw Exception('No categories found');
      }

      setState(() {
        _categories.clear(); // Clear existing categories before adding new ones
        for (var category in productCategoryResponse['data']) {
          if (category['name'] != null && category['id'] != null) {
            _categories.add("${category['name']},${category['id']}");
          }
        }

        if (_categories.isEmpty) {
          throw Exception('Failed to parse category data');
        }

        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching categories: $e');
      setState(() {
        _isLoading = false;
      });

      String errorMessage;
      if (e is Exception) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      } else {
        errorMessage = 'An unexpected error occurred. Please try again later.';
      }

      ToastComponent.showDialog(errorMessage, gravity: Toast.center, duration: Toast.lengthLong, isError: true);
    }
  }

  Future<void> _addProduct() async {
    var name = _nameController.text.trim();
    var description = _descriptionController.text.trim();
    var unitPrice = _unitPriceController.text.trim();
    var purchasePrice = _purchasePriceController.text.trim();
    var gst = _gstController.text.trim();
    var hsnCode = _hsnCodeController.text.trim();
    var currentStock = _currentStockController.text.trim();

    if (name.isEmpty ||
        unitPrice.isEmpty ||
        purchasePrice.isEmpty ||
        currentStock.isEmpty ||
        _selectedCategory == null) {
      ToastComponent.showDialog("Please fill all required fields", gravity: Toast.center, duration: Toast.lengthLong);
      return;
    }

    var postBody = jsonEncode({
      "added_by": "seller",
      "name": name,
      "seller_id": "${user_id.$}",
      "category_id": _selectedCategory?.split(",")[1].toString(),
      "brand_id": "",
      "purchase_price": purchasePrice,
      "description": description,
      "unit_price": unitPrice,
      "current_stock": currentStock,
      "supplier_price": purchasePrice,
      "gst": gst,
      "hsn_code": hsnCode
    });

    try {
      final response = await http.post(
        Uri.parse("${AppConfig.BASE_URL}/product/add"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer ${access_token.$}"},
        body: postBody,
      );

      var responseData = json.decode(response.body);

      if (responseData['status'] == 200) {
        ToastComponent.showDialog(
          "Product added. Wait for admin approval",
          gravity: Toast.center,
          duration: Toast.lengthLong,
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('Failed to add product');
      }
    } catch (e) {
      print('Error adding product: $e');
      ToastComponent.showDialog(
        "Failed to add product. Please try again.",
        gravity: Toast.center,
        duration: Toast.lengthLong,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ToastContext().init(context);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: buildAppBar(context),
      body: _isLoading ? Center(child: CircularProgressIndicator.adaptive()) : buildBody(context),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: MyTheme.dark_grey),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        "Add Product",
        style: TextStyle(color: MyTheme.font_grey, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      elevation: 0.0,
      backgroundColor: Colors.white,
    );
  }

  Widget buildBody(BuildContext context) {
    return SingleChildScrollView(
      controller: _mainScrollController,
      physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "Product Information",
                style: TextStyle(
                  color: MyTheme.dark_grey,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            buildTextField("Product Name", _nameController, "Enter product name"),
            buildTextField("Description", _descriptionController, "Enter product description", maxLines: 3),
            buildDropdown("Category", _selectedCategory, _categories),
            buildTextField("Unit Price", _unitPriceController, "Enter unit price"),
            buildTextField("Purchase Price", _purchasePriceController, "Enter purchase price"),
            buildTextField("GST", _gstController, "Enter GST"),
            buildTextField("HSN Code", _hsnCodeController, "Enter HSN code"),
            buildTextField("Current Stock", _currentStockController, "Enter current stock"),
            buildAddButton(context),
          ],
        ),
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller, String hint, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: MyTheme.red, fontWeight: FontWeight.w600)),
          SizedBox(height: 4.0),
          Container(
            height: maxLines == 1 ? 36 : null,
            child: TextField(
              controller: controller,
              autofocus: false,
              maxLines: maxLines,
              decoration: InputDecorations.buildInputDecoration_1(hintText: hint),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDropdown(String label, String? value, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: MyTheme.red, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 4.0),
          items.isNotEmpty
              ? Container(
                  width: double.infinity,
                  child: DropdownButtonFormField<String>(
                    dropdownColor: Colors.white,
                    menuMaxHeight: 500,
                    value: value,
                    hint: Text("Select ${label}", style: TextStyle(fontSize: 14.0, color: MyTheme.dark_grey)),
                    validator: (value) => value == null ? 'Please select a $label' : null,
                    items: items.map((item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item.split(',')[0]),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    },
                    decoration: InputDecorations.buildInputDecoration_1(),
                  ),
                )
              : Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                  decoration: BoxDecoration(
                    color: MyTheme.red_disabled,
                    border: Border.all(color: MyTheme.accent_color_2, width: 1),
                    borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  ),
                  child: Text("No ${label}s Found for your Account"),
                ),
        ],
      ),
    );
  }

  Widget buildAddButton(BuildContext context) {
    return MaterialButton(
      minWidth: MediaQuery.of(context).size.width,
      height: 50,
      color: MyTheme.red,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8.0))),
      child: Text(
        "Add Product",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      onPressed: _addProduct,
    );
  }
}
