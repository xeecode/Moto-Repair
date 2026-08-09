import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../database/db_helper.dart';
import '../models/product.dart';

class AddProductScreen extends StatefulWidget {
  final Product? product; // if not null -> edit mode

  const AddProductScreen({super.key, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _purchasePriceCtrl = TextEditingController();
  final _salePriceCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String? _imagePath;
  bool _saving = false;

  final List<String> _categories = [
    'Engine Parts',
    'Brake System',
    'Electrical',
    'Body Parts',
    'Suspension',
    'Tyres & Tubes',
    'Filters & Oils',
    'Chain & Sprocket',
    'Lights',
    'Other',
  ];
  String _selectedCategory = 'Engine Parts';

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      final pr = widget.product!;
      _nameCtrl.text = pr.name;
      _selectedCategory = pr.category;
      _purchasePriceCtrl.text = pr.purchasePrice.toString();
      _salePriceCtrl.text = pr.salePrice.toString();
      _quantityCtrl.text = pr.quantity.toString();
      _descCtrl.text = pr.description ?? '';
      _imagePath = pr.imagePath;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 70);
    if (picked == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'part_${DateTime.now().millisecondsSinceEpoch}${p.extension(picked.path)}';
    final savedImage = await File(picked.path).copy('${appDir.path}/$fileName');

    setState(() => _imagePath = savedImage.path);
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final product = Product(
      id: widget.product?.id,
      name: _nameCtrl.text.trim(),
      category: _selectedCategory,
      purchasePrice: double.parse(_purchasePriceCtrl.text),
      salePrice: double.parse(_salePriceCtrl.text),
      quantity: int.parse(_quantityCtrl.text),
      imagePath: _imagePath,
      description: _descCtrl.text.trim(),
    );

    if (widget.product == null) {
      // NEW PART: automatically added to inventory with price & stock
      await DBHelper.instance.insertProduct(product);
    } else {
      await DBHelper.instance.updateProduct(product);
    }

    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(widget.product == null
                ? 'Part added to inventory successfully!'
                : 'Part updated successfully!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Part' : 'Add New Part')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: GestureDetector(
                onTap: _showImageSourceSheet,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _imagePath != null && File(_imagePath!).existsSync()
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(File(_imagePath!), fit: BoxFit.cover),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, size: 32, color: Colors.grey),
                            SizedBox(height: 6),
                            Text('Add Photo', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Part Name *', border: OutlineInputBorder()),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                  labelText: 'Category', border: OutlineInputBorder()),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _purchasePriceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Purchase Price', border: OutlineInputBorder()),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _salePriceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Sale Price *', border: OutlineInputBorder()),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _quantityCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Stock Quantity *', border: OutlineInputBorder()),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _saveProduct,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save),
                label: Text(isEdit ? 'Update Part' : 'Save to Inventory'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
