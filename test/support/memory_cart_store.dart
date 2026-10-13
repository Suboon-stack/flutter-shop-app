import 'package:flutter_shop_app/features/cart/data/cart_item.dart';
import 'package:flutter_shop_app/features/cart/data/cart_store.dart';

/// A [CartStore] that keeps everything in memory.
///
/// Widget tests run inside a FakeAsync zone where Hive's real file IO never
/// completes, so seeding the store via [save] here avoids deadlocks.
class MemoryCartStore extends CartStore {
  Map<int, CartItem> _items = <int, CartItem>{};

  @override
  Map<int, CartItem> load() => Map<int, CartItem>.of(_items);

  @override
  Future<void> save(List<CartItem> items) async {
    _items = {for (final item in items) item.product.id: item};
  }
}