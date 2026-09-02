import '../models/product_model.dart';
import 'product_repository.dart';

class MockProductRepository implements ProductRepository {
  @override
  Future<List<ProductModel>> getProducts(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return [
      // ── Expired products ──
      ProductModel(
        id: 'p1',
        name: 'Whole Milk',
        category: 'Dairy',
        expiryDate: today.subtract(const Duration(days: 3)),
        originalPrice: 4.99,
        quantity: 12,
      ),
      ProductModel(
        id: 'p2',
        name: 'Greek Yogurt',
        category: 'Dairy',
        expiryDate: today.subtract(const Duration(days: 1)),
        originalPrice: 6.49,
        quantity: 8,
      ),
      ProductModel(
        id: 'p3',
        name: 'Sourdough Bread',
        category: 'Bakery',
        expiryDate: today.subtract(const Duration(days: 5)),
        originalPrice: 5.99,
        quantity: 5,
      ),
      ProductModel(
        id: 'p4',
        name: 'Croissants',
        category: 'Bakery',
        expiryDate: today.subtract(const Duration(days: 2)),
        originalPrice: 8.99,
        quantity: 15,
      ),

      // ── Expiring within 3 days (25% discount) ──
      ProductModel(
        id: 'p5',
        name: 'Cheddar Cheese',
        category: 'Dairy',
        expiryDate: today.add(const Duration(days: 2)),
        originalPrice: 7.99,
        quantity: 20,
      ),
      ProductModel(
        id: 'p6',
        name: 'Blueberry Muffins',
        category: 'Bakery',
        expiryDate: today.add(const Duration(days: 1)),
        originalPrice: 6.49,
        quantity: 10,
      ),
      ProductModel(
        id: 'p7',
        name: 'Orange Juice',
        category: 'Beverages',
        expiryDate: today.add(const Duration(days: 3)),
        originalPrice: 5.49,
      ),

      // ── Expiring within 5 days (10% discount) ──
      ProductModel(
        id: 'p8',
        name: 'Butter',
        category: 'Dairy',
        expiryDate: today.add(const Duration(days: 4)),
        originalPrice: 4.49,
      ),
      ProductModel(
        id: 'p9',
        name: 'Potato Chips',
        category: 'Snacks',
        expiryDate: today.add(const Duration(days: 5)),
        originalPrice: 3.99,
      ),

      // ── Expiring within 7 days (5% discount) ──
      ProductModel(
        id: 'p10',
        name: 'Almond Milk',
        category: 'Beverages',
        expiryDate: today.add(const Duration(days: 6)),
        originalPrice: 5.99,
      ),
      ProductModel(
        id: 'p11',
        name: 'Granola Bars',
        category: 'Snacks',
        expiryDate: today.add(const Duration(days: 7)),
        originalPrice: 4.99,
      ),

      // ── Fresh products (no discount) ──
      ProductModel(
        id: 'p12',
        name: 'Sparkling Water',
        category: 'Beverages',
        expiryDate: today.add(const Duration(days: 30)),
        originalPrice: 2.99,
      ),
      ProductModel(
        id: 'p13',
        name: 'Dark Chocolate',
        category: 'Snacks',
        expiryDate: today.add(const Duration(days: 45)),
        originalPrice: 3.49,
      ),
      ProductModel(
        id: 'p14',
        name: 'Cream Cheese',
        category: 'Dairy',
        expiryDate: today.add(const Duration(days: 20)),
        originalPrice: 3.99,
      ),
      ProductModel(
        id: 'p15',
        name: 'Baguette',
        category: 'Bakery',
        expiryDate: today.add(const Duration(days: 12)),
        originalPrice: 4.49,
      ),
    ];
  }
}
