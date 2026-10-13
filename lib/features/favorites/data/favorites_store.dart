import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/storage/hive_init.dart';
import '../../products/data/product.dart';

/// Persists favorited products as JSON snapshots inside a Hive box.
class FavoritesStore {
  static const String _key = 'items';
  final Box box = Hive.box(favoritesBoxName);

  List<Product> load() {
    final raw = box.get(_key) as List? ?? const [];
    final result = <Product>[];
    for (final entry in raw) {
      try {
        result.add(Product.fromJson(Map<String, dynamic>.from(entry as Map)));
      } catch (_) {
        // Skip malformed entries.
      }
    }
    return result;
  }

  Future<void> save(List<Product> favorites) async {
    await box.put(_key, favorites.map((product) => product.toJson()).toList());
  }
}