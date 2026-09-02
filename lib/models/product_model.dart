// class ProductModel {
//   final String id;
//   final String name;
//   final String category;
//   final DateTime expiryDate;
//   final double originalPrice;
//   final int quantity;
//   final String? brand;
//   final DateTime? mfgDate;
//   final String? batchNumber;
//   final String? barcode;
//   final String? description;
//   final String? location;
//   final List<String> images;

//   ProductModel({
//     required this.id,
//     required this.name,
//     required this.category,
//     required this.expiryDate,
//     required this.originalPrice,
//     this.quantity = 1,
//     this.brand,
//     this.mfgDate,
//     this.batchNumber,
//     this.barcode,
//     this.description,
//     this.location,
//     this.images = const [],
//   });

//   ProductModel copyWith({
//     String? id,
//     String? name,
//     String? category,
//     DateTime? expiryDate,
//     double? originalPrice,
//     int? quantity,
//     String? brand,
//     DateTime? mfgDate,
//     String? batchNumber,
//     String? barcode,
//     String? description,
//     String? location,
//     List<String>? images,
//   }) {
//     return ProductModel(
//       id: id ?? this.id,
//       name: name ?? this.name,
//       category: category ?? this.category,
//       expiryDate: expiryDate ?? this.expiryDate,
//       originalPrice: originalPrice ?? this.originalPrice,
//       quantity: quantity ?? this.quantity,
//       brand: brand ?? this.brand,
//       mfgDate: mfgDate ?? this.mfgDate,
//       batchNumber: batchNumber ?? this.batchNumber,
//       barcode: barcode ?? this.barcode,
//       description: description ?? this.description,
//       location: location ?? this.location,
//       images: images ?? this.images,
//     );
//   }

//   /// Days remaining until expiry. Negative means already expired.
//   int get daysRemaining {
//     final now = DateTime.now();
//     final today = DateTime(now.year, now.month, now.day);
//     final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
//     return expiry.difference(today).inDays;
//   }

//   bool get isExpired => daysRemaining < 0;

//   bool get isExpiringSoon => !isExpired && daysRemaining <= 7;

//   /// Discount percentage based on days remaining:
//   /// 7 days → 5%, 5 days → 10%, 3 days → 25%, expired → 0 (donate instead)
//   double get discountPercentage {
//     if (isExpired) return 0;
//     if (daysRemaining <= 3) return 25;
//     if (daysRemaining <= 5) return 10;
//     if (daysRemaining <= 7) return 5;
//     return 0;
//   }

//   double get discountedPrice {
//     if (discountPercentage == 0) return originalPrice;
//     return originalPrice * (1 - discountPercentage / 100);
//   }

//   String get statusLabel {
//     if (isExpired) return 'Expired';
//     if (isExpiringSoon) return 'Expiring Soon';
//     return 'Fresh';
//   }

//   factory ProductModel.fromJson(Map<String, dynamic> json) {
//     return ProductModel(
//       id: json['id'] as String,
//       name: json['name'] as String,
//       category: json['category'] as String,
//       expiryDate: DateTime.parse(json['expiryDate'] as String),
//       originalPrice: (json['originalPrice'] as num).toDouble(),
//       quantity: json['quantity'] != null ? (json['quantity'] as num).toInt() : 1,
//       brand: json['brand'] as String?,
//       mfgDate: json['mfgDate'] != null ? DateTime.parse(json['mfgDate'] as String) : null,
//       batchNumber: json['batchNumber'] as String?,
//       barcode: json['barcode'] as String?,
//       description: json['description'] as String?,
//       location: json['location'] as String?,
//       images: json['images'] != null ? List<String>.from(json['images'] as List) : [],
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'name': name,
//       'category': category,
//       'expiryDate': expiryDate.toIso8601String(),
//       'originalPrice': originalPrice,
//       'quantity': quantity,
//       'brand': brand,
//       'mfgDate': mfgDate?.toIso8601String(),
//       'batchNumber': batchNumber,
//       'barcode': barcode,
//       'description': description,
//       'location': location,
//       'images': images,
//     };
//   }
// }


//version 2- without ui

// import 'package:cloud_firestore/cloud_firestore.dart';

// class ProductModel {
//   final String id;
//   final String name;
//   final String category;
//   final int quantity;
//   final DateTime expiryDate;
//   final double price;
//   final double originalPrice;
//   final String? brand;
//   final String? batchNumber;

//   ProductModel({
//     required this.id,
//     required this.name,
//     required this.category,
//     required this.expiryDate,
//     this.quantity = 1,
//     this.price = 0.0,
//     double? originalPrice,
//     this.brand,
//     this.batchNumber,
//   }) : originalPrice = originalPrice ?? price;

//   // --- Computed Getters ---
//   int get daysRemaining {
//     final now = DateTime.now();
//     final today = DateTime(now.year, now.month, now.day);
//     final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
//     return expiry.difference(today).inDays;
//   }

//   bool get isExpired => daysRemaining < 0;

//   bool get isExpiringSoon => daysRemaining >= 0 && daysRemaining <= 7;

//   double get discountPercentage {
//     if (originalPrice <= 0 || price >= originalPrice) return 0.0;
//     return ((originalPrice - price) / originalPrice) * 100;
//   }

//   double get discountedPrice => price;

//   // --- copyWith Method ---
//   ProductModel copyWith({
//     String? id,
//     String? name,
//     String? category,
//     int? quantity,
//     DateTime? expiryDate,
//     double? price,
//     double? originalPrice,
//     String? brand,
//     String? batchNumber,
//   }) {
//     return ProductModel(
//       id: id ?? this.id,
//       name: name ?? this.name,
//       category: category ?? this.category,
//       quantity: quantity ?? this.quantity,
//       expiryDate: expiryDate ?? this.expiryDate,
//       price: price ?? this.price,
//       originalPrice: originalPrice ?? this.originalPrice,
//       brand: brand ?? this.brand,
//       batchNumber: batchNumber ?? this.batchNumber,
//     );
//   }

//   // --- Firestore Serialization ---
//   factory ProductModel.fromFirestore(DocumentSnapshot doc) {
//     Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
//     return ProductModel(
//       id: doc.id,
//       name: data['name'] ?? '',
//       category: data['category'] ?? 'General',
//       quantity: (data['quantity'] ?? 1) as int,
//       expiryDate: data['expiryDate'] is Timestamp
//           ? (data['expiryDate'] as Timestamp).toDate()
//           : DateTime.now(),
//       price: (data['price'] ?? 0.0).toDouble(),
//       originalPrice: (data['originalPrice'] ?? data['price'] ?? 0.0).toDouble(),
//       brand: data['brand'] as String?,
//       batchNumber: data['batchNumber'] as String?,
//     );
//   }

//   Map<String, dynamic> toFirestore() {
//     return {
//       'name': name,
//       'category': category,
//       'quantity': quantity,
//       'expiryDate': Timestamp.fromDate(expiryDate),
//       'price': price,
//       'originalPrice': originalPrice,
//       'brand': brand,
//       'batchNumber': batchNumber,
//       'createdAt': FieldValue.serverTimestamp(),
//     };
//   }
// }

// version 3 - with ui

// import 'package:cloud_firestore/cloud_firestore.dart';

// class ProductModel {
//   final String id;
//   final String name;
//   final String category;
//   final int quantity;
//   final DateTime expiryDate;
//   final double price;
//   final double originalPrice;
//   final String? brand;
//   final String? batchNumber;

//   ProductModel({
//     required this.id,
//     required this.name,
//     required this.category,
//     required this.expiryDate,
//     this.quantity = 1,
//     this.price = 0.0,
//     double? originalPrice,
//     this.brand,
//     this.batchNumber,
//   }) : originalPrice = originalPrice ?? price;

//   // ─────────────────────────────────────────────
//   // Expiry helpers
//   // ─────────────────────────────────────────────

//   int get daysRemaining {
//     final today = DateTime.now();

//     final currentDate = DateTime(
//       today.year,
//       today.month,
//       today.day,
//     );

//     final expiry = DateTime(
//       expiryDate.year,
//       expiryDate.month,
//       expiryDate.day,
//     );

//     return expiry.difference(currentDate).inDays;
//   }

//   bool get isExpired => daysRemaining < 0;

//   bool get isExpiringSoon =>
//       daysRemaining >= 0 && daysRemaining <= 7;

//   String get statusLabel {
//     if (isExpired) {
//       return 'Expired';
//     }

//     if (isExpiringSoon) {
//       return 'Expiring Soon';
//     }

//     return 'Fresh';
//   }

//   // ─────────────────────────────────────────────
//   // Price helpers
//   // ─────────────────────────────────────────────

//   double get discountPercentage {
//     if (originalPrice <= 0 || price >= originalPrice) {
//       return 0.0;
//     }

//     return ((originalPrice - price) / originalPrice) * 100;
//   }

//   double get discountedPrice => price;

//   // ─────────────────────────────────────────────
//   // Copy
//   // ─────────────────────────────────────────────

//   ProductModel copyWith({
//     String? id,
//     String? name,
//     String? category,
//     int? quantity,
//     DateTime? expiryDate,
//     double? price,
//     double? originalPrice,
//     String? brand,
//     String? batchNumber,
//   }) {
//     return ProductModel(
//       id: id ?? this.id,
//       name: name ?? this.name,
//       category: category ?? this.category,
//       quantity: quantity ?? this.quantity,
//       expiryDate: expiryDate ?? this.expiryDate,
//       price: price ?? this.price,
//       originalPrice: originalPrice ?? this.originalPrice,
//       brand: brand ?? this.brand,
//       batchNumber: batchNumber ?? this.batchNumber,
//     );
//   }

//   // ─────────────────────────────────────────────
//   // Firestore → ProductModel
//   // ─────────────────────────────────────────────

//   factory ProductModel.fromFirestore(
//     DocumentSnapshot<Map<String, dynamic>> doc,
//   ) {
//     final data = doc.data() ?? {};

//     final expiryValue = data['expiryDate'];

//     DateTime expiryDate;

//     if (expiryValue is Timestamp) {
//       expiryDate = expiryValue.toDate();
//     } else if (expiryValue is String) {
//       expiryDate =
//           DateTime.tryParse(expiryValue) ?? DateTime.now();
//     } else {
//       expiryDate = DateTime.now();
//     }

//     final quantityValue = data['quantity'];

//     int quantity = 1;

//     if (quantityValue is num) {
//       quantity = quantityValue.toInt();
//     } else if (quantityValue != null) {
//       quantity = int.tryParse(
//             quantityValue.toString(),
//           ) ??
//           1;
//     }

//     final priceValue = data['price'];

//     double price = 0.0;

//     if (priceValue is num) {
//       price = priceValue.toDouble();
//     } else if (priceValue != null) {
//       price = double.tryParse(
//             priceValue.toString(),
//           ) ??
//           0.0;
//     }

//     final originalPriceValue = data['originalPrice'];

//     double originalPrice = price;

//     if (originalPriceValue is num) {
//       originalPrice = originalPriceValue.toDouble();
//     } else if (originalPriceValue != null) {
//       originalPrice = double.tryParse(
//             originalPriceValue.toString(),
//           ) ??
//           price;
//     }

//     return ProductModel(
//       id: doc.id,
//       name: data['name']?.toString() ?? '',
//       category: data['category']?.toString() ?? 'General',
//       quantity: quantity,
//       expiryDate: expiryDate,
//       price: price,
//       originalPrice: originalPrice,
//       brand: data['brand']?.toString(),
//       batchNumber: data['batchNumber']?.toString(),
//     );
//   }

//   // ─────────────────────────────────────────────
//   // ProductModel → Firestore
//   // ─────────────────────────────────────────────

//   Map<String, dynamic> toFirestore() {
//     return {
//       'name': name,
//       'category': category,
//       'quantity': quantity,
//       'expiryDate': Timestamp.fromDate(expiryDate),
//       'price': price,
//       'originalPrice': originalPrice,
//       'brand': brand,
//       'batchNumber': batchNumber,
//       'createdAt': FieldValue.serverTimestamp(),
//     };
//   }
// }

// version 3- firestore + ui +discount

import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String name;
  final String category;
  final int quantity;
  final DateTime expiryDate;

  // Keep these as the actual stored prices.
  // originalPrice should always remain the original/full price.
  final double price;
  final double originalPrice;

  final String? brand;
  final String? batchNumber;

  ProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.expiryDate,
    this.quantity = 1,
    this.price = 0.0,
    double? originalPrice,
    this.brand,
    this.batchNumber,
  }) : originalPrice = originalPrice ?? price;

  // ─────────────────────────────────────────────
  // Expiry helpers
  // ─────────────────────────────────────────────

  int get daysRemaining {
    final today = DateTime.now();

    final currentDate = DateTime(
      today.year,
      today.month,
      today.day,
    );

    final expiry = DateTime(
      expiryDate.year,
      expiryDate.month,
      expiryDate.day,
    );

    return expiry.difference(currentDate).inDays;
  }

  bool get isExpired => daysRemaining < 0;

  bool get isExpiringSoon =>
      daysRemaining >= 0 && daysRemaining <= 7;

  bool get isFresh => daysRemaining > 7;

  String get statusLabel {
    if (isExpired) {
      return 'Expired';
    }

    if (isExpiringSoon) {
      return 'Expiring Soon';
    }

    return 'Fresh';
  }

  // ─────────────────────────────────────────────
  // Price helpers
  // ─────────────────────────────────────────────

  /// Discount based on how many days are remaining.
  ///
  /// Expired:
  ///   < 0 days -> 100%
  ///
  /// Expiring Soon:
  ///   0-3 days -> 20%
  ///   4-5 days -> 10%
  ///   6-7 days -> 5%
  ///
  /// Fresh:
  ///   > 7 days -> 0%
  double get discountPercentage {
    final days = daysRemaining;

    // Expired
    if (days < 0) {
      return 100.0;
    }

    // 0 to 3 days
    if (days <= 3) {
      return 20.0;
    }

    // 4 to 5 days
    if (days <= 5) {
      return 10.0;
    }

    // 6 to 7 days
    if (days <= 7) {
      return 5.0;
    }

    // Fresh
    return 0.0;
  }

  /// Final selling price calculated from the ORIGINAL price.
  ///
  /// Important:
  /// We do NOT calculate this from `price`.
  /// This prevents discounts from being compounded.
  double get discountedPrice {
    if (isExpired) {
      return 0.0;
    }

    final discount = discountPercentage;

    if (discount == 0) {
      return originalPrice;
    }

    return originalPrice * (1 - discount / 100);
  }

  // ─────────────────────────────────────────────
  // Copy
  // ─────────────────────────────────────────────

  ProductModel copyWith({
    String? id,
    String? name,
    String? category,
    int? quantity,
    DateTime? expiryDate,
    double? price,
    double? originalPrice,
    String? brand,
    String? batchNumber,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      expiryDate: expiryDate ?? this.expiryDate,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      brand: brand ?? this.brand,
      batchNumber: batchNumber ?? this.batchNumber,
    );
  }

  // ─────────────────────────────────────────────
  // Firestore → ProductModel
  // ─────────────────────────────────────────────

  factory ProductModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    // ─────────────────────────────────────────
    // Expiry date
    // ─────────────────────────────────────────

    final expiryValue = data['expiryDate'];

    DateTime expiryDate;

    if (expiryValue is Timestamp) {
      expiryDate = expiryValue.toDate();
    } else if (expiryValue is String) {
      expiryDate =
          DateTime.tryParse(expiryValue) ?? DateTime.now();
    } else {
      expiryDate = DateTime.now();
    }

    // ─────────────────────────────────────────
    // Quantity
    // ─────────────────────────────────────────

    final quantityValue = data['quantity'];

    int quantity = 1;

    if (quantityValue is num) {
      quantity = quantityValue.toInt();
    } else if (quantityValue != null) {
      quantity =
          int.tryParse(quantityValue.toString()) ?? 1;
    }

    // ─────────────────────────────────────────
    // Price
    // ─────────────────────────────────────────

    final priceValue = data['price'];

    double price = 0.0;

    if (priceValue is num) {
      price = priceValue.toDouble();
    } else if (priceValue != null) {
      price =
          double.tryParse(priceValue.toString()) ?? 0.0;
    }

    // ─────────────────────────────────────────
    // Original price
    // ─────────────────────────────────────────

    final originalPriceValue = data['originalPrice'];

    double originalPrice = price;

    if (originalPriceValue is num) {
      originalPrice = originalPriceValue.toDouble();
    } else if (originalPriceValue != null) {
      originalPrice =
          double.tryParse(originalPriceValue.toString()) ?? price;
    }

    return ProductModel(
      id: doc.id,
      name: data['name']?.toString() ?? '',
      category: data['category']?.toString() ?? 'General',
      quantity: quantity,
      expiryDate: expiryDate,
      price: price,
      originalPrice: originalPrice,
      brand: data['brand']?.toString(),
      batchNumber: data['batchNumber']?.toString(),
    );
  }

  // ─────────────────────────────────────────────
  // ProductModel → Firestore
  // ─────────────────────────────────────────────

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category,
      'quantity': quantity,
      'expiryDate': Timestamp.fromDate(expiryDate),

      // Keep original price intact.
      'price': price,
      'originalPrice': originalPrice,

      'brand': brand,
      'batchNumber': batchNumber,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}