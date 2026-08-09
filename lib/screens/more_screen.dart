import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'bill_history_screen.dart';
import 'vehicle_history_screen.dart';
import 'purchases_screen.dart';
import 'suppliers_screen.dart';
import 'expenses_screen.dart';
import 'backup_screen.dart';
import 'settings_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_MoreItem>[
      _MoreItem(
        icon: Icons.history,
        title: 'Bill History',
        subtitle: 'View all past customer bills',
        color: AppColors.primary,
        builder: (_) => const BillHistoryScreen(),
      ),
      _MoreItem(
        icon: Icons.two_wheeler,
        title: 'Vehicle Service History',
        subtitle: 'Search bike number, see repair history',
        color: Colors.teal,
        builder: (_) => const VehicleHistoryScreen(),
      ),
      _MoreItem(
        icon: Icons.local_shipping_outlined,
        title: 'Purchases / Stock-In',
        subtitle: 'Record stock received from suppliers',
        color: Colors.brown,
        builder: (_) => const PurchasesScreen(),
      ),
      _MoreItem(
        icon: Icons.groups_outlined,
        title: 'Suppliers',
        subtitle: 'Manage your parts suppliers',
        color: Colors.indigo,
        builder: (_) => const SuppliersScreen(),
      ),
      _MoreItem(
        icon: Icons.money_off,
        title: 'Shop Expenses',
        subtitle: 'Rent, salary, electricity & other costs',
        color: AppColors.danger,
        builder: (_) => const ExpensesScreen(),
      ),
      _MoreItem(
        icon: Icons.backup_outlined,
        title: 'Backup & Restore',
        subtitle: 'Save or restore all your shop data',
        color: Colors.grey.shade700,
        builder: (_) => const BackupScreen(),
      ),
      _MoreItem(
        icon: Icons.settings_outlined,
        title: 'Settings',
        subtitle: 'Shop name, address & invoice customization',
        color: Colors.blueGrey,
        builder: (_) => const SettingsScreen(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) {
          final item = items[i];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(10),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: item.color),
              ),
              title: Text(item.title,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(item.subtitle,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: item.builder),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MoreItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final WidgetBuilder builder;

  _MoreItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.builder,
  });
}
