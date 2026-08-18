import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myn_seller_app/data_model/myn_order_response.dart';
import 'package:myn_seller_app/my_theme.dart';
import 'package:myn_seller_app/myn_palette.dart';
import 'package:myn_seller_app/repositories/order_repository.dart';
import 'package:myn_seller_app/screens/myn_order_detail.dart';
import 'package:myn_seller_app/ui_elements/skeleton.dart';

class _Period {
  final String label;
  final String? value;
  const _Period(this.label, this.value);
}

/// Business Orders, backed by GET /api/admin/orders — the same endpoint and
/// period filters the web Business Panel uses.
class MynOrders extends StatefulWidget {
  final bool show_back_button;

  MynOrders({this.show_back_button = false});

  @override
  _MynOrdersState createState() => _MynOrdersState();
}

class _MynOrdersState extends State<MynOrders> {
  static const List<_Period> _periods = [
    _Period("All", null),
    _Period("Today", "today"),
    _Period("Yesterday", "yesterday"),
    _Period("1 Week", "week"),
    _Period("1 Month", "month"),
    _Period("5 Months", "5month"),
    _Period("1 Year", "year"),
  ];

  int _periodIndex = 0;
  bool _loading = true;
  String? _error;
  MynOrderListResponse? _data;

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
      final res = await OrderRepository()
          .getMynOrders(period: _periods[_periodIndex].value);
      if (!mounted) return;
      setState(() {
        _data = res;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _selectPeriod(int i) {
    if (i == _periodIndex) return;
    setState(() => _periodIndex = i);
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MynPalette.surface,
      appBar: AppBar(
        titleTextStyle: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w700, color: MynPalette.onYellow),
        title: Text("Orders"),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: MynPalette.brandYellow,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        automaticallyImplyLeading: widget.show_back_button,
        iconTheme: IconThemeData(color: MynPalette.onYellow),
        actions: [
          IconButton(
            onPressed: _loading ? null : _fetch,
            icon: Icon(Icons.refresh_rounded, color: Colors.white),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: MyTheme.accent_color,
        backgroundColor: Colors.white,
        onRefresh: _fetch,
        child: CustomScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildPeriodBar()),
            if (_loading) ...[
              SliverToBoxAdapter(child: _buildTotalsSkeleton()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: const Skeleton(width: 84, height: 16),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => const OrderCardSkeleton(),
                  childCount: 4,
                ),
              ),
            ] else if (_data != null)
              SliverToBoxAdapter(child: _buildTotals(_data!)),
            if (_loading)
              SliverToBoxAdapter(child: SizedBox(height: 90))
            else if (_error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildError(),
              )
            else if ((_data?.orders.isEmpty ?? true))
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmpty(),
              )
            else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Text(
                    "${_data!.orders.length} order${_data!.orders.length == 1 ? '' : 's'}",
                    style: TextStyle(
                        color: MynPalette.heading,
                        fontSize: 16,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _buildOrderCard(_data!.orders[i]),
                  childCount: _data!.orders.length,
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 90)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodBar() {
    return Container(
      color: MyTheme.accent_color,
      padding: const EdgeInsets.only(bottom: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: List.generate(_periods.length, (i) {
            final selected = i == _periodIndex;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                color: selected
                    ? Colors.white
                    : Color.fromRGBO(255, 255, 255, 0.16),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _selectPeriod(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 9),
                    child: Text(
                      _periods[i].label,
                      style: TextStyle(
                        color:
                            selected ? MyTheme.accent_color : Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTotals(MynOrderListResponse d) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _totalTile("Total Paid", d.customerPaidTotal,
                    Icons.payments_rounded, MynPalette.blue, MynPalette.blueTint),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _totalTile("Total Tax", d.totals.totalGst,
                    Icons.receipt_rounded, MynPalette.amber, MynPalette.amberTint),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _totalTile("MYN Commission", d.totals.commission,
                    Icons.percent_rounded, MynPalette.red, MynPalette.redTint),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _totalTile("Net Earnings", d.totals.earnings,
                    Icons.savings_rounded, MynPalette.green, MynPalette.greenTint),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Same 2x2 grid as [_buildTotals] with the figures shimmering, so the header
  /// does not jump when the real numbers arrive.
  Widget _buildTotalsSkeleton() {
    Widget tile() => Container(
          padding: const EdgeInsets.all(14),
          decoration: MynPalette.card(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Row(
                children: [
                  Skeleton(width: 28, height: 28, radius: 14),
                  SizedBox(width: 8),
                  Expanded(child: Skeleton(width: 80, height: 12)),
                ],
              ),
              SizedBox(height: 12),
              Skeleton(width: 96, height: 19),
            ],
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          Row(children: [
            Expanded(child: tile()),
            const SizedBox(width: 12),
            Expanded(child: tile()),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: tile()),
            const SizedBox(width: 12),
            Expanded(child: tile()),
          ]),
        ],
      ),
    );
  }

  Widget _totalTile(
      String label, double value, IconData icon, Color color, Color tint) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: MynPalette.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 28,
                width: 28,
                decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
                child: Icon(icon, size: 15, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: MynPalette.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              MynPalette.money(value),
              style: TextStyle(
                  color: MynPalette.heading,
                  fontSize: 19,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(MynOrder o) {
    final colors = MynPalette.statusColors(o.status);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: MynPalette.card(),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return MynOrderDetail(orderMongoId: o.id, orderLabel: o.orderId);
              }));
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              o.orderId,
                              style: TextStyle(
                                  color: MynPalette.heading,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              o.customerName,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: MynPalette.muted, fontSize: 12.5),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: colors[1],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          o.status,
                          style: TextStyle(
                              color: colors[0],
                              fontSize: 11,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(height: 1, color: MynPalette.cardBorder),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _miniStat("Paid", MynPalette.money(o.customerPaid),
                          MynPalette.heading),
                      _miniStat("Tax", MynPalette.money(o.totalTax),
                          MynPalette.muted),
                      _miniStat("Earnings", MynPalette.money(o.earnings),
                          MynPalette.green),
                      Icon(Icons.chevron_right_rounded,
                          color: MynPalette.muted, size: 20),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(color: MynPalette.muted, fontSize: 11)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                  color: valueColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 54, color: MynPalette.muted),
          const SizedBox(height: 14),
          Text("No orders in this period",
              style: TextStyle(
                  color: MynPalette.heading,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text("Try a different date range.",
              textAlign: TextAlign.center,
              style: TextStyle(color: MynPalette.muted, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 48, color: MynPalette.red),
          const SizedBox(height: 14),
          Text("Couldn't load orders",
              style: TextStyle(
                  color: MynPalette.heading,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            _error ?? "",
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: MynPalette.muted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetch,
            style: ElevatedButton.styleFrom(
              backgroundColor: MyTheme.accent_color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text("Retry"),
          ),
        ],
      ),
    );
  }
}
