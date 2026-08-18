import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myn_seller_app/data_model/myn_product_response.dart';
import 'package:myn_seller_app/my_theme.dart';
import 'package:myn_seller_app/myn_palette.dart';
import 'package:myn_seller_app/repositories/myn_product_repository.dart';
import 'package:myn_seller_app/ui_elements/skeleton.dart';

/// One stocklist item, read from the MYN API.
///
/// Replaces the legacy ProductDetails screen for MYN rows: that one fetched
/// four Laravel endpoints (details, related, top-from-seller, variant info),
/// none of which exist here, and none of its calls were guarded — so the first
/// failure left the screen spinning forever with nothing on it.
class MynProductDetail extends StatefulWidget {
  final String productId;
  final String? fallbackName;

  const MynProductDetail({Key? key, required this.productId, this.fallbackName})
      : super(key: key);

  @override
  State<MynProductDetail> createState() => _MynProductDetailState();
}

class _MynProductDetailState extends State<MynProductDetail> {
  bool _loading = true;
  String? _error;
  MynProduct? _product;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final p = await MynProductRepository().getProduct(widget.productId);
      if (!mounted) return;
      setState(() {
        _product = p;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      // Every failure lands somewhere the seller can see and retry from,
      // instead of an endless spinner.
      setState(() {
        _error = e.toString().replaceFirst("Exception: ", "");
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MynPalette.surface,
      appBar: AppBar(
        titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: MynPalette.onYellow),
        title: Text(_product?.name.isNotEmpty == true
            ? _product!.name
            : (widget.fallbackName ?? "Product")),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: MynPalette.brandYellow,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: MynPalette.onYellow),
      ),
      body: RefreshIndicator(
        color: MyTheme.accent_color,
        onRefresh: _fetch,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) return _buildError();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        _buildImage(),
        const SizedBox(height: 16),
        _buildHeaderCard(),
        const SizedBox(height: 14),
        _buildVariantsCard(),
        if (_loading || (_product?.description.isNotEmpty ?? false)) ...[
          const SizedBox(height: 14),
          _buildDescriptionCard(),
        ],
      ],
    );
  }

  Widget _buildError() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 90, 28, 28),
      children: [
        Icon(Icons.error_outline_rounded, size: 48, color: MynPalette.red),
        const SizedBox(height: 14),
        Text(
          "Couldn't load this product",
          textAlign: TextAlign.center,
          style: TextStyle(
              color: MynPalette.heading,
              fontSize: 16,
              fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          _error!,
          textAlign: TextAlign.center,
          style: TextStyle(color: MynPalette.muted, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 20),
        Center(
          child: ElevatedButton.icon(
            onPressed: _fetch,
            icon: Icon(Icons.refresh_rounded, size: 18),
            label: Text("Try again"),
            style: ElevatedButton.styleFrom(
              backgroundColor: MyTheme.accent_color,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImage() {
    final url = _product?.imageUrl ?? "";

    return Container(
      height: 210,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MynPalette.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: _loading
          ? Center(child: Skeleton(width: 120, height: 120, radius: 16))
          : url.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.image_outlined,
                          size: 40, color: MynPalette.muted),
                      const SizedBox(height: 8),
                      Text("No picture yet",
                          style: TextStyle(
                              color: MynPalette.muted, fontSize: 12.5)),
                    ],
                  ),
                )
              : CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorWidget: (c, u, e) => Center(
                    child: Icon(Icons.broken_image_outlined,
                        size: 36, color: MynPalette.muted),
                  ),
                ),
    );
  }

  Widget _buildHeaderCard() {
    final p = _product;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: MynPalette.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_loading)
            Skeleton(width: 180, height: 20)
          else
            Text(
              p!.name.isEmpty ? "Unnamed item" : p.name,
              style: TextStyle(
                  color: MynPalette.heading,
                  fontSize: 18,
                  fontWeight: FontWeight.w800),
            ),
          const SizedBox(height: 10),
          if (_loading)
            Skeleton(width: 120, height: 24, radius: 12)
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(p!.status.isEmpty ? "Unknown" : p.status,
                    MynPalette.statusColors(p.status)),
                if (p.category.isNotEmpty)
                  _chip(p.category, const [MynPalette.blue, MynPalette.blueTint]),
                if (p.subCategory.isNotEmpty && p.subCategory != p.category)
                  _chip(p.subCategory,
                      const [MynPalette.muted, Color(0xFFEDF2F3)]),
                if (p.brand.isNotEmpty)
                  _chip(p.brand, const [MynPalette.amber, MynPalette.amberTint]),
                if (p.foodType.isNotEmpty)
                  _chip(p.foodType,
                      const [MynPalette.green, MynPalette.greenTint]),
              ],
            ),
          if (!_loading && p!.imageStatus == "Pending") ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.hourglass_top_rounded,
                    size: 15, color: MynPalette.amber),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "Picture is waiting for MYN approval",
                    style:
                        TextStyle(color: MynPalette.muted, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, List<Color> colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors[1],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: colors[0], fontSize: 11.5, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildVariantsCard() {
    final variants = _product?.variants ?? const <MynProductVariant>[];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: MynPalette.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Pricing",
              style: TextStyle(
                  color: MynPalette.heading,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          if (_loading)
            for (int i = 0; i < 2; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: const [
                    Expanded(child: Skeleton(width: 90, height: 14)),
                    Skeleton(width: 70, height: 16),
                  ],
                ),
              )
          else if (variants.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text("No prices set for this item",
                  style: TextStyle(color: MynPalette.muted, fontSize: 13)),
            )
          else
            for (final v in variants) _buildVariantRow(v),
        ],
      ),
    );
  }

  Widget _buildVariantRow(MynProductVariant v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(v.unit,
                    style: TextStyle(
                        color: MynPalette.heading,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600)),
                if (v.taxRate > 0)
                  Text("Tax ${v.taxRate.toStringAsFixed(0)}%",
                      style: TextStyle(
                          color: MynPalette.muted, fontSize: 11.5)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                MynPalette.money(
                    v.offerActive && v.offerPrice > 0 ? v.offerPrice : v.price),
                style: TextStyle(
                    color: MynPalette.heading,
                    fontSize: 15,
                    fontWeight: FontWeight.w800),
              ),
              if (v.hasDiscount)
                Text(
                  MynPalette.money(v.compareAtPrice),
                  style: TextStyle(
                    color: MynPalette.muted,
                    fontSize: 11.5,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: MynPalette.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Description",
              style: TextStyle(
                  color: MynPalette.heading,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (_loading)
            Column(
              children: const [
                Skeleton(width: 260, height: 12),
                SizedBox(height: 8),
                Skeleton(width: 200, height: 12),
              ],
            )
          else
            Text(
              _product!.description,
              style: TextStyle(
                  color: MynPalette.muted, fontSize: 13.5, height: 1.45),
            ),
        ],
      ),
    );
  }
}
