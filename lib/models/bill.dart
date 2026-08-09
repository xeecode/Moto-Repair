class BillItem {
  int? id;
  int billId;
  int productId;
  String productName;
  double price; // sale price at time of billing
  double costPrice; // purchase/cost price at time of billing (for profit calc)
  int quantity;

  BillItem({
    this.id,
    required this.billId,
    required this.productId,
    required this.productName,
    required this.price,
    this.costPrice = 0,
    required this.quantity,
  });

  double get total => price * quantity;
  double get profit => (price - costPrice) * quantity;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'billId': billId,
      'productId': productId,
      'productName': productName,
      'price': price,
      'costPrice': costPrice,
      'quantity': quantity,
    };
  }

  factory BillItem.fromMap(Map<String, dynamic> map) {
    return BillItem(
      id: map['id'] as int?,
      billId: map['billId'] as int,
      productId: map['productId'] as int,
      productName: map['productName'] as String,
      price: (map['price'] as num).toDouble(),
      costPrice: (map['costPrice'] as num?)?.toDouble() ?? 0,
      quantity: map['quantity'] as int,
    );
  }
}

class Bill {
  int? id;
  String customerName;
  String customerPhone;
  String vehicleNumber;
  String vehicleModel;
  double totalAmount;
  double discount;
  double labourCost;
  DateTime createdAt;
  List<BillItem> items;

  Bill({
    this.id,
    required this.customerName,
    required this.customerPhone,
    this.vehicleNumber = '',
    this.vehicleModel = '',
    required this.totalAmount,
    this.discount = 0,
    this.labourCost = 0,
    DateTime? createdAt,
    this.items = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  double get grandTotal => (totalAmount + labourCost) - discount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'vehicleNumber': vehicleNumber,
      'vehicleModel': vehicleModel,
      'totalAmount': totalAmount,
      'discount': discount,
      'labourCost': labourCost,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Bill.fromMap(Map<String, dynamic> map) {
    return Bill(
      id: map['id'] as int?,
      customerName: map['customerName'] as String,
      customerPhone: map['customerPhone'] as String,
      vehicleNumber: map['vehicleNumber'] as String? ?? '',
      vehicleModel: map['vehicleModel'] as String? ?? '',
      totalAmount: (map['totalAmount'] as num).toDouble(),
      discount: (map['discount'] as num?)?.toDouble() ?? 0,
      labourCost: (map['labourCost'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
