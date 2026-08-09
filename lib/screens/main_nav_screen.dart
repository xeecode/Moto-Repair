import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'inventory_screen.dart';
import 'billing_screen.dart';
import 'reports_screen.dart';
import 'more_screen.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _index = 0;

  Widget _currentTab() {
    switch (_index) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const InventoryScreen();
      case 2:
        return const BillingScreen();
      case 3:
        return const ReportsScreen();
      case 4:
      default:
        return const MoreScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Rebuilding the tab fresh each time (instead of IndexedStack) ensures
      // every screen's initState/data-load runs again whenever you switch to
      // it - so newly added/cleared data always shows up immediately.
      body: _currentTab(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard'),
          NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Inventory'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Billing'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Reports'),
          NavigationDestination(
              icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}
