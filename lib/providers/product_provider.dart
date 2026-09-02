// import 'package:flutter/foundation.dart';
// import '../models/product_model.dart';
// import '../repositories/product_repository.dart';

// class ProductProvider extends ChangeNotifier {
//   final ProductRepository _repository;

//   List<ProductModel> _products = [];
//   bool _isLoading = false;
//   String? _errorMessage;

//   ProductProvider(this._repository);

//   // ── Getters ──

//   List<ProductModel> get allProducts => _products;

//   List<ProductModel> get expiringSoonProducts =>
//       _products.where((p) => p.isExpiringSoon).toList()
//         ..sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));

//   List<ProductModel> get expiredProducts =>
//       _products.where((p) => p.isExpired).toList()
//         ..sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));

//   List<ProductModel> get top5Products =>
//       _products.take(5).toList();

//   int get expiringSoonCount => expiringSoonProducts.length;
//   int get expiredCount => expiredProducts.length;
//   int get allItemsCount => _products.length;

//   bool get isLoading => _isLoading;
//   String? get errorMessage => _errorMessage;

//   // ── Actions ──

//   Future<void> loadProducts(String userId) async {
//     _isLoading = true;
//     _errorMessage = null;
//     notifyListeners();

//     try {
//       _products = await _repository.getProducts(userId);
//       _isLoading = false;
//       notifyListeners();
//     } catch (e) {
//       _errorMessage = e.toString().replaceAll('Exception: ', '');
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<bool> addProduct(ProductModel product) async {
//     _isLoading = true;
//     _errorMessage = null;
//     notifyListeners();

//     try {
//       final savedProduct = await _repository.addProduct(product);
//       _products.insert(0, savedProduct);
//       _isLoading = false;
//       notifyListeners();
//       return true;
//     } catch (e) {
//       _errorMessage = e.toString().replaceAll('Exception: ', '');
//       _isLoading = false;
//       notifyListeners();
//       return false;
//     }
//   }

//   void updateQuantity(String productId, int newQuantity) {
//     if (newQuantity < 0) return;
//     final index = _products.indexWhere((p) => p.id == productId);
//     if (index != -1) {
//       _products[index] = _products[index].copyWith(quantity: newQuantity);
//       notifyListeners();
//     }
//   }

//   void deleteProduct(String productId) {
//     _products.removeWhere((p) => p.id == productId);
//     notifyListeners();
//   }
// }


//version 2 - CRUD by firestore

import 'package:flutter/foundation.dart';

import '../models/product_model.dart';
import '../repositories/product_repository.dart';

class ProductProvider extends ChangeNotifier {
  final ProductRepository _repository;

  List<ProductModel> _products = [];
  bool _isLoading = false;
  String? _errorMessage;

  ProductProvider(this._repository);

  // ── Getters ──

  List<ProductModel> get allProducts => _products;

  List<ProductModel> get expiringSoonProducts =>
      _products.where((p) => p.isExpiringSoon).toList()
        ..sort(
          (a, b) => a.daysRemaining.compareTo(b.daysRemaining),
        );

  List<ProductModel> get expiredProducts =>
      _products.where((p) => p.isExpired).toList()
        ..sort(
          (a, b) => a.daysRemaining.compareTo(b.daysRemaining),
        );

  List<ProductModel> get top5Products => _products.take(5).toList();

  int get expiringSoonCount => expiringSoonProducts.length;
  int get expiredCount => expiredProducts.length;
  int get allItemsCount => _products.length;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ── Load Products ──

  Future<void> loadProducts(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _products = await _repository.getProducts(userId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');

      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Add Product ──

  Future<bool> addProduct(ProductModel product) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final savedProduct = await _repository.addProduct(product);

      // Firestore generated the real document ID.
      _products.insert(0, savedProduct);

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');

      _isLoading = false;
      notifyListeners();

      return false;
    }
  }

  // ── Update Quantity ──

  Future<bool> updateQuantity(
    String productId,
    int newQuantity,
  ) async {
    if (newQuantity < 0) return false;

    final index = _products.indexWhere(
      (p) => p.id == productId,
    );

    if (index == -1) return false;

    final oldProduct = _products[index];

    final updatedProduct = oldProduct.copyWith(
      quantity: newQuantity,
    );

    // Optimistic UI update:
    // dashboard changes immediately.
    _products[index] = updatedProduct;
    notifyListeners();

    try {
      await _repository.updateProduct(updatedProduct);

      return true;
    } catch (e) {
      // Firestore update failed.
      // Restore the previous value.
      _products[index] = oldProduct;

      _errorMessage = e.toString().replaceAll(
        'Exception: ',
        '',
      );

      notifyListeners();

      return false;
    }
  }

  // ── Delete Product ──

  Future<bool> deleteProduct(String productId) async {
    final index = _products.indexWhere(
      (p) => p.id == productId,
    );

    if (index == -1) return false;

    final deletedProduct = _products[index];

    // Optimistic UI update:
    // remove it immediately from dashboard.
    _products.removeAt(index);
    notifyListeners();

    try {
      await _repository.deleteProduct(productId);

      return true;
    } catch (e) {
      // Firestore delete failed.
      // Put the product back into the local list.
      _products.insert(index, deletedProduct);

      _errorMessage = e.toString().replaceAll(
        'Exception: ',
        '',
      );

      notifyListeners();

      return false;
    }
  }
}