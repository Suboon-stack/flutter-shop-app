import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/storage/hive_init.dart';
import 'cart_item.dart';

/// Persists the cart as JSON snapshots inside a Hive box.
class CartStore {
  static const String _key = 'items';
  final Box box = Hive.box(cartBoxName);

  Map<int, CartItem> load() {
    final raw = box.get(_key) as List? ?? const [];
    final result = <int, CartItem>{};
    for (final entry in raw) {
      try {
        final item = CartItem.fromJson(
          Map<String, dynamic>.from(entry as Map),
        );
        result[item.product.id] = item;
      } catch (_) {
        // Skip malformed entries so storage corruption never crashes the app.
      }
    }
    return result;
  }

  Future<void> save(List<CartItem> items) async {
    await box.put(
      _key,
      items.map((item) => item.toJson()).toList(),
    );
  }
}