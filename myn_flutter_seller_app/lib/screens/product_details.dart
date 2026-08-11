import 'dart:async';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:myn_seller_app/app_config.dart';
import 'package:myn_seller_app/app_localizations.dart';
import 'package:myn_seller_app/custom/toast_component.dart';
import 'package:myn_seller_app/helpers/color_helper.dart';
import 'package:myn_seller_app/helpers/shared_value_helper.dart';
import 'package:myn_seller_app/my_theme.dart';
import 'package:myn_seller_app/repositories/product_repository.dart';
import 'package:myn_seller_app/screens/productedit.dart';
import 'package:myn_seller_app/ui_elements/list_product_card.dart';
import 'package:photo_view/photo_view.dart';
import 'package:toast/toast.dart';

class ProductDetails extends StatefulWidget {
  final int? id;

  ProductDetails({Key? key, this.id}) : super(key: key);

  @override
  _ProductDetailsState createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  bool _showCopied = false;
  String? _appbarPriceString = ". . .";
  int _currentImage = 0;
  ScrollController _mainScrollController = ScrollController();
  ScrollController _colorScrollController = ScrollController();
  ScrollController _variantScrollController = ScrollController();
  ScrollController _imageScrollController = ScrollController();
  TextEditingController sellerChatTitleController = TextEditingController();
  TextEditingController sellerChatMessageController = TextEditingController();

  //init values
  bool _isInWishList = false;
  var _productDetailsFetched = false;
  dynamic _productDetails = null;
  var _productImageList = [];
  var _colorList = [];
  int _selectedColorIndex = 0;
  var _selectedChoices = [];
  var _choiceString = "";
  String? _variant = "";
  var _totalPrice;
  var _singlePrice;
  var _singlePriceString;
  int? _quantity = 1;
  int? _stock = 0;

  List<dynamic> _relatedProducts = [];
  bool _relatedProductInit = false;
  List<dynamic> _topProducts = [];
  bool _topProductInit = false;

  @override
  void initState() {
    fetchAll();
    super.initState();
  }

  @override
  void dispose() {
    _mainScrollController.dispose();
    _variantScrollController.dispose();
    _imageScrollController.dispose();
    _colorScrollController.dispose();
    super.dispose();
  }

  fetchAll() {
    print("product id : ${widget.id}");
    fetchProductDetails();
    fetchRelatedProducts();
    fetchTopProducts();
  }

  fetchProductDetails() async {
    var productDetailsResponse =
        await ProductRepository().getProductDetails(id: widget.id);

    if (productDetailsResponse.detailed_products!.length > 0) {
      _productDetails = productDetailsResponse.detailed_products![0];
      sellerChatTitleController.text =
          productDetailsResponse.detailed_products![0].name!;
    }

    setProductDetailValues();

    setState(() {});
  }

  fetchRelatedProducts() async {
    var relatedProductResponse =
        await ProductRepository().getRelatedProducts(id: widget.id);

    setState(() {
      _relatedProducts.addAll(relatedProductResponse.products!);
      _relatedProductInit = true;
    });
  }

  fetchTopProducts() async {
    var topProductResponse =
        await ProductRepository().getTopFromThisSellerProducts(id: widget.id);

    setState(() {
      _topProducts.addAll(topProductResponse.products!);
      _topProductInit = true;
    });
  }

  setProductDetailValues() {
    if (_productDetails != null) {
      _appbarPriceString = _productDetails.price_high_low;
      _singlePrice = _productDetails.calculable_price;
      _singlePriceString = _productDetails.main_price;
      calculateTotalPrice();
      _stock = _productDetails.current_stock;
      _productDetails.photos.forEach((photo) {
        _productImageList.add(photo.path);
      });

      _productDetails.choice_options.forEach((choice_opiton) {
        _selectedChoices.add(choice_opiton.options[0]);
      });
      _productDetails.colors.forEach((color) {
        _colorList.add(color);
      });

      setChoiceString();

      if (_productDetails.colors.length > 0 ||
          _productDetails.choice_options.length > 0) {
        fetchAndSetVariantWiseInfo(change_appbar_string: true);
      }
      _productDetailsFetched = true;

      setState(() {});
    }
  }

  setChoiceString() {
    _choiceString = _selectedChoices.join(",").toString();
    //print(_choiceString);
    setState(() {});
  }

  fetchAndSetVariantWiseInfo({bool change_appbar_string = true}) async {
    var color_string = _colorList.length > 0
        ? _colorList[_selectedColorIndex].toString().replaceAll("#", "")
        : "";

    /*print("color string: "+color_string);
    return;*/

    var variantResponse = await ProductRepository().getVariantWiseInfo(
        id: widget.id, color: color_string, variants: _choiceString);

    /*print("vr"+variantResponse.toJson().toString());
    return;*/

    _singlePrice = variantResponse.price;
    _stock = variantResponse.stock;
    if (_quantity! > _stock!) {
      _quantity = _stock;
      setState(() {});
    }

    _variant = variantResponse.variant;
    setState(() {});

    calculateTotalPrice();
    _singlePriceString = variantResponse.price_string;

    if (change_appbar_string) {
      _appbarPriceString = "${variantResponse.variant} ${_singlePriceString}";
    }

    int pindex = 0;
    _productDetails.photos.forEach((photo) {
      if (photo.variant == _variant && variantResponse.image != "") {
        _currentImage = pindex;
      }

      pindex++;
    });

    setState(() {});
  }

  reset() {
    restProductDetailValues();
    _productImageList.clear();
    _colorList.clear();
    _selectedChoices.clear();
    _relatedProducts.clear();
    _topProducts.clear();
    _choiceString = "";
    _variant = "";
    _selectedColorIndex = 0;
    _quantity = 1;
    _productDetailsFetched = false;
    _isInWishList = false;
    sellerChatTitleController.clear();
    setState(() {});
  }

  restProductDetailValues() {
    setState(() {
      _appbarPriceString = " . . .";
      _productDetails = null;
      _productImageList.clear();
      _currentImage = 0;
    });
  }

  Future<void> _onPageRefresh() async {
    reset();
    fetchAll();
  }

  calculateTotalPrice() {
    setState(() {
      _totalPrice = _singlePrice * _quantity;
    });
  }

  _onVariantChange(_choice_options_index, value) {
    _selectedChoices[_choice_options_index] = value;
    setChoiceString();
    setState(() {});
    fetchAndSetVariantWiseInfo();
  }

  _onColorChange(index) {
    _selectedColorIndex = index;
    setState(() {});
    fetchAndSetVariantWiseInfo();
  }

  onPopped(value) async {
    reset();
    fetchAll();
  }

  onCopyTap(setState) {
    setState(() {
      _showCopied = true;
    });
    Timer timer = Timer(Duration(seconds: 3), () {
      setState(() {
        _showCopied = false;
      });
    });
  }

  onPressShare(context) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, StateSetter setState) {
            return AlertDialog(
              insetPadding: EdgeInsets.symmetric(horizontal: 10),
              contentPadding: EdgeInsets.only(
                  top: 36.0, left: 36.0, right: 36.0, bottom: 2.0),
              content: Container(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: TextButton(
                          style: TextButton.styleFrom(
                            minimumSize: new Size(75, 26),
                            backgroundColor: Color.fromRGBO(253, 253, 253, 1),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                side: BorderSide(
                                    color: Colors.black, width: 1.0)),
                          ),
                          child: Text(
                            "Copy Product Link",
                            style: TextStyle(
                              color: MyTheme.medium_grey,
                            ),
                          ),
                          onPressed: () {
                            onCopyTap(setState);
                          },
                        ),
                      ),
                      _showCopied
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                "Copied",
                                style: TextStyle(
                                    color: MyTheme.medium_grey, fontSize: 12),
                              ),
                            )
                          : Container(),
                    ],
                  ),
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Padding(
                      padding: app_language_rtl.$
                          ? EdgeInsets.only(left: 8.0)
                          : EdgeInsets.only(right: 8.0),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          minimumSize: new Size(75, 26),
                          backgroundColor: Color.fromRGBO(253, 253, 253, 1),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              side:
                                  BorderSide(color: Colors.black, width: 1.0)),
                        ),
                        child: Text(
                          "CLOSE",
                          style: TextStyle(
                            color: MyTheme.font_grey,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context, rootNavigator: true).pop();
                        },
                      ),
                    ),
                  ],
                )
              ],
            );
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: app_language_rtl.$ ? TextDirection.rtl : TextDirection.ltr,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: buildAppBar(context),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ProductEdit(id: widget.id)),
            ),
            label: Text(
              'Edit',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            icon: Icon(Icons.edit, color: Colors.white),
            backgroundColor: MyTheme.accent_color,
          ),
          body: _productDetails != null
              ? RefreshIndicator(
                  color: MyTheme.accent_color,
                  backgroundColor: Colors.white,
                  onRefresh: _onPageRefresh,
                  child: CustomScrollView(
                    controller: _mainScrollController,
                    physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics()),
                    slivers: <Widget>[
                      SliverList(
                        delegate: SliverChildListDelegate([
                          SizedBox(height: 10),
                          buildProductImageSection(),
                        ]),
                      ),
                      SliverList(
                        delegate: SliverChildListDelegate([
                          SizedBox(height: 30),
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _productDetails.name,
                                  style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                ),
                                SizedBox(width: 10),
                                MyCustomBadge(_productDetails.is_active),
                              ],
                            ),
                          )
                        ]),
                      ),
                      SliverList(
                        delegate: SliverChildListDelegate([
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                                16.0, 20.0, 16.0, 0.0),
                            child: buildMainPriceRow(),
                          )
                        ]),
                      ),
                      SliverList(
                        delegate:
                            SliverChildListDelegate([buildChoiceOptionList()]),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: buildColorRow()),
                      ),
                      SliverList(
                        delegate: SliverChildListDelegate([
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              "Description",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 16),
                              child: HtmlWidget(_productDetails.description)),
                          Divider(height: 1),
                          buildDescriptionLinks(),
                        ]),
                      ),
                    ],
                  ),
                )
              : Center(
                  child: CircularProgressIndicator(),
                ),
        ),
      ),
    );
  }

  Widget buildDescriptionLinks() {
    return Column(
      children: [
        InkWell(
          onTap: () {
            if (_productDetails.video_link == "") {
              ToastComponent.showDialog(
                  AppLocalizations.of(context)!
                      .product_details_screen_video_not_available,
                  gravity: Toast.center,
                  duration: Toast.lengthLong,
                  isError: true);
              return;
            }
            // Add video link navigation logic here (consider using a video player widget)
          },
          child: Container(
            height: 40,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0.0, 8.0, 0.0),
              child: Row(
                children: [
                  Text(
                    AppLocalizations.of(context)!.product_details_screen_video,
                    style: TextStyle(
                        color: MyTheme.font_grey,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                  Spacer(),
                  Icon(
                    Icons.add,
                    color: MyTheme.font_grey,
                    size: 24,
                  )
                ],
              ),
            ),
          ),
        ),
        Divider(height: 1),
        InkWell(
          onTap: () {
            // Add navigation logic to ProductReviews screen (consider passing product ID)
          },
          child: Container(
            height: 40,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0.0, 8.0, 0.0),
              child: Row(
                children: [
                  Text(
                    AppLocalizations.of(context)!
                        .product_details_screen_reviews,
                    style: TextStyle(
                        color: MyTheme.font_grey,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                  Spacer(),
                  Icon(
                    Icons.add,
                    color: MyTheme.font_grey,
                    size: 24,
                  )
                ],
              ),
            ),
          ),
        ),
        Divider(height: 1),
        InkWell(
          onTap: () {
            // Add navigation logic to CommonWebviewScreen for seller policy
          },
          child: Container(
            height: 40,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0.0, 8.0, 0.0),
              child: Row(
                children: [
                  Text(
                    AppLocalizations.of(context)!
                        .product_details_screen_seller_policy,
                    style: TextStyle(
                        color: MyTheme.font_grey,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                  Spacer(),
                  Icon(
                    Icons.add,
                    color: MyTheme.font_grey,
                    size: 24,
                  )
                ],
              ),
            ),
          ),
        ),
        Divider(height: 1),
        InkWell(
          onTap: () {
            // Add navigation logic to CommonWebviewScreen for return policy
          },
          child: Container(
            height: 40,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0.0, 8.0, 0.0),
              child: Row(
                children: [
                  Text(
                    AppLocalizations.of(context)!
                        .product_details_screen_return_policy,
                    style: TextStyle(
                        color: MyTheme.font_grey,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                  Spacer(),
                  Icon(
                    Icons.add,
                    color: MyTheme.font_grey,
                    size: 24,
                  )
                ],
              ),
            ),
          ),
        ),
        Divider(height: 1),
        InkWell(
          onTap: () {
            // Add navigation logic to CommonWebviewScreen for support policy
          },
          child: Container(
            height: 40,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0.0, 8.0, 0.0),
              child: Row(
                children: [
                  Text(
                    AppLocalizations.of(context)!
                        .product_details_screen_support_policy,
                    style: TextStyle(
                        color: MyTheme.font_grey,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                  Spacer(),
                  Icon(
                    Icons.add,
                    color: MyTheme.font_grey,
                    size: 24,
                  )
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  buildChoiceOptionList() {
    return ListView.builder(
      itemCount: _productDetails.choice_options.length,
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: buildChoiceOpiton(_productDetails.choice_options, index),
        );
      },
    );
  }

  buildChoiceOpiton(choice_options, choice_options_index) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16.0,
        8.0,
        16.0,
        0.0,
      ),
      child: Row(
        children: [
          Padding(
            padding: app_language_rtl.$
                ? EdgeInsets.only(left: 8.0)
                : EdgeInsets.only(right: 8.0),
            child: Container(
              width: 75,
              child: Text(
                choice_options[choice_options_index].title,
                style: TextStyle(color: Color.fromRGBO(153, 153, 153, 1)),
              ),
            ),
          ),
          Container(
            height: 40,
            width: MediaQuery.of(context).size.width - (75 + 40),
            child: Scrollbar(
              controller: _variantScrollController,
              thumbVisibility: false,
              child: ListView.builder(
                itemCount: choice_options[choice_options_index].options.length,
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: buildChoiceItem(
                        choice_options[choice_options_index].options[index],
                        choice_options_index,
                        index),
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }

  buildChoiceItem(option, choice_options_index, index) {
    return Padding(
      padding: app_language_rtl.$
          ? EdgeInsets.only(left: 8.0)
          : EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () {
          _onVariantChange(choice_options_index, option);
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
                color: _selectedChoices[choice_options_index] == option
                    ? MyTheme.accent_color
                    : Color.fromRGBO(224, 224, 225, 1),
                width: 1.5),
            borderRadius: BorderRadius.circular(3.0),
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 3.0),
            child: Center(
              child: Text(
                option,
                style: TextStyle(
                    color: _selectedChoices[choice_options_index] == option
                        ? MyTheme.accent_color
                        : Color.fromRGBO(224, 224, 225, 1),
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }

  buildColorRow() {
    return _colorList.length != 0
        ? Row(
            children: [
              Padding(
                padding: app_language_rtl.$
                    ? EdgeInsets.only(left: 8.0)
                    : EdgeInsets.only(right: 8.0),
                child: Container(
                  width: 75,
                  child: Text(
                    AppLocalizations.of(context)!.product_details_screen_color,
                    style: TextStyle(color: Color.fromRGBO(153, 153, 153, 1)),
                  ),
                ),
              ),
              Container(
                height: 40,
                width: MediaQuery.of(context).size.width - (75 + 40),
                child: Scrollbar(
                  controller: _colorScrollController,
                  thumbVisibility: false,
                  child: ListView.builder(
                    itemCount: _colorList.length,
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: buildColorItem(index),
                      );
                    },
                  ),
                ),
              )
            ],
          )
        : null;
  }

  buildColorItem(index) {
    return Padding(
      padding: app_language_rtl.$
          ? EdgeInsets.only(left: 8.0)
          : EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () {
          _onColorChange(index);
        },
        child: Container(
          height: 30,
          width: 30,
          decoration: BoxDecoration(
              border: Border.all(
                  color: _selectedColorIndex == index
                      ? Colors.purple
                      : Colors.white,
                  width: 1),
              borderRadius: BorderRadius.circular(16.0),
              color: Colors.white),
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: Container(
              height: 24,
              width: 24,
              decoration: BoxDecoration(
                  border: Border.all(
                      color: Color.fromRGBO(222, 222, 222, 1), width: 1),
                  borderRadius: BorderRadius.circular(16.0),
                  color: ColorHelper.getColorFromColorCode(_colorList[index])),
              child: _selectedColorIndex == index
                  ? buildColorCheckerContainer()
                  : Container(),
            ),
          ),
        ),
      ),
    );
  }

  buildColorCheckerContainer() {
    return Padding(
        padding: const EdgeInsets.all(3),
        child: /*Icon(FontAwesome.check, color: Colors.white, size: 16),*/
            Image.asset(
          "assets/white_tick.png",
          width: 16,
          height: 16,
        ));
  }

  Row buildMainPriceRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.only(right: 8.0),
          child: Text(
            "MRP",
            style: TextStyle(
                color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(right: 8.0),
          child: Text(_productDetails.stroked_price,
              style: TextStyle(
                  color: MyTheme.red,
                  fontSize: 18.0,
                  fontWeight: FontWeight.w600)),
        ),
        Padding(
          padding: EdgeInsets.only(right: 8.0),
          child: Text(
            "App Price:",
            style: TextStyle(
                color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Text(
          "₹${_productDetails.supplier_price}",
          style: TextStyle(
              color: MyTheme.accent_color,
              fontSize: 18.0,
              fontWeight: FontWeight.w600),
        )
      ],
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      surfaceTintColor: Colors.white,
      centerTitle: true,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.arrow_back, color: MyTheme.font_grey),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      title: Text(
        "Product Details",
        style: TextStyle(color: MyTheme.font_grey, fontWeight: FontWeight.bold),
      ),
      elevation: 0.0,
      titleSpacing: 0,
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.share_outlined, color: MyTheme.dark_grey),
          onPressed: () {
            onPressShare(context);
          },
        ),
      ],
    );
  }

  buildTopSellingProductList() {
    if (_topProducts.length > 0) {
      return SingleChildScrollView(
        child: ListView.builder(
          itemCount: _topProducts.length,
          scrollDirection: Axis.vertical,
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 3.0),
              child: ListProductCard(
                  id: _topProducts[index].id,
                  image: _topProducts[index].thumbnail_image,
                  name: _topProducts[index].name,
                  main_price: _topProducts[index].main_price,
                  stroked_price: _topProducts[index].stroked_price,
                  has_discount: _topProducts[index].has_discount),
            );
          },
        ),
      );
    } else {
      return Container(
          height: 100,
          child: Center(
              child: Text(
                  AppLocalizations.of(context)!
                      .product_details_screen_no_top_selling_product,
                  style: TextStyle(color: MyTheme.font_grey))));
    }
  }

  openPhotoDialog(BuildContext context, path) => showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            child: Container(
                child: Stack(
              children: [
                PhotoView(
                  enableRotation: true,
                  heroAttributes: const PhotoViewHeroAttributes(tag: "someTag"),
                  imageProvider: NetworkImage(path),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    decoration: ShapeDecoration(
                      color: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(25),
                          bottomRight: Radius.circular(25),
                          topRight: Radius.circular(25),
                          topLeft: Radius.circular(25),
                        ),
                      ),
                    ),
                    width: 40,
                    height: 40,
                    child: IconButton(
                      icon: Icon(Icons.clear, color: MyTheme.white),
                      onPressed: () {
                        Navigator.of(context, rootNavigator: true).pop();
                      },
                    ),
                  ),
                ),
              ],
            )),
          );
        },
      );

  buildProductImageSection() {
    if (_productImageList.length != 0) {
      return InkWell(
          onTap: () {
            openPhotoDialog(context,
                AppConfig.BASE_PATH + _productImageList[_currentImage]);
          },
          child: Column(
            children: [
              CarouselSlider(
                options: CarouselOptions(
                  height: MediaQuery.of(context).size.height * 0.4,
                  aspectRatio: 16 / 9,
                  viewportFraction: 1.0,
                  initialPage: 0,
                  enableInfiniteScroll: true,
                  reverse: false,
                  autoPlay: true,
                  autoPlayInterval: Duration(seconds: 3),
                  autoPlayAnimationDuration: Duration(milliseconds: 800),
                  autoPlayCurve: Curves.fastOutSlowIn,
                  enlargeCenterPage: true,
                  onPageChanged: (index, reason) {
                    setState(() {
                      _currentImage = index;
                    });
                  },
                  scrollDirection: Axis.horizontal,
                ),
                items: _productImageList.map((url) {
                  return Builder(
                    builder: (BuildContext context) {
                      return Container(
                        width: MediaQuery.of(context).size.width,
                        margin: EdgeInsets.symmetric(horizontal: 10.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: FadeInImage.assetNetwork(
                            placeholder: 'assets/placeholder_rectangle.png',
                            image: url != null
                                ? AppConfig.BASE_IMAGE_PATH + url
                                : 'https://developers.elementor.com/path/to/placeholder.png',
                            fit: BoxFit.cover,
                            placeholderErrorBuilder: (context, _, stacktrace) =>
                                Container(
                              child: Image.asset(
                                'assets/placeholder.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                            imageErrorBuilder: (context, _, stacktrace) =>
                                Container(
                              child: Image.asset('assets/placeholder.png',
                                  fit: BoxFit.fill),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _productImageList.map((url) {
                  int index = _productImageList.indexOf(url);
                  return Container(
                    width: 8.0,
                    height: 8.0,
                    margin:
                        EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentImage == index
                          ? Color.fromRGBO(0, 0, 0, 0.9)
                          : Color.fromRGBO(0, 0, 0, 0.4),
                    ),
                  );
                }).toList(),
              ),
            ],
          ));
    }
  }
}

//  Badge your code snippet
MyCustomBadge(bool is_active) {
  return is_active
      ? Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Active',
            style: TextStyle(
              color: Color.fromARGB(255, 232, 252, 232),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        )
      : Container(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Inactive',
            style: TextStyle(
              color: Color.fromARGB(255, 248, 218, 218),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
}
