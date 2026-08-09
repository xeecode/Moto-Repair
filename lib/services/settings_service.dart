import 'package:shared_preferences/shared_preferences.dart';

/// Simple key-value app settings - shop profile info used across the
/// dashboard header and printed/shared invoices.
class ShopSettings {
  String shopName;
  String shopAddress;
  String shopPhone;
  String invoiceFooter;
  int lowStockThreshold;
  String currencySymbol;

  ShopSettings({
    this.shopName = 'Motorcycle Shop',
    this.shopAddress = '',
    this.shopPhone = '',
    this.invoiceFooter = 'Thank you for your business!',
    this.lowStockThreshold = 5,
    this.currencySymbol = 'Rs. ',
  });
}

class SettingsService {
  static const _kShopName = 'shopName';
  static const _kShopAddress = 'shopAddress';
  static const _kShopPhone = 'shopPhone';
  static const _kInvoiceFooter = 'invoiceFooter';
  static const _kLowStockThreshold = 'lowStockThreshold';
  static const _kCurrencySymbol = 'currencySymbol';

  static Future<ShopSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ShopSettings(
      shopName: prefs.getString(_kShopName) ?? 'Motorcycle Shop',
      shopAddress: prefs.getString(_kShopAddress) ?? '',
      shopPhone: prefs.getString(_kShopPhone) ?? '',
      invoiceFooter:
          prefs.getString(_kInvoiceFooter) ?? 'Thank you for your business!',
      lowStockThreshold: prefs.getInt(_kLowStockThreshold) ?? 5,
      currencySymbol: prefs.getString(_kCurrencySymbol) ?? 'Rs. ',
    );
  }

  static Future<void> save(ShopSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kShopName, settings.shopName);
    await prefs.setString(_kShopAddress, settings.shopAddress);
    await prefs.setString(_kShopPhone, settings.shopPhone);
    await prefs.setString(_kInvoiceFooter, settings.invoiceFooter);
    await prefs.setInt(_kLowStockThreshold, settings.lowStockThreshold);
    await prefs.setString(_kCurrencySymbol, settings.currencySymbol);
  }
}
