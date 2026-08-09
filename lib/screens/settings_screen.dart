import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameCtrl = TextEditingController();
  final _shopAddressCtrl = TextEditingController();
  final _shopPhoneCtrl = TextEditingController();
  final _footerCtrl = TextEditingController();
  final _thresholdCtrl = TextEditingController();
  final _currencyCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await SettingsService.load();
    _shopNameCtrl.text = settings.shopName;
    _shopAddressCtrl.text = settings.shopAddress;
    _shopPhoneCtrl.text = settings.shopPhone;
    _footerCtrl.text = settings.invoiceFooter;
    _thresholdCtrl.text = settings.lowStockThreshold.toString();
    _currencyCtrl.text = settings.currencySymbol;
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final settings = ShopSettings(
      shopName: _shopNameCtrl.text.trim().isEmpty
          ? 'Motorcycle Shop'
          : _shopNameCtrl.text.trim(),
      shopAddress: _shopAddressCtrl.text.trim(),
      shopPhone: _shopPhoneCtrl.text.trim(),
      invoiceFooter: _footerCtrl.text.trim().isEmpty
          ? 'Thank you for your business!'
          : _footerCtrl.text.trim(),
      lowStockThreshold: int.tryParse(_thresholdCtrl.text) ?? 5,
      currencySymbol:
          _currencyCtrl.text.trim().isEmpty ? 'Rs. ' : _currencyCtrl.text,
    );

    await SettingsService.save(settings);

    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully!')),
      );
      Navigator.pop(context, true); // true = tell caller settings changed
    }
  }

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _shopAddressCtrl.dispose();
    _shopPhoneCtrl.dispose();
    _footerCtrl.dispose();
    _thresholdCtrl.dispose();
    _currencyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Shop Profile',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('This name & details will show on the Dashboard and every Bill/Invoice.',
                      style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _shopNameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Shop Name *',
                        prefixIcon: Icon(Icons.storefront_outlined)),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _shopAddressCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                        labelText: 'Shop Address',
                        prefixIcon: Icon(Icons.location_on_outlined)),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _shopPhoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                        labelText: 'Shop Phone / WhatsApp',
                        prefixIcon: Icon(Icons.phone_outlined)),
                  ),
                  const SizedBox(height: 26),
                  const Text('Invoice / Bill Customization',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _footerCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Invoice Footer Message',
                        hintText: 'e.g. Thank you for your business!',
                        prefixIcon: Icon(Icons.notes_outlined)),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _currencyCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Currency Symbol',
                        hintText: 'e.g. Rs. or Rs or PKR',
                        prefixIcon: Icon(Icons.attach_money)),
                  ),
                  const SizedBox(height: 26),
                  const Text('Inventory',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _thresholdCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Low Stock Alert Threshold',
                        hintText: 'Alert when stock falls to or below this number',
                        prefixIcon: Icon(Icons.warning_amber_outlined)),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save),
                      label: const Text('Save Settings'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Currency symbol changes apply to new screens only, not existing saved entries.',
                            style: TextStyle(
                                fontSize: 11.5, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
