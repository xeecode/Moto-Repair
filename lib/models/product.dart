class Product {
  int? id;
  String name;
  String category; // e.g. Engine, Brake, Electrical, Body Parts
  double purchasePrice; // cost price
  double salePrice; // selling price
  int quantity; // stock quantity
  String? imagePath; // local file path of product image
  String? description;
  DateTime createdAt;

  Product({
    this.id,
    required this.name,
    required this.category,
    required this.purchasePrice,
    required this.salePrice,
    required this.quantity,
    this.imagePath,
    this.description,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'purchasePrice': purchasePrice,
      'salePrice': salePrice,
      'quantity': quantity,
      'imagePath': imagePath,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      category: map['category'] as String,
      purchasePrice: (map['purchasePrice'] as num).toDouble(),
      salePrice: (map['salePrice'] as num).toDouble(),
      quantity: map['quantity'] as int,
      imagePath: map['imagePath'] as String?,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Product copyWith({
    int? id,
    String? name,
    String? category,
    double? purchasePrice,
    double? salePrice,
    int? quantity,
    String? imagePath,
    String? description,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      salePrice: salePrice ?? this.salePrice,
      quantity: quantity ?? this.quantity,
      imagePath: imagePath ?? this.imagePath,
      description: description ?? this.description,
      createdAt: createdAt,
    );
  }
}
