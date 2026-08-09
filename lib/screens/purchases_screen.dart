import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/product.dart';
import '../models/supplier.dart';
import '../models/purchase.dart';
import 'suppliers_screen.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  List<Purchase> _purchases = [];
  List<Product> _products = [];
  List<Supplier> _suppliers = [];
  final _currency = NumberFormat.currency(locale: 'en_PK', symbol: 'Rs. ');
  final _dateFmt = DateFormat('dd MMM yyyy, hh:mm a');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final purchases = await DBHelper.instance.getAllPurchases();
    final products = await DBHelper.instance.getAllProducts();
    final suppliers = await DBHelper.instance.getAllSuppliers();
    setState(() {
      _purchases = purchases;
      _products = products;
      _suppliers = suppliers;
    });
  }

  void _showAddPurchaseDialog() {
    Product? selectedProduct;
    Supplier? selectedSupplier;
    final qtyCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Record New Purchase (Stock-In)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<Product>(
                  value: selectedProduct,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Part *'),
                  items: _products
                      .map((p) => DropdownMenuItem(
                          value: p, child: Text(p.name, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedProduct = v),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<Supplier?>(
                  value: selectedSupplier,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Supplier (optional)'),
                  items: [
                    const DropdownMenuItem<Supplier?>(
                        value: null, child: Text('No supplier')),
                    ..._suppliers.map((s) =>
                        DropdownMenuItem<Supplier?>(value: s, child: Text(s.name))),
                  ],
                  onChanged: (v) => setDialogState(() => selectedSupplier = v),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantity Purchased *'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Unit Purchase Price *'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final qty = int.tryParse(qtyCtrl.text) ?? 0;
                final price = double.tryParse(priceCtrl.text) ?? 0;
                if (selectedProduct == null || qty <= 0 || price <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fill part, quantity and price')),
                  );
                  return;
                }
                await DBHelper.instance.createPurchase(Purchase(
                  supplierId: selectedSupplier?.id,
                  supplierName: selectedSupplier?.name ?? 'N/A',
                  productId: selectedProduct!.id!,
                  productName: selectedProduct!.name,
                  quantity: qty,
                  unitPrice: price,
                ));
                if (mounted) Navigator.pop(ctx);
                _load();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Stock added to inventory successfully!')),
                  );
                }
              },
              child: const Text('Save Purchase'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchases / Stock-In'),
        actions: [
          IconButton(
            icon: const Icon(Icons.local_shipping),
            tooltip: 'Manage Suppliers',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SuppliersScreen()),
              ).then((_) => _load());
            },
          ),
        ],
      ),
      body: _purchases.isEmpty
          ? const Center(
              child: Text('No purchases recorded yet.\nTap + to add stock.',
                  textAlign: TextAlign.center))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _purchases.length,
              itemBuilder: (ctx, i) {
                final p = _purchases[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Icon(Icons.add_box, color: Colors.white),
                    ),
                    title: Text(p.productName,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        'Supplier: ${p.supplierName}\nQty: ${p.quantity} x ${_currency.format(p.unitPrice)}\n${_dateFmt.format(p.purchaseDate)}'),
                    isThreeLine: true,
                    trailing: Text(_currency.format(p.totalCost),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _products.isEmpty
            ? () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add parts to inventory first!')))
            : _showAddPurchaseDialog,
        icon: const Icon(Icons.add),
        label: const Text('Record Purchase'),
      ),
    );
  }
}
