import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/product.dart';
import 'add_product_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Product> _products = [];
  final _currency = NumberFormat.currency(locale: 'en_PK', symbol: 'Rs. ');
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products = await DBHelper.instance.getAllProducts();
    setState(() => _products = products);
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      _loadProducts();
      return;
    }
    final products = await DBHelper.instance.searchProducts(query);
    setState(() => _products = products);
  }

  Future<void> _deleteProduct(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Part'),
        content: Text('Delete "${product.name}" from inventory?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true && product.id != null) {
      await DBHelper.instance.deleteProduct(product.id!);
      _loadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory / Spare Parts')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search part by name or category...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _search,
            ),
          ),
          Expanded(
            child: _products.isEmpty
                ? const Center(
                    child: Text('No parts in inventory yet.\nTap + to add.',
                        textAlign: TextAlign.center))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _products.length,
                    itemBuilder: (ctx, i) {
                      final p = _products[i];
                      final lowStock = p.quantity <= 5;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(8),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: p.imagePath != null &&
                                    File(p.imagePath!).existsSync()
                                ? Image.file(File(p.imagePath!),
                                    width: 55, height: 55, fit: BoxFit.cover)
                                : Container(
                                    width: 55,
                                    height: 55,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.settings,
                                        color: Colors.grey),
                                  ),
                          ),
                          title: Text(p.name,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              '${p.category}\nPrice: ${_currency.format(p.salePrice)}  |  Stock: ${p.quantity}',
                              style: TextStyle(
                                  color: lowStock ? Colors.red : Colors.black87)),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          AddProductScreen(product: p)),
                                ).then((_) => _loadProducts());
                              } else if (value == 'delete') {
                                _deleteProduct(p);
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                  value: 'edit', child: Text('Edit')),
                              const PopupMenuItem(
                                  value: 'delete', child: Text('Delete')),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddProductScreen()),
          ).then((_) => _loadProducts());
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Part'),
      ),
    );
  }
}
