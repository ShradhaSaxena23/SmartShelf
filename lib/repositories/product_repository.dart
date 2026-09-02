
//CRUD by ui

// import '../models/product_model.dart';

// abstract class ProductRepository {
//   Future<List<ProductModel>> getProducts(String userId);
//   Future<ProductModel> addProduct(ProductModel product);
// }


// version 2 - CRUD by firestore

// import '../models/product_model.dart';

// abstract class ProductRepository {
//   Future<List<ProductModel>> getProducts(String userId);

//   Future<ProductModel> addProduct(ProductModel product);

//   Future<void> updateProduct(ProductModel product);

//   Future<void> deleteProduct(String productId);
// }

//version 3- auth

import '../models/product_model.dart';

abstract class ProductRepository {
  Future<List<ProductModel>> getProducts(String userId);

  Future<ProductModel> addProduct(ProductModel product);

  Future<void> updateProduct(ProductModel product);

  Future<void> deleteProduct(String productId);
}