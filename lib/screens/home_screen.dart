import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import 'inventory_screen.dart';
import 'billing_screen.dart';
import 'bill_history_screen.dart';
import 'purchases_screen.dart';
import 'vehicle_history_screen.dart';
import 'reports_screen.dart';
import 'expenses_screen.dart';
import 'backup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _totalProducts = 0;
  double _inventoryValue = 0;
  double _todaySales = 0;
  int _lowStockCount = 0;
  final _currency = NumberFormat.currency(locale: 'en_PK', symbol: 'Rs. ');

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final products = await DBHelper.instance.getTotalProductsCount();
    final value = await DBHelper.instance.getInventoryValue();
    final sales = await DBHelper.instance.getTodaySales();
    final lowStock = await DBHelper.instance.getLowStockProducts();
    setState(() {
      _totalProducts = products;
      _inventoryValue = value;
      _todaySales = sales;
      _lowStockCount = lowStock.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Motorcycle Shop Manager')),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _statCard('Total Parts', '$_totalProducts', Icons.inventory_2,
                    Colors.blue),
                _statCard('Inventory Value', _currency.format(_inventoryValue),
                    Icons.attach_money, Colors.green),
                _statCard('Today Sales', _currency.format(_todaySales),
                    Icons.point_of_sale, Colors.deepOrange),
                _statCard('Low Stock', '$_lowStockCount', Icons.warning,
                    Colors.red),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Menu',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _menuTile(
              context,
              icon: Icons.inventory,
              title: 'Inventory / Spare Parts',
              subtitle: 'Add, edit, view stock with images & prices',
              color: Colors.blue,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InventoryScreen()),
              ).then((_) => _loadStats()),
            ),
            _menuTile(
              context,
              icon: Icons.receipt_long,
              title: 'New Bill / Billing',
              subtitle: 'Create customer bill, stock auto-updates',
              color: Colors.deepOrange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BillingScreen()),
              ).then((_) => _loadStats()),
            ),
            _menuTile(
              context,
              icon: Icons.history,
              title: 'Bill History',
              subtitle: 'View all past customer bills',
              color: Colors.purple,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BillHistoryScreen()),
              ).then((_) => _loadStats()),
            ),
            _menuTile(
              context,
              icon: Icons.two_wheeler,
              title: 'Vehicle Service History',
              subtitle: 'Search bike number, see full repair history',
              color: Colors.teal,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VehicleHistoryScreen()),
              ),
            ),
            _menuTile(
              context,
              icon: Icons.local_shipping,
              title: 'Purchases / Stock-In',
              subtitle: 'Record stock from suppliers, manage suppliers',
              color: Colors.brown,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PurchasesScreen()),
              ).then((_) => _loadStats()),
            ),
            _menuTile(
              context,
              icon: Icons.money_off,
              title: 'Shop Expenses',
              subtitle: 'Track rent, salary, electricity & other costs',
              color: Colors.red,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExpensesScreen()),
              ),
            ),
            _menuTile(
              context,
              icon: Icons.bar_chart,
              title: 'Reports',
              subtitle: 'Profit/loss, best-selling parts, monthly trends',
              color: Colors.indigo,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportsScreen()),
              ),
            ),
            _menuTile(
              context,
              icon: Icons.backup,
              title: 'Backup & Restore',
              subtitle: 'Save or restore all your shop data',
              color: Colors.grey,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BackupScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color),
              overflow: TextOverflow.ellipsis),
          Text(title,
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _menuTile(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required Color color,
      required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          radius: 26,
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
