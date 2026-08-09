import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/product.dart';
import '../models/bill.dart';
import '../models/supplier.dart';
import '../models/purchase.dart';
import '../models/expense.dart';

class DBHelper {
  DBHelper._privateConstructor();
  static final DBHelper instance = DBHelper._privateConstructor();

  static Database? _database;
  static const String dbFileName = 'motorcycle_shop.db';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<String> get dbPath async {
    final dbDir = await getDatabasesPath();
    return join(dbDir, dbFileName);
  }

  Future<Database> _initDB() async {
    final path = await dbPath;

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          'ALTER TABLE bills ADD COLUMN labourCost REAL NOT NULL DEFAULT 0');
    }
    if (oldVersion < 3) {
      await db.execute(
          "ALTER TABLE bills ADD COLUMN vehicleNumber TEXT NOT NULL DEFAULT ''");
      await db.execute(
          "ALTER TABLE bills ADD COLUMN vehicleModel TEXT NOT NULL DEFAULT ''");
      await db.execute(
          'ALTER TABLE bill_items ADD COLUMN costPrice REAL NOT NULL DEFAULT 0');
      await _createV3Tables(db);
    }
  }

  Future _createV3Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS suppliers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        address TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS purchases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        supplierId INTEGER,
        supplierName TEXT NOT NULL,
        productId INTEGER NOT NULL,
        productName TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unitPrice REAL NOT NULL,
        purchaseDate TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        note TEXT,
        date TEXT NOT NULL
      )
    ''');
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        purchasePrice REAL NOT NULL,
        salePrice REAL NOT NULL,
        quantity INTEGER NOT NULL,
        imagePath TEXT,
        description TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE bills (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerName TEXT NOT NULL,
        customerPhone TEXT NOT NULL,
        vehicleNumber TEXT NOT NULL DEFAULT '',
        vehicleModel TEXT NOT NULL DEFAULT '',
        totalAmount REAL NOT NULL,
        discount REAL NOT NULL DEFAULT 0,
        labourCost REAL NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE bill_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        billId INTEGER NOT NULL,
        productId INTEGER NOT NULL,
        productName TEXT NOT NULL,
        price REAL NOT NULL,
        costPrice REAL NOT NULL DEFAULT 0,
        quantity INTEGER NOT NULL,
        FOREIGN KEY (billId) REFERENCES bills (id) ON DELETE CASCADE
      )
    ''');

    await _createV3Tables(db);
  }

  // ---------------- PRODUCT (INVENTORY) CRUD ----------------

  Future<int> insertProduct(Product product) async {
    final db = await instance.database;
    return await db.insert('products', product.toMap()..remove('id'));
  }

  Future<List<Product>> getAllProducts() async {
    final db = await instance.database;
    final result = await db.query('products', orderBy: 'name ASC');
    return result.map((map) => Product.fromMap(map)).toList();
  }

  Future<List<Product>> searchProducts(String query) async {
    final db = await instance.database;
    final result = await db.query(
      'products',
      where: 'name LIKE ? OR category LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return result.map((map) => Product.fromMap(map)).toList();
  }

  Future<Product?> getProductById(int id) async {
    final db = await instance.database;
    final result = await db.query('products', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Product.fromMap(result.first);
  }

  Future<int> updateProduct(Product product) async {
    final db = await instance.database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // reduce stock quantity when a product is sold (used during billing)
  Future<void> reduceStock(int productId, int soldQty) async {
    final db = await instance.database;
    final product = await getProductById(productId);
    if (product != null) {
      final newQty = product.quantity - soldQty;
      await db.update(
        'products',
        {'quantity': newQty < 0 ? 0 : newQty},
        where: 'id = ?',
        whereArgs: [productId],
      );
    }
  }

  // increase stock (used if a bill item is removed/refunded, or new purchase arrives)
  Future<void> increaseStock(int productId, int qty) async {
    final db = await instance.database;
    final product = await getProductById(productId);
    if (product != null) {
      await db.update(
        'products',
        {'quantity': product.quantity + qty},
        where: 'id = ?',
        whereArgs: [productId],
      );
    }
  }

  // ---------------- BILLING ----------------

  // Creates a bill AND automatically deducts stock for every item - all in one transaction
  Future<int> createBill(Bill bill, List<BillItem> items) async {
    final db = await instance.database;
    late int billId;

    await db.transaction((txn) async {
      billId = await txn.insert('bills', bill.toMap()..remove('id'));

      for (final item in items) {
        // capture current cost price for accurate profit reporting
        final prodResult = await txn.query('products',
            where: 'id = ?', whereArgs: [item.productId]);
        double costPrice = item.costPrice;
        if (prodResult.isNotEmpty) {
          costPrice = (prodResult.first['purchasePrice'] as num).toDouble();
        }

        await txn.insert('bill_items', {
          'billId': billId,
          'productId': item.productId,
          'productName': item.productName,
          'price': item.price,
          'costPrice': costPrice,
          'quantity': item.quantity,
        });

        // automatically reduce inventory stock for the sold part
        if (prodResult.isNotEmpty) {
          final currentQty = prodResult.first['quantity'] as int;
          final newQty = currentQty - item.quantity;
          await txn.update(
            'products',
            {'quantity': newQty < 0 ? 0 : newQty},
            where: 'id = ?',
            whereArgs: [item.productId],
          );
        }
      }
    });

    return billId;
  }

  Future<List<Bill>> getAllBills() async {
    final db = await instance.database;
    final result = await db.query('bills', orderBy: 'createdAt DESC');
    return result.map((map) => Bill.fromMap(map)).toList();
  }

  Future<List<Bill>> getBillsByVehicleNumber(String vehicleNumber) async {
    final db = await instance.database;
    final result = await db.query(
      'bills',
      where: 'vehicleNumber LIKE ?',
      whereArgs: ['%$vehicleNumber%'],
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => Bill.fromMap(map)).toList();
  }

  Future<List<BillItem>> getBillItems(int billId) async {
    final db = await instance.database;
    final result =
        await db.query('bill_items', where: 'billId = ?', whereArgs: [billId]);
    return result.map((map) => BillItem.fromMap(map)).toList();
  }

  Future<int> deleteBill(int billId) async {
    final db = await instance.database;
    // restore stock before deleting
    final items = await getBillItems(billId);
    for (final item in items) {
      await increaseStock(item.productId, item.quantity);
    }
    await db.delete('bill_items', where: 'billId = ?', whereArgs: [billId]);
    return await db.delete('bills', where: 'id = ?', whereArgs: [billId]);
  }

  // ---------------- SUPPLIERS ----------------

  Future<int> insertSupplier(Supplier supplier) async {
    final db = await instance.database;
    return await db.insert('suppliers', supplier.toMap()..remove('id'));
  }

  Future<List<Supplier>> getAllSuppliers() async {
    final db = await instance.database;
    final result = await db.query('suppliers', orderBy: 'name ASC');
    return result.map((map) => Supplier.fromMap(map)).toList();
  }

  Future<int> deleteSupplier(int id) async {
    final db = await instance.database;
    return await db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- PURCHASES (STOCK-IN) ----------------

  // Records a purchase, increases stock, and updates the product's purchase price
  Future<int> createPurchase(Purchase purchase) async {
    final db = await instance.database;
    late int purchaseId;

    await db.transaction((txn) async {
      purchaseId = await txn.insert('purchases', purchase.toMap()..remove('id'));

      final prodResult = await txn.query('products',
          where: 'id = ?', whereArgs: [purchase.productId]);
      if (prodResult.isNotEmpty) {
        final currentQty = prodResult.first['quantity'] as int;
        await txn.update(
          'products',
          {
            'quantity': currentQty + purchase.quantity,
            'purchasePrice': purchase.unitPrice,
          },
          where: 'id = ?',
          whereArgs: [purchase.productId],
        );
      }
    });

    return purchaseId;
  }

  Future<List<Purchase>> getAllPurchases() async {
    final db = await instance.database;
    final result = await db.query('purchases', orderBy: 'purchaseDate DESC');
    return result.map((map) => Purchase.fromMap(map)).toList();
  }

  // ---------------- EXPENSES ----------------

  Future<int> insertExpense(Expense expense) async {
    final db = await instance.database;
    return await db.insert('expenses', expense.toMap()..remove('id'));
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await instance.database;
    final result = await db.query('expenses', orderBy: 'date DESC');
    return result.map((map) => Expense.fromMap(map)).toList();
  }

  Future<int> deleteExpense(int id) async {
    final db = await instance.database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getTotalExpenses({DateTime? from, DateTime? to}) async {
    final db = await instance.database;
    if (from != null && to != null) {
      final result = await db.rawQuery(
          'SELECT SUM(amount) as total FROM expenses WHERE date >= ? AND date <= ?',
          [from.toIso8601String(), to.toIso8601String()]);
      return (result.first['total'] as num?)?.toDouble() ?? 0;
    }
    final result = await db.rawQuery('SELECT SUM(amount) as total FROM expenses');
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  // ---------------- REPORTS ----------------

  // Revenue, cost of goods sold, and net profit within an optional date range
  Future<Map<String, double>> getProfitSummary({DateTime? from, DateTime? to}) async {
    final db = await instance.database;

    String billWhere = '';
    List<dynamic> billArgs = [];
    if (from != null && to != null) {
      billWhere = 'WHERE b.createdAt >= ? AND b.createdAt <= ?';
      billArgs = [from.toIso8601String(), to.toIso8601String()];
    }

    final revenueResult = await db.rawQuery('''
      SELECT SUM(b.totalAmount + b.labourCost - b.discount) as revenue,
             SUM(b.labourCost) as labour
      FROM bills b $billWhere
    ''', billArgs);

    String itemWhere = '';
    List<dynamic> itemArgs = [];
    if (from != null && to != null) {
      itemWhere = 'WHERE b.createdAt >= ? AND b.createdAt <= ?';
      itemArgs = [from.toIso8601String(), to.toIso8601String()];
    }

    final cogsResult = await db.rawQuery('''
      SELECT SUM(bi.costPrice * bi.quantity) as cogs
      FROM bill_items bi
      JOIN bills b ON bi.billId = b.id
      $itemWhere
    ''', itemArgs);

    final expenses = await getTotalExpenses(from: from, to: to);

    final revenue = (revenueResult.first['revenue'] as num?)?.toDouble() ?? 0;
    final cogs = (cogsResult.first['cogs'] as num?)?.toDouble() ?? 0;
    final grossProfit = revenue - cogs;
    final netProfit = grossProfit - expenses;

    return {
      'revenue': revenue,
      'cogs': cogs,
      'grossProfit': grossProfit,
      'expenses': expenses,
      'netProfit': netProfit,
    };
  }

  // Best-selling parts: total quantity sold per product, descending
  Future<List<Map<String, dynamic>>> getBestSellingParts({int limit = 10}) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT productName, SUM(quantity) as totalQty, SUM(price * quantity) as totalRevenue
      FROM bill_items
      GROUP BY productId
      ORDER BY totalQty DESC
      LIMIT ?
    ''', [limit]);
    return result;
  }

  // Monthly revenue for the last N months (for simple bar report)
  Future<List<Map<String, dynamic>>> getMonthlyRevenue({int months = 6}) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT strftime('%Y-%m', createdAt) as month,
             SUM(totalAmount + labourCost - discount) as total
      FROM bills
      GROUP BY month
      ORDER BY month DESC
      LIMIT ?
    ''', [months]);
    return result;
  }

  // ---------------- DASHBOARD STATS ----------------

  Future<int> getTotalProductsCount() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM products');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<double> getInventoryValue() async {
    final db = await instance.database;
    final result = await db
        .rawQuery('SELECT SUM(salePrice * quantity) as total FROM products');
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<double> getTodaySales() async {
    final db = await instance.database;
    final today = DateTime.now();
    final startOfDay =
        DateTime(today.year, today.month, today.day).toIso8601String();
    final result = await db.rawQuery(
        'SELECT SUM(totalAmount - discount) as total FROM bills WHERE createdAt >= ?',
        [startOfDay]);
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<List<Product>> getLowStockProducts({int threshold = 5}) async {
    final db = await instance.database;
    final result = await db.query('products',
        where: 'quantity <= ?', whereArgs: [threshold], orderBy: 'quantity ASC');
    return result.map((map) => Product.fromMap(map)).toList();
  }

  // ---------------- BACKUP / RESTORE ----------------

  Future<Directory> _backupDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/backups');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  // Copies the current live database into a timestamped backup file
  Future<String> createBackup() async {
    final db = await instance.database;
    await db.rawQuery('PRAGMA wal_checkpoint(FULL)'); // flush pending writes
    final liveDbFile = File(await dbPath);
    final backupDir = await _backupDir();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupFile = File('${backupDir.path}/backup_$timestamp.db');
    await liveDbFile.copy(backupFile.path);
    return backupFile.path;
  }

  Future<List<FileSystemEntity>> listBackups() async {
    final dir = await _backupDir();
    final files = dir.listSync().where((f) => f.path.endsWith('.db')).toList();
    files.sort((a, b) => b.path.compareTo(a.path)); // newest first
    return files;
  }

  // Restores from a chosen backup file - closes current DB, replaces file, reopens
  Future<void> restoreBackup(String backupFilePath) async {
    final db = await instance.database;
    await db.close();
    _database = null;

    final liveDbPath = await dbPath;
    await File(backupFilePath).copy(liveDbPath);

    // reopen so the app can keep using the DB immediately
    _database = await _initDB();
  }

  Future<void> deleteBackup(String backupFilePath) async {
    final file = File(backupFilePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  // ---------------- DEMO / RESET ----------------

  // Wipes every table - full reset of all shop data (used from Backup & Restore > Danger Zone)
  Future<void> clearAllData() async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete('bill_items');
      await txn.delete('bills');
      await txn.delete('purchases');
      await txn.delete('suppliers');
      await txn.delete('expenses');
      await txn.delete('products');
    });
  }
}
