import '../models/product_model.dart';
import 'product_repository.dart';

class MockProductRepository implements ProductRepository {
  final List<ProductModel> _items = [];
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _items.addAll([
      ProductModel(
        id: 'p1',
        name: 'Whole Milk',
        category: 'Dairy',
        expiryDate: today.subtract(const Duration(days: 3)),
        originalPrice: 4.99,
        quantity: 12,
        brand: 'Amul',
        batchNumber: 'BCH-2026-01',
      ),
      ProductModel(
        id: 'p2',
        name: 'Greek Yogurt',
        category: 'Dairy',
        expiryDate: today.subtract(const Duration(days: 1)),
        originalPrice: 6.49,
        quantity: 8,
        brand: 'Chobani',
        batchNumber: 'BCH-2026-02',
      ),
      ProductModel(
        id: 'p3',
        name: 'Sourdough Bread',
        category: 'Bakery',
        expiryDate: today.subtract(const Duration(days: 5)),
        originalPrice: 5.99,
        quantity: 5,
        brand: 'Boudin',
        batchNumber: 'BCH-2026-03',
      ),
      ProductModel(
        id: 'p4',
        name: 'Croissants',
        category: 'Bakery',
        expiryDate: today.subtract(const Duration(days: 2)),
        originalPrice: 8.99,
        quantity: 15,
        brand: 'La Boulangerie',
        batchNumber: 'BCH-2026-04',
      ),
      ProductModel(
        id: 'p5',
        name: 'Cheddar Cheese',
        category: 'Dairy',
        expiryDate: today.add(const Duration(days: 2)),
        originalPrice: 7.99,
        quantity: 20,
        brand: 'Tillamook',
        batchNumber: 'BCH-2026-05',
      ),
      ProductModel(
        id: 'p6',
        name: 'Blueberry Muffins',
        category: 'Bakery',
        expiryDate: today.add(const Duration(days: 1)),
        originalPrice: 6.49,
        quantity: 10,
        batchNumber: 'BCH-2026-06',
      ),
      ProductModel(
        id: 'p7',
        name: 'Orange Juice',
        category: 'Beverages',
        expiryDate: today.add(const Duration(days: 3)),
        originalPrice: 5.49,
        brand: 'Tropicana',
        batchNumber: 'BCH-2026-07',
      ),
      ProductModel(
        id: 'p8',
        name: 'Butter',
        category: 'Dairy',
        expiryDate: today.add(const Duration(days: 4)),
        originalPrice: 4.49,
        brand: 'Amul',
        batchNumber: 'BCH-2026-08',
      ),
      ProductModel(
        id: 'p9',
        name: 'Potato Chips',
        category: 'Snacks',
        expiryDate: today.add(const Duration(days: 5)),
        originalPrice: 3.99,
        brand: 'Lay\'s',
        batchNumber: 'BCH-2026-09',
      ),
      ProductModel(
        id: 'p10',
        name: 'Almond Milk',
        category: 'Beverages',
        expiryDate: today.add(const Duration(days: 6)),
        originalPrice: 5.99,
        brand: 'Silk',
        batchNumber: 'BCH-2026-10',
      ),
      ProductModel(
        id: 'p11',
        name: 'Granola Bars',
        category: 'Snacks',
        expiryDate: today.add(const Duration(days: 7)),
        originalPrice: 4.99,
        brand: 'Nature Valley',
        batchNumber: 'BCH-2026-11',
      ),
      ProductModel(
        id: 'p12',
        name: 'Sparkling Water',
        category: 'Beverages',
        expiryDate: today.add(const Duration(days: 30)),
        originalPrice: 2.99,
        brand: 'Perrier',
        batchNumber: 'BCH-2026-12',
      ),
      ProductModel(
        id: 'p13',
        name: 'Dark Chocolate',
        category: 'Snacks',
        expiryDate: today.add(const Duration(days: 45)),
        originalPrice: 3.49,
        brand: 'Lindt',
        batchNumber: 'BCH-2026-13',
      ),
      ProductModel(
        id: 'p14',
        name: 'Cream Cheese',
        category: 'Dairy',
        expiryDate: today.add(const Duration(days: 20)),
        originalPrice: 3.99,
        brand: 'Philadelphia',
        batchNumber: 'BCH-2026-14',
      ),
      ProductModel(
        id: 'p15',
        name: 'Baguette',
        category: 'Bakery',
        expiryDate: today.add(const Duration(days: 12)),
        originalPrice: 4.49,
        batchNumber: 'BCH-2026-15',
      ),
    ]);
    _initialized = true;
  }

  @override
  Future<List<ProductModel>> getProducts(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    await _ensureInitialized();
    return List.from(_items);
  }

  @override
  Future<ProductModel> addProduct(ProductModel product) async {
    await Future.delayed(const Duration(milliseconds: 400));
    await _ensureInitialized();
    final newId = 'p_${DateTime.now().millisecondsSinceEpoch}';
    final savedProduct = product.copyWith(id: newId);
    _items.insert(0, savedProduct);
    return savedProduct;
  }
}
