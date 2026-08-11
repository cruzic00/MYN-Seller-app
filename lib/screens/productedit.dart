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

  /// MongoDB `_id` of the stocklist entry, used by the MYN online-shop API.
  final String? mongo_id;
  final bool showBackButton;

  ProductEdit(
      {Key? key, this.id, this.mongo_id, this.showBackButton = false})
      : super(key: key);

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

  /// Raw product document from the API. Kept so the variant list can be sent
  /// back on save with only the edited fields changed.
  Map<String, dynamic>? _product;

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
      final productId = widget.mongo_id;
      if (productId == null || productId.isEmpty) {
        throw Exception('This product has no MongoDB id');
      }

      final product = await ProductRepository().getMynProduct(productId);

      // Prices live on the first variant ("Plate", "500g", ...); the top-level
      // appPrice/mrp stay at 0 for these items.
      final variants = (product["variants"] as List?) ?? const [];
      final Map<String, dynamic> v0 = variants.isNotEmpty
          ? Map<String, dynamic>.from(variants.first as Map)
          : <String, dynamic>{};

      String num2str(dynamic v) {
        final n = v is num ? v : num.tryParse(v?.toString() ?? "");
        return n == null ? "" : n.toString();
      }

      setState(() {
        _product = product;
        _nameController.text =
            (product["productName"] ?? product["foodName"] ?? "").toString();
        _mrpController.text = num2str(v0["mrp"] ?? v0["compare_at_price"]);
        _sellerPriceController.text =
            num2str(v0["appPrice"] ?? v0["base_price"]);
        _quantityConfirmController.text =
            num2str(product["stock"] ?? v0["stock"] ?? 0);
        _isActive =
            product["status"]?.toString().toLowerCase() != "inactive";
      });
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

  /// Status is sent as part of the single PATCH in [_onPressUpdate]; the API
  /// stores it as the capitalised strings "Active" / "Inactive".
  String get _statusValue => (_isActive ?? true) ? "Active" : "Inactive";

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

    final productId = widget.mongo_id;
    if (productId == null || productId.isEmpty) {
      ToastComponent.showDialog("This product has no MongoDB id",
          gravity: Toast.center, duration: Toast.lengthLong, isError: true);
      return;
    }

    // Send the full variant list back with only the first variant's prices
    // changed, so fields the app does not edit (unit, tax, commission) survive.
    final variants = ((_product?["variants"] as List?) ?? const [])
        .map((v) => Map<String, dynamic>.from(v as Map))
        .toList();

    if (variants.isEmpty) {
      variants.add(<String, dynamic>{"unit": "Unit"});
    }

    variants[0]["appPrice"] = num.tryParse(sellerPrice) ?? 0;
    variants[0]["base_price"] = num.tryParse(sellerPrice) ?? 0;
    variants[0]["mrp"] = num.tryParse(mrp) ?? 0;
    variants[0]["compare_at_price"] = num.tryParse(mrp) ?? 0;
    variants[0]["stock"] = num.tryParse(quantity) ?? 0;

    final ok = await ProductRepository().updateMynProduct(productId, {
      "productName": name,
      "status": _statusValue,
      "stock": num.tryParse(quantity) ?? 0,
      "variants": variants,
    });

    if (ok) {
      ToastComponent.showDialog("Product updated",
          gravity: Toast.center, duration: Toast.lengthLong);
      fetchAll();
    } else {
      ToastComponent.showDialog("Could not update product",
          gravity: Toast.center, duration: Toast.lengthLong, isError: true);
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
              decoration: InputDecorations.buildInputDecoration_1(hint_text: hint),
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
