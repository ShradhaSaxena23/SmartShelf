class ProductModel {
  final String id;
  final String name;
  final String category;
  final DateTime expiryDate;
  final double originalPrice;
  final int quantity;
  final String? brand;
  final DateTime? mfgDate;
  final String? batchNumber;
  final String? barcode;
  final String? description;
  final String? location;
  final List<String> images;

  ProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.expiryDate,
    required this.originalPrice,
    this.quantity = 1,
    this.brand,
    this.mfgDate,
    this.batchNumber,
    this.barcode,
    this.description,
    this.location,
    this.images = const [],
  });

  ProductModel copyWith({
    String? id,
    String? name,
    String? category,
    DateTime? expiryDate,
    double? originalPrice,
    int? quantity,
    String? brand,
    DateTime? mfgDate,
    String? batchNumber,
    String? barcode,
    String? description,
    String? location,
    List<String>? images,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      expiryDate: expiryDate ?? this.expiryDate,
      originalPrice: originalPrice ?? this.originalPrice,
      quantity: quantity ?? this.quantity,
      brand: brand ?? this.brand,
      mfgDate: mfgDate ?? this.mfgDate,
      batchNumber: batchNumber ?? this.batchNumber,
      barcode: barcode ?? this.barcode,
      description: description ?? this.description,
      location: location ?? this.location,
      images: images ?? this.images,
    );
  }

  /// Days remaining until expiry. Negative means already expired.
  int get daysRemaining {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expiry.difference(today).inDays;
  }

  bool get isExpired => daysRemaining < 0;

  bool get isExpiringSoon => !isExpired && daysRemaining <= 7;

  /// Discount percentage based on days remaining:
  /// 7 days → 5%, 5 days → 10%, 3 days → 25%, expired → 0 (donate instead)
  double get discountPercentage {
    if (isExpired) return 0;
    if (daysRemaining <= 3) return 25;
    if (daysRemaining <= 5) return 10;
    if (daysRemaining <= 7) return 5;
    return 0;
  }

  double get discountedPrice {
    if (discountPercentage == 0) return originalPrice;
    return originalPrice * (1 - discountPercentage / 100);
  }

  String get statusLabel {
    if (isExpired) return 'Expired';
    if (isExpiringSoon) return 'Expiring Soon';
    return 'Fresh';
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      expiryDate: DateTime.parse(json['expiryDate'] as String),
      originalPrice: (json['originalPrice'] as num).toDouble(),
      quantity: json['quantity'] != null ? (json['quantity'] as num).toInt() : 1,
      brand: json['brand'] as String?,
      mfgDate: json['mfgDate'] != null ? DateTime.parse(json['mfgDate'] as String) : null,
      batchNumber: json['batchNumber'] as String?,
      barcode: json['barcode'] as String?,
      description: json['description'] as String?,
      location: json['location'] as String?,
      images: json['images'] != null ? List<String>.from(json['images'] as List) : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'expiryDate': expiryDate.toIso8601String(),
      'originalPrice': originalPrice,
      'quantity': quantity,
      'brand': brand,
      'mfgDate': mfgDate?.toIso8601String(),
      'batchNumber': batchNumber,
      'barcode': barcode,
      'description': description,
      'location': location,
      'images': images,
    };
  }
}
