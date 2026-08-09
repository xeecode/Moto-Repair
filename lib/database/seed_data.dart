import 'db_helper.dart';
import '../models/product.dart';
import '../models/supplier.dart';
import '../models/purchase.dart';
import '../models/expense.dart';
import '../models/bill.dart';

/// Adds realistic sample data so you can test the app immediately without
/// manually typing everything in. Call `SeedData.load()` once, and
/// `SeedData.clearEverything()` whenever you want to wipe it before
/// going live with real shop data.
class SeedData {
  static Future<void> load() async {
    final db = DBHelper.instance;

    // ---------------- PRODUCTS ----------------
    final products = [
      Product(name: 'Engine Oil Filter', category: 'Filters & Oils', purchasePrice: 180, salePrice: 280, quantity: 42),
      Product(name: 'Mobil 20W-50 Engine Oil (1L)', category: 'Filters & Oils', purchasePrice: 650, salePrice: 850, quantity: 30),
      Product(name: 'Front Brake Pads Set', category: 'Brake System', purchasePrice: 400, salePrice: 650, quantity: 3),
      Product(name: 'Rear Brake Shoe', category: 'Brake System', purchasePrice: 350, salePrice: 550, quantity: 18),
      Product(name: 'Brake Lever (Clutch Side)', category: 'Brake System', purchasePrice: 220, salePrice: 380, quantity: 25),
      Product(name: '12V Battery (Yuasa)', category: 'Electrical', purchasePrice: 2800, salePrice: 3500, quantity: 8),
      Product(name: 'Headlight Bulb H4', category: 'Lights', purchasePrice: 150, salePrice: 280, quantity: 2),
      Product(name: 'Tail Light Assembly', category: 'Lights', purchasePrice: 450, salePrice: 700, quantity: 12),
      Product(name: 'Spark Plug (NGK)', category: 'Engine Parts', purchasePrice: 180, salePrice: 320, quantity: 50),
      Product(name: 'Piston Kit 70cc', category: 'Engine Parts', purchasePrice: 1200, salePrice: 1800, quantity: 6),
      Product(name: 'Clutch Plate Set', category: 'Engine Parts', purchasePrice: 950, salePrice: 1450, quantity: 10),
      Product(name: 'Chain Sprocket Kit', category: 'Chain & Sprocket', purchasePrice: 1100, salePrice: 1650, quantity: 14),
      Product(name: 'Drive Chain 428H', category: 'Chain & Sprocket', purchasePrice: 800, salePrice: 1250, quantity: 20),
      Product(name: 'Front Suspension Fork Seal', category: 'Suspension', purchasePrice: 300, salePrice: 480, quantity: 16),
      Product(name: 'Rear Shock Absorber', category: 'Suspension', purchasePrice: 1500, salePrice: 2200, quantity: 4),
      Product(name: 'Tubeless Tyre 100/90-17', category: 'Tyres & Tubes', purchasePrice: 3200, salePrice: 4200, quantity: 9),
      Product(name: 'Tube 2.75-18', category: 'Tyres & Tubes', purchasePrice: 350, salePrice: 550, quantity: 22),
      Product(name: 'Side Mirror (Pair)', category: 'Body Parts', purchasePrice: 400, salePrice: 650, quantity: 15),
      Product(name: 'Fuel Tank Cap', category: 'Body Parts', purchasePrice: 250, salePrice: 420, quantity: 11),
      Product(name: 'Seat Cover', category: 'Body Parts', purchasePrice: 500, salePrice: 800, quantity: 7),
    ];

    final insertedIds = <int>[];
    for (final p in products) {
      final id = await db.insertProduct(p);
      insertedIds.add(id);
    }

    // ---------------- SUPPLIERS ----------------
    final supplierId1 = await db.insertSupplier(Supplier(
      name: 'Al-Rehman Auto Parts',
      phone: '0300-1234567',
      address: 'Bahawalpur Bypass Road',
    ));
    final supplierId2 = await db.insertSupplier(Supplier(
      name: 'Khan Spare Parts Wholesale',
      phone: '0333-9876543',
      address: 'Multan Road, Bahawalpur',
    ));

    // ---------------- PURCHASES ----------------
    await db.createPurchase(Purchase(
      supplierId: supplierId1,
      supplierName: 'Al-Rehman Auto Parts',
      productId: insertedIds[8], // Spark Plug
      productName: 'Spark Plug (NGK)',
      quantity: 30,
      unitPrice: 180,
    ));
    await db.createPurchase(Purchase(
      supplierId: supplierId2,
      supplierName: 'Khan Spare Parts Wholesale',
      productId: insertedIds[15], // Tubeless Tyre
      productName: 'Tubeless Tyre 100/90-17',
      quantity: 5,
      unitPrice: 3200,
    ));

    // ---------------- EXPENSES ----------------
    await db.insertExpense(Expense(title: 'Shop Rent - This Month', amount: 25000, category: 'Rent'));
    await db.insertExpense(Expense(title: 'Electricity Bill', amount: 4500, category: 'Electricity'));
    await db.insertExpense(Expense(title: 'Mechanic Salary', amount: 20000, category: 'Staff Salary'));

    // ---------------- BILLS ----------------
    await db.createBill(
      Bill(
        customerName: 'Ahmed Raza',
        customerPhone: '0301-2345678',
        vehicleNumber: 'BWP-4521',
        vehicleModel: 'Honda CG 125',
        totalAmount: 280 + 650,
        labourCost: 300,
        discount: 50,
      ),
      [
        BillItem(billId: 0, productId: insertedIds[0], productName: 'Engine Oil Filter', price: 280, quantity: 1),
        BillItem(billId: 0, productId: insertedIds[1], productName: 'Mobil 20W-50 Engine Oil (1L)', price: 650, quantity: 1),
      ],
    );

    await db.createBill(
      Bill(
        customerName: 'Bilal Hussain',
        customerPhone: '0345-7654321',
        vehicleNumber: 'LEA-1187',
        vehicleModel: 'Yamaha YBR 125',
        totalAmount: 650 + 320 * 2,
        labourCost: 500,
        discount: 0,
      ),
      [
        BillItem(billId: 0, productId: insertedIds[2], productName: 'Front Brake Pads Set', price: 650, quantity: 1),
        BillItem(billId: 0, productId: insertedIds[8], productName: 'Spark Plug (NGK)', price: 320, quantity: 2),
      ],
    );

    await db.createBill(
      Bill(
        customerName: 'Walk-in Customer',
        customerPhone: '',
        vehicleNumber: 'RYK-9034',
        vehicleModel: 'Suzuki GS 150',
        totalAmount: 1250,
        labourCost: 0,
        discount: 100,
      ),
      [
        BillItem(billId: 0, productId: insertedIds[12], productName: 'Drive Chain 428H', price: 1250, quantity: 1),
      ],
    );
  }

  /// Wipes every table so the app is empty again before you switch to
  /// real shop data.
  static Future<void> clearEverything() async {
    await DBHelper.instance.clearAllData();
  }
}
