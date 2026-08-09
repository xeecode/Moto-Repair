import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/bill.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import '../services/settings_service.dart';
import 'billing_screen.dart';
import 'add_product_screen.dart';
import 'bill_detail_screen.dart';
import 'bill_history_screen.dart';
import 'inventory_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _totalProducts = 0;
  double _inventoryValue = 0;
  double _todaySales = 0;
  List<Product> _lowStock = [];
  List<Bill> _recentBills = [];
  ShopSettings _settings = ShopSettings();
  final _dateFmt = DateFormat('dd MMM, hh:mm a');
  late NumberFormat _currency;

  @override
  void initState() {
    super.initState();
    _currency = NumberFormat.currency(locale: 'en_PK', symbol: 'Rs. ');
    _loadStats();
  }

  Future<void> _loadStats() async {
    final settings = await SettingsService.load();
    final products = await DBHelper.instance.getTotalProductsCount();
    final value = await DBHelper.instance.getInventoryValue();
    final sales = await DBHelper.instance.getTodaySales();
    final lowStock = await DBHelper.instance
        .getLowStockProducts(threshold: settings.lowStockThreshold);
    final bills = await DBHelper.instance.getAllBills();
    setState(() {
      _settings = settings;
      _currency =
          NumberFormat.currency(locale: 'en_PK', symbol: settings.currencySymbol);
      _totalProducts = products;
      _inventoryValue = value;
      _todaySales = sales;
      _lowStock = lowStock;
      _recentBills = bills.take(4).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              expandedHeight: 128,
              pinned: true,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: 'Settings',
                  onPressed: () async {
                    final changed = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                    if (changed == true) _loadStats();
                  },
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16, right: 56),
                title: Text(_settings.shopName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.primaryLight],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick actions
                    Row(
                      children: [
                        Expanded(
                          child: _quickAction(
                            icon: Icons.point_of_sale,
                            label: 'New Bill',
                            color: AppColors.accent,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const BillingScreen()),
                            ).then((_) => _loadStats()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _quickAction(
                            icon: Icons.add_box_outlined,
                            label: 'Add Part',
                            color: AppColors.primary,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AddProductScreen()),
                            ).then((_) => _loadStats()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Stat cards
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _statCard('Total Parts', '$_totalProducts',
                            Icons.inventory_2, AppColors.primary),
                        _statCard('Inventory Value',
                            _currency.format(_inventoryValue),
                            Icons.account_balance_wallet, AppColors.success),
                        _statCard('Today Sales', _currency.format(_todaySales),
                            Icons.trending_up, AppColors.accent),
                        _statCard('Low Stock', '${_lowStock.length}',
                            Icons.warning_amber_rounded, AppColors.danger),
                      ],
                    ),

                    if (_lowStock.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _lowStockBanner(),
                    ],

                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Recent Bills',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const BillHistoryScreen()),
                          ),
                          child: const Text('View all'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (_recentBills.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text('No bills yet. Create your first bill!',
                            style: TextStyle(color: Colors.grey.shade600)),
                      )
                    else
                      ..._recentBills.map((bill) => _recentBillTile(bill)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
              overflow: TextOverflow.ellipsis),
          Text(title,
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _lowStockBanner() {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const InventoryScreen()),
      ).then((_) => _loadStats()),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.danger.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.danger.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${_lowStock.length} part${_lowStock.length > 1 ? 's are' : ' is'} running low on stock',
                style: const TextStyle(
                    color: AppColors.danger, fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.danger),
          ],
        ),
      ),
    );
  }

  Widget _recentBillTile(Bill bill) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: const Icon(Icons.receipt, color: AppColors.primary, size: 20),
        ),
        title: Text(bill.customerName,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(_dateFmt.format(bill.createdAt)),
        trailing: Text(_currency.format(bill.grandTotal),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BillDetailScreen(bill: bill)),
        ),
      ),
    );
  }
}
