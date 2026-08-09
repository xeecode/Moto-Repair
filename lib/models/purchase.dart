class Purchase {
  int? id;
  int? supplierId;
  String supplierName;
  int productId;
  String productName;
  int quantity;
  double unitPrice;
  DateTime purchaseDate;

  Purchase({
    this.id,
    this.supplierId,
    required this.supplierName,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    DateTime? purchaseDate,
  }) : purchaseDate = purchaseDate ?? DateTime.now();

  double get totalCost => quantity * unitPrice;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'purchaseDate': purchaseDate.toIso8601String(),
    };
  }

  factory Purchase.fromMap(Map<String, dynamic> map) {
    return Purchase(
      id: map['id'] as int?,
      supplierId: map['supplierId'] as int?,
      supplierName: map['supplierName'] as String,
      productId: map['productId'] as int,
      productName: map['productName'] as String,
      quantity: map['quantity'] as int,
      unitPrice: (map['unitPrice'] as num).toDouble(),
      purchaseDate: DateTime.parse(map['purchaseDate'] as String),
    );
  }
}
