import '../theme/app_theme.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/product.dart';
import '../models/bill.dart';
import 'bill_detail_screen.dart';

class CartLine {
  Product product;
  int qty;
  CartLine({required this.product, this.qty = 1});
  double get total => product.salePrice * qty;
}

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  List<Product> _allProducts = [];
  List<Product> _filtered = [];
  final Map<int, CartLine> _cart = {}; // productId -> CartLine
  final _searchCtrl = TextEditingController();
  final _currency = NumberFormat.currency(locale: 'en_PK', symbol: 'Rs. ');

  final _customerNameCtrl = TextEditingController();
  final _customerPhoneCtrl = TextEditingController();
  final _vehicleNumberCtrl = TextEditingController();
  final _vehicleModelCtrl = TextEditingController();
  final _discountCtrl = TextEditingController(text: '0');
  final _labourCtrl = TextEditingController(text: '0');

  List<String> _categories = ['All'];
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products = await DBHelper.instance.getAllProducts();
    final cats = <String>{'All'};
    for (final p in products) {
      cats.add(p.category);
    }
    setState(() {
      _allProducts = products;
      _categories = cats.toList();
      _applyFilters();
    });
  }

  void _applyFilters() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _allProducts.where((p) {
        final matchesCategory =
            _selectedCategory == 'All' || p.category == _selectedCategory;
        final matchesSearch = q.isEmpty ||
            p.name.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q);
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  void _search(String q) => _applyFilters();

  void _selectCategory(String category) {
    setState(() => _selectedCategory = category);
    _applyFilters();
  }

  void _addToCart(Product product) {
    if (product.quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Out of stock!')),
      );
      return;
    }
    setState(() {
      if (_cart.containsKey(product.id)) {
        final line = _cart[product.id]!;
        if (line.qty < product.quantity) {
          line.qty++;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No more stock available!')),
          );
        }
      } else {
        _cart[product.id!] = CartLine(product: product);
      }
    });
  }

  void _removeFromCart(int productId) {
    setState(() {
      if (_cart[productId] != null) {
        if (_cart[productId]!.qty > 1) {
          _cart[productId]!.qty--;
        } else {
          _cart.remove(productId);
        }
      }
    });
  }

  double get _subtotal =>
      _cart.values.fold(0, (sum, line) => sum + line.total);

  double get _discount => double.tryParse(_discountCtrl.text) ?? 0;

  double get _labourCost => double.tryParse(_labourCtrl.text) ?? 0;

  double get _grandTotal =>
      (_subtotal + _labourCost - _discount).clamp(0, double.infinity);

  Future<void> _showCartAndCheckout() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty. Add parts first.')),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          void bump(int productId, int delta) {
            setState(() {
              final line = _cart[productId];
              if (line == null) return;
              if (delta > 0) {
                if (line.qty < line.product.quantity) {
                  line.qty++;
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No more stock available!')),
                  );
                }
              } else {
                if (line.qty > 1) {
                  line.qty--;
                } else {
                  _cart.remove(productId);
                }
              }
            });
            setModalState(() {});
            if (_cart.isEmpty) Navigator.pop(ctx);
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Customer Bill',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _customerNameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Customer Name',
                        border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _customerPhoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                        labelText: 'Customer Phone',
                        border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _vehicleNumberCtrl,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                              labelText: 'Bike Number',
                              hintText: 'e.g. LEA-1234',
                              border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _vehicleModelCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Bike Model',
                              hintText: 'e.g. Honda 125',
                              border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Parts in this bill',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  // Editable cart lines - qty can be increased/decreased right here
                  ..._cart.values.map((line) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(line.product.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  Text(
                                      '${_currency.format(line.product.salePrice)} x ${line.qty}',
                                      style: const TextStyle(
                                          color: Colors.black54, fontSize: 12)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => bump(line.product.id!, -1),
                            ),
                            Text('${line.qty}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => bump(line.product.id!, 1),
                            ),
                            SizedBox(
                              width: 70,
                              child: Text(
                                _currency.format(line.total),
                                textAlign: TextAlign.right,
                                style:
                                    const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      )),
                  const Divider(),
                  TextField(
                    controller: _labourCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Labour / Service Charges (Rs.)',
                        prefixIcon: Icon(Icons.build),
                        border: OutlineInputBorder()),
                    onChanged: (_) => setModalState(() {}),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _discountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Discount (Rs.)', border: OutlineInputBorder()),
                    onChanged: (_) => setModalState(() {}),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Parts Subtotal'),
                      Text(_currency.format(_subtotal)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Labour Charges'),
                      Text(_currency.format(_labourCost)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Discount'),
                      Text('- ${_currency.format(_discount)}'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Grand Total',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(_currency.format(_grandTotal),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.accent)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Generate Bill'),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _generateBill();
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _generateBill() async {
    final items = _cart.values
        .map((line) => BillItem(
              billId: 0,
              productId: line.product.id!,
              productName: line.product.name,
              price: line.product.salePrice,
              quantity: line.qty,
            ))
        .toList();

    final bill = Bill(
      customerName: _customerNameCtrl.text.trim().isEmpty
          ? 'Walk-in Customer'
          : _customerNameCtrl.text.trim(),
      customerPhone: _customerPhoneCtrl.text.trim(),
      vehicleNumber: _vehicleNumberCtrl.text.trim(),
      vehicleModel: _vehicleModelCtrl.text.trim(),
      totalAmount: _subtotal,
      discount: _discount,
      labourCost: _labourCost,
    );

    // this automatically deducts stock for every part added to the bill
    final billId = await DBHelper.instance.createBill(bill, items);
    bill.id = billId;
    bill.items = items;

    setState(() {
      _cart.clear();
      _customerNameCtrl.clear();
      _customerPhoneCtrl.clear();
      _vehicleNumberCtrl.clear();
      _vehicleModelCtrl.clear();
      _discountCtrl.text = '0';
      _labourCtrl.text = '0';
    });

    await _loadProducts();

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BillDetailScreen(bill: bill)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = _cart.values.fold(0, (sum, l) => sum + l.qty);

    return Scaffold(
      appBar: AppBar(title: const Text('New Bill')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search part to add to bill...',
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
          // Horizontal category tabs
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final cat = _categories[i];
                final selected = cat == _selectedCategory;
                return ChoiceChip(
                  label: Text(cat),
                  selected: selected,
                  onSelected: (_) => _selectCategory(cat),
                  selectedColor: AppColors.accent,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : Colors.black87,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                  backgroundColor: Colors.grey.shade100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                        color: selected
                            ? AppColors.accent
                            : Colors.grey.shade300),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? const Center(child: Text('No parts found in this category.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _filtered.length,
                    itemBuilder: (ctx, i) {
                      final p = _filtered[i];
                      final inCartQty = _cart[p.id]?.qty ?? 0;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: p.imagePath != null &&
                                    File(p.imagePath!).existsSync()
                                ? Image.file(File(p.imagePath!),
                                    width: 48, height: 48, fit: BoxFit.cover)
                                : Container(
                                    width: 48,
                                    height: 48,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.settings,
                                        color: Colors.grey),
                                  ),
                          ),
                          title: Text(p.name),
                          subtitle: Text(
                              '${_currency.format(p.salePrice)}  |  Stock: ${p.quantity}'),
                          trailing: inCartQty > 0
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                          Icons.remove_circle_outline),
                                      onPressed: () => _removeFromCart(p.id!),
                                    ),
                                    Text('$inCartQty'),
                                    IconButton(
                                      icon:
                                          const Icon(Icons.add_circle_outline),
                                      onPressed: () => _addToCart(p),
                                    ),
                                  ],
                                )
                              : IconButton(
                                  icon: const Icon(Icons.add_shopping_cart),
                                  onPressed: p.quantity <= 0
                                      ? null
                                      : () => _addToCart(p),
                                ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCartAndCheckout,
        icon: const Icon(Icons.shopping_cart_checkout),
        label: Text('Checkout ($cartCount)'),
      ),
    );
  }
}
