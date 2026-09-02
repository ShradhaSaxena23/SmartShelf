// import 'package:cloud_firestore/cloud_firestore.dart';

// import '../models/product_model.dart';
// import 'product_repository.dart';

// class FirestoreProductRepository implements ProductRepository {
//   final FirebaseFirestore _firestore;

//   FirestoreProductRepository({
//     FirebaseFirestore? firestore,
//   }) : _firestore = firestore ?? FirebaseFirestore.instance;

//   CollectionReference<Map<String, dynamic>> get _productsCollection =>
//       _firestore.collection('products');

//   @override
//   Future<List<ProductModel>> getProducts(String userId) async {
//     try {
//       final snapshot = await _productsCollection.get();

//       final products = snapshot.docs
//           .map((doc) => ProductModel.fromFirestore(doc))
//           .toList();

//       // Keep the same behavior as the previous provider:
//       // products are sorted locally instead of requiring
//       // a Firestore composite index.
//       products.sort(
//         (a, b) => b.expiryDate.compareTo(a.expiryDate),
//       );

//       return products;
//     } catch (e) {
//       throw Exception('Failed to load products: $e');
//     }
//   }

//   @override
//   Future<ProductModel> addProduct(ProductModel product) async {
//     try {
//       final docRef = _productsCollection.doc();

//       final data = product.toFirestore();

//       // Don't save the temporary/local ID.
//       data.remove('id');

//       await docRef.set(data);

//       final savedSnapshot = await docRef.get();

//       return ProductModel.fromFirestore(savedSnapshot);
//     } catch (e) {
//       throw Exception('Failed to add product: $e');
//     }
//   }

//   @override
//   Future<void> updateProduct(ProductModel product) async {
//     try {
//       final data = product.toFirestore();

//       // We don't want createdAt to change every time
//       // quantity is updated.
//       data.remove('createdAt');

//       await _productsCollection.doc(product.id).update(data);
//     } catch (e) {
//       throw Exception('Failed to update product: $e');
//     }
//   }

//   @override
//   Future<void> deleteProduct(String productId) async {
//     try {
//       await _productsCollection.doc(productId).delete();
//     } catch (e) {
//       throw Exception('Failed to delete product: $e');
//     }
//   }
// }

// version 2 with ui and firestore

// import 'package:cloud_firestore/cloud_firestore.dart';

// import '../models/product_model.dart';
// import 'product_repository.dart';

// class FirestoreProductRepository implements ProductRepository {
//   final FirebaseFirestore _firestore;

//   FirestoreProductRepository({
//     FirebaseFirestore? firestore,
//   }) : _firestore =
//             firestore ?? FirebaseFirestore.instance;

//   CollectionReference<Map<String, dynamic>>
//       get _productsCollection =>
//           _firestore.collection('products');

//   @override
//   Future<List<ProductModel>> getProducts(String userId) async {
//     try {
//       final snapshot =
//           await _productsCollection.get();

//       final List<ProductModel> products =
//           snapshot.docs
//               .map(
//                 (doc) => ProductModel.fromFirestore(doc),
//               )
//               .toList();

//       // Sort locally so we don't require
//       // a Firestore composite index.
//       products.sort(
//         (a, b) =>
//             a.expiryDate.compareTo(b.expiryDate),
//       );

//       return products;
//     } catch (e) {
//       throw Exception(
//         'Failed to load products: $e',
//       );
//     }
//   }

//   @override
//   Future<ProductModel> addProduct(
//     ProductModel product,
//   ) async {
//     try {
//       final docRef =
//           _productsCollection.doc();

//       final data = product.toFirestore();

//       await docRef.set(data);

//       final savedSnapshot =
//           await docRef.get();

//       return ProductModel.fromFirestore(
//         savedSnapshot,
//       );
//     } catch (e) {
//       throw Exception(
//         'Failed to add product: $e',
//       );
//     }
//   }

//   @override
//   Future<void> updateProduct(
//     ProductModel product,
//   ) async {
//     try {
//       final data = product.toFirestore();

//       // Don't change createdAt when updating
//       // quantity or another product field.
//       data.remove('createdAt');

//       await _productsCollection
//           .doc(product.id)
//           .update(data);
//     } catch (e) {
//       throw Exception(
//         'Failed to update product: $e',
//       );
//     }
//   }

//   @override
//   Future<void> deleteProduct(
//     String productId,
//   ) async {
//     try {
//       await _productsCollection
//           .doc(productId)
//           .delete();
//     } catch (e) {
//       throw Exception(
//         'Failed to delete product: $e',
//       );
//     }
//   }
// }

//version 3 auth 

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/product_model.dart';
import 'product_repository.dart';

class FirestoreProductRepository implements ProductRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  FirestoreProductRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  // ------------------------------------------------------------
  // Get the currently authenticated user's UID
  // ------------------------------------------------------------

  String get _currentUserId {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw Exception(
        'No authenticated user found. Please sign in again.',
      );
    }

    return user.uid;
  }

  // ------------------------------------------------------------
  // Products collection for a specific user
  //
  // Firestore structure:
  //
  // users
  //   └── {userId}
  //        └── products
  //             ├── productId1
  //             ├── productId2
  //             └── ...
  // ------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> _productsCollection(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('products');
  }

  // ------------------------------------------------------------
  // GET PRODUCTS
  // ------------------------------------------------------------

  @override
  Future<List<ProductModel>> getProducts(String userId) async {
    try {
      // Make sure the requested UID is the authenticated user.
      final authenticatedUser = _firebaseAuth.currentUser;

      if (authenticatedUser == null) {
        throw Exception(
          'No authenticated user found. Please sign in again.',
        );
      }

      if (authenticatedUser.uid != userId) {
        throw Exception(
          'You are not authorized to access these products.',
        );
      }

      final snapshot = await _productsCollection(userId).get();

      final List<ProductModel> products = snapshot.docs
          .map(
            (doc) => ProductModel.fromFirestore(doc),
          )
          .toList();

      // Sort locally so we don't require
      // a Firestore composite index.
      products.sort(
        (a, b) => a.expiryDate.compareTo(b.expiryDate),
      );

      return products;
    } catch (e) {
      throw Exception(
        'Failed to load products: $e',
      );
    }
  }

  // ------------------------------------------------------------
  // ADD PRODUCT
  // ------------------------------------------------------------

  @override
  Future<ProductModel> addProduct(
    ProductModel product,
  ) async {
    try {
      final userId = _currentUserId;

      final docRef = _productsCollection(userId).doc();

      final data = product.toFirestore();

      await docRef.set(data);

      final savedSnapshot = await docRef.get();

      return ProductModel.fromFirestore(
        savedSnapshot,
      );
    } catch (e) {
      throw Exception(
        'Failed to add product: $e',
      );
    }
  }

  // ------------------------------------------------------------
  // UPDATE PRODUCT
  // ------------------------------------------------------------

  @override
  Future<void> updateProduct(
    ProductModel product,
  ) async {
    try {
      final userId = _currentUserId;

      final data = product.toFirestore();

      // Don't change createdAt when updating
      // quantity or another product field.
      data.remove('createdAt');

      await _productsCollection(userId)
          .doc(product.id)
          .update(data);
    } catch (e) {
      throw Exception(
        'Failed to update product: $e',
      );
    }
  }

  // ------------------------------------------------------------
  // DELETE PRODUCT
  // ------------------------------------------------------------

  @override
  Future<void> deleteProduct(
    String productId,
  ) async {
    try {
      final userId = _currentUserId;

      await _productsCollection(userId)
          .doc(productId)
          .delete();
    } catch (e) {
      throw Exception(
        'Failed to delete product: $e',
      );
    }
  }
}