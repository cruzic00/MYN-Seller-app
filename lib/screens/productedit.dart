import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myn_seller_app/app_config.dart';
import 'package:myn_seller_app/custom/input_decorations.dart';
import 'package:myn_seller_app/custom/toast_component.dart';
import 'package:myn_seller_app/helpers/shared_value_helper.dart';
import 'package:myn_seller_app/my_theme.dart';
import 'package:myn_seller_app/repositories/product_repository.dart';
import 'package:myn_seller_app/ui_sections/drawer.dart';
import 'package:toast/toast.dart';

class ProductEdit extends StatefulWidget {
  final int? id;
  final bool showBackButton;

  ProductEdit({Key? key, this.id, this.showBackButton = false}) : super(key: key);

  @override
  _ProductEditState createState() => _ProductEditState();
}

class _ProductEditState extends State<ProductEdit> {
  final ScrollController _mainScrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mrpController = TextEditingController();
  final TextEditingController _sellerPriceController = TextEditingController();
  final TextEditingController _quantityConfirmController = TextEditingController();

  bool? _isActive;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    fetchAll();
  }

  Future<void> fetchAll() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      var productDetailsResponse = await ProductRepository().getProductDetails(id: widget.id);

      if (productDetailsResponse.detailed_products!.isNotEmpty) {
        var product = productDetailsResponse.detailed_products![0];
        setState(() {
          _nameController.text = product.name!;
          _mrpController.text = product.stroked_value!;
          _sellerPriceController.text = product.supplier_price!;
          _quantityConfirmController.text = product.current_stock.toString();
          _isActive = product.is_active!;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleIsActive() async {
    var postBody = jsonEncode({
      "productId": widget.id,
      "status": _isActive!,
    });

    final response = await http.post(
      Uri.parse("${AppConfig.BASE_URL}/product/change-status"),
      headers: {"Content-Type": "application/json", "Authorization": "Bearer ${access_token.$}"},
      body: postBody,
    );

    var dataUser = json.decode(response.body);
    ToastComponent.showDialog(dataUser['message'], gravity: Toast.center, duration: Toast.lengthLong);
  }

  Future<void> _onPressUpdate() async {
    var name = _nameController.text.trim();
    var mrp = _mrpController.text.trim();
    var sellerPrice = _sellerPriceController.text.trim();
    var quantity = _quantityConfirmController.text.trim();

    if (name.isEmpty || mrp.isEmpty || sellerPrice.isEmpty || quantity.isEmpty) {
      ToastComponent.showDialog("All fields are required",
          gravity: Toast.center, duration: Toast.lengthLong, isError: true);
      return;
    }

    var postBody =
        jsonEncode({"id": widget.id, "name": name, "mrp": mrp, "sellerprice": sellerPrice, "quantity": quantity});

    final response = await http.post(
      Uri.parse("${AppConfig.BASE_URL}/product/update"),
      headers: {"Content-Type": "application/json", "Authorization": "Bearer ${access_token.$}"},
      body: postBody,
    );

    var dataUser = json.decode(response.body);
    await _toggleIsActive();

    if (dataUser['status'] == "success") {
      fetchAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    ToastContext().init(context);
    return Scaffold(
      key: _scaffoldKey,
      drawer: MainDrawer(),
      backgroundColor: Colors.white,
      appBar: buildAppBar(context),
      body: _isLoading
          ? Center(child: CircularProgressIndicator.adaptive())
          : _error != null
              ? Center(
                  child: Text("Error: $_error"),
                )
              : buildBody(context),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: MyTheme.dark_grey),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        "Product Edit",
        style: TextStyle(color: MyTheme.font_grey, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      elevation: 0.0,
      backgroundColor: Colors.white,
    );
  }

  Widget buildBody(BuildContext context) {
    return RefreshIndicator(
      color: MyTheme.red,
      backgroundColor: Colors.white,
      onRefresh: fetchAll,
      child: CustomScrollView(
        controller: _mainScrollController,
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate([buildProfileForm(context)]),
          )
        ],
      ),
    );
  }

  Widget buildProfileForm(BuildContext context) {
    return Padding(
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
          buildTextField("MRP", _mrpController, "Enter product MRP"),
          buildTextField("Product Price", _sellerPriceController, "Enter product price"),
          buildTextField("Product Quantity", _quantityConfirmController, "Enter product quantity"),
          buildCheckbox("Product Published", _isActive, (newValue) {
            setState(() {
              _isActive = newValue;
            });
          }),
          buildUpdateButton(context),
        ],
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: MyTheme.red, fontWeight: FontWeight.w600)),
          SizedBox(height: 4.0),
          Container(
            height: 36,
            child: TextField(
              controller: controller,
              autofocus: false,
              decoration: InputDecorations.buildInputDecoration_1(hintText: hint),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCheckbox(String label, bool? value, ValueChanged<bool?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: CheckboxListTile(
        title: Text(label),
        value: value,
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  Widget buildUpdateButton(BuildContext context) {
    return MaterialButton(
      minWidth: MediaQuery.of(context).size.width,
      height: 50,
      color: MyTheme.red,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8.0))),
      child: Text(
        "Update",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      onPressed: _onPressUpdate,
    );
  }
}
