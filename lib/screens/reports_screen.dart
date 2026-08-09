import '../theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _currency = NumberFormat.currency(locale: 'en_PK', symbol: 'Rs. ');
  Map<String, double> _summary = {};
  List<Map<String, dynamic>> _bestSelling = [];
  List<Map<String, dynamic>> _monthlyRevenue = [];
  String _range = 'All Time';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    DateTime? from;
    DateTime? to;
    final now = DateTime.now();
    if (_range == 'This Month') {
      from = DateTime(now.year, now.month, 1);
      to = now;
    } else if (_range == 'This Week') {
      from = now.subtract(Duration(days: now.weekday - 1));
      to = now;
    }

    final summary = await DBHelper.instance.getProfitSummary(from: from, to: to);
    final best = await DBHelper.instance.getBestSellingParts(limit: 8);
    final monthly = await DBHelper.instance.getMonthlyRevenue(months: 6);

    setState(() {
      _summary = summary;
      _bestSelling = best;
      _monthlyRevenue = monthly.reversed.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final revenue = _summary['revenue'] ?? 0;
    final cogs = _summary['cogs'] ?? 0;
    final grossProfit = _summary['grossProfit'] ?? 0;
    final expenses = _summary['expenses'] ?? 0;
    final netProfit = _summary['netProfit'] ?? 0;

    final maxMonthly = _monthlyRevenue.isEmpty
        ? 1.0
        : _monthlyRevenue
            .map((m) => (m['total'] as num?)?.toDouble() ?? 0)
            .reduce((a, b) => a > b ? a : b);

    final maxSelling = _bestSelling.isEmpty
        ? 1
        : (_bestSelling.first['totalQty'] as num).toInt();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          PopupMenuButton<String>(
            initialValue: _range,
            onSelected: (v) {
              setState(() => _range = v);
              _load();
            },
            itemBuilder: (ctx) => ['All Time', 'This Month', 'This Week']
                .map((r) => PopupMenuItem(value: r, child: Text(r)))
                .toList(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(children: [Text(_range), const Icon(Icons.arrow_drop_down)]),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Profit & Loss',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _summaryRow('Revenue (Sales)', revenue, Colors.blue),
          _summaryRow('Cost of Parts Sold', -cogs, Colors.orange),
          _divider(),
          _summaryRow('Gross Profit', grossProfit, Colors.green, bold: true),
          _summaryRow('Shop Expenses', -expenses, Colors.red),
          _divider(),
          _summaryRow('Net Profit', netProfit, netProfit >= 0 ? Colors.green : Colors.red,
              bold: true, big: true),
          const SizedBox(height: 28),
          const Text('Monthly Revenue (last 6 months)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (_monthlyRevenue.isEmpty)
            const Text('No sales data yet.')
          else
            ..._monthlyRevenue.map((m) {
              final total = (m['total'] as num?)?.toDouble() ?? 0;
              final month = m['month'] as String;
              final ratio = maxMonthly == 0 ? 0.0 : total / maxMonthly;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(month),
                        Text(_currency.format(total),
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: ratio.clamp(0, 1),
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade200,
                        valueColor:
                            const AlwaysStoppedAnimation(AppColors.accent),
                      ),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 28),
          const Text('Best Selling Parts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (_bestSelling.isEmpty)
            const Text('No sales data yet.')
          else
            ..._bestSelling.asMap().entries.map((entry) {
              final i = entry.key;
              final row = entry.value;
              final qty = (row['totalQty'] as num).toInt();
              final revenue = (row['totalRevenue'] as num?)?.toDouble() ?? 0;
              final ratio = maxSelling == 0 ? 0.0 : qty / maxSelling;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text('${i + 1}. ${row['productName']}',
                              overflow: TextOverflow.ellipsis),
                        ),
                        Text('$qty sold',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: ratio.clamp(0, 1),
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation(Colors.blue),
                      ),
                    ),
                    Text(_currency.format(revenue),
                        style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(height: 24);

  Widget _summaryRow(String label, double value, Color color,
      {bool bold = false, bool big = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  fontSize: big ? 17 : 14)),
          Text(
            (value < 0 ? '- ' : '') + _currency.format(value.abs()),
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: big ? 17 : 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
